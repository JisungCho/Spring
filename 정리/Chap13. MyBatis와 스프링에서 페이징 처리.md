# Chap13. MyBatis와 스프링에서 페이징 처리

- 페이징 처리를 위해서는 몇가지 파라미터가 필요

  1. 페이지번호
  2. 한 페이지당 몇개의 데이터를 보여줄 것인지

  => 하나의 객체로 묶어서 전달

- Critetia클래스

  ```java
  package org.zerock.domain;
  
  import lombok.Data;
  import lombok.Getter;
  import lombok.Setter;
  import lombok.ToString;
  
  @Setter
  @Getter
  @ToString
  public class Criteria {
  	//페이지 번호
  	private int pageNum;
  	//한 페이지당 보여줄 데이터양
  	private int amount;
  	
  	private String type; //검색 타입
  	private String keyword; //검색내용
  	
  	public Criteria() { //기본 1페이지 10개
  		this(1,10);
  	}
  	public Criteria(int pageNum,int amount) {
  		this.pageNum = pageNum;
  		this.amount = amount;
  	}
  	
  }
  
  ```

1. MyBatis 처리와 테스트

   - BoardMapper 인터페이스

     ```java
     package org.zerock.mapper;
     
     import java.util.List;
     
     import org.apache.ibatis.annotations.Select;
     import org.zerock.domain.BoardVO;
     import org.zerock.domain.Criteria;
     
     public interface BoardMapper {
     
     	public List<BoardVO> getList();
     	
     	public List<BoardVO> getListWithPaging(Criteria cri);
     	
     	public void insert(BoardVO board);
     	
     	public void insertSelectKey(BoardVO board);
     	
     	public BoardVO read(Long bno);
     	
     	public int delete(Long bno);
     	
     	public int update(BoardVO board);
     }
     
     ```

   - BoardMapper.xml에 getListWithPaging 처리

     ```xml
     	<select id="getListWithPaging" resultType="org.zerock.domain.BoardVO">
     		<![CDATA[
     			select bno,title,content,writer,regdate,updateDate
     			from
     				(
     					select /*+INDEX_DESC(tbl_board pk_board) */ rownum rn,bno,title,content,writer,regdate,updateDate
     					from tbl_board
     					where 
     					rownum <= 20
     			)
     				
     			where rn > 10
     		]]>
     	</select>
     ```

   - 페이징 테스트와 수정

     - BoardMapperTests 클래스에서 테스트

       ```java
       	@Test
       	public void testPaging() {
       		Criteria cri = new Criteria();
       		List<BoardVO> list = mapper.getListWithPaging(cri);
       		
       		list.forEach(board->log.info(board.getBno()));
       	}
       ```

     - Criteria 객체 내부의 값을 이용해서 SQL이 동작

       ```XML
       	<select id="getListWithPaging" resultType="org.zerock.domain.BoardVO">
       		<![CDATA[
       			select bno,title,content,writer,regdate,updateDate
       			from
       				(
       					select /*+INDEX_DESC(tbl_board pk_board) */ rownum rn,bno,title,content,writer,regdate,updateDate
       					from tbl_board
       					where rownum <= #{pageNum} * #{amount}
       			)
       				
       			where rn > (#{pageNum}-1)*#{amount}
       		]]>
       	</select>
       ```

       ```JAVA
       	@Test
       	public void testPaging() {
       		Criteria cri = new Criteria();
       		cri.setPageNum(3);
       		cri.setAmount(10);
       		List<BoardVO> list = mapper.getListWithPaging(cri);
       		
       		list.forEach(board->log.info(board.getBno()));
       	}
       ```

2. BoardController와 BoardService 수정

   1. BoardService 수정 , BoardServiceImpl수정 ,테스트

      ```java
      package org.zerock.service;
      
      import java.util.List;
      
      import org.zerock.domain.BoardVO;
      import org.zerock.domain.Criteria;
      
      public interface BoardService {
      	public void register(BoardVO board);
      	
      	public BoardVO get(Long bno);
      	
      	public boolean modify(BoardVO board);
      	
      	public boolean remove(Long bno);
      	
      	//public List<BoardVO> getList();
      
      	public List<BoardVO> getList(Criteria cri);
      }
      
      ```

      ```java
      	@Override
      	public List<BoardVO> getList(Criteria cri) {
      		log.info("get List with criteria : "+cri);
      		
      		return mapper.getListWithPaging(cri);
      	}
      ```

      ```java
      	@Test
      	public void testGetList() {
      		//service.getList().forEach(board -> log.info(board));
      		
      		service.getList(new Criteria(2, 10)).forEach(board -> log.info(board));
      	
      	}
      ```

   2. BoardController 수정 , BoardController 테스트

      ```java
      	@GetMapping("/list")
      	public void list(Model model,Criteria cri) {
      		log.info("list: "+cri);
      		model.addAttribute("list",service.getList(cri));
      		
      	}
      ```

      ```java
      	@Test
      	public void testListPaging() throws Exception{
      		log.info(
      				mockMvc.perform(MockMvcRequestBuilders.get("/board/list")
      				.param("pageNum","2")
      				.param("amount","50"))
      				.andReturn().getModelAndView().getModelMap());
      	}
      ```

      

   3. 

