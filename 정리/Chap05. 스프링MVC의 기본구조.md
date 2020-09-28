# 스프링 MVC의 기본 구조

### 스프링의 의미

- '코어'라고 할 수 있는 프레임워크에 여러개의 별도의 설정(서브 프로젝트)을 결합해서 다양한 상황에 대처할 수 있도록 개발

### 스프링 MVC 프로젝트의 내부 구조

- 내부적 
  : root-context.xml(순수한 자바 관련 설정) + servlet-context.xml(웹관련 설정,MVC관련 설정) 

- 바깥쪽에 WebApplicationContext라는 존재는 기존의 구조에 MVC설정을 포함하는 구조

  ![5. 스프링 MVC의 기본 구조](https://blog.kakaocdn.net/dn/nRU8k/btqzBsbHwOS/RQ5kZRywRcUcmkAvJwcsRk/img.png)

### 프로젝트의 로딩 구조

- 프로젝트 구동 시 관여하는 xml은 web.xml(톰캣관련) , root-context.xml(스프링관련) , servlet-context.xml(스프링관련)

- web.xml 

  - 톰캣 구동과 관련된 설정
  - 프로젝트의 구동은 web.xml에서 시작
  - web.xml에는 가장 먼저 구동된는 Context Listener가 등록되어 있다.

  - ContextLoaderListener는 해당 웹 애플리케이션 구동 시 같이 동작

  - ```xml
    	<context-param>
            <!--root-context.xml의 경로-->
      		<param-name>contextConfigLocation</param-name>
      		<param-value>/WEB-INF/spring/root-context.xml</param-value>
      	</context-param>
      	
      	<!-- Creates the Spring Container shared by all Servlets and Filters -->
      	<listener>
      		<listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
      	</listener>
    ```

- root-context.xml과 servlet-context.xml의 차이점

  - servlet-contex.xml
  servlet에서 보듯이 요청과 관련된 객체를 정의합니다.
    url과 관련된 controller나, @(어노테이션), ViewResolver, Interceptor, MultipartResolver 등의 설정을 해줍니다.
- root-contex.xml
    servlet-context.xml 과는 반대로 view와 관련되지 않은 객체를 정의합니다.
    따라서 Service, Repository(DAO), DB등 비즈니스 로직과 관련된 설정을 해줍니다.
  아래 사진을 참고하시면 좋을 것 같습니다.
  
- root-context.xml , servlet-context.xml

  - 파일에 정의된 객체(빈)들은 스프링 영역(context)안에 생성되고 객체들 간의 의존성 처리

  - 실행 후 DispatcherServlet이라는 서블릿과 관련된 설정이 동작

  - DispatcherServlet클래스는 내부적으로 웹 관련 처리의 준비작업을 진행 이때 사용하는 파일이 
    servlet-context.xml이다.

  - DispatcherServlet에서 XmlWebApplicationContext를 이용해서 servlet-context.xml을 로딩하고 해석하면서 등록된 객체들은 기존의 객체(빈)들과 같이 연동

  - ```xml
    	<servlet>
      		<servlet-name>appServlet</servlet-name>
      		<servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
      		<init-param>
      			<param-name>contextConfigLocation</param-name>
      			<param-value>/WEB-INF/spring/appServlet/servlet-context.xml</param-value>
      		</init-param>
      		<load-on-startup>1</load-on-startup>
      	</servlet>
      		
      	<servlet-mapping>
      		<servlet-name>appServlet</servlet-name>
      		<url-pattern>/</url-pattern>
      	</servlet-mapping>
    ```

    ![img](https://blog.kakaocdn.net/dn/blvc3H/btqzC3Iw47n/bKHSJ9EztDexezViSq1zrK/img.png)

### 스프링 MVC의 기본 사상

- 스프링 MVC의 경우 개발자들은 자신이 필요한 부분만 집중해서 개발할 수 있는 구조로 만들어져있음
- Servlet/JSP에서는 httpservletrequest/httpservletresponse 객체를 이용해 브라우저에서 전송한 정보를 처리하지만 스프링MVC에서는 이위에 하나의 계층을 더 해서 만든다. 스프링 MVC를 이용하게 되면 개발자들은 Servlet/JSP의 API를 사용할 필요성이 현저하게 줄어듬
- ![img](https://blog.kakaocdn.net/dn/b6XgtQ/btqzBsbH7fA/VsRCo2FI5jUR1VNtnnMH20/img.png)

### 모델2와 스프링mvc

- 스프링 MVC는 모델2 방식으로 처리되는 구조
- '모델2'방식 : 로직과 화면을 분리
  
- ![img](https://t1.daumcdn.net/cfile/tistory/9949DA4E5CB69B822B)
  
- 스프링 MVC 구조

  - Front-Controller패턴 :모든 request는 DispatcherServlet을 통하도록 설계하하는 것
  - ![img](https://blog.kakaocdn.net/dn/tQLB6/btqyh1LYfUC/Py4YgV4idObQn5IzC92HX1/img.png)

  1. 모든 사용자의 request를 Front-controller인 DispatcherServlet받도록 처리
  2. HandlerMapping은 Request의 처리를 담당하는 컨트롤러를 찾기 위해서 존재
  3. @RequestMapping 어노테이션이 적용된 것을 기준으로 판단
  4. HandlerAdapter를 이용해서 해당 컨트롤러를 동작
  5. Controller는 개발자가 작성하는 클래스로 실제 request를 처리하는 로직을 작성
  6. view에 전달해야하는 데이터는 주로 Model이라는 객체에 담아서 전달
  7. Controller는 다양한 타입의 결과를 반환하는데 이에대한 처리는 ViewResolver를 이용
  8. view는 실제로 응답 보내야하는 데이터를 Jsp등을 이용해서 생성하는 역활