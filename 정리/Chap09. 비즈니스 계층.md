# Chap09. 비즈니스 계층

### 비즈니스 계층

- 고객의 요구사항을 반영하는 계층
- 프레젠테이션 계층과 영속 계층의 중간 다리 역활
- 영속 계층은 데이터 베이스를 기준으로 해서 설계
- 비즈니스 계층은 로직을 기준으로 해서 설계
  - Ex)  쇼핑몰에서 상품을 구매한다
    - 영속 계층 -> 상품 객체, 회원 객체
    - 비즈니스 계층 -> 구매 서비스
- 일반적으로 비즈니스 영역에 있는 객체들은 서비스 라는 용어로 많이 사용

### 비즈니스 계층의 설정

- 설계를 할 때 각 계층 간의 연결은 인터페이스를 이용해서 느슨한 연결을 한다.

1. 비즈니스 계층의 설정

   - ```java
     package org.zerock.service;
     
     import java.util.List;
     
     import org.zerock.domain.BoardVO;
     import org.zerock.domain.Criteria;
     
     public interface BoardService {
         //메서드의 이름은 현실적인 로직의 이름
     	public void register(BoardVO board); //등록
     	
     	public BoardVO get(Long bno); //상세조회
     	
     	public boolean modify(BoardVO board); //수정
     	
     	public boolean remove(Long bno); //삭제
     	
     	public List<BoardVO> getList(); //목록가져오기
     }
     
     ```

     ```java
     package org.zerock.service;
     
     import java.util.List;
     
     import org.springframework.beans.factory.annotation.Autowired;
     import org.springframework.stereotype.Service;
     import org.zerock.domain.BoardVO;
     import org.zerock.domain.Criteria;
     import org.zerock.mapper.BoardMapper;
     
     import lombok.AllArgsConstructor;
     import lombok.extern.log4j.Log4j;
      
     
     @Log4j
     @Service //계층 구조상 주로 비즈니스 영역을 담당하는 객체임을 표시하기 위해 사용
     @AllArgsConstructor
     public class BoardServiceImpl implements BoardService {
     	
     	@Autowired
     	private BoardMapper mapper;
     	
     	@Override
     	public void register(BoardVO board) {
     		log.info("register........");
     		
     		mapper.insertSelectKey(board);
     	}
     
     	@Override
     	public BoardVO get(Long bno) {
     		log.info("get........"+bno);
     		return mapper.read(bno);
     	}
     
     	@Override
     	public boolean modify(BoardVO board) {
     		log.info("modify........");
     		
     		return mapper.update(board) == 1;
     	}
     
     	@Override
     	public boolean remove(Long bno) {
     		log.info("remove......"+bno);
     		return mapper.delete(bno) == 1;
     	}
     
     
     	@Override
     	public int getTotal(Criteria cri) {
     		log.info("get total count");
     		return mapper.getTotalCount(cri);
     	}
     	
     	@Override
     	public List<BoardVO> getList() {
     		log.info("getList........");
     		
     		return mapper.getList();
     	}
     	
     
     }
     
     ```

   - 스프링의 서비스 객체 설정

     - root-context.xml에 @Service 어노테이션이 있는 패키지를 스캔하도록 추가

     - 네임스페이스 context 항목 추가

     - ```xml
       <context:component-scan base-package="org.zerock.service"></context:component-scan>
       ```

2. 비즈니스 계층의 구현과 테스트

   - src/test/java 밑에 BoardServiceTests클래스를 작성해서 테스트

   - 등록 작업의 구현과 테스트

     - ```java
       	@Override
       	public void register(BoardVO board) {
       		log.info("register........");
       		
       		mapper.insertSelectKey(board);
       	}
       ```

       ```java
       	@Test
       	public void testRegister() {
       		BoardVO board = new BoardVO();
       		board.setTitle("새로 작성하는 글");
       		board.setContent("새로 작성하는 내용");
       		board.setWriter("newbie");
       		
       		service.register(board);
       		
       		log.info("생성된 게시물의 번호 : "+board.getBno());
       	}
       ```

   - 목록 작업의 구현과 테스트

     - ```java
       	@Override
       	public List<BoardVO> getList() {
       		log.info("getList........");
       		
       		return mapper.getList();
       	}
       ```

       ```java
       	@Test
       	public void testGetList() {
       		service.getList().forEach(board -> log.info(board));
       	}
       ```

   - 조회 작업의 구현과 테스트

     - ```java
       	@Override
       	public BoardVO get(Long bno) {
       		log.info("get........"+bno);
       		return mapper.read(bno);
       	}
       ```

       ```java
       	@Test
       	public void testGet() {
       		log.info(service.get(1L));
       	}
       ```

   - 삭제/수정 구현과 테스트

     - ```java
       	@Override
       	public boolean modify(BoardVO board) {
       		log.info("modify........");
       		
       		return mapper.update(board) == 1; //수정내역이 있음
       	}
       
       	@Override
       	public boolean remove(Long bno) {
       		log.info("remove......"+bno);
       		return mapper.delete(bno) == 1; //수정내역이 있음
       	}
       ```

       ```java
       	@Test
       	public void testDelete() {
       		log.info("REMOVE RESULT : "+service.remove(2L));
       	}
       	
       	@Test
       	public void testUpdate() {
       		BoardVO board = service.get(1L); //특정게시물 일단 조회
       		
       		if(board == null) {
       			return;
       		}
       		
       		board.setTitle("제목 수정합니다");
       		log.info("MODIFY RESULT : "+service.modify(board));
       	}
       ```

       

