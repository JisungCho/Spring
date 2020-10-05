# Chap14. 페이징 화면 처리

- 처리과정
  1. 브라우저 주소창에서 페이지 번호를 전달해서 결과를 확인
  2. JSP 페이지 번호를 출력하는 단계
  3. 각 페이지 번호에 클릭 이벤트 처리
  4. 전체 데이터 개수를 반영해서 페이지 번호 조절

1. 페이징 처리할 때 필요한 정보들

   - 현재 페이지 번호

   - 이전과 다음으로 이동 가능한 링크의 표시 여부

   - 화면에서 보여지는 페이지의 시작 번호와 끝 번호

   1. 끝 페이지 번호와 시작 페이지 번호

      - 페이지를 계산할 때는 끝 번호를 먼저 계산

        ```java
        this.endPage =  (int)(Math.ceil(페이지번호/10.0))* 10
        //1에서 10은 값이 1 *10이므로 끝페이지는 10이고
        //10에서 20페이지는 2 * 10 이므로 끝페이지는 20
        // ....
        ```

      - 끝 페이지를 먼저 계산하면 시작 번호를 계산하기 수월

        ```java
        this.startPage = this.endPage - 9;
        ```

      - 끝 번호(endPage)와 한 페이지당 출력되는 데이터수(amount)의 곱이 전체 데이터 수(total)보다 크다면 끝번호는 다시 전체데이터 수를 이용해서 계산

      - 만일 진짜 끝 페이지(realEnd)가 구해둔 끝 번호(endPage)보다 작다면 끝번호는 작은 값이 되어야만 한다.

        ```java
        realEnd = (int)(Math.ceil((total*1.0)/amount));
        
        if(realEnd < this.endPage){
        	this.endPage = realEnd;
        }
        ```

      - 이전(prev)과 다음(next)

        - 이전 : 시작 번호가 1보다 큰 경우라면 존재

          ```java
          this.prev = this.startPage > 1;
          ```

        - 다음 : realEnd가 endPage보다 큰 경우에만 존재

          ```
          this.next = this.endPage < realEnd;
          ```

   2. 페이징 처리를 위한 클래스 설계

      - PageDTO클래스 설계

        ```JAVA
        package org.zerock.domain;
        
        import lombok.Data;
        
        @Data
        public class PageDTO {
        	private int startPage;
        	private int endPage;
        	private boolean prev , next;
        	
        	private int total;
        	private Criteria cri; // 페이지에서 보여주는 데이터 수 , 현재 페이지 번호가 담겨있음
        	
        	public PageDTO(Criteria cri,int total) {
        		this.cri = cri;
        		this.total = total;
        		
        		this.endPage = (int)(Math.ceil(cri.getPageNum() / 10.0))*10;
        		
        		this.startPage = this.endPage - 9;
        		
        		int realEnd = (int) (Math.ceil((total*1.0)/cri.getAmount()));
        		
        		if(realEnd < this.endPage) {
        			this.endPage = realEnd;
        		}
        		
        		this.prev = this.startPage > 1;
        		this.next = this.endPage < realEnd;
        	}
        	
        }
        
        ```

      - BoardController 클래스의 list()

        ```java
        	@GetMapping("/list")
        	public void list(Model model,Criteria cri) {
        		log.info("list: "+cri);
        		model.addAttribute("list",service.getList(cri));
        		model.addAttribute("pageMaker", new PageDTO(cri, 123));
                //임의로 총 데이터개수를 123개로 지정
        	}
        ```

   3. JSP에서 페이지 번호 출력

      ```jsp
      <div class="pull-right">
      					<ul class="pagination">
      						<c:if test="${pageMaker.prev }">
      							<li class="paginate_button previous"><a href="#">Previous</a></li>
      						</c:if>
      						<c:forEach var="num" begin="${pageMaker.startPage}" end="${pageMaker.endPage }">
      							<li class="paginate_button"><a href="#">${num}</a></li>
      						</c:forEach>
      						<c:if test="${pageMaker.next }">
      							<li class="paginate_button next"><a href="#">Next</a></li>
      						</c:if>
      					</ul>
      				</div>
      ```

      1. 페이지 번호 이벤트 처리

         - < a > 태그를 이용해서 직접 링크를 처리하는 방식의 경우 검색 조건이 붙고 난 후에 처리가 복잡하게 되므로 JS를 통해서 처리

         - list.jsp

           ```jsp
           				<div class="pull-right">
           					<ul class="pagination">
           						<c:if test="${pageMaker.prev }">
           							<li class="paginate_button previous"><a href="${pageMaker.startPage-1 }">Previous</a></li>
           						</c:if>
           						<c:forEach var="num" begin="${pageMaker.startPage}" end="${pageMaker.endPage }">
           							<li class="paginate_button ${pageMaker.cri.pageNum == num ? 'active' : '' }"><a href="${num }">${num}</a></li>
           						</c:forEach>
           						<c:if test="${pageMaker.next }">
           							<li class="paginate_button next"><a href="${pageMaker.endPage+1}">Next</a></li>
           						</c:if>
           					</ul>
           				</div>
           ```

         - < a> 태그가 원래의 동작을 못하도록 JS에서 처리하고, 실제 페에지를 클릭하면 동작을 하는 부분은 별도의 < form > 태그를 이용해서 처리

           ```jsp
           				<form id="actionForm" action="/board/list" method="get">
           					<input type="hidden" name="pageNum" value="${pageMaker.cri.pageNum }"> 
           					<input type="hidden" name="amount" value="${pageMaker.cri.amount }">
           				</form>
           ```

         - list.jsp수정

           ```js
           var actionForm = $("#actionForm");
           				
           $(".paginate_button a").on("click",function(e){ //<a>태그 클릭시
           			e.preventDefault(); //기존 이벤트 중지
           			console.log('click');
           			actionForm.find("input[name='pageNum']").val($(this).attr("href"));
           			//actionForm의 pageNum의 value값을 현재 눌린 <a>태그의 href의 값으로 설정
               actionForm.submit();
           		});
           ```

   4. 조회 페이지로 이동

      - 조회 -> 목록으로 이동시 무조건 1페이지로 이동
      - 조회 페이지로 갈 때 현재 목록 페이지의 pageNum과 amount를 같이 전달
      - < form > 태그에 추가로 게시물의 번호를 같이 전송하고, action값을 조정

      - list.jsp

        ```java
        					<c:forEach items="${list }" var="board">
        						<tbody>
        							<tr>
        								<td><c:out value="${board.bno }" /></td>
        								<td><a class="move" href='<c:out value="${board.bno }"/>'><c:out value="${board.title }"></c:out></a></td>
        								<td><c:out value="${board.writer }"></c:out></td>
        								<td><fmt:formatDate pattern="yyyy-MM-dd" value="${board.regdate }" /></td>
        								<td><fmt:formatDate pattern="yyyy-MM-dd" value="${board.updateDate }" /></td>
        							</tr>
        						</tbody>
        					</c:forEach>
        ```

        ```js
        $('.move').on('click',function(e){ //제목 클릭시
        			e.preventDefault(); //기존 이벤트 중지
        			actionForm.append("<input type='hidden' name='bno' value='"+$(this).attr("href")+"'/>"); // name=bno , value를 href값을 넣어줌
        			actionForm.attr("action","/board/get"); // /board/get으로 이동
        			actionForm.submit(); //submit
        		});
        ```

      1. 조회 페이지에서 다시 목록 페이지로 이동 - 페이지 번호 유지

         - 추가적인 파라미터가 붙으면서 Criteria를 파라미터로 추가

         - BoardController

           ```java
           	@GetMapping({"/get","/modify"})
           	public void get(@RequestParam("bno") Long bno,@ModelAttribute("cri") Criteria cri, Model model) {
           		
           		log.info("/get or /modify");
           		model.addAttribute("board",service.get(bno));
           	}
           ```

         - get.jsp

           ```jsp
           				<form id='operForm' action="/board/modify" method="get">
           					<input type="hidden" id="bno" name="bno" value='<c:out value="${board.bno }"></c:out>'>
           					<input type="hidden" name="pageNum" value='<c:out value="${cri.pageNum }"></c:out>'>
           					<input type="hidden" name="amount" value='<c:out value="${cri.amount }"></c:out>'>
           				</form>
           ```

      ### 수정과 삭제 처리

      - modify.jsp

        ```jsp
        			<div class="panel-body">
        				<form role="form" action="/board/modify" method="post">
        					<input type="hidden" name="pageNum" value="${cri.pageNum }">
        					<input type="hidden" name="amount" value="${cri.amount }">
        ```

      1. 수정/삭제 처리 후 이동

         - BoardController 의 modify()

           ```java
           	@PostMapping("/modify")
           	public String modify(BoardVO board,RedirectAttributes rttr,@ModelAttribute("cri") Criteria cri) {
           		log.info("modify.."+board);
           		
           		if(service.modify(board)) {
           			rttr.addFlashAttribute("result", "success");
           		}
           		rttr.addAttribute("pageNum", cri.getPageNum());
           		rttr.addAttribute("amount", cri.getAmount());
           		
           		return "redirect:/board/list";
           	}
           ```

         - BoardController 의 remove()

           ```java
           	@PostMapping("/remove")
           	public String remove(@RequestParam("bno") Long bno,RedirectAttributes rttr,@ModelAttribute("cri") Criteria cri) {
           		log.info("remove...."+bno);
           		if(service.remove(bno)) {
           			rttr.addFlashAttribute("result", "success");
           		}
           		rttr.addAttribute("pageNum", cri.getPageNum());
           		rttr.addAttribute("amount", cri.getAmount());
           
           		return "redirect:/board/list";
           	}
           ```

      2. 수정/삭제 페이지에서 목록 페이지로 이동

         - modify.jsp 

           ```JS
           <script type="text/javascript">
           	$(document).ready(function(){
           		var formObj = $("form");
           		
           		$("button").on("click",function(e){
           			e.preventDefault();
           			
           			var operation = $(this).data("oper");
           			
           			console.log(operation);
           			
           			if(operation === 'remove'){
           				formObj.attr("action","/board/remove");
           			}else if(operation === 'list'){
           				formObj.attr("action","/board/list").attr("method","get");
           				
           				var pageNumTag = $('input[name="pageNum"]').clone();
           				var amountTag = $('input[name="amount"]').clone();
           				
           				formObj.empty(); //필요한 태그만 추가
           				formObj.append(pageNumTag);
           				formObj.append(amountTag);
           
           			}
           			formObj.submit();
           		});
           	});
           </script>
           ```

      ### Mybatis에서 전체 데이터 개수 처리

      - BoardMapper인터페이스

        ```java
        public int getTotalCount(Criteria cri);
        ```

      - BoardMapper.xml

        ```xml
        	<select id="getTotalCount" resultType="int">
        		select count(*) from tbl_board where bno > 0
        	</select>
        ```

      - BoardService

        ```java
        public int getTotal(Criteria cri);
        ```

      - BoardServiceImpl

        ```java
        	@Override
        	public int getTotal(Criteria cri) {
        		log.info("get total count");
        		return mapper.getTotalCount(cri);
        	}
        ```

        

      - BoardController

        ```java
        	@GetMapping("/list")
        	public void list(Model model,Criteria cri) {
        		log.info("list: "+cri);
        		model.addAttribute("list",service.getList(cri));
        		
        		int total = service.getTotal(cri);
        		
        		log.info("total : "+total);
        		
        		model.addAttribute("pageMaker", new PageDTO(cri, total));
        	}
        ```

        

