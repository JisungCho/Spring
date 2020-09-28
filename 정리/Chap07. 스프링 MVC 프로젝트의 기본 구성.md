# Chap07. 스프링 MVC 프로젝트의 기본 구성

### 3-tier 방식

![enter image description here](https://i.stack.imgur.com/7tkSn.png)

![img](https://blog.kakaocdn.net/dn/bUEl3U/btqAzyOdC98/CjiWwdRIyG5MdkUBPC52dK/img.png)

- Presentation tier 
  - 화면에 보여주는 기술을 사용하는 영역
  - Servlet/JSP나 스프링MVC가 담당하는 영역
- Business Tier 
  - 순수한 비즈니스 로직 담당
  - 고객이 원하는 요구 사항을 반영
  - 'xxxService'와 같은 이름으로 구성
- Persistence tier
  - 데이터를 어떤 방식으로 보관하고 사용하는가에 대한 설계

### 프로젝트 구성

- pom.xml 구성

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/maven-v4_0_0.xsd">
  	<modelVersion>4.0.0</modelVersion>
  	<groupId>org.zerock</groupId>
  	<artifactId>controller</artifactId>
  	<name>ex02</name>
  	<packaging>war</packaging>
  	<version>1.0.0-BUILD-SNAPSHOT</version>
      <!--자바 버전과 스프링버전 수정-->
  	<properties>
  		<java-version>1.8</java-version>
  		<org.springframework-version>5.0.7.RELEASE</org.springframework-version>
  		<org.aspectj-version>1.6.10</org.aspectj-version>
  		<org.slf4j-version>1.6.6</org.slf4j-version>
  	</properties>
  	<dependencies>
  		<!-- Spring -->
  		<dependency>
  			<groupId>org.springframework</groupId>
  			<artifactId>spring-context</artifactId>
  			<version>${org.springframework-version}</version>
  			<exclusions>
  				<!-- Exclude Commons Logging in favor of SLF4j -->
  				<exclusion>
  					<groupId>commons-logging</groupId>
  					<artifactId>commons-logging</artifactId>
  				</exclusion>
  			</exclusions>
  		</dependency>
  		<dependency>
  			<groupId>org.springframework</groupId>
  			<artifactId>spring-webmvc</artifactId>
  			<version>${org.springframework-version}</version>
  		</dependency>
  
  		<!-- AspectJ -->
  		<dependency>
  			<groupId>org.aspectj</groupId>
  			<artifactId>aspectjrt</artifactId>
  			<version>${org.aspectj-version}</version>
  		</dependency>
  
  		<!-- Logging -->
  		<dependency>
  			<groupId>org.slf4j</groupId>
  			<artifactId>slf4j-api</artifactId>
  			<version>${org.slf4j-version}</version>
  		</dependency>
  		<dependency>
  			<groupId>org.slf4j</groupId>
  			<artifactId>jcl-over-slf4j</artifactId>
  			<version>${org.slf4j-version}</version>
  			<scope>runtime</scope>
  		</dependency>
  		<dependency>
  			<groupId>org.slf4j</groupId>
  			<artifactId>slf4j-log4j12</artifactId>
  			<version>${org.slf4j-version}</version>
  			<scope>runtime</scope>
  		</dependency>
  		<dependency>
  			<groupId>log4j</groupId>
  			<artifactId>log4j</artifactId>
  			<version>1.2.15</version>
  			<exclusions>
  				<exclusion>
  					<groupId>javax.mail</groupId>
  					<artifactId>mail</artifactId>
  				</exclusion>
  				<exclusion>
  					<groupId>javax.jms</groupId>
  					<artifactId>jms</artifactId>
  				</exclusion>
  				<exclusion>
  					<groupId>com.sun.jdmk</groupId>
  					<artifactId>jmxtools</artifactId>
  				</exclusion>
  				<exclusion>
  					<groupId>com.sun.jmx</groupId>
  					<artifactId>jmxri</artifactId>
  				</exclusion>
  			</exclusions>
  		</dependency>
  
  		<!-- @Inject -->
  		<dependency>
  			<groupId>javax.inject</groupId>
  			<artifactId>javax.inject</artifactId>
  			<version>1</version>
  		</dependency>
  			
          <!--서블릿 버전 수정-->
  		<!-- Servlet -->
  		<dependency>
  			<groupId>javax.servlet</groupId>
  			<artifactId>javax.servlet-api</artifactId>
  			<version>3.1.0</version>
  			<scope>provided</scope>
  		</dependency>
  		<dependency>
  			<groupId>javax.servlet.jsp</groupId>
  			<artifactId>jsp-api</artifactId>
  			<version>2.1</version>
  			<scope>provided</scope>
  		</dependency>
  		<dependency>
  			<groupId>javax.servlet</groupId>
  			<artifactId>jstl</artifactId>
  			<version>1.2</version>
  		</dependency>
  
  		<!-- 추가 -->
  		<dependency>
  			<groupId>org.springframework</groupId>
  			<artifactId>spring-test</artifactId>
  			<version>${org.springframework-version}</version>
  		</dependency>
  		<dependency>
  			<groupId>org.springframework</groupId>
  			<artifactId>spring-jdbc</artifactId>
  			<version>${org.springframework-version}</version>
  		</dependency>
  		<dependency>
  			<groupId>org.springframework</groupId>
  			<artifactId>spring-tx</artifactId>
  			<version>${org.springframework-version}</version>
  		</dependency>
  		<dependency>
  			<groupId>com.zaxxer</groupId>
  			<artifactId>HikariCP</artifactId>
  			<version>2.7.8</version>
  		</dependency>
  		<dependency>
  			<groupId>org.mybatis</groupId>
  			<artifactId>mybatis</artifactId>
  			<version>3.4.6</version>
  		</dependency>
  		<dependency>
  			<groupId>org.mybatis</groupId>
  			<artifactId>mybatis-spring</artifactId>
  			<version>1.3.2</version>
  		</dependency>
  		<dependency>
  			<groupId>org.bgee.log4jdbc-log4j2</groupId>
  			<artifactId>log4jdbc-log4j2-jdbc4.1</artifactId>
  			<version>1.16</version>
  		</dependency>
  		<dependency>
  			<groupId>org.projectlombok</groupId>
  			<artifactId>lombok</artifactId>
  			<version>1.18.0</version>
  			<scope>provided</scope>
  		</dependency>
          <!-- 추가 끝-->
          
  		<!-- Test -->
          <!--junit 버전 수정-->
  		<dependency>
  			<groupId>junit</groupId>
  			<artifactId>junit</artifactId>
  			<version>4.12</version>
  			<scope>test</scope>
  		</dependency>
  	</dependencies>
  	<build>
  		<plugins>
  			<plugin>
  				<artifactId>maven-eclipse-plugin</artifactId>
  				<version>2.9</version>
  				<configuration>
  					<additionalProjectnatures>
  						<projectnature>org.springframework.ide.eclipse.core.springnature</projectnature>
  					</additionalProjectnatures>
  					<additionalBuildcommands>
  						<buildcommand>org.springframework.ide.eclipse.core.springbuilder</buildcommand>
  					</additionalBuildcommands>
  					<downloadSources>true</downloadSources>
  					<downloadJavadocs>true</downloadJavadocs>
  				</configuration>
  			</plugin>
  			<plugin>
  				<groupId>org.apache.maven.plugins</groupId>
  				<artifactId>maven-compiler-plugin</artifactId>
  				<version>2.5.1</version>
  				<configuration>
                      <!--Maven관련 자바 버전 수정-->
  					<source>1.8</source>
  					<target>1.8</target>
  					<compilerArgument>-Xlint:all</compilerArgument>
  					<showWarnings>true</showWarnings>
  					<showDeprecation>true</showDeprecation>
  				</configuration>
  			</plugin>
  			<plugin>
  				<groupId>org.codehaus.mojo</groupId>
  				<artifactId>exec-maven-plugin</artifactId>
  				<version>1.2.1</version>
  				<configuration>
  					<mainClass>org.test.int1.Main</mainClass>
  				</configuration>
  			</plugin>
  		</plugins>
  	</build>
  </project>
  
  ```

- 테이블 생성과 Dummy  데이터 생성

  ```sql
  create sequence seq_board;
  
  create table tbl_board (
      bno number(10,0),
      title varchar2(200) not null,
      content varchar2(2000) not null,
      writer varchar2(50) not null,
      regdate date default sysdate,
      updatedate date default sysdate
  );
  
  alter table tbl_board add constraint pk_board primary key(bno);
  
  insert into tbl_board (bno, title, content, writer) values (seq_board.nextval, '테스트 제목', '테스트 내용', 'user00');
  ```

- 데이터베이스 관련 설정 및 테스트

  - root-context.xml에 mybatis-spring 네임스페이스를 추가

  - DataSource의 설정과 Mybatis 설정을 추가

  - ```xml
    	<!-- Root Context: defines shared resources visible to all other web components -->
      	<bean id="hikariConfig" class="com.zaxxer.hikari.HikariConfig">
      		<property name="driverClassName" value="net.sf.log4jdbc.sql.jdbcapi.DriverSpy"/>
      		<property name="jdbcUrl" value="jdbc:log4jdbc:oracle:thin:@localhost:1521:XE"/>
      		<property name="username" value="book_ex"></property>
      		<property name="password" value="book_ex"></property>
      	</bean>
      	
      	<bean id="dataSource" class="com.zaxxer.hikari.HikariDataSource" destroy-method="close">
      		<constructor-arg ref="hikariConfig"></constructor-arg>
      	</bean>
      	
      	<bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
      			<property name="dataSource" ref="dataSource"></property>
      	</bean>
      	
      	<mybatis-spring:scan base-package="org.zerock.mapper"/>
    ```

  - log4jdbc.log4j2.properties파일을 추가