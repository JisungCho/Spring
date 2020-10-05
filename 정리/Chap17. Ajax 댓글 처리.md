# Chap17. Ajax 댓글 처리

- 데이터베이스 상에서 댓글은 전형적인 1:N 의 관계
- 하나의 게시물에 여러 개의 댓글을 추가하는 형태로 구성
- 화면은 조회 화면상에서 별도의 화면 이동 없이 처리하기 때문에 Ajax를 이용해서 호출

### 댓글 처리를 위한 영속 설정

- tbl_reply

  ```sql
  create table tbl_reply(
  	rno number(10,0),
      bno number(10,0) not null,
      reply varchar2(1000) not null,
      replyer varchar2(50) not null,
      replyDate date default sysdate,
      updateDate date default sysdate
  );
  
  create sequence seq_reply;
  
  alter table tbl_reply add constraint pk_reply primary key (rno); /*PK설정*/
  
  alter table tbl_reply add constraint fk_reply_board foreign key (bno) references tbl_board (bno);/*tbl_board 참조*/
  ```

1. ReplyVO 클래스의 추가

   ```java
   package org.zerock.domain;
   
   import java.util.Date;
   
   import lombok.Data;
   
   @Data
   public class ReplyVO {
   	private Long rno;
   	private Long bno;
   	
   	private String reply;
   	private String replyer;
   	private Date replyDate;
   	private Date updateDate;
   }
   
   ```

2. ReplyMapper 클래스와 xml 처리

   ```java
   package org.zerock.mapper;
   
   import java.util.List;
   
   import org.apache.ibatis.annotations.Param;
   import org.zerock.domain.Criteria;
   import org.zerock.domain.ReplyVO;
   
   public interface ReplyMapper {
   	
   }
   
   ```

   ```xml
   <?xml version="1.0" encoding="UTF-8" ?>
   <!DOCTYPE mapper
     PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
     "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
   <!--namespace 주의-->
   <mapper namespace="org.zerock.mapper.ReplyMapper">
   
   </mapper>
   ```

   - ReplyMapper 테스트

     ```java
     package org.zerock.mapper;
     
     import java.util.List;
     import java.util.stream.IntStream;
     
     import org.junit.Test;
     import org.junit.runner.RunWith;
     import org.springframework.beans.factory.annotation.Autowired;
     import org.springframework.test.context.ContextConfiguration;
     import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
     import org.zerock.domain.Criteria;
     import org.zerock.domain.ReplyVO;
     
     import lombok.Setter;
     import lombok.extern.log4j.Log4j;
     
     @RunWith(SpringJUnit4ClassRunner.class)
     @ContextConfiguration("file:src/main/webapp/WEB-INF/spring/root-context.xml")
     @Log4j
     public class ReplyMapperTests {
     	@Setter(onMethod_ = @Autowired)
     	private ReplyMapper mapper;
     	
     	private Long[] bnoArr = { //존재는 게시물의 번호
     			60L,61L,62L,63L,64L
     	};
         
     	@Test
     	public void testMapper() {
     		log.info(mapper);
     	}
     }
     
     ```

3. CRUD작업

   - 등록,수정,삭제 조회 작업을 처리

   - 등록

     ```JAVA
     package org.zerock.mapper;
     
     import java.util.List;
     
     import org.apache.ibatis.annotations.Param;
     import org.zerock.domain.Criteria;
     import org.zerock.domain.ReplyVO;
     
     public interface ReplyMapper {
     	public int insert(ReplyVO vo);
     }
     ```

     ```XML
     <insert id="insert">
     	insert into tbl_reply (rno,bno,reply,replyer) 
     	values (seq_reply.nextval,#{bno},#{reply},#{replyer})
     </insert>
     ```

     ```JAVA
     	@Test
     	public void testCreate() {
     		IntStream.rangeClosed(1, 10).forEach(i -> {
     			ReplyVO vo = new ReplyVO();
     			
     			//게시물 번호
     			vo.setBno(bnoArr[i % 5]); // bnoArr의 0,1,2,3,4째
     			vo.setReply("댓글 테스트 " +i);
     			vo.setReplyer("replyer " + i);
     			
     			mapper.insert(vo);
     		});
     	}
     ```

   - 조회

     ```java
     public ReplyVO read(Long rno);
     ```

     ```xml
     <select id="read" resultType="org.zerock.domain.ReplyVO">
     	select * from tbl_reply where rno = #{rno}
     </select>
     ```

     ```java
     	@Test
     	public void testRead() {
     		Long targetRno = 5L;
     		
     		ReplyVO vo = mapper.read(targetRno);
     		
     		log.info(vo);
     	}
     ```

   - 삭제

     ```java
     public int delete(Long rno);
     ```

     ```xml
     <delete id="delete">
     	delete from tbl_reply where rno = #{rno}
     </delete>
     ```

     ```java
     	public void testDelete() {
     		Long targetRno = 3L;
     		
     		mapper.delete(targetRno);
     	}
     ```

   - 수정

     ```java
     public int update(ReplyVO reply);
     ```

     ```xml
     <update id="update">
     	update tbl_reply set reply = #{reply}, updateDate = sysdate where rno = #{rno}
     </update>
     ```

     ```java
     	@Test
     	public void testUpdate() {
     		Long targeRno = 10L;
     		
     		ReplyVO vo = mapper.read(targeRno);
     		
     		vo.setReply("Update Reply");
     		
     		int count = mapper.update(vo);
     		
     		log.info("Update Count :" +count);
     	}
     ```

4. @Param 어노테이션과 댓글 목록

   - 댓글의 목록과 페이징 처리는 기존의 게시물 페이징 처리와 유사하지만 추가적으로 특정한 게시물의 댓글들만을 대상으로 하기 떄문에 추가로 게시물의 번호가 필요

   - MyBatis는 두 ㄱ 이상의 데이터를 파라미터로 전달

     1. 별도의 객체로 구성
     2. Map을 이용
     3. @Param을 이용 -> 가장 간단
        - Param의 속성값은 MyBatis에서 SQL을 이용할 때 #{ }의 이름으로 사용이 가능

     ```JAVA
     	public List<ReplyVO> getListWithPaging(
     				@Param("cri") Criteria cri, //XML에서 사용가능
     				@Param("bno") Long bno // XML에서 사용가능
     	);
     ```

     ```XML
     <select id="getListWithPaging" resultType="org.zerock.domain.ReplyVO">
     		<![CDATA[
     			select rno,bno,reply,replyer,replydate,updatedate
     			from tbl_reply
     			where bno = #{bno}
     			order by rno asc
     		]]>
     </select>
     ```

     ```java
     	@Test
     	public void testList() {
     		
     		Criteria cri = new Criteria();
     		
     		List<ReplyVO> replies = mapper.getListWithPaging(cri, bnoArr[1]);
     		
     		replies.forEach(reply -> log.info(reply));
     	}
     ```

### 서비스 영역과 Controller 처리

- ReplyService 인터페이스와 ReplyServiceImpl클래스를 작성

  ```java
  package org.zerock.service;
  
  import java.util.List;
  
  import org.zerock.domain.Criteria;
  import org.zerock.domain.ReplyPageDTO;
  import org.zerock.domain.ReplyVO;
  
  public interface ReplyService {
  	public int register(ReplyVO vo); //등록
  	
  	public ReplyVO get(Long rno); //조회
  	
  	public int modify(ReplyVO vo); //수정
  	
  	public int remove(Long rno); //삭제
  	
  	public List<ReplyVO> getList(Criteria cri,Long bno); //목록
  	
  }
  
  ```

  ```java
  package org.zerock.service;
  
  import java.util.List;
  
  import org.springframework.beans.factory.annotation.Autowired;
  import org.springframework.stereotype.Service;
  import org.zerock.domain.Criteria;
  import org.zerock.domain.ReplyPageDTO;
  import org.zerock.domain.ReplyVO;
  import org.zerock.mapper.ReplyMapper;
  
  import lombok.extern.log4j.Log4j;
  
  @Service
  @Log4j
  public class ReplyServiceImpl implements ReplyService{
  	
  	@Autowired
  	private ReplyMapper mapper;
  
  	@Override
  	public int register(ReplyVO vo) {
  		log.info("register......."+vo);
  		return mapper.insert(vo);
  	}
  
  	@Override
  	public ReplyVO get(Long rno) {
  		log.info("get......."+rno);
  		return mapper.read(rno);
  	}
  
  	@Override
  	public int modify(ReplyVO vo) {
  		log.info("modify........."+vo);
  		
  		return mapper.update(vo);
  	}
  
  	@Override
  	public int remove(Long rno) {
  		log.info("remove......"+rno);
  		
  		return mapper.delete(rno);
  	}
  
  	@Override
  	public List<ReplyVO> getList(Criteria cri, Long bno) {
  		log.info("get Reply List of a Board " + bno);
  		
  		return mapper.getListWithPaging(cri, bno);
  	}
  
  }
  
  ```

1. ReplyController의 설계

   - @ResetController 어노테이션을 이용해서 설계

     |  작업  |            URL            | HTTP 전송방식 |
     | :----: | :-----------------------: | ------------- |
     |  등록  |       /replies/new        | POST          |
     |  조회  |       /replies/:rno       | GET           |
     |  삭제  |       /replies/:rno       | DELETE        |
     |  수정  |       /replies/:rno       | PUT           |
     | 페이지 | /replies/pages/:bno/:page | GET           |

     - REST 방식으로 동작하는 URL을 설계 할 때는 PK를 기준으로 작성

     ```JAVA
     package org.zerock.controller;
     
     import java.util.List;
     
     import org.apache.ibatis.annotations.Delete;
     import org.springframework.http.HttpStatus;
     import org.springframework.http.MediaType;
     import org.springframework.http.ResponseEntity;
     import org.springframework.web.bind.annotation.DeleteMapping;
     import org.springframework.web.bind.annotation.GetMapping;
     import org.springframework.web.bind.annotation.PathVariable;
     import org.springframework.web.bind.annotation.PostMapping;
     import org.springframework.web.bind.annotation.RequestBody;
     import org.springframework.web.bind.annotation.RequestMapping;
     import org.springframework.web.bind.annotation.RequestMethod;
     import org.springframework.web.bind.annotation.RestController;
     import org.zerock.domain.Criteria;
     import org.zerock.domain.ReplyPageDTO;
     import org.zerock.domain.ReplyVO;
     import org.zerock.service.ReplyService;
     
     import lombok.AllArgsConstructor;
     import lombok.extern.log4j.Log4j;
     
     @RestController // REST방식
     @RequestMapping("/replies/")
     @Log4j
     @AllArgsConstructor
     public class ReplyController {
     	//자동주입
     	private ReplyService service;
     }
     
     ```

2. 등록 작업과 테스트

   - REST 방식으로 처리할 때 주의해야 하는 점은 **브라우저나 외부에서 서버를 호출할 때 데이터의 포맷과 서버에서 보내주는 데이터의 타입을 명확히 설계**

   ```JAVA
   //json데이터가 들어오면 일반 문자열을 전달
   @PostMapping(value = "/new" , consumes = "application/json" ,produces = {MediaType.TEXT_PLAIN_VALUE})
   	public ResponseEntity<String> create(@RequestBody ReplyVO vo){ //들어온 json데이터를 ReplyVO형태로 맵핑
   		log.info("ReplyVO :"+ vo);
   		
   		int insertCount = service.register(vo); // 업로드 성공하면 1
   		
   		log.info("Reply INSERT COUNT : "+insertCount);
   		
   		return insertCount == 1 ? new ResponseEntity<String>("success",HttpStatus.OK) : new ResponseEntity<String>(HttpStatus.INTERNAL_SERVER_ERROR);
   	}
   ```

3. 특정 게시물의 댓글 목록 확인

   ```JAVA
   @GetMapping(value="/pages/{bno}/{page}", produces= {
   			MediaType.APPLICATION_XML_VALUE, MediaType.APPLICATION_JSON_VALUE
   	})
   	public ResponseEntity<List<ReplyVO>> getList(
   			@PathVariable("page") int page,
   			@PathVariable("bno") Long bno
   			) {
   		log.info("getList...............");
   		Criteria cri = new Criteria(page, 10);
   		log.info(cri);
   		return new ResponseEntity<>(service.getList(cri, bno), HttpStatus.OK);
   	}
   ```

4. 댓글 삭제/조회

   ```JAVA
   	@GetMapping(value = "/{rno}" , produces = {
   			MediaType.APPLICATION_XML_VALUE,
   			MediaType.APPLICATION_JSON_UTF8_VALUE}) //xml, json반환
   	public ResponseEntity<ReplyVO> get(@PathVariable("rno") Long rno){
   		log.info("get : "+rno);
   		
   		return new ResponseEntity<ReplyVO>(service.get(rno), HttpStatus.OK); // body,header리턴
   	}
   	
   	@DeleteMapping(value = "/{rno}" , produces = {MediaType.TEXT_PLAIN_VALUE})
   	public ResponseEntity<String> remove(@PathVariable("rno") Long rno){
   		log.info("remove : "+rno);
   		
   		return service.remove(rno) == 1 
   		? new ResponseEntity<String>("success", HttpStatus.OK)
   		: new ResponseEntity<String>(HttpStatus.INTERNAL_SERVER_ERROR);
   	}
   ```

5. 댓글 수정

   ```java
   	@RequestMapping(method = {RequestMethod.PUT , RequestMethod.PATCH},
   			value="/{rno}",
   			consumes = "application/json", //json데이터가 들어옴
   			produces = {MediaType.TEXT_PLAIN_VALUE}) // 일반 문자열 반환
   	public ResponseEntity<String> modify(@PathVariable("rno") Long rno , @RequestBody ReplyVO vo){
   		
   		vo.setRno(rno); //vo의 rno설정
   		
   		log.info("rno...."+rno);
   		log.info("modify: "+vo);
   		return service.modify(vo) == 1
   				? new ResponseEntity<String>("success", HttpStatus.OK)
   						: new ResponseEntity<String>(HttpStatus.INTERNAL_SERVER_ERROR);
   	}
   ```

   