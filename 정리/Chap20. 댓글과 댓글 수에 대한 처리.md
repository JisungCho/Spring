# Chap20. 댓글과 댓글 수에 대한 처리

- 댓글 수를 보여주기 위해서는 tbl_reply 테이블에 insert 하고, tbl_board 테이블에는 댓글의 수를 의미하는 replyCnt라는 칼럼을 추가해서 해당 게시물 댓글의 수를 update

  ```sql
  alter table tbl_board add (replycnt number default 0);
  ```

  - 기존의 예제에서 작업해 놓은 댓글 업데이트

    ```sql
    update tbl_board set replycnt = (
    	select count(bno) from tbl_reply where tbl_reply.bno = tbl_board.bno
    );
    ```

### 프로젝트 수정

1. BoardVO , BoardMapper 수정

   - BoardVO에 댓글의 숫자를 의미하는 변수 설정

     ```JAVA
     package org.zerock.domain;
     
     import java.util.Date;
     
     import org.springframework.format.annotation.DateTimeFormat;
     
     import lombok.Data;
     
     @Data
     public class BoardVO {
     	private Long bno;
     	private String title;
     	private String content;
     	private String writer;
     	
     	@DateTimeFormat(pattern = "yyyy-MM-dd")
     	private Date regdate;
     	@DateTimeFormat(pattern = "yyyy-MM-dd")
     	private Date updateDate;
     	
     	private int replyCnt;
     }
     
     ```

   - BoardMapper

     ```java
     package org.zerock.mapper;
     
     import java.util.List;
     
     import org.apache.ibatis.annotations.Param;
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
     	
     	public int getTotalCount(Criteria cri);
     	
         //게시물의 번호 , 증가나 감소를 의미하 amount
     	public void updateReplyCnt(@Param("bno") Long bno,@Param("amount") int amount);
     }
     
     ```

   - BoardMapper.xml

     ```xml
     	<update id="updateReplyCnt">
     		update tbl_board set replycnt = replycnt + #{amount} where bno = #{bno}
     	</update>
     ```

     ```xml
     	<select id="getListWithPaging" resultType="org.zerock.domain.BoardVO">
     		<![CDATA[
     			select bno,title,content,writer,regdate,updateDate,replycnt
     			from
     				(
     					select /*+INDEX_DESC(tbl_board pk_board) */ rownum rn,bno,title,content,writer,regdate,updateDate,replycnt
     					from tbl_board
     					where 
     		]]>
     		<include refid="criteria"></include>
     		<![CDATA[
     			rownum <= #{pageNum} * #{amount}
     			)
     				
     			where rn > (#{pageNum}-1)*#{amount}
     		]]>
     	</select>
     ```

2. ReplyServiceImpl의 트랜잭션 처리

   ```java
   package org.zerock.service;
   
   import java.util.List;
   
   import org.springframework.beans.factory.annotation.Autowired;
   import org.springframework.stereotype.Service;
   import org.springframework.transaction.annotation.Transactional;
   import org.zerock.domain.Criteria;
   import org.zerock.domain.ReplyPageDTO;
   import org.zerock.domain.ReplyVO;
   import org.zerock.mapper.BoardMapper;
   import org.zerock.mapper.ReplyMapper;
   
   import lombok.extern.log4j.Log4j;
   
   @Service
   @Log4j
   public class ReplyServiceImpl implements ReplyService{
   	
   	@Autowired
   	private ReplyMapper mapper;
   	
   	@Autowired
   	private BoardMapper boardmapper;
   
   	@Override
   	@Transactional
   	public int register(ReplyVO vo) {
   		log.info("register......."+vo);
   		
   		boardmapper.updateReplyCnt(vo.getBno(), 1); //게시물의 번호에 댓글의 수를 1증가시킴
   		
   		return mapper.insert(vo);
   	}
   
   	@Override
   	@Transactional
   	public int remove(Long rno) {
   		log.info("remove......"+rno);
   		
   		ReplyVO vo = mapper.read(rno);
   		
   		boardmapper.updateReplyCnt(vo.getBno(), -1);//게시물의 번호에 해당하는 댓글의 수를 1감소 시킴
   		
   		return mapper.delete(rno);
   	}
   
   
   
   }
   
   ```

3. 화면 수정

   - list.jsp

     ```jsp
     					<c:forEach items="${list }" var="board">
     						<tbody>
     							<tr>
     								<td><c:out value="${board.bno }" /></td>
     								<td><a class="move" href='<c:out value="${board.bno }"/>'><c:out value="${board.title }"></c:out><b>[ ${board.replyCnt } ]</b></a></td>
     								<td><c:out value="${board.writer }"></c:out></td>
     								<td><fmt:formatDate pattern="yyyy-MM-dd" value="${board.regdate }" /></td>
     								<td><fmt:formatDate pattern="yyyy-MM-dd" value="${board.updateDate }" /></td>
     							</tr>
     						</tbody>
     					</c:forEach>
     ```

     