# Chap30. Spring Web Security 소개

- 스프링 시큐리티의 기본 동작 방식
  - 서블릿의 여러 종류의 필터와 인터셉터를 이용해서 처리
    - 필터 : 단순한 필터
    - 인터셉터 : 스프링에서 필터와 유사한 역활
  - 필터와 인터셉터의 공통점과  차이점
    - 공통점
      - 특정한 서블릿이나 컨트롤러의 접근에 관여
    - 차이점
      - 필터 : 스프링과 무관한 서블릿 자원
      - 인터셉터는 스프링의 빈으로 관리되면서 스프링의 컨텍스트 내에 속한다.
  - 스프링 시큐리티를 이용하게 되면 인터셉터와 필터를 이용하면서 별도의 컨텍스트를 생성해서 처리

### Spring Web Security의 설정

- pom.xml 설정

  ```xml
  <dependency>
      <groupId>org.springframework.security</groupId>
      <artifactId>spring-security-web</artifactId>
      <version>5.0.7.RELEASE</version>
  </dependency>
  
  <dependency>
      <groupId>org.springframework.security</groupId>
      <artifactId>spring-security-config</artifactId>
      <version>5.0.7.RELEASE</version>
  </dependency>
  
  <dependency>
      <groupId>org.springframework.security</groupId>
      <artifactId>spring-security-core</artifactId>
      <version>5.0.7.RELEASE</version>
  </dependency>
  
  <!-- https://mvnrepository.com/artifact/org.springframework.security/spring-security-taglibs -->
  <dependency>
      <groupId>org.springframework.security</groupId>
      <artifactId>spring-security-taglibs</artifactId>
      <version>5.0.7.RELEASE</version>
  </dependency>
  ```

1. security-context.xml생성

   - 스프링 시큐리티는 단독으로 설정할 수 있기 때문에 기존의 root-context.xml이나 servlet-context.xml과 별도로 security-context.xml을 따로 작성

   - security-context.xml은 네임스페이스에서 security항목 체크

   - 네임스페이스 버전 변경

     ```xml
     <?xml version="1.0" encoding="UTF-8"?>
     <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     	xmlns:security="http://www.springframework.org/schema/security"
     	xsi:schemaLocation="http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security.xsd
     		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
     
     ```

2. web.xml설정

   - 스프링 시큐리티가 스프링 MVC에서 사용되기 위해서는 필터를 이용해서 스프링 동작에 관려

   - web.xml

     ```xml
     	<filter>
     		<filter-name>springSecurityFilterChain</filter-name>
     		<filter-class>org.springframework.web.filter.DelegatingFilterProxy</filter-class>
     	</filter>
     	<filter-mapping>
     		<filter-name>springSecurityFilterChain</filter-name>
     		<url-pattern>/*</url-pattern>
     	</filter-mapping>
     ```

     - 실행하면 springSecurityFilterChain이라는 빈이 제대로 설정되지 않아서 에러가 발생 

   - web.xml

     ```xml
     	<!-- The definition of the Root Spring Container shared by all Servlets and Filters -->
     	<context-param>
     		<param-name>contextConfigLocation</param-name>
     		<param-value>/WEB-INF/spring/root-context.xml /WEB-INF/spring/security-context.xml</param-value>
     	</context-param>
     ```

   - security-context.xml

     ```xml
     <?xml version="1.0" encoding="UTF-8"?>
     <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     	xmlns:security="http://www.springframework.org/schema/security"
     	xsi:schemaLocation="http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security.xsd
     		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
     
     	<security:http> <!--스프링 시큐리티의 시작 지점이 필요-->
     
     		<security:form-login />
     
     	</security:http>
     
     	<security:authentication-manager> <!--스프링 시큐리티가 동작하기 위해서는 Authentication Manager라는 존재 필요-->
     
     	</security:authentication-manager>
     </beans>
     
     ```

### 시큐리티가 필요한 URI 설계

- /sample/all  => 로그인을 하지 않은 사용자도 접근 가능한  uri

- /sample/member => 로그인 한 사용자들만이 접근할 수 있는 uri

- /sample/admin => 로그인 한 사용자들 중에서 관리자 권한을 가진 사용자만이 접근할 수 있는 uri

- SampleController클래스 작성

  ```java
  package org.zerock.controller;
  
  import org.springframework.security.access.annotation.Secured;
  import org.springframework.security.access.prepost.PreAuthorize;
  import org.springframework.stereotype.Controller;
  import org.springframework.web.bind.annotation.GetMapping;
  import org.springframework.web.bind.annotation.RequestMapping;
  
  import lombok.extern.log4j.Log4j;
  
  @Log4j
  @Controller
  @RequestMapping("/sample")
  public class SampleController {
  	@GetMapping("/all")
  	public void doAll() {
  		log.info("do all can access everybody");
  	}
  	
  	@GetMapping("/member")
  	public void doMember() {
  		log.info("logined member");
  	}
  	
  	@GetMapping("/admin")
  	public void doAdmin() {
  		log.info("admin only");
  	}
  }
  
  ```

- all.jsp , member.jsp , admin.jsp작성

  ```jsp
  <%@ page language="java" contentType="text/html; charset=UTF-8"
      pageEncoding="UTF-8"%>
      <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
  <%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
  <!DOCTYPE html>
  <html>
  <head>
  <meta charset="UTF-8">
  <title>Insert title here</title>
  </head>
  <body>
  <h1>/sample/all Page</h1>
  </body>
  </html>
  ```

  ```jsp
  <%@ page language="java" contentType="text/html; charset=UTF-8"
      pageEncoding="UTF-8"%>
      <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
  <%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
  <!DOCTYPE html>
  <html>
  <head>
  <meta charset="UTF-8">
  <title>Insert title here</title>
  </head>
  <body>
  <h1>/sample/member Page</h1>
  </body>
  </html>
  ```

  ```jsp
  <%@ page language="java" contentType="text/html; charset=UTF-8"
      pageEncoding="UTF-8"%>
      <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
  <%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
  <!DOCTYPE html>
  <html>
  <head>
  <meta charset="UTF-8">
  <title>Insert title here</title>
  </head>
  <body>
  <h1>/sample/admin Page</h1>
  </body>
  </html>
  ```

### 인증(Authentication)과 권한 부여(Authorization)

- 인증 : 자기 스스로가 무언가 자신을 증명할 만한 자료를 제시

- 권한 부여 : 남에 의해서 자격이 부여

  ![img](https://www.techtalks.lk/assets/images/posts/1540960050)
  - AuthenticationManager : 인증을 담당하는 존재 , 그 밑에 다양한 방식의 인증을 처리할 수 있도록 아래와 같은 구조로 설계
  - ProviderManager : 인증에 대한 처리를 AuthenticationProvider라는 타입의 객체를 이용해서 처리를 위임
  - AuthenticationProvider는 실제 인증 작업을 진행 , 이때 인증된 정보에는 권한에 대한 정보를 같이 전달, 이 처리는 UserDetailsService라는 존재와 관련
  - UserDetailsService 인터페이스의 구현체는 실제로 사용자의 정보와 사용자가 가진 권한의 정보를 처리해서 반환

- 개발자가 스프링 시큐리티를 커스터마이징 하는 방식

  1. AuthenticationProvider를 직접 구현
  2. 실제 처리를 담당하는 UserDetailsService를 구현하는 방식 => 대부분의 경우 사용