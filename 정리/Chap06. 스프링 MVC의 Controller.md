# 스프링 MVC의 Controller

### 스프링 mvc Controller의 특징

- **HttpServletRequest , HttpServletResponse를 거의 사용할 필요없이 필요한 기능 구현**
- **다양한 타입의 파라미터 처리, 다양한 타입의 리턴타입 사용 가능**
- **GET/POST 방식 등 전속 방식에 대한 처리를 어노테이션으로 처리가능**
- **상속/인터페이스 방식 대신에 어노테이션만으로도 필요한 설정 가능**

### @Controller , @RequestMapping

- ```java
  package org.zerock.controller;
  
  import org.springframework.stereotype.Controller;
  import org.springframework.web.bind.annotation.RequestMapping;
  
  import lombok.extern.log4j.Log4j;
  
  @Controller
  
  @RequestMapping("/sample/*")
  
  @Log4j
  
  public class SampleController {
      @RequestMapping("")
  
      public void basic() {
  
          log.info("basic.............");
  
      }
  
  }
  ```

  -  @Controller라는 어노테이션을 적용하면 자동으로 스프링의 객체로 등록한다.
    그 이유는 servlet-context.xml에 지정된 패키지를 조사해서 그 안에 객체 설정에 사용되는 어노테이션이 있으면 자동으로 스프링 객체로 등록하라는 설정이 있기 때문에

    ```xml
    <context:component-scan base-package="org.zerock.controller" />
    
    </beans:beans>
    ```

  - @RequestMapping은 현재 클래스의 모든 메서드들의 기본적인 URL경로

  - @RequestMapping은 클래스의 선언과 메서드 선언에 사용할 수 있다

  - @log4j를 이용하면 스프링이 인식할 수 있는 정보가 출력됨

### @RequestMapping의 변화

- 몇 가지 속성을 추가할 수 있다.

- method속성 : GET방식 / Post방식 

  ```java
  	@RequestMapping(value = "/basic" , method = {RequestMethod.GET , RequestMethod.POST})
  	public void basic() {
  		log.info("basic...........");
  	}
  	
  	@GetMapping("/basicOnlyGet")
  	public void basicGet2() {
  		log.info("basic get only get...........");
  	}
  ```

### Controller의 파라미터 수집

- Controller를 작성할 때 가장 편리한 기능은 파라미터가 자동으로 수집되는 기능 , 따라서 request.getparameter()를 이용하는 불편함을 없앨 수 있다.

  - ```java
    package org.zerock.domain;
    
    import lombok.Data;
    
    @Data
    public class SampleDTO {
    	private String name;
    	private int age;
    }
    
    ```

  - @Data를 이용하면 getter/setter.equals.toString 등의 메서드 자동생성

  - SampleDTO를 Controller의 파라미터로 사용하게 되면 자동으로 setter메서드가 동작하면서 파라미터를 수집

  - ```java
    package org.zerock.controller;
    
    import org.springframework.stereotype.Controller;
    import org.springframework.web.bind.annotation.GetMapping;
    import org.springframework.web.bind.annotation.RequestMapping;
    import org.springframework.web.bind.annotation.RequestMethod;
    import org.zerock.domain.SampleDTO;
    
    import lombok.extern.log4j.Log4j;
    
    @Controller
    
    @RequestMapping("/sample/*")
    
    @Log4j
    
    public class SampleController {
    
    --생략--
    
        @GetMapping("/ex01")
    
        public String ex01(SampleDTO dto) {
    
            log.info(" "+dto);
    
            return "ex01";
    
        }
    
    }
    ```

1. 파라미터의 수집과 변환

   - Controller가 파라미터를 수집하는 방식은 파라미터 타입에 따라 자동으로 변환하는 방식

   - @RequestParam은 파라미터로 사용된 변수의 이름과 전달되는 파라미터의 이름이 다른 경우사용

   - ```java
     	@GetMapping("/ex02")
     	public String ex02(@RequestParam("name") String name, @RequestParam("age") int age) {
     		
     		log.info("name : "+name);
     		log.info("age : "+age);
     		return "ex02";
     	}
     ```

2. 리스트, 배열 처리

   - 리스트나 배열을 처리할때 파라미터 타입은 실제적인 클래스 타입으로 지정

   - ```java
     	@GetMapping("/ex02List")
     	public String ex02List(@RequestParam("ids") ArrayList<String> ids) {
     		log.info("ids : "+ids);
     		return "ex02List";
     	}
     	 
     	@GetMapping("/ex02Array")
     	public String ex02Array(@RequestParam("ids") String[] ids) {
     		log.info("array ids : "+ids);
     		return "ex02Array";
     	}
     ```

3. 객체 리스트

   - ```java
     package org.zerock.domain;
     
     import java.util.ArrayList;
     import java.util.List;
     
     import jdk.internal.org.jline.utils.Log;
     import lombok.Data;
     
     @Data
     public class SampleDTOList {
     	private List<SampleDTO> list;
     	
     	public SampleDTOList() {
     		System.out.println("객체 생성");
     		list = new ArrayList<SampleDTO>();
     	}
     }
     
     ```

     ```java
     	@GetMapping("/ex02Bean")
     	public String ex02Bean(SampleDTOList list) {
     		log.info("list dtos : "+list);
     		return "ex02Bean";
     	}
     ```

4. @initBinder

   - 스프링 Controller에서는 파라미터를 바인딩할 때 자동으로 호출되는 @initBinder를 이용해서 문자열을 Date타입으로 바꾸는 등의 변화를 줄수있음

   - ```java
     package org.zerock.domain;
     
     import java.util.Date;
     
     import org.springframework.format.annotation.DateTimeFormat;
     
     import lombok.Data;
     
     @Data
     public class TodoDTO {
     	private String title;
     	private Date dueDate;
     }
     
     ```

     ```java
     	@InitBinder 
     	public void initBinder(WebDataBinder binder) { 
     		 SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
     		 binder.registerCustomEditor(java.util.Date.class, new
     		 CustomDateEditor(dateFormat, false)); 
     	}
     
     	@GetMapping("/ex03")
     	public String ex03(TodoDTO todo) {
     		log.info("todo : "+todo);
     		return "ex03";
     	}
     ```

5. @DateTimeFormat

   - 파리미터로 사용되는 인스턴스 변수에 해당 어노테이션을 줘서 간편하게 바꿀 수 있다.

   - ```java
     package org.zerock.domain;
     
     import java.util.Date;
     
     import org.springframework.format.annotation.DateTimeFormat;
     
     import lombok.Data;
     
     @Data
     public class TodoDTO {
     	private String title;
     	
     	@DateTimeFormat(pattern = "yyyy/MM/dd") //해당 형식으로 문자열이 들어오면 변환
     	private Date dueDate;
     }
     
     ```

### Model이라는 데이터 전달자

- Controller의 메서드를 작성할 때는 Model이라는 타입을 파라미터로 지정할 수 있다.
- Model 객체는 JSP에 컨트롤러에서 생성된 데이터를 담아서 전달하는 역활
- 메서드의 파라미터에 Model 타입이 지정된 경우, **스프링은 특별하게 Model 타입의 객체를 만들어서 메서드에 주입**
- **Model은 주로 Controller에 전달된 데이터를 이용해서 추가적인 데이터를 가져와야하는 경우 사용**
  예를들어 페이지 번호를 파라미터로 전달받고, 실제 데이터를 View로 전달해야 하는 경우
- 스프링 MVC의 Controller는 기본적으로 Java Beans 규칙에 맞는 객체는 다시 화면으로 객체를 전달 
  - Java Beans 규칙 : 단순히 생성자가 없거나 빈 생성자를 가져야하고, getter/setter를 가진 클래스의 객체들을 의미
  - 기본 자료형의 경우는 파라미터로 선언하더라도 기본적으로 화면까지 전달되지 않음

1. @ModelAttribute 어노테이션

   - 강제로 전달받은 파라미터를 Model에 담아서 전달하도록 할 떄 필요한 어노테이션이고, 타입에 관계없이 Model에 담겨서 전달

     ```
     	@GetMapping("/ex04")
     	public String ex04(SampleDTO dto , @ModelAttribute("page")int page) {
     		log.info("dto : "+dto);
     		log.info("page : "+page);
     		return "/sample/ex04";
     	}
     ```

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
     
     <h2>SAMPLEDTO ${sampleDTO}</h2>
     <h2>PAGE ${page}</h2>
     
     </body>
     </html>
     ```

2. RedirectAttributes

   - 스프링 MVC가 자동으로 전달해 주는 타입
   - 일회성으로 데이터를 전달하는 용도
   - Model과 같이 파라미터로 선언
   - addFlashAttribute(이름,값) 메서드를 이용해서 화면에 한 번만 사용하고 다음에는 사용되지 않는 데이터를 전달하기 위해서 사용

### Controller의 리턴 타입

- **void : 호출하는 URL과 동일한 이름의 jsp를 의미**
- **String : jsp를 이용하는 경우에는 jsp파일의 경로와 파일이름을 나타내기 위해서 사용**
- **VO , DTO 타입 : 주로 JSON 타입의 데이터를 만들어서 반환하는 용도로 사용**
- **ResponseEntity 타입 : response할 때 Http 헤더 정보와 내용을 가공하는 용도로 사용**
- **Model ,ModelAndView : Model로 데이터를 반환하거나 화면까지 같이 지정하는 경우에 사용**
- **HttpHeaders : 응답에 내용 없이 Http헤더 메세지만 전달하는 용도**

1. void 타입

   - 호출하는 URL과 동일한 이름의 jsp를 호출

   - ```java
     @GetMapping("/ex05")
     
         public void ex05() {
     
             System.out.println("ex05");
     
         }
     ```

2. String 타입

   - 상황에 따라 다른 화면을 보여줄 필요가 있을 경우 사용

   - String 타입에는 다음과 같은 특별한 키워드를 붙여서 사용할 수 있다.

     - redirect 
     - forward

   - ```java
     	@RequestMapping(value = "/", method = RequestMethod.GET)
     	public String home(Locale locale, Model model) {
     		logger.info("Welcome home! The client locale is {}.", locale);
     		
     		Date date = new Date();
     		DateFormat dateFormat = DateFormat.getDateTimeInstance(DateFormat.LONG, DateFormat.LONG, locale);
     		
     		String formattedDate = dateFormat.format(date);
     		
     		model.addAttribute("serverTime", formattedDate );
     		
     		return "home";
     	}
     ```

3. 객체 타입

   - JSON 데이터를 만들어 내는 용도로 사용

   - jaskson-databind 라이브러리를 pom.xml에 추가

   - ```java
     	@GetMapping("/ex06")
     	public @ResponseBody SampleDTO ex06() {
     		log.info("/ex06........");
     		
     		SampleDTO dto = new SampleDTO();
     		dto.setAge(10);
     		dto.setName("홍길동");
     		
     		return dto;
     	}
     ```

4. ResponseEntity 타입

   - 원하는 헤더 정보나 데이터를 전달할 수 있다.

   - ```JAVA
     	@GetMapping("/ex07")
     	public ResponseEntity<String> ex07(){
     		log.info("/ex07...............");
     		
     		String msg = "{\"name\":\"홍길동\"}";
     		
     		HttpHeaders header = new HttpHeaders();
     		header.add("Content-Type", "application/json;charset=UTF-8");
     		
     		return new ResponseEntity<String>(msg, header, HttpStatus.OK);
     	}
     ```

5. 파일업로드

   - commons-fileupload를 pom.xml에 추가해서 사용

   - ```xml
     <!--반드시id속성의 값을 multipartResolver로 지정-->	
     <beans:bean id="multipartResolver" class="org.springframework.web.multipart.commons.CommonsMultipartResolver">
     		<beans:property name="defaultEncoding" value="utf-8"></beans:property>
         <!--한번에 request 할수 있는 최대 크기-->
     		<beans:property name="maxUploadSize" value="104857560"></beans:property>
         <!--파일당 최대 크기-->
     		<beans:property name="maxUploadSizePerFile" value="2097152"></beans:property>
         <!--maxInMemorySize이상의 크기의 데이터를 임시 파일로 보관하는 장소-->
     		<beans:property name="uploadTempDir" value="file:/C:/upload/tmp"></beans:property>
         <!--메모리상에 유지하는 최대의 크기-->
     		<beans:property name="maxInMemorySize" value="10485756"></beans:property>
     	</beans:bean>
     ```

     ```java
     	@GetMapping("/exUpload")
     	public void exUpload() {
     		log.info("/exUpload..........");
     	}
     	
     	@PostMapping("/exUploadPost")
     	public void exUploadPost(ArrayList<MultipartFile> files) {
     		files.forEach(file -> {
     			log.info("--------------------------------");
     			log.info("name:"+file.getOriginalFilename());
     			log.info("size:"+file.getSize());
     		});
     	}
     ```

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
     	<form action="/sample/exUploadPost" method="post"
     		enctype="multipart/form-data">
     		<div>
     			<input type="file" name="files">
     		</div>
     		<div>
     			<input type="file" name="files">
     		</div>
     		<div>
     			<input type="file" name="files">
     		</div>
     		<div>
     			<input type="file" name="files">
     		</div>
     		<div>
     			<input type="file" name="files">
     		</div>
     		<div>
     			<input type="submit">
     		</div>
     	</form>
     </body>
     </html>
     ```

### Controller의 Exception 처리

- @ExceptionHandler와 @ControllerAdvice를 이용한 처리
- @ResponseEntity를 이용하는 예외 메세지 구성

1. @ControllerAdvice

   - AOP를 이용하는 방식
     핵심적인 로직은 아니지만 프로그램에서 필요한 공통적인 관심사는 분리하는 개념

   - < component-scan >을 통해서 해당 패키지의 내용을 조사하도록 해야함

     ```xml
     	<context:component-scan base-package="org.zerock.exception" />
     ```

     

   - @ControllerAdvice : 해당 객체가 스프링의 컨트롤러에서 발생하는 예외를 처리하는 존재

   - @ExceptionHandler : 해당 메서드가 () 에 들어가는 예외 타입을 처리함

   - ```java
     package org.zerock.exception;
     
     import org.springframework.http.HttpStatus;
     import org.springframework.ui.Model;
     import org.springframework.web.bind.annotation.ControllerAdvice;
     import org.springframework.web.bind.annotation.ExceptionHandler;
     import org.springframework.web.bind.annotation.ResponseStatus;
     import org.springframework.web.servlet.NoHandlerFoundException;
     
     import lombok.extern.log4j.Log4j;
     
     @ControllerAdvice
     @Log4j
     public class CommonExceptionAdvice {
     	
     	@ExceptionHandler(Exception.class)
     	public String except(Exception ex,Model model) {
     		log.error("Exception....."+ex.getMessage());
     		model.addAttribute("exception", ex); //model에 저장
     		log.error(model);
     		return "error_page";
     	}
     	
     }
     
     ```

     ```jsp
     <%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>
     <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
     <%@ page session="false" import="java.util.*" %>
     <!DOCTYPE html>
     <html>
     <head>
     <meta charset="UTF-8">
     <title>Insert title here</title>
     </head>
     <body>
     	<h4><c:out value="${exception.getMessage() }"></c:out></h4>
     	
     	<ul>
     		<c:forEach items="${exception.getStackTrace()}" var="stack">
     			<li><c:out value="${stack }"></c:out></li>
     		</c:forEach>
     	</ul>
     </body>
     </html>
     ```

2. 404에러 페이지

   - web.xml을 이용해서 별도의 에러페이지를 지정

     ```xml
     		<init-param>
     			<param-name>throwExceptionIfNoHandlerFound</param-name>
     			<param-value>true</param-value>
     		</init-param>
     ```

     ```java
     package org.zerock.exception;
     
     import org.springframework.http.HttpStatus;
     import org.springframework.ui.Model;
     import org.springframework.web.bind.annotation.ControllerAdvice;
     import org.springframework.web.bind.annotation.ExceptionHandler;
     import org.springframework.web.bind.annotation.ResponseStatus;
     import org.springframework.web.servlet.NoHandlerFoundException;
     
     import lombok.extern.log4j.Log4j;
     
     @ControllerAdvice
     @Log4j
     public class CommonExceptionAdvice {
     	
     	@ExceptionHandler(Exception.class)
     	public String except(Exception ex,Model model) {
     		log.error("Exception....."+ex.getMessage());
     		model.addAttribute("exception", ex);
     		log.error(model);
     		return "error_page";
     	}
     	
     	@ExceptionHandler(NoHandlerFoundException.class)
     	@ResponseStatus(HttpStatus.NOT_FOUND)
     	public String handle404(NoHandlerFoundException ex) {
     		return "custom404";
     	}
     }
     
     ```

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
     	<h1>해당 URL은 존재하지 않습니다.</h1>
     </body>
     </html>
     ```

     

