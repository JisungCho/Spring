# Chap18. AOP라는 패러다임

- AOP는 관점 지향 프로그래밍
  - 관점 == 관심사 == 개발 시 필요한 고민이나 염두에 두어야 하는 일 == 중요한 로직은 아니지만, 사전 조건이나 사후 조건
- **AOP : 관심사 + 비즈니스 로직 을 분리해서 별도의 코드로 작성하도록 하고,실행할 때 이를 결합하는 방식으로 접근**

1. AOP 용어들

   ![img](https://mblogthumb-phinf.pstatic.net/MjAxOTA5MjlfMTA5/MDAxNTY5NzY0Nzk5MTAz.9t8KxTmasiS1hmiKmYEU6cQj16BGkhlbaSFKi10e1Esg.l81mTR--qdqqcXne0gb4i98bi8cjxfVmAbj3WfNlyQ4g.PNG.dkdldoafotn/image.png?type=w800)

   - Target 
     - 개발자가 작성한 핵심 비즈니스 로직을 가지는 객체
     - 순수한 비즈니스 로직을 의미하고, 어떠한 관심사들과도 관계를 맺지 않는다.
   - Proxy
     - 내부적으로는 Target을 호출하지만, 중간에 필요한 관심사들을 거쳐서 Target을 호출하도록 자동 혹은 수동으로 작성
     - 대부분의 경우 스프링 AOP 기능을 이용해서 자동으로 생성되는 방식을 이용
   - JointPoint 
     - Target 객체가 가진 메서드
     - 외부에서의 호출은 Proxy객체를 통해서 Target객체의 JointPoint를 호출

   ![img](https://d2h0cx97tjks2p.cloudfront.net/blogs/wp-content/uploads/sites/2/2018/07/Program_Execution.jpg)

   - Pointcut

     - Target에 존재하는 메서드중 어느 메서드에 관심사를 결합할 것인지 결정하는 것
     - 관심사와 비즈니스 로직이 결합되는 지점을 결정

   - Aspect , Advice

     - Aspect : 관심사 자체를 의미하는 추상명사
     - Advice : Aspect를 구현한 코드 , 실제 걱정거리를 분리해 놓은 코드를 의미

   - Advice의 동작 위치에 따라 구분

     | 구분                   | 설명                                                         |
     | ---------------------- | ------------------------------------------------------------ |
     | Before Advice          | 1. Target의 JoinPoint를 호출하기 전에 실행되는 코드<br />2. 코드의 실행 자체에는 관여할 수 없다. |
     | After Returning Advice | 모든 실행이 정상적으로 이루어진 후에 동작하는 코드           |
     | After Throwing Advice  | 예외가 발생한 뒤에 동작하는 코드                             |
     | After Advice           | 정상적으로 실행되거나 예외가 발생했을 때 구분 없이 실행되는 코드 |
     | Around Advice          | 1. @Before와 @After가 합쳐진 것<br />2. 매개변수로 ProeedingJoinPoint 객체를 받음3. joinpoint로 제어 |

   - Advice는 스프링3 이후 어노테이션 만으로도 모든 설정이 가능

   - Target에 어떤 Advice를 적용할 것인지 XML이용한 설정 , 어노테이션 이용한 설정

   - Pointcut은 Advice를 어떤 Joinpoint에 결합할 것인지를 결정하는 설정

     | 구분                  | 설명                                                       |
     | --------------------- | ---------------------------------------------------------- |
     | execution(@execution) | 메서드 기준으로 Pointcut을 설정                            |
     | within(@within)       | 특정한 타입(클래스)을 기준으로 Pointcut 설정               |
     | this                  | 주어진 인터페이스를 구현한 객체를 대상으로 Pointcut을 설정 |
     | args(@args)           | 특정한 파라미터를 가지는 대상들만을 Pointcut으로 설정      |
     | @annotation           | 특정한 어노테이션이 적용된 대상들만을 Pointcut으로 설정    |



### AOP 실습

- AOP 기능은 주로 일반적인 POJO클래스 들에 적용
- Controller에는 주로 인터셉터나 필터등을 이용
- 예제에서는 서비스 계층에 AOP 적용

1. 예제 프로젝트 생성

   - pox.xml에 스프링 버전과 AOP버전을 수정 , AspectJ 버전 역시 1.9.0으로 변경
   - 기타 라이브러리 추가

2. 서비스 계층 설계

   ```java
   package org.zerock.service;
   	
   public interface SampleService {
   	public Integer doAdd(String str1,String str2) throws Exception;
   }
   
   ```

   ```java
   package org.zerock.service;
   
   import org.springframework.stereotype.Service;
   
   @Service
   public class SampleServiceImpl implements SampleService {
   
   	@Override
   	public Integer doAdd(String str1, String str2) throws Exception {
   		return Integer.parseInt(str1) + Integer.parseInt(str2);
   	}
   }
   ```

3. Advice 작성

   - LogAdvice

   ```java
   package org.zerock.aop;
   
   import java.util.Arrays;
   
   import org.aspectj.lang.ProceedingJoinPoint;
   import org.aspectj.lang.annotation.AfterThrowing;
   import org.aspectj.lang.annotation.Around;
   import org.aspectj.lang.annotation.Aspect;
   import org.aspectj.lang.annotation.Before;
   import org.springframework.stereotype.Component;
   
   import lombok.extern.log4j.Log4j;
   
   @Aspect //해당 클래스의 객체가 Aspect를 구현한 것임
   @Log4j
   @Component // AOP와는 관계가 없지만 스프링에서 bean으로 인식하기 위해서 사용
   public class LogAdvice {
   	@Before("execution(* org.zerock.service.SampleService*.*(..))") //BeforeAdvice를 구현한 메서드에 추가
       //executuon... 문자열은 AspectJ의 표현식
       //맨앞의 *는 접근제한자를 의미 맨뒤의 *는 클래스의 이름과 메서드의 이름을의미
   	public void logBefore() {
   		log.info("=====================================");
   	}
   }
   
   ```

   - Pointcut은 별도의 @Pointcut으로 지정해서 사용

### AOP 설정

- root-context.xml을 선택해서 네임스페이스에 aop와 context를 추가

  ```xml
  <!--service패키지와 aop 패키지를 스캔 이 과저에서 SampleServiceImpl클래스와 LogAdvice는 스프링의 빈으로 등록-->
  <context:component-scan base-package="org.zerock.service"></context:component-scan>
  <context:component-scan base-package="org.zerock.aop"></context:component-scan>
  
  <!--LogAdvice에 설정한 @Before가 동작-->
  <aop:aspectj-autoproxy></aop:aspectj-autoproxy>
  
  ```



### AOP 테스트

- SampleServiceTests

  - aop 설정을 한 Target에 대하여 proxy 객체가 정상적으로 만들어져있는지 확인

  ```java
  package org.zerock.service;
  
  import org.junit.Test;
  import org.junit.runner.RunWith;
  import org.springframework.beans.factory.annotation.Autowired;
  import org.springframework.test.context.ContextConfiguration;
  import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
  
  import lombok.extern.log4j.Log4j;
  
  @RunWith(SpringJUnit4ClassRunner.class)
  @ContextConfiguration("file:src/main/webapp/WEB-INF/spring/root-context.xml")
  @Log4j
  public class SampleServiceTests {
  	@Autowired
  	private SampleService service;
  	
  	@Test
  	public void testClass() {
  		log.info(service);
  		log.info(service.getClass().getName());
  	}
  	
  	@Test
  	public void testAdd() throws Exception{
  		log.info(service.doAdd("123", "456"));
  	}
  }
  
  ```

1. args를 이용한 파라미터 추적

   - 상황에 따라서 해당 메서드에 전달되는 파라미터가 무엇인지 기록하거나, 예외가 발생했을 때 어떤 파라미터에 문제가 있는지 알고싶은경우

   - LogAdvice

     ```java
     	@Before("execution(* org.zerock.service.SampleService*.doAdd(String,String)) && args(str1,str2)")
     	public void logBeforeWithParam(String str1,String str2) {
     		log.info("str1 : "+str1);
     		log.info("str2 : "+str2);
     	}
     ```

2. @AfterThrowing

   - 지정된 대상이 예외를 발생한 후에 동작하면서 문제를 찾을 수 있도록 도와줄 수 있다.
   - LogAdvice

   ```java
   	
   	@AfterThrowing(pointcut = "execution(* org.zerock.service.SampleService*.*(..))" , throwing = "exception")
   	public void logException(Exception exception) {
   		
   		log.info("Exception....!!!!");
   		log.info("exception: "+exception);
   	}
   ```

   - SampleServiceTests

     ```java
     	@Test
     	public void testAddError() throws Exception{
     		log.info(service.doAdd("123","abc"));
     	}
     ```



### @Around 와 ProceedingJoinPoint

- AOP를 이용해서 좀 더 구체적인 처리를 하고 싶다면 @Around 와 ProceedingJoinPoint를 이용해야한다.
- @Around 
  - 직접 대상 메서드를 실행할 수 있는 권한
  - 메서드의 실행 전과 실행 후에 처리가 가능
- ProceedingJoinPoint
  - @Around와 같이 결합해서 파라미터나 예외등을 처리할 수 있다.

- LogAdvice

  ```java
  @Around("execution(* org.zerock.service.SampleService*.*(..))")
  	public Object logTime(ProceedingJoinPoint pjp) { // ProceedingJoinPoint라는 파라미터는 AOP의 대상이 되는 Target이나 파라미터등을 파악 +직접 실행을 결정
          //@Around가 적용되는 메서드의 경우에는 리턴 타입이 void가 아닌 타입으로 설정하고, 메서드의 실행 결과 역시 직접 반화는 형태로 작성
  		long start = System.currentTimeMillis();
  		
  		log.info("Target : "+pjp.getTarget());
  		log.info("Param : "+Arrays.toString(pjp.getArgs()));
  		
  		Object result = null;
  		
  		try {
  			result = pjp.proceed();
  		} catch (Throwable e) {
  			e.printStackTrace();
  		}
  		
  		long end = System.currentTimeMillis();
  		
  		log.info("Time : "+(end-start));
  		
  		return result;
  	}
  ```

  