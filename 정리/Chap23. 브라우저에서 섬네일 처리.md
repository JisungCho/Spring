# Chap23. 브라우저에서 섬네일 처리

- 남은 작업
  1. 업로드 후에 업로드 부분을 초기화 시키는 작업
  2. 결과 데이터를 이용해서 화면에 섬네일이나 파일 이미지를 보여주는 작업

### < input type='file' > 의 초기화

- uploadAjax.jsp

  ```js
  var cloneObj = $(".uploadDiv").clone(); //업로드 부분의 태그를 복사
  
  $('#uploadBtn').on("click", function(e) {
  	function checkExtension(fileName, fileSize) {
  		if (fileSize >= maxSize) {
  			.....
  ```

  ```js
  $.ajax({
  					url : '/uploadAjaxAction',
  					processData : false,
  					contentType : false,
  					data : formData,
  					type : 'POST',
  					dataType : 'json', //결과 타입
  					success : function(result) {
  						console.log(result);
  						
  						$(".uploadDiv").html(cloneObj.html()); //비어있는 상태로 변경
  					}
  				});
  ```

### 업로드된 이미지 처리

1. 파일 이름 출력

   - uploadAjax.jsp

     ```jsp
     	<div class="uploadDiv">
     		<input type="file" name="uploadFile" multiple>
     	</div>
     	<div class="uploadResult">
             <!--업로드된 파일 이름 출력-->
     		<ul>
     		</ul>
     	</div>
     ```

     ```js
     var uploadResult = $(".uploadResult ul");
     
     function showUploadedFile(uploadResultArr) { //파라미터로 업로드된 파일 리스트
     
     				var str = "";
     				
     				$(uploadResultArr).each(function(i,obj) {
     						
     						str += "<li>"+obj.fileName+"</li>";
                         
     				});
         		uploadResult.append(str); // ul에 추가
     }
     
     ```

     ```js
     $.ajax({
     					url : '/uploadAjaxAction',
     					processData : false,
     					contentType : false,
     					data : formData,
     					type : 'POST',
     					dataType : 'json', //결과 타입
     					success : function(result) {
     						console.log(result);
     						showUploadedFile(result); //업로드된 파일의 목록을 파라미터로 전달
     						$(".uploadDiv").html(cloneObj.html());
     					}
     				});
     ```

2. 일반 파일의 파일 처리

   - 우선적으로 일반 파일이 업로드된 상황에서 첨부파일의 아이콘을 보여줌

   - uploadAjax.jsp

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
     </style>
     .
     .
     .
     	<div class="uploadResult">
     		<ul>
     		</ul>
     	</div>
     .
     .
     .
     .
     <script>
     function showUploadedFile(uploadResultArr) { //파라미터로 업로드된 파일 리스트
     
     				var str = "";
     				
     				$(uploadResultArr).each(function(i,obj) {
     						
     					if(!obj.image){ //이미지가 아니면 첨부파일 이미지 추가
                             	str += "<li><img src='/resources/img/attach.png'>"+obj.fileName+"</li>";
                         }else{
                             	str += "<li>"+obj.fileName+"</li>";
                         }
     				});
         		uploadResult.append(str); // ul에 추가
     }
     </script>
     ```

3. 섬네일 이미지 보여주기

   - 서버에서 섬네일은 GET방식을 통해서 가져올 수 있도록 처리
   - 특정한 URI뒤에 파일 이름을 추가하면 이미지 파일 데이터를 가져와서 < img > 태그를 작성
   - 경로나 파일 이름에 한글 혹은 공백 등의 문자가 들어가면 문제가 발생 따라서 JS의 encodeURIComponent() 함수를이용

   - UploadController에서 섬네일 데이터 전송

     ```java
     	
     	@GetMapping("/display")
     	@ResponseBody //데이터 반환
     	public ResponseEntity<byte[]> getFile(String fileName) { // 년/월/일/파일이름 형식으로 문자열 파라미터전달
     		log.info("fileName: "+fileName);
     		
     		File file = new File("c:\\upload\\"+fileName); //해당경로의 파일 
     		
     		log.info("file: "+file);
     		ResponseEntity<byte[]> result = null;
     		
     		try {
     			HttpHeaders header = new HttpHeaders();
     			header.add("Content-Type", Files.probeContentType(file.toPath())); //해당경로 파일의 MIME타입
     			result = new ResponseEntity<byte[]>(FileCopyUtils.copyToByteArray(file),header,HttpStatus.OK);
     			//BODY에 byte[]로 복사 , header정보 , 상태정보 담음
     		} catch (Exception e) {
     			e.printStackTrace();
     		}
     		return result; // 담은 정보 전달
     	}
     	
     ```

   - JavaScript처리

     - uploadAjax.jsp

       ```jsp
       <script>
       function showUploadedFile(uploadResultArr) { //파라미터로 업로드된 파일 리스트
       
       				var str = "";
       				
       				$(uploadResultArr).each(function(i,obj) {
       						
       					if(!obj.image){ //이미지가 아니면 첨부파일 이미지 추가
                               	str += "<li><img src='/resources/img/attach.png'>"+obj.fileName+"</li>";
                           }else{ //이미지면
                               	var fileCallPath = encodeURIComponent(obj.uploadPath+"/s_"+obj.uuid+"_"+obj.fileName);
       							// 파일경로/s_uuid_파일이름
       							
       							// UploadController의 display요청
       							str += "<li><img src='/display?fileName="+fileCallPath+"'></li>";
                           }
       				});
           		uploadResult.append(str); // ul에 추가
       }
       </script>
       ```

       

     