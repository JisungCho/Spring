# Chap19. 스프링에서 트랜잭션 관리

- 비즈니스에서는 쪼개질 수 없는 하나의 단위 작업을 트랜잭션 이라는 용어를 사용
- 트랜잭션 == 한 번에 이루어지는 작업의 단위
- 트랜잭션의 성격
  1. 원자성 : 어떤 작업이 잘못되는 경우 모든 것은 다시 원점으로 돌아가야함
  2. 일관성 : 트랜잭션이 성공했다면 데이터베이스의 모든 데이터는 일관성을 유지해야만한다
  3. 격리 : 트랜잭션으로 처리되는 중간에 외부에서의 간섭은 없어야한다
  4. 영속성 : 트랜잭션이 성공적으로 처리되면 그 결과는 영속적으로 보관
- 트랜잭션으로 관리한다 , 트랜잭션으로 묶는다는 표현은 AND 연산과 유사

### 데이터베이스 설계와 트랜잭션

- 데이터베이스의 저장 구조를 효율적으로 관리하기 위해서 흔히 정규화라는 작업을 한다

- 정규화
  - 중복된 데이터를 제거해서 데이터 저장의 효율을 올리자
  - 정규화를 진행하면
    1. 테이블은 늘어나고
    2. 각 테이블의 데이터 양은 줄어드는것
  - 정규화를 진행하면서 원칙적으로 칼럽으로 처리되지 않는 데이터
    1. 시간이 흐르면 변경되는 데이터
    2. 계산이 가능한 데이터
    3. 누구에게나 정해진 값을 이용하는 경우
- 역정규화
  - 중복이나 계산되는 값을 데이터베이스 상에 보관하고, 대신에 조인이나 서브쿼리의 사용을 줄이는방식
  - 중복이나 계산의 결과를 미리 보관해서 좀 더 빠른 결과를 얻기위한 노력

### 트랜잭션 설정 실습

- 교재 468P 참조

1. 예제 테이블 생성

   ```sql
   create table tbl_sample1(col1 varchar2(500));
   create table tbl_sample2(col1 varchar2(50));
   /*50바이트가 넘을 시 tbl_sample2에서는 오류가 발생*/
   ```

   - Sample1Mapper

     ```java
     package org.zerock.mapper;
     
     import org.apache.ibatis.annotations.Insert;
     
     public interface Sample1Mapper {
     
     	@Insert("insert into tbl_sample1 (col1) values (#{data})")
     	public int insertCol1(String data);
     }
     
     ```

   - Sample2Mapper

     ```java
     package org.zerock.mapper;
     
     import org.apache.ibatis.annotations.Insert;
     
     public interface Sample2Mapper {
     	
     	@Insert("insert into tbl_sample2 (col2) values (#{data})")
     	public int insertCol2(String data);
     }
     
     ```

2. 비즈니스 계층과 트랜잭션 설정

   - SampleTxService 

     ```java
     package org.zerock.service;
     
     public interface SampleTxService {
     	public void addDate(String value);
     }
     
     ```

   - SampleTxServiceImpl

     ```java
     package org.zerock.service;
     
     import org.springframework.beans.factory.annotation.Autowired;
     import org.springframework.stereotype.Service;
     import org.springframework.transaction.annotation.Transactional;
     import org.zerock.mapper.Sample1Mapper;
     import org.zerock.mapper.Sample2Mapper;
     
     import jdk.internal.org.jline.utils.Log;
     import lombok.extern.log4j.Log4j;
     
     @Service
     @Log4j
     public class SampleTxServiceImpl implements SampleTxService{
     
     	@Autowired
     	private Sample1Mapper mapper1;
     	@Autowired
     	private Sample2Mapper mapper2;
     	
     	@Override
     	@Transactional //트랜잭션 처리 , 예외 발생 시 rollback()
     	public void addDate(String value) {
     
     		log.info("mapper1..............");
     		mapper1.insertCol1(value);
     		
     		log.info("mapper2..............");
     		mapper2.insertCol2(value);
     		
     		log.info("end....................");
     	}
     
     }
     
     ```

   - SampleTxServiceTests

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
     public class SampleTxServiceTests {
     	@Autowired
     	public SampleTxService service;
     	
     	@Test
     	public void testLong() {
     		String str = "Starry\r\n"+"paint your palette blue and grey\r\n"+"Look out on a summer's day";
     		
     		log.info(str.getBytes().length);
     		
     		service.addDate(str);
     	}
     	
     }
     
     ```

     