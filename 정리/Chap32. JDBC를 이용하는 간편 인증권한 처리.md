# Chap32. JDBC를 이용하는 간편 인증/권한 처리

- JDBC를 이용하는 방식

  - 사용자를 확인하는 인증
  - 권한등을 부여하는 인가 과정

- 인증과 권한에 대한 처리

  1. **Authentication Manager를 통해서 이루어짐**
  2. **인증이나 권한 정보를 제공하는 Provider가 필요**
  3. **UserDetailsService라는 인터페이스를 구현한 존재를 활용**

  ![spring security auth process](https://changrea.io/static/87ddc2ad0c971bd8c2a5f0b10c258463/fcda8/spring-security-auth-process.png)

- 기존에 데이터베이스가 존재하는 상황에서 Mybatis나 기타 프레임워크 없이 사용하는 방법

  ```xml
  	<security:authentication-manager>
  
  		<security:authentication-provider>
  			<security:jdbc-user-service data-source-ref="dataSource"/>
  		</security:authentication-provider>
  		
  	</security:authentication-manager>
  ```

### JDBC를 이용하기 위한 테이블 설정

- JDBC를 이용해서 인증/권한을 체크하는 방식

  1. 지정된 형식으로 테이블을 생성해서 사용
  2. 기존에 작성된 데이터베이스를 이용

- 스프링 시큐리티가 JDBC를 이용하는 경우에 사용하는 클래스는 JdbcUserDetailsManager클래스

- **스프링 시큐리티의 지정된 테이블을 생성하는 SQL**

  ```SQL
  create table users(
        username varchar2(50) not null primary key,
        password varchar2(50) not null,
        enabled char(1) default '1');
  
        
   create table authorities (
        username varchar2(50) not null,
        authority varchar2(50) not null,
        constraint fk_authorities_users foreign key(username) references users(username));
        
   create unique index ix_auth_username on authorities (username,authority);
  
  
  insert into users (username, password) values ('user00','pw00');
  insert into users (username, password) values ('member00','pw00');
  insert into users (username, password) values ('admin00','pw00');
  
  insert into authorities (username, authority) values ('user00','ROLE_USER');
  insert into authorities (username, authority) values ('member00','ROLE_MANAGER'); 
  insert into authorities (username, authority) values ('admin00','ROLE_MANAGER'); 
  insert into authorities (username, authority) values ('admin00','ROLE_ADMIN');
  commit;
  
  ```

  ```xml
  	<security:authentication-manager>
  
  		<security:authentication-provider>
  			<security:jdbc-user-service data-source-ref="dataSource"/>
  		</security:authentication-provider>
  		
  		
  	</security:authentication-manager>
  ```

1.  PasswordEncoder 문제 해결

   - **스프링 시큐리티 5부터는 기본적으로 PasswordEncoder를 지정**

   - 데이터베이스 등을 이용하는 경우에는 PasswordEncoder라는 것을 이용

   - CustomNoOpPasswordEncoder

     ```java
     package org.zerock.security;
     
     import org.springframework.security.crypto.password.PasswordEncoder;
     
     import lombok.extern.log4j.Log4j;
     
     @Log4j
     public class CustomNoOpPasswordEncoder implements PasswordEncoder{@Override
     	public String encode(CharSequence rawPassword) {
     		log.warn("before encode : "+rawPassword);
     		
     		return rawPassword.toString();
     	}
     
     	@Override
     	public boolean matches(CharSequence rawPassword, String encodedPassword) {
     		log.warn("matches : "+rawPassword+":"+encodedPassword);
     		return rawPassword.toString().equals(encodedPassword);
     	}
     
     }
     
     ```

     ```xml
     <?xml version="1.0" encoding="UTF-8"?>
     <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     	xmlns:security="http://www.springframework.org/schema/security"
     	xsi:schemaLocation="http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security.xsd
     		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
     
     	<bean id="customAccessDenied" class="org.zerock.security.CustomAccessDeniedHandler"></bean>
     	<bean id="customLoginSuccess" class="org.zerock.security.CustomLoginSuccessHandler"></bean> -
     	<bean id="customPasswordEncoder" class="org.zerock.security.CustomNoOpPasswordEncoder"></bean> 
     
     
     	<security:http>
     		<security:intercept-url pattern="/sample/all" access="permitAll" />
     		<security:intercept-url pattern="/sample/member" access="hasRole('ROLE_MEMBER')" />
     		<security:intercept-url pattern="/sample/admin" access="hasRole('ROLE_ADMIN')" />
     		<!-- <security:access-denied-handler error-page="/accessError" /> -->
     		<security:access-denied-handler ref="customAccessDenied" />
     		<security:form-login login-page="/customLogin"/>
     		<security:logout logout-url="/customLogout" invalidate-session="true" delete-cookies="remember-me,JSESSION_ID"/>
     		<security:remember-me data-source-ref="dataSource" token-validity-seconds="604800"/>
     		<!-- <security:csrf disabled="true"/> -->
     		
     	</security:http>
     
     	<security:authentication-manager>
     
     		<security:authentication-provider>
     			<security:password-encoder ref="customPasswordEncoder" />
     			<security:jdbc-user-service data-source-ref="dataSource"/> 
     		</security:authentication-provider>
     		
     		
     	</security:authentication-manager>
     </beans>
     
     ```

### 기존의 테이블을 이용하는 경우

- JDBC를 이용하고 기존에 테이블이 있다면 약간의 지정된 결과를 반환하는 쿼리를 작성
- < security:jdbc-user-service > 태그에 users-by-username-query , authorities-by-username-query 속성에 적당한 쿼리문을 지정해주면 jdbc를 이용하는 설정을 그대로 사용

1. 인증/권한을 위한 테이블 설계

   ```sql
   create table tbl_member(
         userid varchar2(50) not null primary key,
         userpw varchar2(100) not null,
         username varchar2(100) not null,
         regdate date default sysdate, 
         updatedate date default sysdate,
         enabled char(1) default '1');
   
   
   create table tbl_member_auth (
        userid varchar2(50) not null,
        auth varchar2(50) not null,
        /*userid를 외래키로 사용*/
        constraint fk_member_auth foreign key(userid) references tbl_member(userid)
   );
   ```

2. BCryptPasswordEncoder 클래스를 이용한 패스워드 보호

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   	xmlns:security="http://www.springframework.org/schema/security"
   	xsi:schemaLocation="http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security.xsd
   		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
   
   	<bean id="customAccessDenied" class="org.zerock.security.CustomAccessDeniedHandler"></bean>
   	<bean id="customLoginSuccess" class="org.zerock.security.CustomLoginSuccessHandler"></bean> 
       
       <!--BcryptPasswordEncoder 클래스는 이미 스프링 시큐리티에서 제공-->
       <bean id="bcryptPasswordEncoder" class="org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder"></bean>
   
   
   	<security:http>
   		<security:intercept-url pattern="/sample/all" access="permitAll" />
   		<security:intercept-url pattern="/sample/member" access="hasRole('ROLE_MEMBER')" />
   		<security:intercept-url pattern="/sample/admin" access="hasRole('ROLE_ADMIN')" />
   		<!-- <security:access-denied-handler error-page="/accessError" /> -->
   		<security:access-denied-handler ref="customAccessDenied" />
   		<security:form-login login-page="/customLogin"/>
   		<security:logout logout-url="/customLogout" invalidate-session="true" delete-cookies="remember-me,JSESSION_ID"/>
   		<security:remember-me data-source-ref="dataSource" token-validity-seconds="604800"/>
   		<!-- <security:csrf disabled="true"/> -->
   		
   	</security:http>
   
   	<security:authentication-manager>
   
   		<security:authentication-provider>
               <security:password-encoder ref="bcryptPasswordEncoder"/>
   			<security:jdbc-user-service data-source-ref="dataSource"/> 
   		</security:authentication-provider>
   		
   		
   	</security:authentication-manager>
   </beans>
   
   ```

- 인코딩된 패스워드를 가지는 사용자 추가

  - MemberTests클래스

    ```java
    package org.zerock.security;
    
    import java.sql.Connection;
    import java.sql.PreparedStatement;
    import java.sql.SQLException;
    
    import javax.sql.DataSource;
    
    import org.junit.Test;
    import org.junit.runner.RunWith;
    import org.springframework.beans.factory.annotation.Autowired;
    import org.springframework.security.crypto.password.PasswordEncoder;
    import org.springframework.test.context.ContextConfiguration;
    import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
    
    import lombok.extern.log4j.Log4j;
    
    @RunWith(SpringJUnit4ClassRunner.class)
    @ContextConfiguration({"file:src/main/webapp/WEB-INF/spring/root-context.xml","file:src/main/webapp/WEB-INF/spring/security-context.xml"})
    @Log4j
    public class MemberTests {
    	@Autowired
    	private PasswordEncoder pwencoder;
    	
    	@Autowired
    	private DataSource ds;
    	
    	@Test
    	public void testInsertMember() {
    		String sql = "insert into tbl_member(userid,userpw,username) values(?,?,?)";
    		
    		for(int i=0;i<100;i++) {
    			Connection con = null;
    			PreparedStatement pstmt = null;
    			
    			try {
    				con = ds.getConnection();
    				pstmt = con.prepareStatement(sql);
    				
    				pstmt.setString(2, pwencoder.encode("pw"+i));
    				
    				if(i<80) {
    					pstmt.setString(1, "user"+i);
    					pstmt.setString(3, "일반사용자"+i);
    				}else if(i<90) {
    					pstmt.setString(1, "manager"+i);
    					pstmt.setString(3, "운영자"+i);
    				}else {
    					pstmt.setString(1, "admin"+i);
    					pstmt.setString(3, "관리자"+i);
    				}
    				pstmt.executeUpdate();
    			} catch (Exception e) {
    				// TODO: handle exception
    			}finally {
    				if(pstmt != null ) {
    					try {
    						pstmt.close();
    					} catch (SQLException e) {
    						// TODO Auto-generated catch block
    						e.printStackTrace();
    					}
    				}
    				if(con != null) {
    					try {
    						con.close();
    					} catch (SQLException e) {
    						// TODO Auto-generated catch block
    						e.printStackTrace();
    					}
    				}
    			}
    		}
    	}
    	
    }
    
    ```

  - 생성된 사용자에 권한 추가하기

    사용자 생성이 완료되었다면 tbl_mbember_auth 테이블에 사용자의 권한에 대한 정보도 tbl_mebmer_auth 테이블에 추가

    ```java
    @Test
    	public void testInsertAuth() {
    		String sql = "insert into tbl_member_auth(userid,auth) values(?,?)";
    		
    		for(int i=0;i<100;i++) {
    			Connection con = null;
    			PreparedStatement pstmt = null;
    			
    			try {
    				con = ds.getConnection();
    				pstmt = con.prepareStatement(sql);
    				
    				
    				if(i<80) {
    					pstmt.setString(1, "user"+i);
    					pstmt.setString(2, "ROLE_USER");
    				}else if(i<90) {
    					pstmt.setString(1, "manager"+i);
    					pstmt.setString(2, "ROLE_MEMBER");
    				}else {
    					pstmt.setString(1, "admin"+i);
    					pstmt.setString(2, "ROLE_ADMIN");
    				}
    				pstmt.executeUpdate();
    			} catch (Exception e) {
    				// TODO: handle exception
    			}finally {
    				if(pstmt != null ) {
    					try {
    						pstmt.close();
    					} catch (SQLException e) {
    						// TODO Auto-generated catch block
    						e.printStackTrace();
    					}
    				}
    				if(con != null) {
    					try {
    						con.close();
    					} catch (SQLException e) {
    						// TODO Auto-generated catch block
    						e.printStackTrace();
    					}
    				}
    			}
    		}
    	}
    ```

    

  