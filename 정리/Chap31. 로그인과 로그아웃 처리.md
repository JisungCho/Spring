# Chap31. 로그인과 로그아웃 처리

### 접근 제한 설정

- security-context.xml

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  	xmlns:security="http://www.springframework.org/schema/security"
  	xsi:schemaLocation="http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security.xsd
  		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
  
  	<security:http>
          
          <!--인터셉터를 이용해서 접근을 제한-->
  		<security:intercept-url pattern="/sample/all" access="permitAll" /> <!--pattern : uri의 패턴, access : 권한을 체크하는데 access안에 문자열에는 표현식이 사용될 수도 있고 권한명을 사용할 수도있지만 표현식을 사용하는 방식이 권장--> 
  		<security:intercept-url pattern="/sample/member" access="hasRole('ROLE_MEMBER')" />
  		<security:intercept-url pattern="/sample/admin" access="hasRole('ROLE_ADMIN')" />
  		<security:form-login />
  	</security:http>
  
  	<security:authentication-manager>
  
  	</security:authentication-manager>
  </beans>
  
  ```

### 단순  로그인처리

- 스프링 시큐리티에서 명심해야할 사항

  - **username이나 User라는 용어의 의미가 일반적인 시스템에서의 의미와 차이가있다**
    - **일반 시스템에서 userid는 스프링시큐리티에서 username에 해당 , 일반적으로 사용자의 이름을 username이라고 처리하는 것과 혼동하면 안됨**
    - **스프링 시큐리티의 User는 인증 정보와 권한을 가진 객체이므로 일반적인 경우에 사용하는 사용자 정보와는 다른 의미**

- 인증과 권한에 대한 실제 처리는 UserDetailsService라는 것을 이용해서 처리

  - security-context.xml	

    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    	xmlns:security="http://www.springframework.org/schema/security"
    	xsi:schemaLocation="http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security.xsd
    		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
    
    	<security:http>
            
            <!--인터셉터를 이용해서 접근을 제한-->
    		<security:intercept-url pattern="/sample/all" access="permitAll" /> <!--pattern : uri의 패턴, access : 권한을 체크하는데 access안에 문자열에는 표현식이 사용될 수도 있고 권한명을 사용할 수도있지만 표현식을 사용하는 방식이 권장--> 
    		<security:intercept-url pattern="/sample/member" access="hasRole('ROLE_MEMBER')" />
    		<security:intercept-url pattern="/sample/admin" access="hasRole('ROLE_ADMIN')" />
    		<security:form-login />
    	</security:http>
    
    	<security:authentication-manager>
    		
            <security:authentication-provider>
            	<security:user-service>
                	<security:user name="member" password="member" authorities="ROLE_MEMBER"/>
                </security:user-service>
            </security:authentication-provider>
            
    	</security:authentication-manager>
    </beans>
    
    ```

    - PasswordEncoder라는 존재가 없기 때문에 에러가 발생

      - 일단 패스워드의 인코딩 처리없이 사용하고 싶다면 password앞에 {noop} 문자열을 추가

        ```xml
                <security:authentication-provider>
                	<security:user-service>
                    	<security:user name="member" password="{noop}member" authorities="ROLE_MEMBER"/>
                    </security:user-service>
                </security:authentication-provider>
        ```


  1. 로그아웃 확인

     - 로그아웃은 개발자 페이지에서 JSESSIONID 쿠키를 강제로 삭제

  2. 여러 권한을 가지는 사용자 설정

     ```XML
     <?xml version="1.0" encoding="UTF-8"?>
     <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     	xmlns:security="http://www.springframework.org/schema/security"
     	xsi:schemaLocation="http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security.xsd
     		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
     
     	<security:http>
             
             <!--인터셉터를 이용해서 접근을 제한-->
     		<security:intercept-url pattern="/sample/all" access="permitAll" /> <!--pattern : uri의 패턴, access : 권한을 체크하는데 access안에 문자열에는 표현식이 사용될 수도 있고 권한명을 사용할 수도있지만 표현식을 사용하는 방식이 권장--> 
     		<security:intercept-url pattern="/sample/member" access="hasRole('ROLE_MEMBER')" /> <!--ROLE_MEMBER권한을 가진회원-->
     		<security:intercept-url pattern="/sample/admin" access="hasRole('ROLE_ADMIN')" /> <!--ROLE_ADMIN권한을 가진회원-->
     		<security:form-login />
     	</security:http>
     
     	<security:authentication-manager>
     		
             <security:authentication-provider>
             	<security:user-service>
                 	<security:user name="member" password="{noop}member" authorities="ROLE_MEMBER"/>
                     <security:user name="admin" password="{noop}admin" authorities="ROLE_MEMBER, ROLE_ADMIN"/>
                 </security:user-service>
             </security:authentication-provider>
             
     	</security:authentication-manager>
     </beans>
     
     ```

  3. 접근 제한 메세지의 처리

     - 특정한 사용자가 로그인은 했지만, URI를 접근할 수 있는 권한이 없는 상황이 발생
       - EX) MEMBER가 ADMIN에 접근
     - 스프링 시큐리티에서는 접근 제한에 대해서 
       1. AccessDeniedHandler를 직접 구현
       2. 특정한  URI를 지정

     ```XML
     <?xml version="1.0" encoding="UTF-8"?>
     <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     	xmlns:security="http://www.springframework.org/schema/security"
     	xsi:schemaLocation="http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security.xsd
     		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
     
     	<security:http>
             
             <!--인터셉터를 이용해서 접근을 제한-->
     		<security:intercept-url pattern="/sample/all" access="permitAll" /> <!--pattern : uri의 패턴, access : 권한을 체크하는데 access안에 문자열에는 표현식이 사용될 수도 있고 권한명을 사용할 수도있지만 표현식을 사용하는 방식이 권장--> 
     		<security:intercept-url pattern="/sample/member" access="hasRole('ROLE_MEMBER')" /> <!--ROLE_MEMBER권한을 가진회원-->
     		<security:intercept-url pattern="/sample/admin" access="hasRole('ROLE_ADMIN')" /> <!--ROLE_ADMIN권한을 가진회원-->
     		<security:form-login />
           
             <!--error-page속성으로 특정한 uri지정-->
            	<security:access-denied-handler error-page="/accessError" />
             
     	</security:http>
     
     	<security:authentication-manager>
     		
             <security:authentication-provider>
             	<security:user-service>
                 	<security:user name="member" password="{noop}member" authorities="ROLE_MEMBER"/>
                     <security:user name="admin" password="{noop}admin" authorities="ROLE_MEMBER, ROLE_ADMIN"/>
                 </security:user-service>
             </security:authentication-provider>
             
     	</security:authentication-manager>
     </beans>
     
     ```

     - CommonController

       ```java
       package org.zerock.controller;
       
       import org.springframework.security.core.Authentication;
       import org.springframework.stereotype.Controller;
       import org.springframework.ui.Model;
       import org.springframework.web.bind.annotation.GetMapping;
       
       import lombok.extern.log4j.Log4j;
       
       @Controller
       @Log4j
       public class CommonController {
       	
           //auth에 사용자의 정보가 들어감
           @GetMapping("/accessError")
       	public void accessDenied(Authentication auth,Model model) {
       		log.info("access Denied:" + auth);
       		model.addAttribute("msg","Access Denied");
       	}
       	
       }
       
       ```

     - accessError.jsp

       ```jsp
       <%@ page language="java" contentType="text/html; charset=UTF-8"
           pageEncoding="UTF-8"%>
       <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
       <%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
       <!DOCTYPE html>
       <html>
       <head>
       <meta charset="UTF-8">
       <title>Access Denied Page</title>
       </head>
       <body>
       <h1>Access Denied Page</h1>
       <!--HttpServletRequest안에 SPRING_SECURITY_403_EXCEPTION이라는 이름으로 AccessDeniedException 객체가 전달-->
       <h2><c:out value="${SPRING_SECURITY_403_EXCEPTION.getMessage()}"></c:out></h2>
       <h2><c:out value="${msg }"></c:out></h2>
       </body>
       </html>
       ```

  4. AccessDeniedHandler 인터페이스를 구현하는 경우

     - 접근 제한이 된 경우에 다양한 처리를 하고 싶다면 직접 AccessDeniedHandler 인터페이스를 구현하는 편이 좋다.

       - 접근이 제한이 되었을 때 쿠키나 세션에 특정한 작업
       - HttpServletResponse에 특정한 헤더 정보를 추가

     - CustomeAccessDeniedHandler

       ```java
       package org.zerock.security;
       
       import java.io.IOException;
       
       import javax.servlet.ServletException;
       import javax.servlet.http.HttpServletRequest;
       import javax.servlet.http.HttpServletResponse;
       
       import org.springframework.security.access.AccessDeniedException;
       import org.springframework.security.web.access.AccessDeniedHandler;
       
       import lombok.extern.log4j.Log4j;
       
       @Log4j
       public class CustomAccessDeniedHandler implements AccessDeniedHandler { //AccessDeniedHandler를 직접구현
       
       	@Override
       	public void handle(HttpServletRequest request, HttpServletResponse response,
       			AccessDeniedException accessDeniedException) throws IOException, ServletException {//request.response를 파라미터로 사용하기 때문에 직접적으로 서블릿 API를 이용하는 처리가 가능
       		log.error("Access Denied Handler");
       		
       		log.error("Redirect....");
       		
       		response.sendRedirect("/accessError");
       		
       	}
       
       }
       
       ```

     - security-context.xml

       ```xml
       <?xml version="1.0" encoding="UTF-8"?>
       <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       	xmlns:security="http://www.springframework.org/schema/security"
       	xsi:schemaLocation="http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security.xsd
       		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
       
       	<security:http>
               
               <!--인터셉터를 이용해서 접근을 제한-->
       		<security:intercept-url pattern="/sample/all" access="permitAll" /> <!--pattern : uri의 패턴, access : 권한을 체크하는데 access안에 문자열에는 표현식이 사용될 수도 있고 권한명을 사용할 수도있지만 표현식을 사용하는 방식이 권장--> 
       		<security:intercept-url pattern="/sample/member" access="hasRole('ROLE_MEMBER')" /> <!--ROLE_MEMBER권한을 가진회원-->
       		<security:intercept-url pattern="/sample/admin" access="hasRole('ROLE_ADMIN')" /> <!--ROLE_ADMIN권한을 가진회원-->
       		<security:form-login />
             
               <!--AccessDeniedHandler를 구현한 클래스를 ref로 사용-->
              	<security:access-denied-handler ref="customAccessDeniedHandler" />
               
       	</security:http>
       
       	<security:authentication-manager>
       		
               <security:authentication-provider>
               	<security:user-service>
                   	<security:user name="member" password="{noop}member" authorities="ROLE_MEMBER"/>
                       <security:user name="admin" password="{noop}admin" authorities="ROLE_MEMBER, ROLE_ADMIN"/>
                   </security:user-service>
               </security:authentication-provider>
               
       	</security:authentication-manager>
       </beans>
       
       ```

### 커스텀 로그인 페이지

- security-context.xml

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  	xmlns:security="http://www.springframework.org/schema/security"
  	xsi:schemaLocation="http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security.xsd
  		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
  
  	<security:http>
          
          <!--인터셉터를 이용해서 접근을 제한-->
  		<security:intercept-url pattern="/sample/all" access="permitAll" /> <!--pattern : uri의 패턴, access : 권한을 체크하는데 access안에 문자열에는 표현식이 사용될 수도 있고 권한명을 사용할 수도있지만 표현식을 사용하는 방식이 권장--> 
  		<security:intercept-url pattern="/sample/member" access="hasRole('ROLE_MEMBER')" /> <!--ROLE_MEMBER권한을 가진회원-->
  		<security:intercept-url pattern="/sample/admin" access="hasRole('ROLE_ADMIN')" /> <!--ROLE_ADMIN권한을 가진회원-->
          
          <!--login-page 속성의 uri는 반드시 GET방식으로 접근하는 URI를 지정-->
  		<security:form-login login-page="/customLogin" />
        
          <!--AccessDeniedHandler를 구현한 클래스를 ref로 사용-->
         	<security:access-denied-handler ref="customAccessDeniedHandler" />
          
  	</security:http>
  
  	<security:authentication-manager>
  		
          <security:authentication-provider>
          	<security:user-service>
              	<security:user name="member" password="{noop}member" authorities="ROLE_MEMBER"/>
                  <security:user name="admin" password="{noop}admin" authorities="ROLE_MEMBER, ROLE_ADMIN"/>
              </security:user-service>
          </security:authentication-provider>
          
  	</security:authentication-manager>
  </beans>
  
  ```

- CommonController

  ```
  	@GetMapping("/customLogin")
  	public void loginInput(String error,String logout,Model model) {
  		log.info("error: "+error);
  		log.info("logout: "+logout);
  		
  		if(error != null) {
  			model.addAttribute("error","Login Error Check Your Account");
  		}
  		
  		if(logout != null) {
  			model.addAttribute("logout","Logout!!");
  		}
  	}
  ```

- customLogin.jsp

  ```jsp
  <%@ page language="java" contentType="text/html; charset=UTF-8"
  	pageEncoding="UTF-8"%>
  <!DOCTYPE html>
  <html lang="en">
  
  <head>
  
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="">
  <meta name="author" content="">
  
  <title>customLogin</title>
  
  </head>
  <body>
  	<h1>Custom Login Page</h1>
      <h2>
        ${error}  
      </h2>
      <h3>
          ${logout}
      </h3>
      
      <!--실제 시큐리티의 로그인 작업은 '/login'을 통해서 이루어지는데 반드시 POST방식으로 전송-->
      <form method='post' action="/login">
          <div>
              <!--반드시 username-->
              <input type='text' name='username' value='admin'>
          </div>
          <div>
              <!--반드시 password-->
              <input type='password' name='password' value='admin'>
          </div>
          <div>
              <input type='submit'>
          </div>
          <!--name은 '_csrf'로 전송되고 value는 임의값이 들어감-->
          <input type='hidden' name="${_csrf.parameterName}" value="${_csrf.token}"
      </form>
  </body>
  </html>
  
  ```

### CSRF 공격과 토큰

- 스프링 시큐리티에서 POST방식을 이용하는 경우 기본적으로 CSRF 토큰이라는 것을 이용
- CSRF 토큰은 사이트간 위조 방지의 목적으로 특정한 값의 토큰을 사용하는 방식
- CSRF 공격은 사이트간 요청 위조

1. CSRF 토큰
   - 사용자가 임의로 변하는 특정한 토큰값을 서버에서 체크하는 방식
     1. 서버에서는 브라우저에 데이터를 전송할 때 CSRF 토큰을 같이 전송
     2. 사용자가 POST방식 등으로 특정한 작업을 할 때는 브라우저에서 전송된 CSRF토큰의 값과 서버가 보관하고 있는 토큰의 값을 비교
     3. 만일 CSRF 토큰의 값이 다르다면 작업을 처리하지 않음
2. 스프링 시큐리티의 CSRF 설정
   - CSRF 토큰은 세션을 통해서 보관
   - 브라우저에서 전송된 CSRF 토큰값을 검사하는 방식으로 처리

### 로그인 성공과 AuthenticationSuccessHandler

- 로그인을 처리하다 보면 로그인 성공 이후에 특정한 동작을 하도록 제어하고 싶은 경우가 있다.
- 이런 경우를 위해서 스프링 시큐리티에서는 AuthenticationSuccessHandler라는 인터페이스를 구현해서 설정

- CustomLoginSuccessHandler

  ```java
  package org.zerock.security;
  
  import java.io.IOException;
  import java.util.ArrayList;
  import java.util.List;
  
  import javax.servlet.ServletException;
  import javax.servlet.http.HttpServletRequest;
  import javax.servlet.http.HttpServletResponse;
  
  import org.springframework.security.core.Authentication;
  import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
  
  import lombok.extern.log4j.Log4j;
  
  @Log4j
  public class CustomLoginSuccessHandler implements AuthenticationSuccessHandler{
  	
      //로그인 한 사용자에 부여된 권한 Authentication 객체를 이용해서 사용자가 가진 모든 권한을 문자열로 체크
  	@Override
  	public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
  			Authentication auth) throws IOException, ServletException {
  		// TODO Auto-generated method stub
  		
  		log.warn("Login Success");
  		
  		List<String> roleNames = new ArrayList<String>();
  		
          //사용자가 가진 모든권한을 가져와서 roleNames에 넣어줌
  		auth.getAuthorities().forEach(authority -> {
  			roleNames.add(authority.getAuthority());
  		});
  		
  		log.warn("ROLE NAMES: "+roleNames);
  		
          //권한이 ROLE_ADMIN이면 ADMIN페이지로 이동
  		if(roleNames.contains("ROLE_ADMIN")) {
  			response.sendRedirect("/sample/admin");
  			return;
  		}
          
          //권한이 ROLE_MEMBER이면 ADMIN페이지로 이동
  		if(roleNames.contains("ROLE_MEMBER")) {
  			response.sendRedirect("/sample/member");
  			return;
  		}
  		
  		response.sendRedirect("/");
  	}
  
  }
  
  ```

### 로그아웃의 처리와 LogoutSuccessHandler

- 로그아웃 처리 방식

  - 특정한 uri지정
  - logoutSuccessHandler 핸들러 등록

- security-context.xml

  ```xml
  <security:logout logout-url="/customLogout" invalidate-session="true" />
  ```

- CommonController

  ```java
  	@GetMapping("/customLogout")
  	public void logoutGET() {
  		log.info("custom logout");
  	}
  ```

- customLogout.jsp

  ```jsp
  <%@ page language="java" contentType="text/html; charset=UTF-8"
  	pageEncoding="UTF-8"%>
  <!DOCTYPE html>
  <html lang="en">
  
  <head>
  
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="">
  <meta name="author" content="">
  
  <title>customLogin</title>
  
  </head>
  <body>
  	<h1>Custom Logout Page</h1>
      <h2>
        ${error}  
      </h2>
      <h3>
          ${logout}
      </h3>
      
     <!--로그아웃도 post방식으로 전달-->
      <form method='post' action="/customLogout">
  		<input type='hidden' name="${_csrf.parameterName}" value="${_csrf.token}">
          <button>로그아웃</button>
      </form>
  </body>
  </html>
  
  ```

- logoutSuccessHandler를 정의해서 처리

  - 생략

- admin.jsp

  ```jsp
  <a href="/customLogout">Logout</a>
  ```

  

