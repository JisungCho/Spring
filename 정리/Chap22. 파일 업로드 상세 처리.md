# Chap22. 파일 업로드 상세 처리

### 파일의 확장자나 크기의 사전 처리

- 특정 크기 이상의 파일은 업로드할 수 없도록 제한하는 처리를 JS로 처리

- 파일 확장자의 경우 정규 표현식을 이용해서 검사 

- uploadAjax.jsp

  ```jsp
  <%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
  <script src="http://code.jquery.com/jquery-latest.min.js"></script>
  <!DOCTYPE html>
  <html>
  <head>
  <meta charset="UTF-8">
  <title>Insert title here</title>
  </head>
  <body>
  	<h1>Upload with Ajax</h1>
  
  	<div class="uploadDiv">
  		<input type="file" name="uploadFile" multiple>
  	</div>
  
  	<button id="uploadBtn">Upload</button>
  
  	<script>
  		$(document).ready(function() {
  
  			var regex = new RegExp("(.*?)\.(exe|sh|zip|alz)$"); //파일확장자 검사
  			var maxSize = 5242880; // 5MB
  
  			function checkExtension(fileName, fileSize) {
  					if (fileSize >= maxSize) {
  						alert("파일 사이즈 초과");
  						return false;
  					}
  
  					if (regex.test(fileName)) {
  						alert("해당 종류의 파일은 업로드할 수 없습니다.");
  						return false;
  					}
  					return true;				
              }			
  			$('#uploadBtn').on("click", function(e) { //upload버튼 클릭시
  				
  				var formData = new FormData();//첨부파일 처리를 위한 FormData객체 만듬 , <form>태그와 같음
  
  				var inputFile = $("input[name='uploadFile']"); //<input>정보 가져옴
  
  				var files = inputFile[0].files; //첨부한파일정보
  
  				console.log(files);
                  
                  
  				//add filedate to formdate
  				for (var i = 0; i < files.length; i++) {
         				
                      if(!checkExtension(files[i].name, files[i].size)){
  						return false;
  					}
                      
  					formData.append("uploadFile", files[i]); //formData에 파일추가
  				}
  
  				$.ajax({
  					url : '/uploadAjaxAction',
  					processData : false, //무조건 false로설정
  					contentType : false,//무조건 false로 설정
  					data : formData, // 파일 데이터
  					type : 'POST',
  					success : function(result) {
  						alert("Uploaded")
  					}
  				});
  			});
  		});
          
  	</script>
  </body>
  </html>
  ```

1. 중복된 이름의 첨부파일 처리

   - 중복된 이름의 파일 처리

     => UUID이용

   - 한 폴더 내에 너무 많은 파일의 생성

     => 년/월/일 단위의 폴더생성

2. 년/월/일 폴더의 생성

   - mkdirs() 를 이용하면 필요한 상위 폴더까지 한 번에 생성

   - UploadController

     ```java
     	private String getFolder() {
     		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
     		
     		Date date = new Date();
     		
     		String str = sdf.format(date);
     		
     		return str.replace("-", File.separator); // \표시
     		
     		// 2020\\11\\11 이런식의 문자열 생성
     	}
     	
     	@PostMapping(value = "/uploadAjaxAction")
     	public void uploadAjaxPost(MultipartFile[] uploadFile) {
     		log.info("update ajax post.............");
     		
     		String uploadFolder = "C:\\upload";
     		
     		
     		//make folder
     		File uploadPath = new File(uploadFolder, getFolder());
             log.info("upload path:"+uploadPath);
     		
     		if(uploadPath.exists() == false) { //중복된 폴더가 없으면 폴더 생성
     			uploadPath.mkdirs();
     		}
     		//make yyyy/MM/dd folder
     		
     		for(MultipartFile multipartFile : uploadFile) {
     			
     			log.info("------------------------------------------");
     			log.info("Upload File Name : " + multipartFile.getOriginalFilename());
     			log.info("Upload File Size : "+multipartFile.getSize());
     			
     			String uploadFileName = multipartFile.getOriginalFilename();
     			
     			//IE has file path
     			uploadFileName = uploadFileName.substring(uploadFileName.lastIndexOf("\\")+1);
     			log.info("only file name : "+uploadFileName);
     			
                 
     			
     			//File saveFile = new File(uploadFolder, uploadFileName);
     			File saveFile = new File(uploadPath, uploadFileName); //날짜폴더에 파일 업로드
     			
     			try {
     				multipartFile.transferTo(saveFile);
     				
     			} catch (Exception e) {
     				log.error(e.getMessage());
     			}
     		}
     	}
     ```

3. 중복 방지를 위한 UUID 적용

   - UploadController

     ```java
     	private String getFolder() {
     		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
     		
     		Date date = new Date();
     		
     		String str = sdf.format(date);
     		
     		return str.replace("-", File.separator); // \표시
     		
     		// 2020\\11\\11 이런식의 문자열 생성
     	}
     	
     	@PostMapping(value = "/uploadAjaxAction")
     	public void uploadAjaxPost(MultipartFile[] uploadFile) {
     		log.info("update ajax post.............");
     		
     		String uploadFolder = "C:\\upload";
     		
     		
     		//make folder
     		File uploadPath = new File(uploadFolder, getFolder());
             log.info("upload path:"+uploadPath);
     		
     		if(uploadPath.exists() == false) { //중복된 폴더가 없으면 폴더 생성
     			uploadPath.mkdirs();
     		}
     		//make yyyy/MM/dd folder
     		
     		for(MultipartFile multipartFile : uploadFile) {
     			
     			log.info("------------------------------------------");
     			log.info("Upload File Name : " + multipartFile.getOriginalFilename());
     			log.info("Upload File Size : "+multipartFile.getSize());
     			
     			String uploadFileName = multipartFile.getOriginalFilename();
     			
     			//IE has file path
     			uploadFileName = uploadFileName.substring(uploadFileName.lastIndexOf("\\")+1);
     			log.info("only file name : "+uploadFileName);
     			
                 UUID uuid = UUID.randomUUID(); //랜덤값
     			uploadFileName = uuid.toString()+"_"+uploadFileName; //랜덤값_파일이름
     			
     			//File saveFile = new File(uploadFolder, uploadFileName);
     			File saveFile = new File(uploadPath, uploadFileName); //날짜폴더에 파일 업로드
     			
     			try {
     				multipartFile.transferTo(saveFile);
     				
     			} catch (Exception e) {
     				log.error(e.getMessage());
     			}
     		}
     	}
     ```

### 섬네일 이미지 생성

- 일반 파일과 이미지 파일을 구분

  - 일반 파일은 원래대로

  - 이미지 파일의 경우에는섬네일을 생성하는 추가작업 필요

  - Thumbnailator 라이브러리를 이용해서 섬네일 이미지를 생성

    - pom.xml

      ```xml
      		<!-- https://mvnrepository.com/artifact/net.coobird/thumbnailator -->
      		<dependency>
      			<groupId>net.coobird</groupId>
      			<artifactId>thumbnailator</artifactId>
      			<version>0.4.8</version>
      		</dependency>
      ```

  - UploadController에서는 다음과 같은 단계를 이용해서 섬네일 생성

    - 업로드된 파일이 이미지 종류의 파일인지
    - 이미지 파일의 경우에는 섬네일 이미지 생성 및 저장

1. 이미지 파일의 판단

   - 특정한 파일이 이미지 타입인지를 검사하는 별도의 메서드를 추가

     - UploadController

       ```java
       private boolean checkImageType(File file) {
       		try {
       			String contentType = Files.probeContentType(file.toPath());
                   //파일의 확장자를 통해서 MIME타입을 판단
       			
       			return contentType.startsWith("image"); //타입이 이미지이면 true
       		} catch (IOException e) {
       			e.printStackTrace();
       		}
       		return false;
       	}
       ```

       ```JAVA
       	private String getFolder() {
       		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
       		
       		Date date = new Date();
       		
       		String str = sdf.format(date);
       		
       		return str.replace("-", File.separator); // \표시
       		
       		// 2020\\11\\11 이런식의 문자열 생성
       	}
       	
       	@PostMapping(value = "/uploadAjaxAction")
       	public void uploadAjaxPost(MultipartFile[] uploadFile) {
       		log.info("update ajax post.............");
       		
       		String uploadFolder = "C:\\upload";
       		
       		
       		//make folder
       		File uploadPath = new File(uploadFolder, getFolder());
               log.info("upload path:"+uploadPath);
       		
       		if(uploadPath.exists() == false) { //중복된 폴더가 없으면 폴더 생성
       			uploadPath.mkdirs();
       		}
       		//make yyyy/MM/dd folder
       		
       		for(MultipartFile multipartFile : uploadFile) {
       			
       			log.info("------------------------------------------");
       			log.info("Upload File Name : " + multipartFile.getOriginalFilename());
       			log.info("Upload File Size : "+multipartFile.getSize());
       			
       			String uploadFileName = multipartFile.getOriginalFilename();
       			
       			//IE has file path
       			uploadFileName = uploadFileName.substring(uploadFileName.lastIndexOf("\\")+1);
       			log.info("only file name : "+uploadFileName);
       			
                   UUID uuid = UUID.randomUUID(); //랜덤값
       			uploadFileName = uuid.toString()+"_"+uploadFileName; //랜덤값_파일이름
       			
       			//File saveFile = new File(uploadFolder, uploadFileName);
       			File saveFile = new File(uploadPath, uploadFileName); //날짜폴더에 파일 업로드
       			
       			try {
       				multipartFile.transferTo(saveFile);
       				
                       if(checkImageType(saveFile)) { //이미지 파일인지 확인
       					
       					FileOutputStream thumbnail = new FileOutputStream(new File(uploadPath,"s_"+uploadFileName));
       					Thumbnailator.createThumbnail(multipartFile.getInputStream(),thumbnail,100,100);
                           //섬네일 이미지 생성
       					thumbnail.close();
       				}
       			} catch (Exception e) {
       				log.error(e.getMessage());
       			}
       		}
       	}
       ```

   ### 업로드된 파일의 데이터 변환

   - 브라우저에 업로드된 파일에 대한 피드백 보내기
   - 서버에서 Ajax의 결과로 전달해야 하는 데이터
     1. 원본 파일의 일름
     2. 파일이 저장된 경로
     3. UUID
     4. 파일이 이미지인지 아닌지에 대한 정보
   - Ajax의 결과로 보낼 데이터를 별도의 객체를 생성해서 전달

   1. AttachFileDTO

      ```JAVA
      package org.zerock.domain;
      
      import lombok.Data;
      
      @Data
      public class AttachFileDTO {
      	private String fileName; //원본파일이름
      	private String uploadPath; //업로드경로
      	private String uuid; //UUID
      	private boolean image; //이미지인지 아닌지
      }
      
      ```

      - UploadController수정

        ```java
        	@PostMapping(value = "/uploadAjaxAction" , produces = MediaType.APPLICATION_JSON_UTF8_VALUE)
        	@ResponseBody //JSON데이터로 응답
        	public ResponseEntity<List<AttachFileDTO>> uploadAjaxPost(MultipartFile[] uploadFile) {
        		log.info("update ajax post.............");
        		
        		List<AttachFileDTO> list = new ArrayList<>(); //AttachFileDTO를 담을 리스트생성
        		
        		String uploadFolder = "C:\\upload";
        		
                String uploadFolderPath = getFolder();
        		
        		//make folder
        		File uploadPath = new File(uploadFolder, getFolder());
                log.info("upload path:"+uploadPath);
        		
        		if(uploadPath.exists() == false) { //중복된 폴더가 없으면 폴더 생성
        			uploadPath.mkdirs();
        		}
        		//make yyyy/MM/dd folder
        		
        		for(MultipartFile multipartFile : uploadFile) {
        			
        			log.info("------------------------------------------");
        			log.info("Upload File Name : " + multipartFile.getOriginalFilename());
        			log.info("Upload File Size : "+multipartFile.getSize());
        			
        			AttachFileDTO attachFileDTO = new AttachFileDTO(); //AttachFileDTO 생성
        			
        			String uploadFileName = multipartFile.getOriginalFilename();
        			
        			//IE has file path
        			uploadFileName = uploadFileName.substring(uploadFileName.lastIndexOf("\\")+1);
        			log.info("only file name : "+uploadFileName);
        			
        			attachFileDTO.setFileName(uploadFileName); //파일이름 저장
        			
                    UUID uuid = UUID.randomUUID(); //랜덤값
        			uploadFileName = uuid.toString()+"_"+uploadFileName; //랜덤값_파일이름
        			
        			//File saveFile = new File(uploadFolder, uploadFileName);
        			File saveFile = new File(uploadPath, uploadFileName); //날짜폴더에 파일 업로드
        			
        			try {
        				multipartFile.transferTo(saveFile);
        				
        				
        				attachFileDTO.setUuid(uuid.toString());//UUID
        				attachFileDTO.setUploadPath(uploadFolderPath);//업로드경로			
        				
                        if(checkImageType(saveFile)) { //이미지 파일인지 확인
                        	attachFileDTO.setImage(true); //이미지 true
        					
        					FileOutputStream thumbnail = new FileOutputStream(new File(uploadPath,"s_"+uploadFileName));
        					Thumbnailator.createThumbnail(multipartFile.getInputStream(),thumbnail,100,100);
                            //섬네일 이미지 생성
        					thumbnail.close();
        				}
        				list.add(attachFileDTO); // 리스트에 추가
        			} catch (Exception e) {
        				log.error(e.getMessage());
        			}
        		}
                return new ResponseEntity<>(list, HttpStatus.OK);
        	}
     ```
   
2. 브라우저에서 Ajax처리
   
   - uploadAjax.jsp
   
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
        						showUploadedFile(result);
        						$(".uploadDiv").html(cloneObj.html());
        					}
        				});
     ```
   
     
   
   