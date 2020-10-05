# Chap15. 검색처리	

### 검색 기능과 SQL

- 검색 기능의 분류
  1. 제목/내용/작성자와 같이 **단일 항목 검색**
  2. 제목+내용 , 제목+작성자 등등 **다중 항목 검색**

- 검색 조건에 대한 처리는 인라인뷰의 내부에서 이루어져야함

  - ex) 제목이 Test를 포함하는 모든 게시물을 조회

  ```sql
  select * from 
  (
  	select /*+INDEX_DESC(tbl_board pk_board) */
  	rownum rn,bno,title,content,writer,regdate,update
  	from tbl_board
  	where title like '%Test%' and rownum <= 20
  )
  where rn > 10;
  ```

1. 다중 항목 검색

   - 예상 sql문

     ```sql
     select * from 
     (
     	select /*+INDEX_DESC(tbl_board pk_board) */
     	rownum rn,bno,title,content,writer,regdate,updatedate
     	from tbl_board
     	where title like '%Test%' or content like '%Test%' and rownum <= 20
     )
     where rn > 10;
     ```

     - 하지만 실제로 결과는 10건 보다 더 많이 나온다 왜냐하면 and가 or보다 우선순위가 높기 떄문에 rownum<=20 면서 content에 Test라는 문자열이 있거나 제목에 Test라는 문자열이 있는 게시물을 검색
     - 따라서 ( )연산자를 이용해서 우선순위를 설정

   - 올바른 sql문

     ```sql
     select * from 
     (
     	select /*+INDEX_DESC(tbl_board pk_board) */
     	rownum rn,bno,title,content,writer,regdate,updatedate
     	from tbl_board
     	where ( title like '%Test%' or content like '%Test%' ) and rownum <= 20
     )
     where rn > 10;
     ```

### MyBatis의 동적 SQL문

- 검색 조건이 변하면 SQL의 내용 역시 변하기 때문에 XML이나 어노테이션 같이 고정된 문자열을 작성하는 방식으로는 제대로 처리 할 수 없다.
- **MyBatis의 동적 태그 기능을 통해서 SQL을 파라미터들의 조건에 맞게 조정 가능**

1. MyBatis의 동적 태그
   - if
     - test라는 속성과 함계 특정한 조건이 true가 되었을 떄 포함된 SQL을 사용하고자 할 때 작성
   - choose(when,otherwise)
     - 여러 상황들중 하나의 상황에서만 동작
   - trim(where,set)
     - if , choose같은 태그들을 내포하여 SQL들을 연결해 주고 , 앞 뒤에 필요한 구문들을 추가하거나 생략하는 역활
   - foreach
     - List, 배열 , 맵 등을 이용해서 루프를 처리

### 검색 조건 처리를 위한 Criteria의 변화

- **pageNum과 amount를 수집하는 역활  + 검색조건  +  검색에 사용할 키워드**

- Criteria의 확장을 통해 수정

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
  	
  	public Criteria() {
  		this(1,10);
  	}
  	public Criteria(int pageNum,int amount) {
  		this.pageNum = pageNum;
  		this.amount = amount;
  	}
  	
  	public String[] getTypeArr() { // 검색 조건이 각 글자로 (T,W,C)로 구성되어 있으므로 검색 조건을 배열로 만들어서 한 번에 처리
  		return type==null? new String[] {} : type.split(""); //TW가 들어면 T,W로 쪼개서 배열로 변경
  	}
  }
  
  ```

1. BoardMapper.xml에서 Criteria 처리

   - getListWithPaging()을 수정

     ```xml
     <select id="getList" resultType="org.zerock.domain.BoardVO">
     		<![CDATA[
     		select * from tbl_board where bno > 0
     		]]>
     	</select>
     
     	<select id="getListWithPaging" resultType="org.zerock.domain.BoardVO">
     		<![CDATA[
     			select bno,title,content,writer,regdate,updateDate
     			from
     				(
     					select /*+INDEX_DESC(tbl_board pk_board) */ rownum rn,bno,title,content,writer,regdate,updateDate
     					from tbl_board
     					where 
     		]]>
              <!--prefix : 접두사-->
             <!--suffix :  접미사-->
             <!-- prefixOverrides : 하위 엘레먼트가 생성한 내용의 맨앞에 해당하는 문자가 있으면 자동으로 지워줌-->
             <!--collection : 전달받은 인자값 , getTypeArr을 호출-->
     		<trim prefix="(" suffix=") AND " prefixOverrides="OR">
                 <!--T,W,C-->
     			<foreach collection="typeArr" item="type">
                     <!--맨앞에 OR을 붙여줌 처음에는 prefixOverrides 때문에 지워짐-->
     				<trim prefix="OR">
     					<choose>
                             <!--배열의 값을 조회-->
     						<when test="type == 'T'.toString()">
     							title like '%'||#{keyword}||'%'
     						</when>
     						<when test="type == 'C'.toString()">
     							content like '%'||#{keyword}||'%'
     						</when>
     						<when test="type == 'W'.toString()">
     							writer like '%'||#{keyword}||'%'
     						</when>
     					</choose>
     				</trim>
     			</foreach>
     		</trim>
     
     		<![CDATA[
     			rownum <= #{pageNum} * #{amount}
     			)
     				
     			where rn > (#{pageNum}-1)*#{amount}
     		]]>
     	</select>
     ```

   - BoardMapperTests를 통해서 테스트

     ```java
     	@Test
     	public void testSearch() {
     		Criteria cri = new Criteria();
     		cri.setKeyword("새로"); //검색 키워드
     		cri.setType("TC"); //검색 조건
     		
     		List<BoardVO> list = mapper.getListWithPaging(cri);
     		
     		list.forEach(board -> log.info(board));
     	}
     ```

   - < sql > , < include > 을 이용해서 BoardMapper.xml 수정

     - < sql > 이라는 태그를 이용해서 SQL의 일부를 별도로 보관, 필요한 경우 < include > 태그를 통해 포함 시킴

     ```XML
     	<sql id="criteria">
     		<trim prefix="(" suffix=") AND " prefixOverrides="OR">
     			<foreach collection="typeArr" item="type">
     				<trim prefix="OR">
     					<choose>
     						<when test="type == 'T'.toString()">
     							title like '%'||#{keyword}||'%'
     						</when>
     						<when test="type == 'C'.toString()">
     							content like '%'||#{keyword}||'%'
     						</when>
     						<when test="type == 'W'.toString()">
     							writer like '%'||#{keyword}||'%'
     						</when>
     					</choose>
     				</trim>
     			</foreach>
     		</trim>
     
     	</sql>
     
     	<select id="getList" resultType="org.zerock.domain.BoardVO">
     		<![CDATA[
     		select * from tbl_board where bno > 0
     		]]>
     	</select>
     
     	<select id="getListWithPaging" resultType="org.zerock.domain.BoardVO">
     		<![CDATA[
     			select bno,title,content,writer,regdate,updateDate
     			from
     				(
     					select /*+INDEX_DESC(tbl_board pk_board) */ rownum rn,bno,title,content,writer,regdate,updateDate
     					from tbl_board
     					where 
     		]]>
     		<include refid="criteria"></include> <!--포함시킴-->
     		<![CDATA[
     			rownum <= #{pageNum} * #{amount}
     			)
     				
     			where rn > (#{pageNum}-1)*#{amount}
     		]]>
     	</select>
     ```

### 화면에서 검색 조건 처리

- 주의 사항
  1. **페이지 번호가 파라미터로 유지되었던 것처럼 검색 조건과 키워드 역시 항상 화면 이동 시 같이 전송**
  2. **화면에서 검색 버튼을 클릭하면 새로 검색을 한다는 의미이므로 1페이지로 이동**
  3. **한글의 경우 GET방식으로 이동하는 경우 문제가 생길 수 있으므로 주의**

1. 목록 화면에서의 검색 처리

   ```jsp
   				<div class="row">
   					<div class="col-lg-12">
   						<form id="searchForm" action="/board/list" method="get">
   							<select name="type">
   								<option value="" >--</option>
   								<option value="T">제목</option>
   								<option value="C">내용</option>
   								<option value="W">작성자</option>
   								<option value="TC">제목 OR 내용</option>
   								<option value="TW">제목 OR 작성자</option>
   								<option value="TWC">제목 OR 내용 OR 작성자</option>
   							</select>
   							<input type="text" name="keyword">
   							<!-- 검색 했을 떄도 페이지 정보 전달 -->
   							<input type="hidden" name="pageNum" value="${pageMaker.cri.pageNum }"> 
   							<input type="hidden" name="amount" value="${pageMaker.cri.amount }">
   							<button class="btn btn-default">Search</button>
   						</form>
   					</div>
   				</div>
   ```

   - 문제점

     - **3페이지를 보다가 검색을 하면 3페이지로 이동하는 문제**
     - **검색 후 페이지를 이동하면 검색 조건이 사라지는 문제**
     - **검색 후 화면에서는 어떤 검색 조건과 키워드를 이용했는지 알 수 없는 문제**

   - 검색 버튼의 이벤트 처리

     - list.jsp

       ```js
       		var searchForm = $('#searchForm'); //검색 조건
       		
       		$("#searchForm button").on('click',function(e){ // Search 버튼 클릭 시
       			e.preventDefault(); //submit동작 중지
       			
       			//검색 종류가 없으면
       			if(!searchForm.find("option:selected").val()){
       				alert("검색종류를 선택하세요");
       				return false;
       			}
       			//검색 키워드가 없으면
       			if(!searchForm.find("input[name='keyword']").val()){
       				alert("키워드를 입력하세요");
       				return false;
       			}
       			
       			//pageNum의 값을 1로 바꿔줌 1페이지로 이동하게 설정
       			searchForm.find("input[name='pageNum']").val("1");
       			
       			searchForm.submit();// submit 실행
       		});
       ```

     - 검색 후에 어떤 검색 조건과 키워드를 사용했는지 (list.jsp) 

       ```jsp
       <div class="row">
       					<div class="col-lg-12">
       						<form id="searchForm" action="/board/list" method="get">
       							<select name="type">
       								<option value="" <c:out value="${pageMaker.cri.type == null? 'selected' : ''}"/>>--</option>
       								<option value="T" <c:out value="${pageMaker.cri.type eq 'T'? 'selected' : ''}"/>>제목</option>
       								<option value="C" <c:out value="${pageMaker.cri.type eq 'C'? 'selected' : ''}"/>>내용</option>
       								<option value="W" <c:out value="${pageMaker.cri.type eq 'W'? 'selected' : ''}"/>>작성자</option>
       								<option value="TC" <c:out value="${pageMaker.cri.type eq 'TC'? 'selected' : ''}"/>>제목 OR 내용</option>
       								<option value="TW" <c:out value="${pageMaker.cri.type eq 'TW'? 'selected' : ''}"/>>제목 OR 작성자</option>
       								<option value="TWC" <c:out value="${pageMaker.cri.type eq 'TWC'? 'selected' : ''}"/>>제목 OR 내용 OR 작성자</option>
       							</select>
       							<input type="text" name="keyword" value="${pageMaker.cri.keyword }">
       							<!-- 검색 했을 떄도 페이지 정보 전달 -->
       							<input type="hidden" name="pageNum" value="${pageMaker.cri.pageNum }"> 
       							<input type="hidden" name="amount" value="${pageMaker.cri.amount }">
       							<button class="btn btn-default">Search</button>
       						</form>
       					</div>
       				</div>
       ```

     - 페이지 번호를 클릭해서 이동할 때도 검색 조건과 키워드는 같이 전달 (list.jsp)

       ```jsp
       				<form id="actionForm" action="/board/list" method="get">
       					<input type="hidden" name="pageNum" value="${pageMaker.cri.pageNum }"> 
       					<input type="hidden" name="amount" value="${pageMaker.cri.amount }">
                           <!--페이지 이동 시 검색조건과 키워드 전달-->
       					<input type="hidden" name="type" value="${pageMaker.cri.type }">
       					<input type="hidden" name="keyword" value="${pageMaker.cri.keyword }">
       				</form>
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

2. 조회 페이지에서 검색 처리

   - 목록 페이지에서 조회 페이지로의 이동은 이미 < form > 태그를 이용해서 처리

   - **다만 조회 페이지는 아직 Criteria의 type과 keyword에 대한 처리가 없기 떄문에 이부분을 처리** (get.jsp)

     ```jsp
     				<form id='operForm' action="/board/modify" method="get">
     					<input type="hidden" id="bno" name="bno" value='<c:out value="${board.bno }"></c:out>'>
     					<input type="hidden" name="pageNum" value='<c:out value="${cri.pageNum }"></c:out>'>
     					<input type="hidden" name="amount" value='<c:out value="${cri.amount }"></c:out>'>
     					<input type="hidden" name="type" value="${cri.type }">
     					<input type="hidden" name="keyword" value="${cri.keyword }">
     				</form>
     ```

3. 수정 / 삭제 페이지에서 검색 처리

   - modify.jsp

     ```jsp
     <div class="panel-body">
     				<form role="form" action="/board/modify" method="post">
     					<input type="hidden" name="pageNum" value="${cri.pageNum }">
     					<input type="hidden" name="amount" value="${cri.amount }">
     					<input type="hidden" name="type" value="${cri.type }">
     					<input type="hidden" name="keyword" value="${cri.keyword }">
     					<div class="form-group">
     						<label>Bno</label><input class="form-control" name="bno" value='<c:out value='${board.bno }'/>' readonly="readonly">
     					</div>
     					<div class="form-group">
     						<label>Title</label><input class="form-control" name="title" value='<c:out value='${board.title}'/>'>
     					</div>
     					<div class="form-group">
     						<label>Text Area</label>
     						<textarea class="form-control" rows="3" name="content"><c:out value='${board.content}' /></textarea>
     					</div>
     					<div class="form-group">
     						<label>Writer</label><input class="form-control" name="writer" value='<c:out value='${board.writer}'/>' readonly="readonly">
     					</div>
     					<div class="form-group">
     						<label>RegDate</label> <input class="form-control" name='regDate' value='<fmt:formatDate pattern = "yyyy-MM-dd" value = "${board.regdate}" />' readonly="readonly">
     					</div>
     
     					<div class="form-group">
     						<label>Update Date</label> <input class="form-control" name='updateDate' value='<fmt:formatDate pattern = "yyyy-MM-dd" value = "${board.updateDate}" />' readonly="readonly">
     					</div>
     					<button type="submit" data-oper="modify" class="btn btn-default">Modify</button>
     					<button type="submit" data-oper="remove" class="btn btn-danger">Remove</button>
     					<button type="submit" data-oper="list" class="btn btn-info">List</button>
     				</form>
     			</div>
     ```

   - 수정 /  삭제 처리는 BoardController에서 redirect 방식으로 동작하므로 type과 keyword 조건을 같이 리다이렉트 시에 포함

     ```java
     	@PostMapping("/modify")
     	public String modify(BoardVO board,RedirectAttributes rttr,@ModelAttribute("cri") Criteria cri) {
     		log.info("modify.."+board);
     		
     		if(service.modify(board)) {
     			rttr.addFlashAttribute("result", "success");
     		}
     		rttr.addAttribute("pageNum", cri.getPageNum());
     		rttr.addAttribute("amount", cri.getAmount());
     		rttr.addAttribute("type", cri.getType());
     		rttr.addAttribute("keyword", cri.getKeyword());
     		
     		return "redirect:/board/list";
     	}
     	
     	@PostMapping("/remove")
     	public String remove(@RequestParam("bno") Long bno,RedirectAttributes rttr,@ModelAttribute("cri") Criteria cri) {
     		log.info("remove...."+bno);
     		if(service.remove(bno)) {
     			rttr.addFlashAttribute("result", "success");
     		}
     		rttr.addAttribute("pageNum", cri.getPageNum());
     		rttr.addAttribute("amount", cri.getAmount());
     		rttr.addAttribute("type", cri.getType());
     		rttr.addAttribute("keyword", cri.getKeyword());
     		return "redirect:/board/list";
     	}
     ```

   - modify.jsp에서 다시 목록으로 이동하는 경우에 필요한 파라미터만 전송하기 위해 < form > 태그의 모든 내용을 지우고 다시 추가하는 방식을 사용

     ```js
     <script type="text/javascript">
     	$(document).ready(function(){
     		var formObj = $("form");
     		
     		$("button").on("click",function(e){ // 수정 , 삭제 , 목록 클릭시
     			e.preventDefault();
     			
     			var operation = $(this).data("oper");
     			
     			console.log(operation);
     			
     			if(operation === 'remove'){
     				formObj.attr("action","/board/remove");
     			}else if(operation === 'list'){
     				formObj.attr("action","/board/list").attr("method","get");
     				
     				var pageNumTag = $('input[name="pageNum"]').clone();
     				var amountTag = $('input[name="amount"]').clone();
     				var typeTag = $('input[name="type"]').clone();
     				var keywordTag = $('input[name="keyword"]').clone();
     				
     				formObj.empty();
     				formObj.append(pageNumTag);
     				formObj.append(amountTag);
     				formObj.append(typeTag);
     				formObj.append(keywordTag);
     			}
     			formObj.submit();
     		});
     	});
     </script>
     ```

   - UriComponentsBuilder

     - 웹페이지에서 매번 파라미터를 유지하는 일이 번거롭고 힘들때 사용

     - UriComponentsBuilder는 여러 개의 파라미터들을 연결해서 URL 의 형태로 만들어주는 기능

       ```JAVA
       package org.zerock.domain;
       
       import org.springframework.web.util.UriComponentsBuilder;
       
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
       	
       	public Criteria() {
       		this(1,10);
       	}
       	public Criteria(int pageNum,int amount) {
       		this.pageNum = pageNum;
       		this.amount = amount;
       	}
       	
       	public String[] getTypeArr() {
       		return type==null? new String[] {} : type.split("");
       	}
       	
       	public String getListLink() {
       		UriComponentsBuilder builder = UriComponentsBuilder.fromPath("")
       				.queryParam("pageNum", this.pageNum)
       				.queryParam("amount", this.getAmount())
       				.queryParam("type", this.getType())
       				.queryParam("keyword", this.getKeyword());
       			
       		return builder.toUriString();
       		//get방식에 적합한 URL 인코딩 결과로 만들어 진다.
       	}
       }
       
       ```

       ```java
       	
       	@PostMapping("/modify")
       	public String modify(BoardVO board,RedirectAttributes rttr,@ModelAttribute("cri") Criteria cri) {
       		log.info("modify.."+board);
       		
       		if(service.modify(board)) {
       			rttr.addFlashAttribute("result", "success");
       		}
       		
       		return "redirect:/board/list"+cri.getListLink();
       	}
       	
       	@PostMapping("/remove")
       	public String remove(@RequestParam("bno") Long bno,RedirectAttributes rttr,@ModelAttribute("cri") Criteria cri) {
       		log.info("remove...."+bno);
       		if(service.remove(bno)) {
       			rttr.addFlashAttribute("result", "success");
       		}
       
       		return "redirect:/board/list"+cri.getListLink();
       	}
       ```

       

