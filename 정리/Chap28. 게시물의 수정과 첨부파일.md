# Chap28. 게시물의 수정과 첨부파일

- 게시물의 수정에서 첨부파일은 수정이라는 개념보다는 삭제 후 다시 추가한다는 개념으로 접근

### 화면에서 첨부파일 수정

- 원본 이미지 확대나 다운로드 기능이 필요하지 않다
- 게시물 조회와 달리 삭제 버튼이 있어야한다.

1. 첨부파일 데이터보여주기

   - modify.jsp

     ```jsp
     <style>
     .uploadResult {
     	width: 100%;
     	background-color: gray;
     }
     
     .uploadResult ul {
     	display: flex;
     	flex-flow: row;
     	justify-content: center;
     	align-items: center;
     }
     
     .uploadResult ul li {
     	list-style: none;
     	padding: 10px;
     	align-content: center;
     	text-align: center;
     }
     
     .uploadResult ul li img {
     	width: 100px;
     }
     
     .uploadResult ul li span{
     	color:white;
     }
     
     .bigPictureWrapper{
     	position: absolute;
     	display: none;
     	justify-content: center;
     	align-items: center;
     	top: 0%;
     	width: 100%;
     	height: 100%;
     	background-color: gray;
     	z-index: 100;
     	background: rgba(255,255,255,0.5);
     }
     .bigPicture{
     	position: relative;
     	display: flex;
     	justify-content: center;
     	align-items: center;
     }
     
     .bigPicture img{
     	width:600px;
     }
     </style>
     
     
     
     <div class="bigPictureWrapper">
     	<div class="bigPicture">
     	</div>
     </div>
     <div class="row">
     	<div class="col-lg-12">
     		<div class="panel panel-default">
     			<div class="panel-heading">Files</div>
     			<div class="panel-body">
     				<div class="form-group uploadDiv">
     					<input type="file" name="uploadFile" multiple="multiple">
     				</div>
     				<div class="uploadResult">
     					<ul>
     					</ul>
     				</div>
     			</div>
     		</div>
     	</div>
     </div>
     ```

     ```jsp
     <script>
      $(document).ready(function() {
     	(function() {
     		
     		var bno = "${board.bno}";
     		
     		$.getJSON("/board/getAttachList", {bno : bno}, function(arr) {
     			console.log(arr);
     			
     			var str = "";
     			
     			$(arr).each(function(i,attach) {
     				//image Type
     				if(attach.fileType){ 
     					var fileCallPath = encodeURIComponent(attach.uploadPath+"/s_"+attach.uuid+"_"+attach.fileName);
     					
     					str += "<li data-path='"+attach.uploadPath+"'";
     					str += " data-uuid='"+attach.uuid+"' data-filename='"+attach.fileName+"' data-type='"+attach.image+"'><div>";
     					str += "<span>"+attach.fileName+"</span>"
     					str += "<button type='button' data-file=\'"+fileCallPath+"\' data-type='image' class='btn btn-warning btn-circle'>";
     					str += "<i class='fa fa-times'></i></button><br>";
     					str += "<img src='/display?fileName="+fileCallPath+"'>";
     					str += "</div>";
     					str += "</li>";
     				}else{
     					str += "<li data-path='"+attach.uploadPath+"'";
     					str += " data-uuid='"+attach.uuid+"' data-filename='"+attach.fileName+"' data-type='"+attach.image+"'><div>";
     					str += "<span>"+attach.fileName+"</span>";
     					str += "<button type='button' data-file=\'"+fileCallPath+"\' data-type='file' class='btn btn-warning btn-circle'>";
     					str += "<i class='fa fa-times'></i></button><br>";
     					str += "<img src='/resources/img/attach.png'>";
     					str += "</div>";
     					str += "</li>";
     				}
     				
     			});
     			$(".uploadResult ul").html(str);
     		});
     	})();
     </script>
     ```

2. 첨부파일의 삭제 이벤트

   - 사용자가 특정 첨부파일을 삭제했을 때 화면에서만 삭제하고, 최종적으로 게시물을 수정했을 때 이를 반영

   - modify.jsp

     ```js
     	$(".uploadResult").on("click","button",function(e){
     		console.log("delete file");
     		
     		if(confirm("Remove this file?")){
     			
     			var targetLi = $(this).closest("li");
     			targetLi.remove();
     		}
     	})
     ```

3. 첨부파일 추가

   ```js
   		var regex = new RegExp("(.*?)\.(exe|sh|zip|alz)$");
   		var maxSize = 5242880; //5mb
   		
   		function checkExtension(fileName,fileSize) {
   			if(fileSize >= maxSize){
   				alert("파일 사이즈 초과 ");
   				return false;
   			}
   			if(regex.test(fileName)){
   				alert("해당종류의 파일은 업로드할 수 없습니다.");
   				return false;
   			}
   			return true;
   		}
   function showUploadResult(uploadResultArr){
   			if(!uploadResultArr || uploadResultArr.length == 0){
   				return;
   			}
   			var uploadUL = $(".uploadResult ul");
   			var str = "";
   			$(uploadResultArr).each(function(i,obj){
   				if(obj.image){
   					var fileCallPath = encodeURIComponent(obj.uploadPath+"/s_"+obj.uuid+"_"+obj.fileName);
   					
   					str += "<li data-path='"+obj.uploadPath+"'";
   					str += " data-uuid='"+obj.uuid+"' data-filename='"+obj.fileName+"' data-type='"+obj.image+"'><div>";
   					str += "<span> "+obj.fileName+"</span>";
   					str += "<button type='button' data-file=\'"+fileCallPath+"\' data-type='image' class='btn btn-warning btn-circle'>";
   					str += "<i class='fa fa-times'></i></button></br>";
   					str += "<img src='/display?fileName="+fileCallPath+"'>";
   					str += "</div>";
   					str += "</li>";
   					
   				}else{
   					var fileCallPath = encodeURIComponent(obj.uploadPath+"/"+obj.uuid+"_"+obj.fileName);
   					var fileLink = fileCallPath.replace(new RegExp(/\\/g),"/");
   					
   					str += "<li data-path='"+obj.uploadPath+"'";
   					str += " data-uuid='"+obj.uuid+"' data-filename='"+obj.fileName+"' data-type='"+obj.image+"'><div>";
   					str += "<span> "+obj.fileName+"</span>";
   					str += "<a><button type='button' data-file=\'"+fileCallPath+"\' data-type='file' class='btn btn-warning btn-circle'>";
   					str += "<i class='fa fa-times'></i></button></br>";
   					str += "<img src='/resources/img/attach.png'></a>";
   					str += "</div>";
   					str += "</li>";
   				}
   			});
   			uploadUL.append(str);
   		}
   		
   		$("input[type=\'file\']").change(function(e) {
   		    var formData = new FormData();
   		    var inputFile = $("input[name='uploadFile']");
   		    var files = inputFile[0].files;
   		    
   		    for(var i = 0; i < files.length; i++){
   		      if(!checkExtension(files[i].name, files[i].size) ){
   		        return false;
   		      }
   		      formData.append("uploadFile", files[i]);
   		    }
   			
   			
   			$.ajax({
   				url:'/uploadAjaxAction',
   				processData: false,
   				contentType: false,
   				data:formData,
   				type: "POST",
   				dataType: 'json',
   				success: function(result) {
   					console.log(result);
   					showUploadResult(result);
   				}
   			});
   		});
   ```

4. 게시물 수정 이벤트 처리

   ```jsp
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
   				var typeTag = $('input[name="type"]').clone();
   				var keywordTag = $('input[name="keyword"]').clone();
   				
   				formObj.empty();
   				formObj.append(pageNumTag);
   				formObj.append(amountTag);
   				formObj.append(typeTag);
   				formObj.append(keywordTag);
   			}else if(operation == 'modify'){
   				console.log("submit clicked");
   				
   				var str = "";
   				
   				$(".uploadResult ul li").each(function(i,obj){
   					var jobj = $(obj);
   					console.log(jobj);
   					
   					
   					 str += "<input type='hidden' name='attachList["+i+"].fileName' value='"+jobj.data("filename")+"'>";
   				     str += "<input type='hidden' name='attachList["+i+"].uuid' value='"+jobj.data("uuid")+"'>";
   				     str += "<input type='hidden' name='attachList["+i+"].uploadPath' value='"+jobj.data("path")+"'>";
   				     str += "<input type='hidden' name='attachList["+i+"].fileType' value='"+jobj.data("type")+"'>";
   				});
   				formObj.append(str).submit();
   			}
   			formObj.submit();
   		});
   	});
   </script>
   ```

### 서버 측 게시물 수정과 컴파일

- 게시물의 모든 첨부파일 목록을 삭제하고, 다시 첨부파일 목록을 추가하는 형태로 처리

1. BoardServiceImpl수정

   ```java
   	@Override
   	public boolean modify(BoardVO board) {
   		log.info("modify........");
   		
   		attachMapper.deleteAll(board.getBno()); //데이터베이스에서 해당게시물에 대한 모든 첨부파일을 지움
   		
   		boolean modifyResult = mapper.update(board) == 1; //수정
   		
   		if(modifyResult && board.getAttachList() != null && board.getAttachList().size()>0) { //수정이고 첨부파일이 있으면
   			board.getAttachList().forEach(attach->{
   				attach.setBno(board.getBno()); // 게시물번호설정
   				attachMapper.insert(attach); //등록
   			});
   		}
   		
   		return modifyResult;
   	}
   ```

   