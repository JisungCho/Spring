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


### JavaScript 준비

1. JavaScript의 모듈화

   - jQuery를 이용해 Ajax를 쉽게 처리

   - 화면 내에서 JS처리를 하다보면 언 순간 이벤트 처리와 DOM처리,Ajax처리 등이 마구 섞여서 유지보수가 힘든 코드를 만들 수 있음 => JS를 하나의 모듈처럼 구성

     - webapp / resources / js / reply.js 추가

       ```js
       console.log("Reply Module......");
       
       var replyService = {};
       ```

     - board/get.jsp에 reply.js추가

       ```jsp
       		<!-- /.modal-content -->
       	</div>
       	<!-- /.modal-dialog -->
       </div>
       <!-- /.modal -->
       <script type="text/javascript" src="/resources/js/reply.js"></script> <!-- reply.js 추가 -->
       <script>
        
       	console.log("===============");
       	console.log("JS TEST");
       ```

   - 모듈 구성하기

     - **모듈 패턴 : Java의 클래스처럼 JS를 이용해서 메서드를 가지는 객체**

     - **모듈 패턴은 JS의 즉시 실행함수와  { } 를 이용해서 객체를 구성**

     - **JS의 즉시 실행 함수는  ( )안에 함수를 선언하고 바깥쪽에서 실행해 버림**

     - reply.js

       ```JAVA
       console.log("Reply Module......");
       
       var replyService = (function(){ //replyService라는 변수에 name이라는 속성에 'AAAA'라는 속성값을 가진 객체가 할당
       	return {name:"AAAA"};
       })();
       ```

     - get.jsp

       ```jsp
       <script type="text/javascript" src="/resources/js/reply.js"></script> <!-- reply.js 추가 -->
       <script type="text/javascript">
       	$(document).ready(function(){
       		console.log(replyService);
       	});
       </script>
       ```

2. reply.js 등록 처리

   - 즉시 실행하는 함수 내부에서 필요한 메서드를 구성해서 객체를 구성

   - reply.js

     ```js
     console.log("Reply Module......");
     
     var replyService = (function(){
     	
     	function add(reply, callback, error) { // 파라미터로 callback 과 error를 함수로 받음
     		console.log("add reply...............");
     
     		$.ajax({
     			type : 'post', //post방식
     			url : '/replies/new',  //url
     			data : JSON.stringify(reply), //JavaScript 값이나 객체를 JSON 문자열로 변환
     			contentType : "application/json; charset=utf-8", // MIMETYPE : JSON
     			success : function(result, status, xhr) { //성공시
     				if (callback) {
     					callback(result);
     				}
     			},
     			error : function(xhr, status, er) { //실패시
     				if (error) {
     					error(er);
     				}
     			}
     		})
     	}
         
         return {add:add}; //add의 결과를 add속성에 담음
     })();
     		
     ```

   - JS는 특이하게 함수의 파라미터 개수를 일치시킬 필요가 없다. 따라서 callback이나 error와 같은 파라미터는 필요에 따라서 작성할 수 있음

   - get.jsp

     ```jsp
     <script type="text/javascript" src="/resources/js/reply.js"></script> <!-- reply.js 추가 -->
     <script>
      
     	console.log("===============");
     	console.log("JS TEST");
     	
     	var bnoValue = '<c:out value="${board.bno}"/>'; //게시물의 번호 
     	
      	//for replyService add test
     	replyService.add(
     	    //객체타입으로 전달
     	    {reply:"JS Test", replyer:"tester", bno:bnoValue}
     	    ,
             //Ajax 전송결과를 처리하는 함수를 파라미터도 같이전달
     	    function(result){ 
     	      alert("RESULT: " + result);
     	    }
     	);  
     </script>
     ```

3. 댓글의 목록 처리

   - 페이징 처리를 제외하고 전체 댓글을 가져오는 형태로 일단 구현

   - reply.js

     ```js
     var replyService = (function(){
     	
     	function add(reply, callback, error) { // 파라미터로 callback 과 error를 함수로 받음
     		console.log("add reply...............");
     
     		$.ajax({
     			type : 'post', //post방식
     			url : '/replies/new',  //url
     			data : JSON.stringify(reply), //JavaScript 값이나 객체를 JSON 문자열로 변환
     			contentType : "application/json; charset=utf-8", // MIMETYPE : JSON
     			success : function(result, status, xhr) { //성공시
     				if (callback) {
     					callback(result);
     				}
     			},
     			error : function(xhr, status, er) { //실패시
     				if (error) {
     					error(er);
     				}
     			}
     		})
     	}
         
         function getList(param, callback, error) {
     		
     		var bno = param.bno;
     		var page = param.page || 1;
     		
             //getJSON ; http의 method를 통해서 서버의 특정 uri가 던져주는 결과를 JSON형태로 받아오는 역활
     		$.getJSON("/replies/pages/"+bno+"/"+page+".json",
     			function(data){
     				if(callback){
     					callback(data);
     				}
     			}).fail(function(xhr,status,err){
     				if(error){
     					error();
     				}
     			});
     	}
         
         return {
             add:add
         	getList:getList
         }; 
     })();	
     
     ```

   - get.jsp

     ```jsp
     <script type="text/javascript" src="/resources/js/reply.js"></script> <!-- reply.js 추가 -->
     <script>
      
     	console.log("===============");
     	console.log("JS TEST");
     	
     	var bnoValue = '<c:out value="${board.bno}"/>'; //게시물의 번호 
     	
         //bno와 page번호 날려줌 , callback함수
         replyService.getList({bno:bnoValue, page:1},function(list){
     		for(var i=0, len = list.length||0; i<len; i++){
     			console.log(list[i]);
     		}
     	}); 
         
     </script>
     ```

4. 댓글 삭제와 갱신

   - reply.js

     ```js
     var replyService = (function(){
     	
     	function add(reply, callback, error) { // 파라미터로 callback 과 error를 함수로 받음
     		....
     	}
         
         function getList(param, callback, error) {
     			....
     	}
     	
     	function remove(rno, callback, error) { //댓글번호
     		console.log("remove...............");
     
     		$.ajax({
     			type : 'delete', //REST delete
     			url : '/replies/'+rno ,
     			success : function(deleteResult, status, xhr) {
     				if (callback) {
     					callback(deleteResult); //callback함수에 deleteResult전달 , 삭제결과
     				}
     			},
     			error : function(xhr, status, er) {
     				if (error) {
     					error(er);
     				}
     			}
     		})
     	}	
     	
         
         return {
             add:add
         	getList:getList
         	remove:remove
         }; 
     })();	
     ```

   - get.jsp

     ```jsp
     <script type="text/javascript" src="/resources/js/reply.js"></script> <!-- reply.js 추가 -->
     <script>
      
     	console.log("===============");
     	console.log("JS TEST");
     	
     	var bnoValue = '<c:out value="${board.bno}"/>'; //게시물의 번호 
     	
     	replyService.remove(18, function(count) { //18번 댓글 삭제
     		console.log(count);
     		
     		if(count === "success"){
     			alert("REMOVED");
     		}
     	}, function(err) {
     		alert("ERROR");
     	});
         
     </script>
     ```

5. 댓글 수정

   - 수정하는 내용과 함께 댓글의 번호를 전송

   - reply.js

     ```js
     var replyService = (function(){
     	
     	function add(reply, callback, error) { // 파라미터로 callback 과 error를 함수로 받음
     		....
     	}
         
         function getList(param, callback, error) {
     			....
     	}
     	
     	function remove(rno, callback, error) { //댓글번호
     		....
     	}	
     	
         function update(reply, callback, error) { 
     		console.log("update..............."+reply.rno);
     
     		$.ajax({
     			type : 'put', //REST PUT
     			url : '/replies/'+reply.rno ,
     			data : JSON.stringify(reply), // js데이터를 JSON 문자열로 변환
     			contentType : "application/json; charset=utf-8",
     			success : function(result, status, xhr) {
     				if (callback) {
     					callback(result);
     				}
     			},
     			error : function(xhr, status, er) {
     				if (error) {
     					error(er);
     				}
     			}
     		})
     	}
         
         return {
             add:add
         	getList:getList
         	remove:remove
             update:update
         }; 
     })();	
     ```

   - get.jsp

     ```jsp
     <script type="text/javascript" src="/resources/js/reply.js"></script> <!-- reply.js 추가 -->
     <script>
      
     	console.log("===============");
     	console.log("JS TEST");
     	
     	var bnoValue = '<c:out value="${board.bno}"/>'; //게시물의 번호 
     	
     	replyService.update({rno:20,bno:bnoValue,reply:"Modified"}, function(result) {
     		alert("수정완료....");
     	});
         
     </script>
     ```

6. 댓글 조회 처리

   - reply.js

     ```js
     var replyService = (function(){
     	
     	function add(reply, callback, error) { // 파라미터로 callback 과 error를 함수로 받음
     		....
     	}
         
         function getList(param, callback, error) {
     			....
     	}
     	
     	function remove(rno, callback, error) { //댓글번호
     		....
     	}	
     	
         function update(reply, callback, error) { 
     		....
     	}
     	
     	function get(rno, callback, error) {
     		console.log("get...............");
     
     		$.get("/replies/"+rno+".json",function(result){
     			if(callback){
     				callback(result);
     			}
     		}).fail(function(xhr,status,err){
     			if(error){
     				error();
     			}
     		});
     	}	    
         return {
             add:add
         	getList:getList
         	remove:remove
             update:update
             get:get
         }; 
     })();	
     ```

   - get.jsp

     ```jsp
     <script type="text/javascript" src="/resources/js/reply.js"></script> <!-- reply.js 추가 -->
     <script>
      
     	console.log("===============");
     	console.log("JS TEST");
     	
     	var bnoValue = '<c:out value="${board.bno}"/>'; //게시물의 번호 
     	
     	replyService.get(20, function(data) {
     		console.log(data);
     	});
         
     </script>
     ```

### 이벤트 처리와 HTML 처리

1. 댓글 목록 처리

   - get.jsp

     ```jsp
     <div class="row">
     	<div class="col-lg-12">
     		<div class="panel panel-default">
     			<div class="panel-heading">
     				<i class="fa fa-comments fa-fw"></i> Reply
     			</div>
     			<div class="panel-body">
     				<ul class="chat">
     					<li class="left clearfix" data-rno='12'>
     						<div>
     							<div class="header">
     								<strong class="primary-font">user00</strong> <small class="pull-right text-muted">2018-01-01 13:13</small>
     							</div>
     							<p>Good job!</p>
     						</div>
     					</li>
                         <!--end reply-->
     				</ul>
                     <!--end ul-->
     			</div>
     		</div>
     	</div>
     </div>
     ```

   - 이벤트 처리

     - 게시글의 조회 페이지가 열리면 자동으로 댓글 목록을 가져와서 < li > 태그를 구성

     - get.jsp

       ```jsp
       <script>
       	$(document).ready(function(){
       		var bnoValue = "${board.bno}";
       		var replyUL = $(".chat"); // 댓글목록의 ul
       		
       		showList(1);  //showList호출
       		
       		function showList(page){
       			
       			console.log("show list : "+page); 
       			//페이지 번호가 있다면 보내고 아니면 1
       			replyService.getList({bno:bnoValue,page: page||1}, function(list) {
       				
       				var str="";
       				if(list == null || list.length==0){
       					return;
       				}
       				
       				for(var i=0, len=list.length || 0; i<len;i++){
       					str += "<li class='left clearfix' data-rno='"+list[i].rno+"'>";
       					str += "<div><div class='header'><strong class='primary-font'>"+list[i].replyer+"</strong>";
       					str += "<small class='pull-right' text-muted>"+list[i].replyDate+"</small></div>";
       					str += "<p>"+list[i].reply+"</p></div></li>";
       				}
                       
       				replyUL.html(str); //기존 요소를 지우고 추가
       				
       			});
       		}
       	   
       	});
       </script>
       
       ```

   - 시간에 대한 처리

     - reply.js

       ```js
       var replyService = (function(){
       	
       	function add(reply, callback, error) { // 파라미터로 callback 과 error를 함수로 받음
       		....
       	}
           
           function getList(param, callback, error) {
       			....
       	}
       	
       	function remove(rno, callback, error) { //댓글번호
       		....
       	}	
       	
           function update(reply, callback, error) { 
       		....
       	}
       	
       	function get(rno, callback, error) {
       			.....
       	}	    
       	function displayTime(timeValue){
       		var today = new Date(); //현재시간
       		
       		var gap = today.getTime() - timeValue; //현재시간 - 댓글 입력한시간
       		
       		var dateObj = new Date(timeValue); //댓글 입력한 시간
       		var str = "";
       		
       		if(gap < (1000*60*60*24)) { //24시간 보다 작으면,하루이내
       			
       			var hh = dateObj.getHours(); 
       			var mi = dateObj.getMinutes();
       			var ss = dateObj.getSeconds();
       			
       			return[ (hh>9 ? '':'0')+hh, ":",(mi>9?'':'0')+mi,":" ,(ss>9?'':'0')+ss].join(''); // 15:23:34이런식으로 표현
       		}else{ //하루가 지남
       			var yy = dateObj.getFullYear(); 
       			var mm = dateObj.getMonth()+1;
       			var dd = dateObj.getDate();
       		
       			return[ yy,"/",(mm>9?'':'0')+mm,"/",(dd>9?'':'0')+dd].join(''); // 2020/10/5이런식으로 나오게함
       		}
       	}	
           return {
               add:add
           	getList:getList
           	remove:remove
               update:update
               get:get
               displayTime:displayTime
           }; 
       })();	
       ```

     - get.jsp

       ```jsp
       <script>
       	$(document).ready(function(){
       		var bnoValue = "${board.bno}";
       		var replyUL = $(".chat"); // 댓글목록의 ul
       		
       		showList(1);  //showList호출
       		
       		function showList(page){
       			
       			console.log("show list : "+page); 
       			//페이지 번호가 있다면 보내고 아니면 1
       			replyService.getList({bno:bnoValue,page: page||1}, function(list) {
       				
       				var str="";
       				if(list == null || list.length==0){
       					return;
       				}
       				
       				for(var i=0, len=list.length || 0; i<len;i++){
       					str += "<li class='left clearfix' data-rno='"+list[i].rno+"'>";
       					str += "<div><div class='header'><strong class='primary-font'>"+list[i].replyer+"</strong>";
       					str += "<small class='pull-right' text-muted>"+replyService.displayTime(list[i].replyDate)+"</small></div>";
       					str += "<p>"+list[i].reply+"</p></div></li>";
       				}
                       
       				replyUL.html(str); //기존 요소를 지우고 추가
       				
       			});
       		}
       	   
       	});
       </script>
       
       ```

2. 새로운 댓글 처리

   - get.jsp

     ```jsp
     <div class="row">
     	<div class="col-lg-12">
     		<div class="panel panel-default">
     			<div class="panel-heading">
     				<i class="fa fa-comments fa-fw"></i> Reply
     				<button id="addReplyBtn" class="btn btn-primary btn-xs pull-right">New Reply</button>
     			</div>
     			<div class="panel-body">
     				<ul class="chat">
     					<li class="left clearfix" data-rno='12'>
     						<div>
     							<div class="header">
     								<strong class="primary-font">user00</strong> <small class="pull-right text-muted">2018-01-01 13:13</small>
     							</div>
     							<p>Good job!</p>
     						</div>
     					</li>
     				</ul>
     			</div>
     		</div>
     	</div>
     </div>
     ```

   - get.jsp에 모달창 추가

     ```jsp
     <!-- Modal -->
     <div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
     	<div class="modal-dialog">
     		<div class="modal-content">
     			<div class="modal-header">
     				<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
     				<h4 class="modal-title" id="myModalLabel">Reply Modal</h4>
     			</div>
     			<div class="modal-body">
     				<div class="form-group">
     					<label>Reply</label>
     					<input class="form-control" name="reply" value="New Reply!!!!">
     				</div>
     				<div class="form-group">
     					<label>Replyer</label>
     					<input class="form-control" name="replyer" value="replyer">
     				</div>
     				<div class="form-group">
     					<label>Reply Date</label>
     					<input class="form-control" name="replyDate" value="">
     				</div>								
     			</div>
     			<div class="modal-footer">
     				<button id="modalModBtn" type="button" class="btn btn-warning">Modify</button>
     				<button id="modalRemoveBtn" type="button" class="btn btn-danger">Remove</button>
     				<button id="modalRegisterBtn" type="button" class="btn btn-primary">Register</button>
     				<button id="modalCloseBtn" type="button" class="btn btn-default">Close</button>
     			</div>
     		</div>
     		<!-- /.modal-content -->
     	</div>
     	<!-- /.modal-dialog -->
     </div>
     <!-- /.modal -->
     ```

   - 새로운 댓글의 추가 버튼 이벤트 처리

     - get.jsp

       ```jsp
       <script>
       	$(document).ready(function(){
       		var bnoValue = "${board.bno}";
       		var replyUL = $(".chat"); // 댓글목록의 ul
       		
       		showList(1);  //showList호출
       		
       		function showList(page){
       			
       			console.log("show list : "+page); 
       			//페이지 번호가 있다면 보내고 아니면 1
       			replyService.getList({bno:bnoValue,page: page||1}, function(list) {
       				
       				var str="";
       				if(list == null || list.length==0){
       					return;
       				}
       				
       				for(var i=0, len=list.length || 0; i<len;i++){
       					str += "<li class='left clearfix' data-rno='"+list[i].rno+"'>";
       					str += "<div><div class='header'><strong class='primary-font'>"+list[i].replyer+"</strong>";
       					str += "<small class='pull-right' text-muted>"+replyService.displayTime(list[i].replyDate)+"</small></div>";
       					str += "<p>"+list[i].reply+"</p></div></li>";
       				}
                       
       				replyUL.html(str); //기존 요소를 지우고 추가
       				
       			});
       		}
               
               var modal = $(".modal"); //모달창
       		var modalInputReply = modal.find("input[name='reply']"); //reply
       		var modalInputReplyer = modal.find("input[name='replyer']"); //replyer
       		var modalInputReplyDate = modal.find("input[name='replyDate']"); // replyDate
       		
       		var modalModBtn = $("#modalModBtn"); //수정버튼
       		var modalRemoveBtn = $("#modalRemoveBtn"); //삭제버튼
       		var modalRegisterBtn = $("#modalRegisterBtn"); //등록버튼
               
       		$("#addReplyBtn").on("click",function(e){ //New Reply버튼 클릭
       			modal.find("input").val(""); // modal 창의 모든 input태그의 값을 비움
       			modalInputReplyDate.closest("div").hide(); // replyDate를 숨김
       			modal.find("button[id != 'modalCloseBtn']").hide(); // Close버튼 빼고 다 숨김
       			
       			modalRegisterBtn.show(); // Register버튼 보여줌
       			
       			$(".modal").modal("show"); //모달창 보여줌
       		});        
       	   
       		modalRegisterBtn.on("click",function(e){
       			var reply = {
                       //댓글내용 , 작성자 , 게시글번호를 reply객체에 담음
       					reply : modalInputReply.val(),
       					replyer : modalInputReplyer.val(),
       					bno : bnoValue
       			};
       			replyService.add(reply, function(result) {
       				alert(result); //success
       				
       				modal.find("input").val(""); //modal의 input태그의 값을 비워주고
       				modal.modal("hide"); // modal창을 숨김
       				
       				showList(1); //목록 갱신
       				
       			})
       		});
               
       	});
       </script>
       
       ```

3. 특정 댓글의 클릭 이벤트 처리

   - 해당 댓글을 수정하거나 삭제하는 경우에 발생

   - DOM에서 이벤트 리스너를 등록하는 것은 반드시 해당 DOM 요소가 존재해야만 가능 그런데 Ajax를 통해서 태그들이 만들어지면 이후에 이벤트를 등록해야 하기 때문에 일반적인 방식이 아니라 **이벤트 위임**의 형태로 작성

   - **이벤트 위임 : 실제로는 이벤트를 동적으로 생성되는 요소가 아닌 이미 존재하는 요소에 이벤트를 걸어주고, 나중에 이벤트의 대상을 변경해주는 방식**

     - get.jsp

     ```js
     $(".chat").on("click","li",function(e){ //실제이벤트는 li를 누를때 일어나지만 동적요소에는 이벤트를 걸 수 없기 떄문에이벤트를 일단chat에 걸어줌
     			var no = $(this).data("rno");
     			
     			console.log(rno);
     			
     			replyService.get(rno, function(reply) {
     				modalInputReply.val(reply.reply);
     				modalInputReplyer.val(reply.replyer);
     				modalInputReplyDate.val(replyService.displayTime(reply.replyDate)).attr("readonly","readonly");
     				modal.data("rno",reply.rno); // data-rno 속성을 추가
     				
     				modal.find("button[id != 'modalCloseBtn']").hide(); // close버튼 말고 점부 숨김
     				modalModBtn.show(); //수정버튼 보임
     				modalRemoveBtn.show(); // 삭제버튼 보임
     				
     				$(".modal").modal("show"); //모달창 보여줌
     			});
     });
     ```

4. 댓글의 수정/삭제 이벤트 처리

   - get.jsp

     ```js
     		modalModBtn.on("click",function(e){  //수정버튼 클릭
     			var reply = {
     					rno : modal.data("rno"), //해당 li의 data-rno값 읽어옴
     					reply : modalInputReply.val() //reply값 가져옴
     			};
     			replyService.update(reply, function(result) {
     				
     				alert(result);
     				modal.modal("hide");
     				showList(1);
     			})
     		});
     ```

     ```js
     		modalRemoveBtn.on("click",function(e){
     			var rno = modal.data("rno"); //해당 li의 data-rno값 읽어옴
     			
     			replyService.remove(rno,function(result){
     				alert(result);
     				modal.modal("hide");
     				showList(pageNum);
     			})
     			
     		});
     ```

     

### 댓글의 페이징 처리

1. 데이터베이스의 인덱스 설계

   - tbl_reply 테이블을 접근할 떄 댓글의 번호(rno)가 중심이 아니라. 게시물의 번호(bno)가 중심이 된다.

   - 현재 pk_reply는 rno인데 이것을 통해서 조회를 하게 되면 특정 게시물의 번호를 찾을 떄 건너뛰어 가면서 찾아야 하기 떄문에 성능저하가 올 수 있다.

   - 따라서 bno기준으로 인덱스를 만든다.

     ```sql
     create index idx_reply on tbl_reply(bno desc,rno asc);
     ```

2. 인덱스를 이용한 페이징 쿼리

   - 특정한 게시물의 rno의 순번대로 데이터를 조회하고 싶다면 다음과 같은 쿼리를 작성

     ```sql
     select /*+INDEX(tbl_reply idx_reply)*/
     	rownum rn,bno,rno,reply,replyer,replyDate,updateDate
     	from tbl_reply
     	where bno = 3145745
     	and rno >0
     ```

   - 페이징 처리를 해서 댓글 가져오기

     ```
     select rno,bno,reply,replyer,replydate,updatedate
     from (
     	select /*+INDEX(tbl_reply idx_reply)*/
     	rownum rn,bno,rno,reply,replyer,replyDate,updateDate
     	from tbl_reply
     	where bno = 게시물번호 and rno >0 and rownum<=20
     )
     where rn >10
     ```

   - ReplyMapper.xml

     ```xml
     <select id="getListWithPaging" resultType="org.zerock.domain.ReplyVO">
     		<![CDATA[
     			select rno,bno,reply,replyer,replydate,updatedate
     			from (
     				select /*+INDEX(tbl_reply idx_reply)*/ 
     				rownum rn, bno , rno ,reply , replyer , replyDate , updateDate from tbl_reply
     				where bno = #{bno} and rno > 0 and rownum <= #{cri.pageNum} * #{cri.amount}
     			)
     			where rn > (#{cri.pageNum}-1) * #{cri.amount}
     		]]>
     </select>
     ```

   - ReplyMapperTests

     ```java
     	@Test
     	public void testList2() {
     		
     		Criteria cri = new Criteria(2, 10); //2페이지 , 10개씩
     		
     		List<ReplyVO> replies = mapper.getListWithPaging(cri, 68L); //68번 게시물의 댓글2페이지 10개씩 보여줌
     		
     		replies.forEach(reply -> log.info(reply));
     	}
     ```

3. 댓글의 숫자 파악

   - 페이징 처리하기 위해서는 해당 게시물의 전체 댓글의 숫자를 파악해서 화면에 보여줄 필요가 있다

   - ReplyMapper

     ```java
     package org.zerock.mapper;
     
     import java.util.List;
     
     import org.apache.ibatis.annotations.Param;
     import org.zerock.domain.Criteria;
     import org.zerock.domain.ReplyVO;
     
     public interface ReplyMapper {
     	
     	public int insert(ReplyVO vo);
     	
     	public ReplyVO read(Long rno);
     	
     	public int delete(Long rno);
     	
     	public int update(ReplyVO reply);
     	
     	public List<ReplyVO> getListWithPaging(
     				@Param("cri") Criteria cri,
     				@Param("bno") Long bno
     			);
     	
     	public int getCountByBno(Long Bno); //전체 댓글의 수
     }
     ```

   - ReplyMapper.xml

     ```xml
     <select id="getCountByBno" resultType="int">
     		<![CDATA[
     			select count(rno) from tbl_reply where bno = #{bno}
     		]]>
     </select>
     ```

4. ReplyServiceImpl에서 댓글과 댓글 수 처리

   - 댓글의 페이징 처리가 필요한 경우에는 댓글 목록과 함께 전체 댓글의 수를 같이 전달

   - ReplyPageDTO

     ```java
     package org.zerock.domain;
     
     import java.util.List;
     
     import lombok.AllArgsConstructor;
     import lombok.Data;
     
     @Data
     @AllArgsConstructor
     public class ReplyPageDTO { 
     	private int replyCnt; //댓글의수
     	private List<ReplyVO> list; //댓글목록
     }
     
     ```

   - ReplyService

     ```java
     package org.zerock.service;
     
     import java.util.List;
     
     import org.zerock.domain.Criteria;
     import org.zerock.domain.ReplyPageDTO;
     import org.zerock.domain.ReplyVO;
     
     public interface ReplyService {
     	public int register(ReplyVO vo);
     	
     	public ReplyVO get(Long rno);
     	
     	public int modify(ReplyVO vo);
     	
     	public int remove(Long rno);
     	
     	public List<ReplyVO> getList(Criteria cri,Long bno);
     	
     	public ReplyPageDTO getListPage(Criteria cri,Long bno);
     }
     
     ```

   - ReplyServiceImpl

     ```java
     	@Override
     	public ReplyPageDTO getListPage(Criteria cri, Long bno) {
             //해당 게시글의 댓글 수 , 댓글 목록
     		return new ReplyPageDTO(mapper.getCountByBno(bno), mapper.getListWithPaging(cri, bno)); 
     	}
     ```

   - ReplyController 수정

     ```java
     	@GetMapping(value = "/pages/{bno}/{page}" , produces = {
     				MediaType.APPLICATION_XML_VALUE,
     				MediaType.APPLICATION_JSON_UTF8_VALUE})
     	public ResponseEntity<ReplyPageDTO> getList(@PathVariable("page") int page,
     												 @PathVariable("bno") Long bno){
     		log.info("getList.........");
     		Criteria cri = new Criteria(page, 10);
     		log.info(cri);
     		
     		return new ResponseEntity<ReplyPageDTO>(service.getListPage(cri, bno),HttpStatus.OK);
     	}
     ```

### 댓글 페이지의 화면 처리

- 처리 방식

  - 게시물을 조회하는 페이지에 들어오면 기본적으로 가장 오래된 댓글들을 가져와서 1페이지에 보여준다
  - 1페이지의 게시물을 가져올 때 해당 게시물의 댓글의 숫자를 파악해서 댓글의 페이지 번호를 출력
  - 댓글이 추가되면 댓글의 숫자만을 가져와서 최종 페이지를 찾아서 이동
  - 댓글의 수정과 삭제 후에는 다시 동일 페이지를 호출

  

1. 댓글 페이지 계산과 출력

   - Ajax로 가져오는 데이터가 replyCnt , list 라는 데이터로 구성되므로 이를 처리하는 reply.js 의 내용 역시 이를 처리하는 구조로 수정

     - reply.js

       ```js
       	function getList(param, callback, error) {
       		
       		var bno = param.bno;
       		var page = param.page || 1;
       		
       		$.getJSON("/replies/pages/"+bno+"/"+page+".json",
       			function(data){
       				if(callback){
       					//callback(data);
       					callback(data.replyCnt , data.list); //댓글 수와 목록을 가져오는 경우
       				}
       			}).fail(function(xhr,status,err){
       				if(error){
       					error();
       				}
       			});
       	}
       ```

   - get.jsp

     ```js
     //page 번호가 -1 로 전달되면 마지막 페이지를 찾아서 다시 호출
     function showList(page){
     			
     			console.log("show list : "+page);
     			
     			replyService.getList({bno:bnoValue,page: page||1}, function(replyCnt, list) {
     				console.log("replyCnt : "+replyCnt);
     				console.log("list : "+list);
     				
     				if(page == -1){
     					pageNum = Math.ceil(replyCnt/10.0); // 마지막 페이지 찾기
     					showList(pageNum); //마지막 페이지 호출
     					return;
     				}
     				
     				var str="";
     				if(list == null || list.length==0){
     					return;
     				}
     				
     				for(var i=0, len=list.length || 0; i<len;i++){
     					str += "<li class='left clearfix' data-rno='"+list[i].rno+"'>";
     					str += "<div><div class='header'><strong class='primary-font'>"+list[i].replyer+"</strong>";
     					str += "<small class='pull-right' text-muted>"+replyService.displayTime(list[i].replyDate)+"</small></div>";
     					str += "<p>"+list[i].reply+"</p></div></li>";
     				}
     				replyUL.html(str);
     				
     				showReplyPage(replyCnt); //페이징 처리
     				
     			});
     		}
     ```

     ```js
     		modalRegisterBtn.on("click",function(e){
     			var reply = {
     					reply : modalInputReply.val(),
     					replyer : modalInputReplyer.val(),
     					bno : bnoValue
     			};
     			replyService.add(reply, function(result) {
     				alert(result);
     				
     				modal.find("input").val("");
     				modal.modal("hide");
     				
     				//showList(1);
     				showList(-1); //마지막 페이지로 이동
     			})
     		});
     ```

     ```jsp
     <div class="row">
     	<div class="col-lg-12">
     		<div class="panel panel-default">
     			<div class="panel-heading">
     				<i class="fa fa-comments fa-fw"></i> Reply
     				<button id="addReplyBtn" class="btn btn-primary btn-xs pull-right">New Reply</button>
     			</div>
     			<div class="panel-body">
     				<ul class="chat">
     					<li class="left clearfix" data-rno='12'>
     						<div>
     							<div class="header">
     								<strong class="primary-font">user00</strong> <small class="pull-right text-muted">2018-01-01 13:13</small>
     							</div>
     							<p>Good job!</p>
     						</div>
     					</li>
     				</ul>
     			</div>
     			<!-- 댓글 번호창 -->
     			<div class="panel-footer">
     			
     			</div>
     		</div>
     	</div>
     </div>
     ```

     ```js
     		var pageNum = 1; //페이지번호
     		var replyPageFooter = $(".panel-footer"); //게시물 번호 div
     		
     		function showReplyPage(replyCnt) { //댓글의 갯수가 파라미터로 옴
     			var endNum = Math.ceil(pageNum/10.0) * 10; //끝번호
     			var startNum = endNum - 9; //시작번호
     			
     			var prev = startNum != 1; 
     			var next = false;
     			
     			if(endNum * 10 >= replyCnt){ //데이터 수의 맞게 페이지 조정
     				endNum = Math.ceil(replyCnt/10.0);
     			}
     			if(endNum * 10 < replyCnt){
     				next = true;
     			}
     				
     			 var str = "<ul class='pagination pull-right'>";
     		      
     		      if(prev){
     		        str+= "<li class='page-item'><a class='page-link' href='"+(startNum -1)+"'>Previous</a></li>";
     		      }
     		      
     		      for(var i = startNum ; i <= endNum; i++){
     		        
     		        var active = pageNum == i? "active":""; //같은 페이지면 활성화
     		        
     		        str+= "<li class='page-item "+active+" '><a class='page-link' href='"+i+"'>"+i+"</a></li>";
     		      }
     		      
     		      if(next){
     		        str+= "<li class='page-item'><a class='page-link' href='"+(endNum + 1)+"'>Next</a></li>";
     		      }
     		      
     		      str += "</ul></div>";
     		      
     		      console.log(str);
     		      
     		      replyPageFooter.html(str);			
     		}
     ```

   - 페이지의 번호를 클릭했을 때 새로운 댓글을 가져오기

     ```js
     replyPageFooter.on("click","li a", function(e){
     	        e.preventDefault();
     	        console.log("page click");
     	        
     	        var targetPageNum = $(this).attr("href"); //page번호 가져오기
     	        
     	        console.log("targetPageNum: " + targetPageNum);
     	        
     	        pageNum = targetPageNum;
     	        
     	        showList(pageNum); //갱신
     	      });  
     ```

2. 댓글 수

   ```js
   	modalModBtn.on("click",function(e){
   			var reply = {
   					rno : modal.data("rno"),
   					reply : modalInputReply.val()
   			};
   			replyService.update(reply, function(result) {
   				
   				alert(result);
   				modal.modal("hide");
   				showList(pageNum);
   			})
   		});
   		
   		modalRemoveBtn.on("click",function(e){
   			var rno = modal.data("rno");
   			
   			replyService.remove(rno,function(result){
   				alert(result);
   				modal.modal("hide");
   				showList(pageNum);
   			})
   			
   		});
   ```

   

