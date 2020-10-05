# Chap11. 화면 처리

- 부트스트랩을 이용해 구성
- SB Admin2 사용

### 목록 페이지 작업과 includes

- '/WEB-INF/views/board/list.jsp'추가

1. SB Admin2 페이지 적용하기

   - SB Admin2의 page폴더에 있는 tables.html 내용을 list.jsp에 그대로 복사

   - WebConfig 클래스에는 CSS나 JS 파일과 같이 정적인 자원들의 경로를 'resources'라는 경로로 지정

     ```xml
     	<!-- Handles HTTP GET requests for /resources/** by efficiently serving up static resources in the ${webappRoot}/resources directory -->
     	<resources mapping="/resources/**" location="/resources/" />
     ```

   - SB Admin2의 압축을 풀어둔 모든 폴더를 프로젝트 내 webapp밑의 resources 폴더로 복사해 넣음

   - list.jsp에서 CSS, JS파일의 경로를 '/resources'로 시작하도록 변경

2. includes 적용

   - JSP를 작성할 때마다 많은 양의 html 코드를 이용하는 것을 피하기 위해 JSP의 include 지시자를 활용해서 페이지 제작 시에 필요한 내용만을 작성할 수 있게 사전에 작업
   - header.jsp 적용
   - footer.jsp적용

3. jQuery 라이브러리 변경

   - footer.jsp에서 jQuery 라이브러리를 header.jsp로 이동

### 목록 화면 처리

- views/board/list.jsp

  ```jsp
  <%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
  <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
  <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
  
  <%@ include file="../includes/header.jsp"%>
  
  <div class="row">
  	<div class="col-lg-12">
  		<h1 class="page-header">Tables</h1>
  	</div>
  	<!-- /.col-lg-12 -->
  </div>
  <!-- /.row -->
  
  <div class="row">
  	<div class="col-lg-12">
  		<div class="panel panel-default">
  			<div class="panel-heading">
  				Board List Page
  			</div>
  			<!-- /.panel-heading -->
  			<div class="panel-body">
  				<table width="100%" class="table table-striped table-bordered table-hover">
  					<thead>
  						<tr>
  							<th>#번호</th>
  							<th>제목</th>
  							<th>작성자</th>
  							<th>작성일</th>
  							<th>수정일</th>
  						</tr>
  					</thead>
                  </table>
  			</div>
  		</div>
  	</div>
  </div>
  <!-- /.row -->
  <%@ include file="../includes/footer.jsp"%>
  ```

1. Model에 담긴 데이터 출력

   - '/board/list'를 실행했을 때 이미 BoardController는 Model을 이용해서 게시물의 목록을 list라는 이름으로 담아서 전달

   - list.jsp

     ```jsp
     				<table width="100%" class="table table-striped table-bordered table-hover">
     					<thead>
     						<tr>
     							<th>#번호</th>
     							<th>제목</th>
     							<th>작성자</th>
     							<th>작성일</th>
     							<th>수정일</th>
     						</tr>
     					</thead>
                         <!--Model객체로 전달된 정보 받음-->
     					<c:forEach items="${list }" var="board">
     						<tbody>
     							<tr>
     								<td><c:out value="${board.bno }" /></td>
     								<td><c:out value="${board.title }"></c:out></td>
     								<td><c:out value="${board.writer }"></c:out></td>
     								<td><fmt:formatDate pattern="yyyy-MM-dd" value="${board.regdate }" /></td>
     								<td><fmt:formatDate pattern="yyyy-MM-dd" value="${board.updateDate }" /></td>
     							</tr>
     						</tbody>
     					</c:forEach>
     				</table>
     ```

### 목록 입력 페이지와 등록 처리

- 게시물의 등록 작업은 POST 방식으로 처리하지만, 화면에서 입력을 받아야 하므로 GET방식으로 입력페이지를 볼 수 있도록 BoardController에 메서드를 추가

  ```java
  	@GetMapping("/register")
  	public void register() {
  		//void면 register.jsp로 이동
  	}
  ```

- register.jsp 페이지 작성

  ```jsp
  <%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
  <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
  <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
  
  <%@ include file="../includes/header.jsp"%>
  
  <div class="row">
  	<div class="col-lg-12">
  		<h1 class="page-header">Board Register</h1>
  	</div>
  	<!-- /.col-lg-12 -->
  </div>
  <!-- /.row -->
  
  <div class="row">
  	<div class="col-lg-12">
  		<div class="panel panel-default">
  			<div class="panel-heading">Board Register</div>
  			<!-- /.panel-heading -->
  			<div class="panel-body">
                  <!--BoardController의 '/board/register' 로 전송-->
                  <!--input , textarea태그의 name속성은 BoardVO 클래스의 변수와 일치시킴-->
  				<form role="form" action="/board/register" method="post">
  					<div class="form-group">
  						<label>Title</label><input class="form-control" name="title">
  					</div>
  					<div class="form-group">
  						<label>Text Area</label><textarea class="form-control" rows="3" name="content"></textarea>
  					</div>
  					<div class="form-group">
  						<label>Writer</label><input class="form-control" name="writer">
  					</div>
  					<button type="submit" class="btn btn-default">Submit</button>
  					<button type="reset" class="btn btn-default">Reset</button>
  				</form>
  			</div>
  		</div>
  	</div>
  </div>
  <!-- /.row -->
  <%@ include file="../includes/footer.jsp"%>
  ```

1. 한글 문제와 UTF-8 필터 처리

   - 브라우저에서 한글이 깨져서 전송되는지를 확인

   - 문제가 없다면 스프링 MVC쪽에서 한글을 처리하는 필터를 등록

     ```xml
     	<filter>
     		<filter-name>encoding</filter-name>
     		<filter-class>org.springframework.web.filter.CharacterEncodingFilter</filter-class>
     		<init-param>
     			<param-name>encoding</param-name>
     			<param-value>UTF-8</param-value>
     		</init-param>
     	</filter>
     	
     	<filter-mapping>
     		<filter-name>encoding</filter-name>
     		<servlet-name>appServlet</servlet-name>
     	</filter-mapping>
     ```

2. 재전송(redirect)처리

   - 등록, 수정 , 삭제 작업은 처리가 완료된 후 다시 동일한 내용을 전송할 수 없도록 아예 브라우저의 URL을 이동하는 방식을 이용 -> 모달창을 통해 등록 수정 삭제의 결과를 바로 알 수 있게 함\
   - BoardController에서 redirect 처리를 할 때 RedirectAttributes 라는 특별한 타입의 객체를 이용해서 addFlashAttribute()를 사용하는데, 이 메서드를 이용하면 일회성으로만 데이터를 전달

3. 모달(Modal)창 보여주기

   - list.jsp

   ```jsp
   				<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
   					<div class="modal-dialog">
   						<div class="modal-content">
   							<div class="modal-header">
   								<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
   								<h4 class="modal-title" id="myModalLabel">Modal title</h4>
   							</div>
   							<div class="modal-body">처리가 완료되었습니다.</div>
   							<div class="modal-footer">
   								<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
   							</div>
   						</div>
   						<!-- /.modal-content -->
   					</div>
   					<!-- /.modal-dialog -->
   				</div>
   ```

   ```jsp
   <script type="text/javascript">
   	$(document).ready(function(){
   		var result = '<c:out value="${result}"/>' //리다이렉트로 전송된 등록된 게시물의 번호
   		checkModal(result);
   		
   	function checkModal(result) {
   			if(result === ''){ //게시물이 등록된 경우가 아니면
   				return;
   			}
   			if(parseInt(result) > 0){ //게시물이 등록된 경우
   				$(".modal-body").html("게시글 "+parseInt(result)+"번이 등록되었습니다.");
   			}
   			
   			$("#myModal").modal("show"); //모달창 보여줌
   		}
   </script>
   ```

4. 목록에서 버튼으로 이동하기

   - list.jsp 

     ```jsp
     			<div class="panel-heading">
     				Board List Page
     				<button id="regBtn" type="button" class="btn btn-xs pull-right">Register New Board</button>
     			</div>
     ```

     ```jsp
     <script type="text/javascript">
     	$(document).ready(function(){
     		var result = '<c:out value="${result}"/>' //리다이렉트로 전송된 등록된 게시물의 번호
     		checkModal(result);
     		
     	function checkModal(result) {
     			if(result === ''){ //게시물이 등록된 경우가 아니면
     				return;
     			}
     			if(parseInt(result) > 0){ //게시물이 등록된 경우
     				$(".modal-body").html("게시글 "+parseInt(result)+"번이 등록되었습니다.");
     			}
     			
     			$("#myModal").modal("show"); //모달창 보여줌
     		}
     		
     		$('#regBtn').on("click",function(){ //Register New Board 클릭시 게시물 등록 페이지로 이동
     			self.location = "/board/register";
     		});
     </script>
     ```


### 조회 페이지와 이동

- 목록 페이지에서 링크를 통해서 GET 방식으로 특정한 번호의 게시물을 조회

1. 조회 페이지 작성

   - 게시물 번호를 출력
   - 모든 데이터가 읽기 전용으로 처리

   ```JAVA
   	@GetMapping("/get")
   	public void get(@RequestParam("bno") Long bno, Model model) {
   		
   		log.info("/get");
   		model.addAttribute("board",service.get(bno));
           //get.jsp로 board전달
   	}
   ```

   - get.jsp

   ```jsp
   <div class="row">
   	<div class="col-lg-12">
   		<h1 class="page-header">Board Read</h1>
   	</div>
   	<!-- /.col-lg-12 -->
   </div>
   <!-- /.row -->
   
   <div class="row">
   	<div class="col-lg-12">
   		<div class="panel panel-default">
   			<div class="panel-heading">Board Read Page</div>
   			<!-- /.panel-heading -->
   			<div class="panel-body">
                   <!--모든 데이터는 읽기 전용-->
   				<div class="form-group">
   					<label>Bno</label><input class="form-control" name="bno" value='<c:out value='${board.bno }'/>' readonly="readonly">
   				</div>
   				<div class="form-group">
   					<label>Title</label><input class="form-control" name="title" value='<c:out value='${board.title}'/>' readonly="readonly">
   				</div>
   				<div class="form-group">
   					<label>Text Area</label>
   					<textarea class="form-control" rows="3" name="content" readonly="readonly"><c:out value='${board.content}'/></textarea>
   				</div>
   				<div class="form-group">
   					<label>Writer</label><input class="form-control" name="writer" value='<c:out value='${board.writer}'/>' readonly="readonly">
   				</div>
   				<button data-oper='modify' class="btn btn-default" onclick="location.href='/board/modify?bno=${board.bno}'">Modify</button>
   				<button data-oper='list' class="btn btn-info" onclick="location.href='/board/list'">List</button>
   			</div>
   		</div>
   	</div>
   </div>
   ```

2. 목록 페이지와 뒤로 가기 문제

   - 목록 페이지에서 각 게시물 제목에 a태그를 적용해서 조회 페이지로 이동하게 처리
     - 만약 새창을 통해서 보고싶다면 a태그의 속성으로 target='_blank'를 지정

   ```jsp
   <tr>
   								<td><c:out value="${board.bno }" /></td>
   								<td><a href='/board/get?bno=<c:out value="${board.bno }"/>'><c:out value="${board.title }"></c:out></a></td>
   								<td><c:out value="${board.writer }"></c:out></td>
   								<td><fmt:formatDate pattern="yyyy-MM-dd" value="${board.regdate }" /></td>
   								<td><fmt:formatDate pattern="yyyy-MM-dd" value="${board.updateDate }" /></td>
   							</tr>
   ```

   - 뒤로가기의 문제

     - 등록 -> 목록 -> 조회에서 뒤로 가기 동작 시 다시 등록결과 확인창으로 이동
     - 브라우저에서 뒤로가기나 앞으로가기를 하면 서버를 다시 호출하는 게 아니라 과거에 자신이 가진 모든 데이터를 활용하기 때문
     - 이 문제를 해결하려면 window의 history 객체를 이용해서 현재 페이지는 모달창을 띄울 필요가 없다고 표시

     ```js
     var result = '<c:out value="${result}"/>'
     		
     		checkModal(result);
     		
     		history.replaceState({},null,null);
     		
     		function checkModal(result) {
     			if(result === '' || history.state){
     				return;
     			}
     			if(parseInt(result) > 0){
     				$(".modal-body").html("게시글 "+parseInt(result)+"번이 등록되었습니다.");
     			}
     			
     			$("#myModal").modal("show");
     		}
     		
     		$('#regBtn').on("click",function(){
     			self.location = "/board/register";
     		});
     ```

### 게시물의 수정/삭제 처리

- 수정/삭제의 방법
  1. 조회 페이지에서 직접 처리
  2. 별도의 수정/삭제 페이지를 만들어서 해당 페이지에서 수정과 삭제 처리 (추세)
- 조회 페이지에서 GET방식으로 처리되는 URL을 통해서 수정/삭제 버튼이 존재하는 화면을 볼 수 있게 제작
- 수정 혹은 삭제 작업은 POST방식으로 처리 , 결과는 목록화면에서 확인

1. 수정/삭제 페이지로 이동

   - BoardController

     ```java
     	@GetMapping({"/get","/modify"}) //URL을 배열로 처리해서 여러 URL을 처리하도록 설정
     	public void get(@RequestParam("bno") Long bno, Model model) {
     		
     		log.info("/get or /modify");
     		model.addAttribute("board",service.get(bno));
     	}
     ```

   - modify.jsp

     ```jsp
     <form role="form" action="/board/modify" method="post">
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
     						<label>RegDate</label> <input type="hidden" class="form-control" name='regDate' value='<fmt:formatDate pattern = "yyyy-MM-dd" value = "${board.regdate}" />' readonly="readonly">
     					</div>
     
     					<div class="form-group">
     						<label>Update Date</label> <input type="hidden" class="form-control" name='updateDate' value='<fmt:formatDate pattern = "yyyy-MM-dd" value = "${board.updateDate}" />' readonly="readonly">
     					</div>
     					<button type="submit" data-oper="modify" class="btn btn-default">Modify</button>
     					<button type="submit" data-oper="remove" class="btn btn-danger">Remove</button>
     					<button type="submit" data-oper="list" class="btn btn-info">List</button>
     				</form>
     ```

     - 버튼에 따라서 다른 동작을 할 수 있도록 수정

       ```javascript
       <script type="text/javascript">
       	$(document).ready(function(){
       		var formObj = $("form"); //form태그
       		
       		$("button").on("click",function(e){ //버튼 클릭시
       			e.preventDefault(); //이벤트 멈춤
       			
       			var operation = $(this).data("oper"); //눌린 버튼의 data-oper속성 읽어옴
       			
       			console.log(operation);
       			
       			if(operation === 'remove'){ // data-oper 속성이 remove이면
       				formObj.attr("action","/board/remove"); //boardController의 /board/remove로 이동
       			}else if(operation === 'list'){ // data-oper 속성이 list이면
                       self.location = "/board/list";
                       //boardController의 /board/list로 이동
                       return;
       			}
       			formObj.submit();
       		});
       	});
       </script>
       ```

2. 게시물 수정/삭제 확인

3. 조회 페이지에서 < form > 처리

   - 직접 버튼에 링크를 처리하는 방식을 사용하여 처리하였지만, 나중에 다양한 상황을 처리하기 위해서 < form > 태그를 이용해서 수정

     - get.jsp

       ```jsp
       				<button data-oper='modify' class="btn btn-default">Modify</button>
       				<button data-oper='list' class="btn btn-info">List</button>
       				
       				<form id='operForm' action="/board/modify" method="get">
       					<input type="hidden" id="bno" name="bno" value='<c:out value="${board.bno }"></c:out>'>
       				</form>
       ```

       ```javascript
       	$(document).ready(function(){
       		var operForm = $("#operForm"); 
       		
       		$("button[data-oper='modify']").on("click",function(e){ //modify버튼클릭
       			operForm.attr("action","/board/modify").submit();// /board/modify이동
       		});
       		$("button[data-oper='list']").on("click",function(e){ //list버튼 클릭
       			operForm.find('#bno').remove(); // list이동시 아무런 데이터 필요하지 않으므로 삭제
       			operForm.attr("action","/board/list"); // /board/list 이동
       			operForm.submit();
       		});
       	});
       ```

4. 수정 페이지에서 링크 처리

   - modify.jsp

     ```javascript
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
                     //버튼이 List인 경우 action속성과 method 속성을 변경
     				formObj.attr("action","/board/list").attr("method","get");
     				//list로 이동시 아무런 파라미터도 필요없기 떄문에 form의 내용 전부 삭제
     				formObj.empty();
     			}
     			formObj.submit();
     		});
     	});
     </script>
     ```

     

