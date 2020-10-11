# Chap35. 자동 로그인

- 스프링 시큐리티의 경우 'remember-me' 기능을 메모리상에서 처리하거나, 데이터베이스를 이용하는 형태로 약간의 설정만으로 구현이 가능
- security-context.xml에 < security:remember-me > 태그를 이용해서 기능을 구현
  - key : Hash 암/복호화에 사용할 키 값
  - token-validity-seconds : 토큰 유효 기간
  - authentication-success-handler-ref : 핸들러를 커스마이징 했다면 로그인 성공 후 수행할 로직 
  - user-service-ref : UserDetailsService를 커스터마이징 했을 경우 주입

### 데이터베이스를 이용하는 자동 로그인

- 자동 로그인 기능을 처리하는 방식중에서 가장 많이 사용되는 방식

  - **로그인이 되었던 정보를 데이터베이스를 이용해서 기록해 두었다가, 사용자의 재방문 시 세션에 정보가 없으면 데이터베이스를 조회해서 사용**

  - 스프링 시큐리티에서는 필요한 정보를 보관하는 용도일 뿐이므로, 커스터마이징 하기 보다는 지정된 형식의 테이블을 생성

    ```sql
    CREATE TABLE persistent_logins (
        username varchar(64) not null,
        series varchar(64) not null,
        token varchar(64) not null,
        last_used timestamp not null,
    );
    ```

  - security-context.xml

    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    	xmlns:security="http://www.springframework.org/schema/security"
    	xsi:schemaLocation="http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security.xsd
    		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
    
    	<bean id="customAccessDenied" class="org.zerock.security.CustomAccessDeniedHandler"></bean>
    	<bean id="customLoginSuccess" class="org.zerock.security.CustomLoginSuccessHandler"></bean> 
    	<bean id="bcryptPasswordEncoder" class="org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder"></bean>
    	<bean id="customUserDetailsService" class="org.zerock.security.CustomUserDetailsService"></bean>
    
    
    	<security:http>
    		<security:intercept-url pattern="/sample/all" access="permitAll" />
    		<security:intercept-url pattern="/sample/member" access="hasRole('ROLE_MEMBER')" />
    		<security:intercept-url pattern="/sample/admin" access="hasRole('ROLE_ADMIN')" />
    		<security:access-denied-handler ref="customAccessDenied"/>
    		<security:form-login login-page="/customLogin" authentication-success-handler-ref="customLoginSuccess"/>
    		<security:logout logout-url="/customLogout" invalidate-session="true"/>
    		<security:remember-me data-source-ref="dataSource" token-validity-seconds="604800"/>
    		<!-- <security:csrf disabled="true"/> -->
    		
    	</security:http>
    
    	<security:authentication-manager>
    
    		<security:authentication-provider user-service-ref="customUserDetailsService">
    			<security:password-encoder ref="bcryptPasswordEncoder" />
    			<!-- <security:jdbc-user-service data-source-ref="dataSource"/> -->
    		</security:authentication-provider>
    		
    		
    	</security:authentication-manager>
    </beans>
    
    ```

  1. 로그인 화면에 자동 로그인 설정

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
                 <input type='checkbox' name='remember-me'> Remember Me
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

  2. 로그아웃 시 쿠키 삭제

     - security-context.xml

       ```xml
       <?xml version="1.0" encoding="UTF-8"?>
       <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       	xmlns:security="http://www.springframework.org/schema/security"
       	xsi:schemaLocation="http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security.xsd
       		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
       
       	<bean id="customAccessDenied" class="org.zerock.security.CustomAccessDeniedHandler"></bean>
       	<bean id="customLoginSuccess" class="org.zerock.security.CustomLoginSuccessHandler"></bean> 
       	<bean id="bcryptPasswordEncoder" class="org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder"></bean>
       	<bean id="customUserDetailsService" class="org.zerock.security.CustomUserDetailsService"></bean>
       
       
       	<security:http>
       		<security:intercept-url pattern="/sample/all" access="permitAll" />
       		<security:intercept-url pattern="/sample/member" access="hasRole('ROLE_MEMBER')" />
       		<security:intercept-url pattern="/sample/admin" access="hasRole('ROLE_ADMIN')" />
       		<security:access-denied-handler ref="customAccessDenied"/>
       		<security:form-login login-page="/customLogin" authentication-success-handler-ref="customLoginSuccess"/>
       		<security:logout logout-url="/customLogout" invalidate-session="true" delete-cookies="remember-me,JSESSION_ID"/>
       		<security:remember-me data-source-ref="dataSource" token-validity-seconds="604800"/>
       		<!-- <security:csrf disabled="true"/> -->
       		
       	</security:http>
       
       	<security:authentication-manager>
       
       		<security:authentication-provider user-service-ref="customUserDetailsService">
       			<security:password-encoder ref="bcryptPasswordEncoder" />
       			<!-- <security:jdbc-user-service data-source-ref="dataSource"/> -->
       		</security:authentication-provider>
       		
       		
       	</security:authentication-manager>
       </beans>
       
       ```

       