# Chap21 .파일 업로드 방식

- 첨부파일을 서버에 전송하는 방식
  1. < form > 태그
  2. Ajax => 예제에서는 Ajax를 이용해서 구현

1. 스프링의 첨부파일을 위한 설정(p489)

   - 스프링 버전 수정
   - 서블릿 버전수정
   - Lombok추가

   1. web.xml을 이용하는 경우의 첨부파일 설정

      - web.xml 상단에 XML 네임스페이스가 2.5버전으로 된 설정을 찾아서 수정 3.1버전으로

      - web.xml < servlet > 태그 내에 < multipart-config > 태그를 추가

        ```xml
        		<multipart-config>
        			<location>C:\\upload\\temp</location> <!--업로드되는 파일을 저장할 공간-->
        			<max-file-size>20971520</max-file-size> <!--업로드되는 파일의 최대 크기-->
        			<max-request-size>41943040</max-request-size> <!--한번에 올릴 수 있는 최대크기-->
        			<file-size-threshold>20971520</file-size-threshold> <!--특정 사이즈의 메모리 사용-->
        		</multipart-config>
        ```

      - 웹에 관련된 설정이므로 servlet-context.xml에 MultipartResolver라는 타입의 객체를 빈으로 등록

        ```xml
        <!--빈을 설정할 떄 id는 multipartResolver라는 지정된 이름을 사용-->	
        	<beans:bean id="multipartResolver" class="org.springframework.web.multipart.support.StandardServletMultipartResolver">
        	</beans:bean>
        
        ```

### < form > 방식의 파일 업로드

- 첨부파일의 처리는 컨트롤러에서 이루어짐

- UploadController

  ```java
  package org.zerock.controller;
  
  import java.io.File;
  import java.io.FileOutputStream;
  import java.io.IOException;
  import java.io.UnsupportedEncodingException;
  import java.net.URLDecoder;
  import java.net.URLEncoder;
  import java.nio.file.Files;
  import java.text.SimpleDateFormat;
  import java.util.ArrayList;
  import java.util.Date;
  import java.util.List;
  import java.util.UUID;
  
  import org.springframework.core.io.FileSystemResource;
  import org.springframework.core.io.Resource;
  import org.springframework.http.HttpHeaders;
  import org.springframework.http.HttpStatus;
  import org.springframework.http.MediaType;
  import org.springframework.http.ResponseEntity;
  import org.springframework.stereotype.Controller;
  import org.springframework.ui.Model;
  import org.springframework.util.FileCopyUtils;
  import org.springframework.web.bind.annotation.GetMapping;
  import org.springframework.web.bind.annotation.PostMapping;
  import org.springframework.web.bind.annotation.RequestHeader;
  import org.springframework.web.bind.annotation.ResponseBody;
  import org.springframework.web.multipart.MultipartFile;
  import org.zerock.domain.AttachFileDTO;
  
  import lombok.extern.log4j.Log4j;
  import net.coobird.thumbnailator.Thumbnailator;
  
  @Controller
  @Log4j
  public class UploadController {
      
  	@GetMapping("/uploadForm")
  	public void uploadForm() {
  		log.info("upload form");
  	}//uploadForm.jsp로 이동
  	
  }
  
  ```

- uploadForm.jsp

  ```jsp
  <%@ page language="java" contentType="text/html; charset=UTF-8"
      pageEncoding="UTF-8"%>
  <!DOCTYPE html>
  <html>
  <head>
  <meta charset="UTF-8">
  <title>Insert title here</title>
  </head>
  <body>
  
  <!--enctype="multipart/form-data" : file을 보낼것이라는것을 명시-->    
  <form action="uploadFormAction" method="post" enctype="multipart/form-data">
  	<input type="file" name="uploadFile" multiple="multiple"> <!--여러개의 file을 보낼것-->
  	<button>submit</button>
  </form>
  
  </body>
  </html>
  ```

1. MultipartFile 타입

   - 업로드되는 파일 데이터로 MultipartFile 타입을 통해 쉽게 처리

     - uploadController

       ```java
       	@PostMapping("/uploadFormAction") //파일업로드 처리
       	public void uploadFormPost(MultipartFile[] uploadFile,Model model) {
       		
       		String uploadFolder = "C:\\upload"; //저장할 주소
       		
       		for(MultipartFile multipartFile : uploadFile) {
       			log.info("------------------------------------------");
       			log.info("Upload File Name : " + multipartFile.getOriginalFilename()); //파일이름
       			log.info("Upload File Size : "+multipartFile.getSize()); //파일크기
       		}
       	}
       ```

   - MultipartFile 메서드

     | String getName()             | 파라미터의 이름 < input >태그의 이름   |
     | ---------------------------- | -------------------------------------- |
     | String getOriginalFileName() | 업로드되는 파일의 이름                 |
     | boolean isEmpty()            | 파일이 존재하지 않는 경우 true         |
     | long getSize()               | 업로드되는 파일의 크기                 |
     | byte[ ] getBytes()           | byte[ ] 로 파일 데이터 변환            |
     | InputStream getInputStream() | 파일데이터와 연결된 inputStream을 반환 |
     | transferTo(File file)        | 파일의 저장                            |

   - 파일 저장

     - transferTo() 를 이용해서 파일 저장

     ```java
     	@PostMapping("/uploadFormAction") //파일업로드 처리
     	public void uploadFormPost(MultipartFile[] uploadFile,Model model) {
     		
     		String uploadFolder = "C:\\upload"; //저장할 주소
     		
     		for(MultipartFile multipartFile : uploadFile) {
     			log.info("------------------------------------------");
     			log.info("Upload File Name : " + multipartFile.getOriginalFilename()); //파일이름
     			log.info("Upload File Size : "+multipartFile.getSize()); //파일크기
     			
     			File saveFile = new File(uploadFolder, multipartFile.getOriginalFilename());
     			
     			try {
     				multipartFile.transferTo(saveFile); //파일 저장
     			} catch (Exception e) {
     				log.error(e.getMessage());
     			}
     		}
     	}
     ```

   ### Ajax를 이용하는 파일 업로드

   - Ajax를 이용해서 파일 데이터만을 전송하는 방식

   - Ajax를 이용하는 첨부파일 처리는 FormData라는 객체를 이용

   - UploadController

     ```java
     
     	@GetMapping("/uploadAjax")
     	public void uploadAjax() {
     		log.info("upload ajax...");
     	} //uploadAjax.jsp이동
     ```

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
     
     			$('#uploadBtn').on("click", function(e) { //upload버튼 클릭시
     				
     				var formData = new FormData();//첨부파일 처리를 위한 FormData객체 만듬 , <form>태그와 같음
     
     				var inputFile = $("input[name='uploadFile']"); //<input>정보 가져옴
     
     				var files = inputFile[0].files; //첨부한파일정보
     
     				console.log(files);
                     
     			});
     		});
             
     	</script>
     </body>
     </html>
     ```

2. jQuery를 이용한 첨부파일 전송

   - 첨부파일을 전송하기 위해 FormData타입이 객체에 파일 데이터 추가

   - Ajax에 옵션 추가

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
     
     			$('#uploadBtn').on("click", function(e) { //upload버튼 클릭시
     				
     				var formData = new FormData();//첨부파일 처리를 위한 FormData객체 만듬 , <form>태그와 같음
     
     				var inputFile = $("input[name='uploadFile']"); //<input>정보 가져옴
     
     				var files = inputFile[0].files; //첨부한파일정보
     
     				console.log(files);
                     
                     
     				//add filedate to formdate
     				for (var i = 0; i < files.length; i++) {
                         
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

   - UploadController의일부

     ```java
     @PostMapping(value = "/uploadAjaxAction")
     	public void uploadAjaxPost(MultipartFile[] uploadFile) {
     		log.info("update ajax post.............");
     		
     		String uploadFolder = "C:\\upload";
     		
     		for(MultipartFile multipartFile : uploadFile) {
     			
     			log.info("------------------------------------------");
     			log.info("Upload File Name : " + multipartFile.getOriginalFilename());
     			log.info("Upload File Size : "+multipartFile.getSize());
     			
     			String uploadFileName = multipartFile.getOriginalFilename();
                 //IE인경우 파일경로가 들어감, 크롬은 파일이름이 그대로 들어감
     			
     			//IE has file path
     			uploadFileName = uploadFileName.substring(uploadFileName.lastIndexOf("\\")+1); //순수한 파일이름
     			log.info("only file name : "+uploadFileName);
     			
     			File saveFile = new File(uploadFolder, uploadFileName);
     			
     			try {
     				multipartFile.transferTo(saveFile);// 해당경로에 해당파일이름으로 파일을 업로드
     			} catch (Exception e) {
     				log.error(e.getMessage());
     			}
     		}
     		
     	}
     ```

2. 파일 업로드에서 고려해야 하는 점들

   1. 동일한 이름으로 파일이 업로드 되었을 때 기존 파일이 사라지는 문제
   2. 이미지 파일의 경우에는 원본 파일의 용량이 큰 경우 섬네일 이미지를 생성해야 하는 문제
   3. 이미지 파일과 일반 파일을 구분해서 다운로드 혹은 페이지에서 조회하도록 처리하는 문제
   4. 첨부파일 공격에 대비하기 위한 업로드 파일의 확장자 제한

