# Chap33. 커스텀 UserDetailsService 활용

- **스프링 시큐리티에서 username이라고 부르는 사용자의 정보만을 이용하기 때문에 실제 프로젝트에서 사용자의 이름이나 이메일등의 자세한 정보를 이용할 경우에는 충분하지 못하다**

- **직접 UserDetailsService를 구현해서 원하는 객체를 인증과 권한 체크에 활용**

- UserDetailsService인터페이스는 단 하나의 메서드만 존재

  - **loadUserByUsername()**

    - **반환타입  : UserDetails** 

      - **사용자의 정보와 권한 정보등을 담고있음**

    - UserDetails 타입은 getAuthorities() , getPassword() , getUserName() 등의 여러 추상 메서드를 가지고 있어서 개발 전에 이를 직접 구현할 것인지 UserDetails인터페이스를 구현해둔 스프링 시큐리티의 여러 하위 클래스를 이용할 것인지 판단

      => **가장 일반적인 방법은 User클래스를 상속하는 형태**

### 회원 도메인, 회원 Mapper설계

- tbl_member 테이블과 tbl_member_auth 테이블을 Mybatis를 이용하는 코드로 처리

- MemberVO , AuthVO

  ```java
  package org.zerock.domain;
  
  import java.util.Date;
  import java.util.List;
  
  import lombok.Data;
  
  @Data
  public class MemberVO {
  	private String userid;
  	private String userpw;
  	private String userName;
  	private boolean enabled;
  	
  	private Date regDate;
  	private Date updateDate;
      
      //여러개의 권한을 가질 수 있음
  	private List<AuthVO> authList;
  }
  
  ```

  ```java
  package org.zerock.domain;
  
  import lombok.Data;
  
  @Data
  public class AuthVO {
  	private String userid;
  	private String auth;
  }
  
  ```

1. MemberMapper

   - Member 객체를 가져오는 경우에는 한 번에 tbl_member와 tbl_member_auth를 조인햇 처리할 수 있는 방식으로 Mybatis의 resultMap이라는 기능을 사용
   - Mybatis의 ResultMap을 이용하면 하나의 쿼리로 MemberVO와 내부의 AuthVO 리스트까지 아래와 같이 처리

   - MemberMapper인터페이스

     ```
     package org.zerock.mapper;
     
     import org.zerock.domain.MemberVO;
     
     public interface MemberMapper {
     	public MemberVO read(String userid);
     }
     
     ```

   - MemberMapper.xml

     ```xml
     <?xml version="1.0" encoding="UTF-8" ?>
     <!DOCTYPE mapper
       PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
       "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
     <mapper namespace="org.zerock.mapper.MemberMapper">
     
     	<resultMap type="org.zerock.domain.MemberVO" id="memberMap">
     		<id property="userid" column="userid"/>
     		<result property="userpw" column="userpw"/>
     		<result property="userName" column="username"/>
     		<result property="regDate" column="regdate"/>
     		<result property="updateDate" column="updatedate"/>
     		<collection property="authList" resultMap="authMap">
     		</collection>
     	</resultMap>
     	
     	<resultMap type="org.zerock.domain.AuthVO" id="authMap">
     		<result property="userid" column="userid"/>
     		<result property="auth" column="auth"/>
     	</resultMap>
     	
         
         <!--left outer join 은 항상 왼쪽 테이블의 내용을 다 반환한 다음에 on의 조건에 따라 오른쪽 테이블과 join하고 오른쪽 테이블에 없는 내용일 경우 null을 반환하고 on 조건에서 필터링한 후에 동일한 결합키가 복수개의 레코드로 존재할 경우 (n-1)  개수씩 레코드가 더 늘어납니다. 그런 다음에 where 절을 통해 필터링한 다음 결과를 반환합니다. -->
     	<select id="read" resultMap="memberMap">
     		SELECT mem.userid , userpw , username, enabled, regdate, updatedate , auth
     		FROM tbl_member mem 
     		LEFT OUTER JOIN tbl_member_auth auth 
     		ON mem.userid = auth.userid WHERE mem.userid = #{userid}
     	</select>
     </mapper>
     ```
     
   - MemberMapper xptmxm
   
     ```java
     package org.zerock.mapper;
     
     import org.junit.Test;
     import org.junit.runner.RunWith;
  import org.springframework.beans.factory.annotation.Autowired;
     import org.springframework.test.context.ContextConfiguration;
  import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
     import org.zerock.domain.MemberVO;
     
     import lombok.extern.log4j.Log4j;
     
     @RunWith(SpringJUnit4ClassRunner.class)
     @ContextConfiguration({"file:src/main/webapp/WEB-INF/spring/root-context.xml","file:src/main/webapp/WEB-INF/spring/security-context.xml"})
     @Log4j
     public class MemberMapperTests {
     	@Autowired
     	private MemberMapper mapper;
     	
     	@Test
     	public void testRead() {
     		MemberVO vo = mapper.read("admin90");
     		
     		log.info(vo);
     		
     		vo.getAuthList().forEach(auth->log.info(auth));
     	}
     }
     
     ```

### CustomUserDetailsService 구성

- UserDetailsService를 구현하는 클래스를 직접 작성

  1. **CustomUserDetailsService는 스프링 시큐리티의 UserDeatailsService를 구현**
  2. MemberMapper타입의 인스턴스를 주입받아서 실제 기능을 구현

- CustomUserDetailsService

  ```java
  package org.zerock.security;
  
  import org.springframework.beans.factory.annotation.Autowired;
  import org.springframework.security.core.userdetails.UserDetails;
  import org.springframework.security.core.userdetails.UserDetailsService;
  import org.springframework.security.core.userdetails.UsernameNotFoundException;
  import org.zerock.domain.MemberVO;
  import org.zerock.mapper.MemberMapper;
  import org.zerock.security.domain.CustomUser;
  
  import lombok.extern.log4j.Log4j;
  
  @Log4j
  public class CustomUserDetailsService implements UserDetailsService {
  	@Autowired
  	private MemberMapper membermapper;
  
  	@Override
  	public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
  
  		log.warn("Load User By UserName : "+username);
  		
  		return null;
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
  
  	<bean id="customAccessDenied" class="org.zerock.security.CustomAccessDeniedHandler"></bean>
  	<bean id="customLoginSuccess" class="org.zerock.security.CustomLoginSuccessHandler"></bean>
  	<bean id="bcryptPasswordEncoder" class="org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder"></bean>
  	<bean id="customUserDetailsService" class="org.zerock.security.CustomUserDetailsService"></bean>
  
  
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
  
  		<security:authentication-provider user-service-ref="customUserDetailsService">
  			<security:password-encoder ref="bcryptPasswordEncoder" />
  			<!-- <security:jdbc-user-service data-source-ref="dataSource"/> -->
  		</security:authentication-provider>
  		
  		
  	</security:authentication-manager>
  </beans>
  
  ```

1. MemberVO를 UserDetails 타입으로 변환

   - UserDetailsService는 loadUserByUsername() 라는 하나의 추상 메서드만을 가지고 있으면 리턴타입은 UserDetails

   - 따라서 MemberVO의 인스턴스를 스프링 시큐리티의 UserDetails 타입으로 변환하는 작업을 처리

   - CustomUser

     ```java
     package org.zerock.security.domain;
     
     import java.util.Collection;
     import java.util.stream.Collectors;
     
     import org.springframework.security.core.GrantedAuthority;
     import org.springframework.security.core.authority.SimpleGrantedAuthority;
     import org.springframework.security.core.userdetails.User;
     import org.zerock.domain.MemberVO;
     
     import lombok.Getter;
     
     @Getter
     public class CustomUser extends User {
     	
     	private static final long serialVersionUID = 1L;
     	private MemberVO member;
     
     	public CustomUser(String username, String password, Collection<? extends GrantedAuthority> authorities) {
     		super(username, password, authorities);
     		// TODO Auto-generated constructor stub
     	}
     	
     	public CustomUser(MemberVO vo) {
     		super(vo.getUserid(), vo.getUserpw(), vo.getAuthList().stream().map(auth -> new SimpleGrantedAuthority(auth.getAuth())).collect(Collectors.toList()));
     	
     		this.member = vo;
     	}
     
     }
     
     ```

   - CustomUserDetailsService

     ```java
     package org.zerock.security;
     
     import org.springframework.beans.factory.annotation.Autowired;
     import org.springframework.security.core.userdetails.UserDetails;
     import org.springframework.security.core.userdetails.UserDetailsService;
     import org.springframework.security.core.userdetails.UsernameNotFoundException;
     import org.zerock.domain.MemberVO;
     import org.zerock.mapper.MemberMapper;
     import org.zerock.security.domain.CustomUser;
     
     import lombok.extern.log4j.Log4j;
     
     @Log4j
     public class CustomUserDetailsService implements UserDetailsService {
     	@Autowired
     	private MemberMapper membermapper;
     
     	@Override
     	public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
     
     		log.warn("Load User By UserName : "+username);
     		
     		//userName means userid
     		MemberVO vo = membermapper.read(username);
     		
     		log.warn("queried by member mapper : "+vo);
     		return vo == null ? null : new CustomUser(vo);
     		
     	}
     }
     
     ```

     

