# Chap08. 영속/비즈니스 계층의 CRUD구현

- 영속 계층의 작업 순서
  - **테이블의 칼럼 구조를 반영하는 VO 클래스의 생성**
  - **Mybatis의 Mapper 인터페이스의 작성/XML처리**
  - **작성한 Mapper인터페이스의 테스트**

### 영속 계층의 구현 준비

1. VO클래스 작성

   - ```java
     package org.zerock.domain;
     
     import java.util.Date;
     
     import org.springframework.format.annotation.DateTimeFormat;
     
     import lombok.Data;
     
     @Data //Getter , setter ,toString 등을 만듬
     public class BoardVO {
     	private Long bno;
     	private String title;
     	private String content;
     	private String writer;
     	
     	@DateTimeFormat(pattern = "yyyy-MM-dd")
     	private Date regdate;
     	@DateTimeFormat(pattern = "yyyy-MM-dd")
     	private Date updateDate;
     }
     
     ```

2. Mapper인터페이스와 Mapper XML

   - Mybatis는 SQL을 처리하는데 어노테이션이나 XML을 이용

     - 어노테이션 : 간단한SQL때 사용  / SQL이 복잡한 경우 사용이 힘듬
     - XML : 단순 텍스트를 수정하는 과정만으로 처리가 끝남 / 유지 보수성이 떨어짐

   - Mapper 인터페이스

     - root-context.xml에 해당 패키지를 스캔하도록 설정

       ```xml
       <mybatis-spring:scan base-package="org.zerock.mapper"/>
       ```

     - Mapper 인터페이스를 작성할 때는 select와 insert 작업을 우선해서 작성

     - BoardMapper 인터페이스를 작성할 때는 이미 작성된 BoardVO 클래스를 적극적으로 활용해서 필요한 SQL을 어노테이션의 속성값으로 처리

     - 항상 SQL문을 테스트 할 때는 SQL Developer에서 먼저 테스트

       ```java
       package org.zerock.mapper;
       
       import java.util.List;
       
       import org.apache.ibatis.annotations.Select;
       import org.zerock.domain.BoardVO;
       
       public interface BoardMapper {
       
       	@Select("select * from tbl_board where bno>0")
       	public List<BoardVO> getList();
       	
       }
       
       ```

       ```java
       package org.zerock.mapper;
       
       import java.util.List;
       
       import org.junit.Test;
       import org.junit.runner.RunWith;
       import org.springframework.beans.factory.annotation.Autowired;
       import org.springframework.test.context.ContextConfiguration;
       import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
       import org.zerock.domain.BoardVO;
       import org.zerock.domain.Criteria;
       
       import lombok.Setter;
       import lombok.extern.log4j.Log4j;
       
       @RunWith(SpringJUnit4ClassRunner.class)
       @ContextConfiguration("file:src/main/webapp/WEB-INF/spring/root-context.xml")
       @Log4j
       public class BoardMapperTests {
       	
       	@Setter(onMethod_ = @Autowired )
       	private BoardMapper mapper;
           
           @Test
       	public void testGetList() {
       		mapper.getList().forEach(board -> log.info(board));
           }
       }
       
       ```

   - Mapper XML 파일

     - ```xml
       <?xml version="1.0" encoding="UTF-8" ?>
       <!DOCTYPE mapper
         PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
         "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
       <mapper namespace="org.zerock.mapper.BoardMapper">
       	<select id="getList" resultType="org.zerock.domain.BoardVO">
       		<![CDATA[
       		select * from tbl_board where bno > 0
       		]]>
       	</select>
       
       </mapper>
       ```

     - < mapper > 의 namespace 속성값을 Mapper 인터페이스와 동일한 이름을 줘야함

     - 태그의 id 속성값은 메서드이름과 일치하게

     - CDATA 부분은 XML에서 부등호를 사용하기 위해서 사용

### 영속 영역의 CRUD구현

- 가장 먼저 구현할 수 있는 부분이 영속 영역이다 . 왜냐하면 VO클래스 등 약간의 준비만으로 테스트 할 수 있기 때문이다.
- Mybatis는 내부적으로 JDBC의 PreparedStatement를 활용하고 필요한 파라미터를 처리하는 '?'에 대한 치환은 '#{속성}' 을 이용해서 처리

1. create(insert) 처리

   - 자동으로 PK값이 정해지는 경우에는 2가지 방식으로 처리할 수 있음

     - insert만 처리되고 생성된 pk값을 알 필요가 없는 경우
     - insert문이 실행되고 생성된 pk값을 알아야 하는 경우

     ```java
     package org.zerock.mapper;
     
     import java.util.List;
     
     import org.apache.ibatis.annotations.Select;
     import org.zerock.domain.BoardVO;
     
     public interface BoardMapper {
     
     	//@Select("select * from tbl_board where bno>0")
     	public List<BoardVO> getList();
     	
         public void insert(BoardVO board);
     	
     	public void insertSelectKey(BoardVO board);
     }
     ```

     ```xml
     <?xml version="1.0" encoding="UTF-8" ?>
     <!DOCTYPE mapper
       PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
       "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
     <mapper namespace="org.zerock.mapper.BoardMapper">
     
     	<select id="getList" resultType="org.zerock.domain.BoardVO">
     		<![CDATA[
     		select * from tbl_board where bno > 0
     		]]>
     	</select>
     
     	<insert id="insert">
     		<!-- 단순히 시퀀스의 다음 값을 구해서 insert 할 때 사용 -->
     		insert into tbl_board(bno,title,content,writer) values(seq_board.nextval,#{title},#{content},#{writer})
     	</insert>
     
     	<insert id="insertSelectKey">
     		
     		<selectKey keyProperty="bno" order="BEFORE" resultType="long">
     			<!--DUAL이라는 테이블은 SYS 사용자가 소유하는 오라클의 표준 테이블로서 오직 한 행(row)에 한 컬럼만 담고 있는 dummy 테이블로서 일시적인 산술연산이나 날짜 연산을 위하여 주로 쓰인다.-->
     			<!-- insert실행전에 수행 -->
     			<!-- KeyProperty는 리턴받을 변수명 -->
     			select seq_board.nextval from dual
     		</selectKey>
     
     		insert into tbl_board(bno,title,content,writer) values(#{bno},#{title},#{content},#{writer})
     	</insert>
     
     </mapper>
     ```

     ```java
     	@Test//insert만 처리되고 생성된 pk값을 알 필요가 없는 경우
     	public void testInsert() {
     		BoardVO board = new BoardVO();
     		board.setTitle("새로 작성하는 글");
     		board.setContent("새로 작성하는 내용");
     		board.setWriter("newbie");
     		
     		mapper.insert(board);
     		
     		log.info(board);
     	}
     ```

     ```java
     	@Test//insert문이 실행되고 생성된 pk값을 알아야 하는 경우
     	public void testInsertSelectKey() {
     		BoardVO board = new BoardVO();
     		board.setTitle("새로 작성하는 글 select key");
     		board.setContent("새로 작성하는 내용 select key");
     		board.setWriter("newbie");
     		
     		mapper.insertSelectKey(board);
     		
     		log.info(board);
     	}
     ```

2. read(select) 처리

   - ```java
     package org.zerock.mapper;
     
     import java.util.List;
     
     import org.apache.ibatis.annotations.Select;
     import org.zerock.domain.BoardVO;
     import org.zerock.domain.Criteria;
     
     public interface BoardMapper {
     
     	//@Select("select * from tbl_board where bno>0")
     	public List<BoardVO> getList();
     	
     	public List<BoardVO> getListWithPaging(Criteria cri);
     	
     	public void insert(BoardVO board);
     	
     	public void insertSelectKey(BoardVO board);
     	
         //bno를 이용해서 조회
     	public BoardVO read(Long bno);
     	
     }
     ```

     ```xml
     <!--Mybatis의 모든 파라미터와 리턴 타입의 처리는 get파라미터명(),set 칼럼명()-->
     <!--하지만 #{속성}이 하나만 존재하는 경우 별도의 get파라미터명()을 사용하지 않고 처리-->
     	<select id="read" resultType="org.zerock.domain.BoardVO">
     		select * from tbl_board where bno = #{bno}
     	</select>
     ```

     ```java
     	@Test
     	public void testRead() {
     		BoardVO board = mapper.read(5L);
     		
     		log.info(board);
     	}
     ```

3. delete처리

   - 등록, 삭제 , 수정과 같은 DML 작업은 몇 건의 데이터가 등록,삭제,수정되었는지 반환할 수 있다.

   - ```JAVA
     package org.zerock.mapper;
     
     import java.util.List;
     
     import org.apache.ibatis.annotations.Select;
     import org.zerock.domain.BoardVO;
     import org.zerock.domain.Criteria;
     
     public interface BoardMapper {
     
     	//@Select("select * from tbl_board where bno>0")
     	public List<BoardVO> getList();
     	
     	public List<BoardVO> getListWithPaging(Criteria cri);
     	
     	public void insert(BoardVO board);
     	
     	public void insertSelectKey(BoardVO board);
     	
     	public BoardVO read(Long bno);
     	
     	public int delete(Long bno);
     }
     
     ```

     ```XML
     	<delete id="delete">
     		delete from tbl_board where bno = #{bno}
     	</delete>
     ```

     ```JAVA
     	@Test
     	public void testDelete() {
     		log.info("DELETE COUNT : "+mapper.delete(3L));
     	}
     ```

4. update처리

   - ```java
     package org.zerock.mapper;
     
     import java.util.List;
     
     import org.apache.ibatis.annotations.Select;
     import org.zerock.domain.BoardVO;
     import org.zerock.domain.Criteria;
     
     public interface BoardMapper {
     
     	//@Select("select * from tbl_board where bno>0")
     	public List<BoardVO> getList();
     	
     	public List<BoardVO> getListWithPaging(Criteria cri);
     	
     	public void insert(BoardVO board);
     	
     	public void insertSelectKey(BoardVO board);
     	
     	public BoardVO read(Long bno);
     	
     	public int delete(Long bno);
     	
     	public int update(BoardVO board);
     	
     }
     
     ```

     ```xml
     	<update id="update">
     		update tbl_board
     		set title = #{title},
     		content = #{content},
     		writer = #{writer},
     		updateDate = sysdate
     		where bno = #{bno}
     	</update>
     ```

     ```java
     	@Test
     	public void testUpdate() {
     		BoardVO board = new BoardVO();
     		board.setBno(5l);
     		board.setTitle("수정된 제목");
     		board.setContent("수정된 내용");
     		board.setWriter("user00");
     		
     		int count = mapper.update(board);
     		log.info("update count : "+count);
     	}
     ```

     