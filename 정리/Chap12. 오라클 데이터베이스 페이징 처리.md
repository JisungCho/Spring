# Chap12. 오라클 데이터베이스 페이징 처리

- 페이징 처리
  1. 번호를 이용하거나
  2. 계속 보기 형태

### order by의 문제

- 데이터가 많을 수록 정렬이라는 작업은 많은 리소스를 소모함
- 데이터베이스를 이용할 때 웹,애플리케이션에서 가장 신경쓰는 부분
  1. 빠르게 처리
  2. 필요한 양만큼 데이터를 가져옴
- 빠르게 동작하는 SQL을 위해서는 먼저 order by를 이용하는 작업은 가능하면 하지 말아야한다.
  1. 데이터가 적은경우 사용
  2. 정렬을 빠르게 할 수 있는 방법이 있는 경우 사용

1. 실행 계획과 order by
   - 실행 계획 : SQL을 데이터베이스에서 어떻게 처리 할 것인가?
   - SQL 처리 과정
     1. SQL 파싱
        - SQL 구문오류 판단
        - SQL 대상 객체 존재 검사
     2. SQL 최적화
        - SQL이 실행 되는데 필요한 비용
        - 비용을 기준으로 실행 계획을 세워서 실행
     3. SQL 실행 
        - 실행 계획을 통해서 메모리상에서 데이터를 읽거나 물리적인 공간에서 데이터를 로딩
   - 실행 계획을 세우는 것은 데이터베이스에서 하는 역활이기 때문에 데이터의 양이나 제약 조건 등의 여러 상황에 따라서 데이터베이스는 실행 계획을 다르게 작성

### order by 보다는 인덱스

- 데이터가 많은 상태에서 정렬 작업이 문제가 된다 이 문제를 해결하기위해서 인덱스(index)를 사용
- 인덱스는 이미 정렬된 구조이므로 이를 이용해서 별도의 정렬을 하지 않는다.

```sql
select /*+ INDEX_DESC(tbl_board pk_board)*/ * from tbl_board where bno > 0;
```

![image](https://user-images.githubusercontent.com/52770718/94983987-80386900-0582-11eb-9e6e-87acc12bbb3c.png)

- 특징 
  1. SORT를 하지않았다
  2. TBL_BOARD를 바로 접근하는 것이 아니라 PK_BOARD를 이용해서 접근
  3. RANGE SCAN DESCENDING , BY INDEX ROWID로 접근

1. PK_BOARD라는 인덱스

   ```sql
   alter table tbl_board add constraint pk_board primary key(bno);
   ```

   - 데이터베이스에서 PK는 식별자의 의미와 인덱스의 의미를 가짐
   - 인덱스와 실제 테이블을 연결하는 고리는 ROWID라는 존재, ROWID는 데이터베이스 내의 주소에 해당하는데 모든 데이터는 자신만의 주소를 가지고 있음

### 인덱스를 이용하는 정렬

- 인덱스에서 가장 중요한 개념 중 하나는 정렬이 되어 있다는 점
- 따라서 SORT하는 과정을 생략할 수 있음

1.  인덱스와 오라클 힌트

   - 오라클은 select문을 전달할 때 힌트라는 것을 사용
     - 힌트는 말 그래도 select문을 이렇게 실행해 주면 좋겠습니다라는 힌트
     - 따라서 힌트를 이용한 select문을 작성한 후에는 실행 계획을 통해서 개발자가 원하는 대로 SQL이 실행되는지를 확인하는 습관을 가져야함
     - 강제성이 부여됨

2. 힌트 사용 문법

   - 힌트 구문은 /*+로 시작하고  */로 마무리된다. 힌트 자체는 SQL로 처리되지 않기 때문에 위의 그림처럼 뒤칼럼명이 나오더라도 별도의 ,로 처리되지 않는다

3. FULL 힌트

   - 힌트 중에서 SELECT문을 실행할 때 테이블 전체를 스캔할 것으로 명시하는 힌트

     ```sql
     SELECT /*+FULL(tbl_board)*/ * from tbl_board order by bno desc;
     ```

4. INDEX_ASC , INDEX_DESC 힌트

   - 인덱스를 순서대로 이용할것인지 역순으로 이용할 것인지를 지정

   - order by를 위해서 사용

     ```sql
     select /*+ INDEX_ASC(tbl_board pk_board) */ * from tbl_board where bno > 0;
     ```

### ROWNUM과 인라인뷰

- 전체가 아닌 필요한 만큼의 데이터를 가져오는 방식
- 오라클 데이터베이스는 페이지 처리를 위해서 ROWNUM이라는 특별한 키워드를 사용해서 데이터에 순번을 붙여 사용 => SQL이 실행된 결과에 넘버링을 해줌
- ROWNUM은 실제 데이터가 아니라 테이블에서 데이터를 추출한 후에 처리되는 변수이므로 상황에 따라 그 값이 매번 달라질 수 있다.

1. 인덱스를 이용한 접근 시 ROWNUM

   1. PK_BOARD 인덱스를 통해서 테이블에 접근
   2. 접근한 데이터에 ROWNUM 부여

2. 페이지 번호 1,2의 데이터

   - ```sql
     select /*+ INDEX_DESC(tbl_board pk_board) */ rownum rn,bno,title,content from tbl_board where rownum>10 and rownum <=20;
     ```

   - SQL을 작성할 때 ROWNUM 조건은 반드시 1이 포함

     ```sql
     select /*+ INDEX_DESC(tbl_board pk_board) */ rownum rn,bno,title,content from tbl_board where rownum<=20
     ```

### 인라인뷰 처리

- select문 안쪽 from에서 다시 select문

```sql
select bno,title,content
from (
	select /* + INDEX_DESC(tbl_board pk_board) */
		rownum rn,bno,titke,content
	from tbl_board
	where rownum <= 20
)
where rn >10;
```

- 필요한 순서로 정렬된 데이터에 ROWNUM을 붙인다.
- 처음부터 해당 페이지의 데이터를 ROWNUM<30과 같은 조건을 이용해서 구한다.
- 구해놓은 데이터를 하나의 테이블처럼 간주하고 인라인뷰로 처리
- 인라인뷰에서 필요한 데이터만을 남긴다.