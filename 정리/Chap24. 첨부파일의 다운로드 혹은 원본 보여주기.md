# Chap24. 첨부파일의 다운로드 혹은 원본 보여주기

- 브라우저에서 보이는 첨부파일
  1. 이미지 종류
  2. 일반파일
- 이미지 첨부파일
  - 섬네일 이미지를 클릭했을 때 화면에 크게 원본 파일을 보여주는 형태로 처리
  - 브라우저에서 새로운 < div > 등을 생성해서처리 -> light-box
- 일반파일
  - 다운로드



### 첨부파일 다운로드

- 서버에서 MIME타입을 다운로드 타입으로 지정

- 적절한 헤더 메세지를 통해서 다운로드 이름을 지정

- 이미지와 달리 다운로드는 MIME타입이 고정

- UploadController

  - 테스트1

    ```JAVA
    @GetMapping(value = "/download" , produces = MediaType.APPLICATION_OCTET_STREAM_VALUE) //다운로드 MIME타입
    	@ResponseBody
    	public ResponseEntity<Resource> downloadFile(@RequestHeader("User-Agent") String userAgent,String fileName){
    		log.info("download file : "+fileName);
    		
    		Resource resource = new FileSystemResource("C:\\upload\\"+fileName);
    		
    		log.info("Resources: "+resources);
            
            return null;
    	}
    
    ```

  - 테스트2

    ```java
    @GetMapping(value = "/download" , produces = MediaType.APPLICATION_OCTET_STREAM_VALUE) //다운로드 MIME타입
    	@ResponseBody
    	public ResponseEntity<Resource> downloadFile(String fileName){
    		log.info("download file : "+fileName);
    		
    		Resource resource = new FileSystemResource("C:\\upload\\"+fileName);
    		
    		log.info("Resources: "+resources);
    		
    		String resourceName = resource.getFilename(); //파일의이름
    		
    		HttpHeaders headers = new HttpHeaders(); //헤더생성
    		
            //Content-Disposition : 다운ㄹ드시 저장되는 이름 설정
            //attachment: 다운로드되거나, 로컬에 저장될 용도로 쓰이는것인지 명시
    		try{
    			headers.add("Content-Disposition", "attachment; filename="+new String(resourceName.getBytes("UTF-8"),"ISO-8859-1"));
    		} catch (UnsupportedEncodingException e) {
    			e.printStackTrace();
    		}
            
            return new ResponseEntity<Resource>(resource, headers, HttpStatus.OK);
    	}
    
    ```

  1. IE/Edge 브라우저의 문제

     - Content-Disposition의 값을 처리하는 방식이 IE에서는 다르기 때문에 한글 이름이 제대로 다운로드 되지않음

     - HttpServletRequest에 포함된 헤더 정보들을 이용해서 어떤 브라우저인지 체크해서 처리

     - 디바이스의 정보를 알 수있는 헤더는 'User-Agent'

     - UploadController

       ```JAVA
       @GetMapping(value = "/download" , produces = MediaType.APPLICATION_OCTET_STREAM_VALUE) //다운로드 MIME타입
       	@ResponseBody
       	public ResponseEntity<Resource> downloadFile(@RequestHeader("User-Agent") String userAgent,String fileName){
       		log.info("download file : "+fileName);
       		
       		Resource resource = new FileSystemResource("C:\\upload\\"+fileName);
       		
       		log.info("Resources: "+resources);
       		
       		String resourceName = resource.getFilename(); //파일의이름
       		
       		HttpHeaders headers = new HttpHeaders(); //헤더생성
       		
               //Content-Disposition : 다운로드시 저장되는 이름 설정
               //attachment: 다운로드되거나, 로컬에 저장될 용도로 쓰이는것인지 명시
       		try {
       			String downloadName = null;
       			if(userAgent.contains("Trident")) { //IE일때
       				log.info("IE browser");
       				downloadName = URLEncoder.encode(resourceName,"UTF-8").replaceAll("\\", " ");
       			
       			}else if(userAgent.contains("Edge")) { //edge일때
       				log.info("Edge browser");
       				downloadName = URLEncoder.encode(resourceName, "UTF-8");
       				log.info("Edge name: "+downloadName);
       
       			}else { //크롬일때
       				log.info("Chrome browser");
       				downloadName = new String(resourceName.getBytes("UTF-8"),"ISO-8859-1");
       			}
       			
       			headers.add("Content-Disposition", "attachment; filename="+downloadName);
       		} catch (UnsupportedEncodingException e) {
       			e.printStackTrace();
       		}        
               return new ResponseEntity<Resource>(resource, headers, HttpStatus.OK);
       	}
       
       ```

  2. 업로드 된 후 다운로드 처리

     - /uploadAjax 화면에서 업로드된 후 파일 이미지를 클릭한 경우에 다운로드가 될 수 있도록 처리

     - uploadAjax.jsp

       ```js
       $(document).ready(function() {
       			
       			var uploadResult = $(".uploadResult ul");
       			
       			function showUploadedFile(uploadResultArr) {
       				var str = "";
       				
       				$(uploadResultArr).each(
       					function(i,obj) {
       						if(!obj.image){
       							var fileCallPath = encodeURIComponent(obj.uploadPath+"/"+obj.uuid+"_"+obj.fileName);
       							str += "<li><div><a href='/download?fileName="+fileCallPath+"'>"+"<img src='/resources/img/attach.png'>"+obj.fileName+"</a></li>";
       						}else{
       							//str += "<li>"+obj.fileName+"</li>";
       							var fileCallPath = encodeURIComponent(obj.uploadPath+"/s_"+obj.uuid+"_"+obj.fileName);
       							
       							str += "<li><img src='/display?fileName="+fileCallPath+"'></li>";
       						}
       					});
       				uploadResult.append(str);
       			}
       ```

     - UploadController

       - uuid가 붙은 부분을 제거하고 순수하게 다운로드되는 파일의 이름으로 저장

         ```java
         @GetMapping(value = "/download" , produces = MediaType.APPLICATION_OCTET_STREAM_VALUE) //다운로드 MIME타입
         	@ResponseBody
         	public ResponseEntity<Resource> downloadFile(@RequestHeader("User-Agent") String userAgent,String fileName){
         		log.info("download file : "+fileName);
         		
         		Resource resource = new FileSystemResource("C:\\upload\\"+fileName);
         		
         		log.info("Resources: "+resources);
         		
         		String resourceName = resource.getFilename(); //파일의이름
         		
                 //remove UUID
                 String resourceOriginalName = resourceName.substring(resourceName.indexOf("_")+1);
                 //uuid_파일.확장자 -> 파일.확장자
                 
         		HttpHeaders headers = new HttpHeaders(); //헤더생성
         		
                 //Content-Disposition : 다운로드시 저장되는 이름 설정
                 //attachment: 다운로드되거나, 로컬에 저장될 용도로 쓰이는것인지 명시
         		try {
         			String downloadName = null;
         			if(userAgent.contains("Trident")) { //IE일때
         				log.info("IE browser");
         				downloadName = URLEncoder.encode(resourceName,"UTF-8").replaceAll("\\", " ");
         			
         			}else if(userAgent.contains("Edge")) { //edge일때
         				log.info("Edge browser");
         				downloadName = URLEncoder.encode(resourceName, "UTF-8");
         				log.info("Edge name: "+downloadName);
         
         			}else { //크롬일때
         				log.info("Chrome browser");
         				downloadName = new String(resourceName.getBytes("UTF-8"),"ISO-8859-1");
         			}
         			
         			headers.add("Content-Disposition", "attachment; filename="+downloadName);
         		} catch (UnsupportedEncodingException e) {
         			e.printStackTrace();
         		}        
                 return new ResponseEntity<Resource>(resource, headers, HttpStatus.OK);
         	}
         
         ```

### 

### 원본 이미지 보여주기

- 섬네일의 이미지가 '업로드된 경로+/s+UUID+파일이름' 에서 /s가 / 로 변경되는 점이다르다
- 원본 이미지를 화면에서 보기 위해서는 < div > 를 생성하고 해당 < div >에 이미지 태그를 작성해서 넣어주는 작업과 이름화면상에서 절대 위치를 이용해서 보여줄 필요가 있다.

1. 원본 이미지를 보여줄 < div >처리

   - uploadAjax

   ```js
   	function showImage(fileCallPath) {
   		alert(fileCallPath);
   	}
   
   $(document).ready(function() {
   ```

   - showImage함수는 $(document).ready 바깥쪽에 작성 , 나중에 < a > 태그에서 직접 showImage를 호출하는 방식으로 사용하기위해

   ```js
   $(document).ready(function() {
   			
   			var uploadResult = $(".uploadResult ul");
   			
   			function showUploadedFile(uploadResultArr) {
   				var str = "";
   				
   				$(uploadResultArr).each(
   					function(i,obj) {
   						if(!obj.image){
   							var fileCallPath = encodeURIComponent(obj.uploadPath+"/"+obj.uuid+"_"+obj.fileName);
   							str += "<li><div><a href='/download?fileName="+fileCallPath+"'>"+"<img src='/resources/img/attach.png'>"+obj.fileName+"</a></li>";
   						}else{
   							//str += "<li>"+obj.fileName+"</li>";
   							var fileCallPath = encodeURIComponent(obj.uploadPath+"/s_"+obj.uuid+"_"+obj.fileName);
   							
                               var originPath = obj.uploadPath+"\\"+obj.uuid+"_"+obj.fileName;
   							
   							originPath = originPath.replace(new RegExp(/\\/g), "/"); 
   							
   							str += "<li><a href=\"javascript:showImage(\'"+originPath+"\')\"><img src='/display?fileName="+fileCallPath+"'></a></li>"
   						}
   					});
   				uploadResult.append(str);
   			}
   ```

- CSS와 HTML처리

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
    .
    .
    .
    	<div class="uploadDiv">
    		<input type="file" name="uploadFile" multiple>
    	</div>
    	<div class="uploadResult">
    		<ul>
    		</ul>
    	</div>
    	<div class="bigPictureWrapper">
    		<div class="bigPicture">
    		
    		</div>
    	</div>
    ```

    ```js
    function showImage(fileCallPath) {
    		//alert(fileCallPath);
    		
    		$(".bigPictureWrapper").css("display","flex").show();
    		
    		$(".bigPicture").html("<img src='/display?fileName="+encodeURI(fileCallPath)+"'>").animate({width: "100%", height: "100%"}, 1000);
    		
    		$(".bigPictureWrapper").on("click",function(e){
    			$(".bigPicture").animate({width: "0%", height: "0%"}, 1000);
    			setTimeout(function() {
    				$(".bigPictureWrapper").hide();
    			}, 1000);
    		})
    	}
    ```

### 첨부파일 삭제

- 이미지 파일의 경우에는 섬네일까지 같이 삭제

- 파일을 삭제한 후에는 브라우저에서도 섬내일이나 파일 아이콘이 삭제

- 비정상적으로 브라우저의 종료 시 업로드된 파일의 처리

- 화면에서 삭제 기능

  - uploadAjax.jsp

    ```
    		$(document).ready(function() {
    			
    			var uploadResult = $(".uploadResult ul");
    			
    			function showUploadedFile(uploadResultArr) {
    				var str = "";
    				
    				$(uploadResultArr).each(
    					function(i,obj) {
    						if(!obj.image){
    							var fileCallPath = encodeURIComponent(obj.uploadPath+"/"+obj.uuid+"_"+obj.fileName);
    							
    							var fileLink = fileCallPath.replace(new RegExp(/\\/g)."/");
    							
    							str += "<li><div><a href='/download?fileName="+fileCallPath+"'>"+"<img src='/resources/img/attach.png'>"+obj.fileName+"</a>"
    									+"<span data-file=\'"+fileCallPath+"\' data-type='file'> x </span>"
    									+"</div></li>";
    						}else{
    							//str += "<li>"+obj.fileName+"</li>";
    							var fileCallPath = encodeURIComponent(obj.uploadPath+"/s_"+obj.uuid+"_"+obj.fileName);
    							
    							var originPath = obj.uploadPath+"\\"+obj.uuid+"_"+obj.fileName;
    							
    							originPath = originPath.replace(new RegExp(/\\/g), "/");
    							
    							str += "<li><a href=\"javascript:showImage(\'"+originPath+"\')\"><img src='/display?fileName="+fileCallPath+"'></a>"
    									+"<span data-file=\'"+fileCallPath+"\' data-type='image'> x </span>"
    									+"</li>";
    						}
    					});
    				uploadResult.append(str);
    			}
    
    ```

  - x표시에 대한 이벤트

    ```js
    $(".uploadResult").on("click","span",function(e){
    				var targetFile = $(this).data("file"); //data-file속성
    				var type = $(this).data("type"); //data-type속성
    				var targetLi = $(this).closest("li");
    				console.log(targetFile);
    				
    				$.ajax({
    					url:'/deleteFile',
    					data: {
    							fileName:targetFile,
    							type:type
    						  },
    					dataType: 'text',
    					type : 'POST',
    					success: function(result) {
    						alert(result);
    					}
    				});
    			})
    		});
    ```

  - 서버에서 첨부파일의 삭제

    ```java
    	@PostMapping("/deleteFile")
    	@ResponseBody
    	public ResponseEntity<String> deleteFile(String fileName,String type){
    		log.info("deleteFile:"+fileName);
    		
    		File file;
    		
    		try {
    			file = new File("c:\\upload\\"+URLDecoder.decode(fileName,"UTF-8"));
                
                //일반첨부파일삭제 , 섬네익삭제
    			file.delete();
    			
    			if(type.equals("image")) { //이미지이면
    				String largeFileName = file.getAbsolutePath().replace("s_", "");
    				log.info("largeFileName : "+largeFileName);
    				
    				file = new File(largeFileName);
    				
    				file.delete(); //원본파일삭제
    			}
    		} catch (Exception e) {
    			e.printStackTrace();
    			return new ResponseEntity<>(HttpStatus.NOT_FOUND);
    		}
    		return new ResponseEntity<String>("deleted",HttpStatus.OK);
    	}
    ```

    

  