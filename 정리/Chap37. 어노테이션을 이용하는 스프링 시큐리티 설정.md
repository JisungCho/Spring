# Chap37. 어노테이션을 이용하는 스프링 시큐리티 설정

- 스프링 시큐리티 역시 다른 기능들처럼 어노테이션을 이용해서 필요한 설정을 추가할 수 있다.

  - @Secured : 스프링 시큐리티 초기부터 사용되었고, () 안에 ROLE_ADMIN 과 같은 문자열 혹은 문자열 배열을 이용
  - @PreAuthorize : 요청이 들어와 함수를 실행하기전에 권한을 검사하는 어노테이션
  - @PostAuthorize : 함수를 실행하고 클라이언트한테 응답을 하기 직전에 권한을 검사

-  SampleController

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
  	
  	@PreAuthorize("hasAnyRole('ROLE_ADMIN','ROLE_MEMBER')")
  	@GetMapping("/annoMember")
  	public void doMember2() {
  		log.info("logined annotation member");
  		
  	}
  	
  	@Secured("ROLE_ADMIN")
  	@GetMapping("/annoAdmin")
  	public void doAdmin2() {
  		log.info("admin annotation only");
  		
  	}
  }
  
  ```

- servlet-context.xml에 관련 설정 추가

  - security 네임스페이스 추가 (버전 정보는 지움)

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <beans:beans xmlns="http://www.springframework.org/schema/mvc" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  	xmlns:beans="http://www.springframework.org/schema/beans" xmlns:context="http://www.springframework.org/schema/context"
  	xmlns:security="http://www.springframework.org/schema/security"
  	xsi:schemaLocation="http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security.xsd
  		http://www.springframework.org/schema/mvc https://www.springframework.org/schema/mvc/spring-mvc.xsd
  		http://www.springframework.org/schema/beans https://www.springframework.org/schema/beans/spring-beans.xsd
  		http://www.springframework.org/schema/context https://www.springframework.org/schema/context/spring-context.xsd">
  
  	<!-- DispatcherServlet Context: defines this servlet's request-processing infrastructure -->
  	
  	<!-- Enables the Spring MVC @Controller programming model -->
  	<annotation-driven />
  
  	<!-- Handles HTTP GET requests for /resources/** by efficiently serving up static resources in the ${webappRoot}/resources directory -->
  	<resources mapping="/resources/**" location="/resources/" />
  
  	<!-- Resolves views selected for rendering by @Controllers to .jsp resources in the /WEB-INF/views directory -->
  	<beans:bean class="org.springframework.web.servlet.view.InternalResourceViewResolver">
  		<beans:property name="prefix" value="/WEB-INF/views/" />
  		<beans:property name="suffix" value=".jsp" />
  	</beans:bean>
  	
  	<context:component-scan base-package="org.zerock.controller" />
  	
  	<security:global-method-security pre-post-annotations="enabled" secured-annotations="enabled"/>
  	
  </beans:beans>
  
  ```

  

