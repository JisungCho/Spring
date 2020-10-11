# Chap34. 스프링 시큐리티 JSP에서 사용하기

### JSP에서 로그인한 사용자 정보 보여주기

- 스프링 시큐리티와 관련된 정보를 출력하거나 사용하려면 JSP페이지 상단에 스프링 시큐리티 관련 태그 라이브러리의 사용을 선언

-  **< sec:authenticationn > 태그와 principal 이라는 이름의 속성을 사용**

- admin.jsp

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
  
  <p>principal : <sec:authentication property="principal"/> </p> <!--UserDetailsService에서 반환된 객체 즉, CustomUser객체-->
  <p>MemberVO : <sec:authentication property="principal.member"/></p>
  <p>사용자이름 : <sec:authentication property="principal.member.userName"/></p>
  <p>사용자아이디 : <sec:authentication property="principal.username"/></p>
  <p>사용자 권한 리스트 : <sec:authentication property="principal.member.authList"/></p>
  
  <a href="/customLogout">Logout</a>
  </body>
  </html>
  ```

### 표현식을 이용하는 동적 화면 구성

- 스프링 시큐리티의 표현식은 security-context.xml에서도 사용가능

![image](https://user-images.githubusercontent.com/52770718/95647551-411e9080-0b0b-11eb-9d0b-8b1e9ccde034.png)

- all.jsp

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
  <sec:authorize access="isAnonymous()">
  	<a href="/customLogin">로그인</a>
  </sec:authorize>
  <sec:authorize access="isAuthenticated()">
  	<a href="/customLogout">로그아웃</a>
  </sec:authorize>
  </body>
  </html>
  ```

  