# Chap16. REST 방식으로 전환

- REST (Representational State Transfer)

  - **하나의 URI는 하나의 고유한 리소스(Resource)를 대표하도록 설계된다는 개념 + 전송방식 을 결합해서 원하는 작업을 지정**

    ![image](https://user-images.githubusercontent.com/52770718/95042217-25cf1200-0714-11eb-9068-40714ddcfb8f.png)

    - URI vs URL
      - URL : 이 곳에 가면 당신이 원하는 것을 찾을 수 있다.
      - URI : 당신이 원하는 곳의 주소는 여기입니다.(현실적이고 구체적)

  - **스프링은 @RequestMapping이나 @ResponseBody와 같이 REST 방식의 데이터 처리를 위한 여러 종류의 어노테이션 기능이 있다.**

    - @ResetController 
      - Controller가 REST 방식을 처리하기 위한 것임을 명시
    - @ResponseBody
      - 일반적인 JSP와 같은 뷰로 전달되는 게 아니라 데이터 자체를 전달하기 위한 용도
    - @PathVariable
      - URL 경로에 있는 값을 파라미터로 추출하려고 할 때 사용
    - @CrossOrigin
      - Ajax의 도메인 문제 해결
    - @RequestBody
      - JSON 데이터를 원하는 타입으로 바인딩 처리

### @ResetController

- **서버에 전송하는 것이 순수한 데이터**
- **기존의 Controller에서 Model에 데이터를 담아서 JSP와 같은 뷰로 전달하는 방식이 아니므로 기존의 Controller와는 조금 다르게 동작**
- **@Controller와 메서드 선언부에 @ResponseBody 를 이용해서 동일한 결과를 만들 수 있음**
- **메서드의 리턴 타입으로 사용자가 정의한 클래스 타입을 사용할 수 있고, 이를 JSON이나 XML로 자동으로 처리할 수 있다.**

- JSON
  - 구조가 있는 데이터를 { }로 묶고 키와 값으로 구성하는 경량의 데이터 포멧
- Jackson 라이브러리 추가

### @ResetController의 반환 타입

- SampleController 생성

  ```JAVA
  package org.zerock.controller;
  
  import java.util.HashMap;
  import java.util.List;
  import java.util.Map;
  import java.util.stream.Collectors;
  import java.util.stream.IntStream;
  
  import org.springframework.http.HttpStatus;
  import org.springframework.http.MediaType;
  import org.springframework.http.ResponseEntity;
  import org.springframework.web.bind.annotation.GetMapping;
  import org.springframework.web.bind.annotation.PathVariable;
  import org.springframework.web.bind.annotation.PostMapping;
  import org.springframework.web.bind.annotation.RequestBody;
  import org.springframework.web.bind.annotation.RequestMapping;
  import org.springframework.web.bind.annotation.RestController;
  import org.zerock.domain.SampleVO;
  import org.zerock.domain.Ticket;
  
  import lombok.extern.log4j.Log4j;
  
  @RestController //REST방식
  @RequestMapping("/sample")
  @Log4j
  public class SampleController {
  	
  }
  
  ```

1. 단순 문자열 반환

   - 주로 일반 문자열이나 JSON , XML등을 반환

   ```java
   package org.zerock.controller;
   
   import java.util.HashMap;
   import java.util.List;
   import java.util.Map;
   import java.util.stream.Collectors;
   import java.util.stream.IntStream;
   
   import org.springframework.http.HttpStatus;
   import org.springframework.http.MediaType;
   import org.springframework.http.ResponseEntity;
   import org.springframework.web.bind.annotation.GetMapping;
   import org.springframework.web.bind.annotation.PathVariable;
   import org.springframework.web.bind.annotation.PostMapping;
   import org.springframework.web.bind.annotation.RequestBody;
   import org.springframework.web.bind.annotation.RequestMapping;
   import org.springframework.web.bind.annotation.RestController;
   import org.zerock.domain.SampleVO;
   import org.zerock.domain.Ticket;
   
   import lombok.extern.log4j.Log4j;
   
   @RestController //REST방식
   @RequestMapping("/sample")
   @Log4j
   public class SampleController {
   	// produces : 해당 메서드가 생산하는 MIME 타입
   	@GetMapping(value = "/getText" ,produces = "text/plain; charset=UTF-8")
   	public String getText() {
   		log.info("MIMETYPE : "+MediaType.TEXT_PLAIN_VALUE);
   		
   		return "안녕하세요";
   	}
   }
   
   ```

2. 객체의 반환

   - 객체를 반환하는 작업은 JSON이나 XML을 이용

     - SampleVO

       ```java
       package org.zerock.domain;
       
       import lombok.AllArgsConstructor;
       import lombok.Data;
       import lombok.NoArgsConstructor;
       
       @Data
       @AllArgsConstructor // 비어 있는 생성자
       @NoArgsConstructor // 모든 속성을 사용하는 생성자
       public class SampleVO {
       	private Integer mno;
       	private String firstName;
       	private String lastName;
       }
       
       ```

     - SampleController

       ```java
       	//MIME타입은 JSON,UTF-8 , XML
       	@GetMapping(value = "/getSample", produces = { MediaType.APPLICATION_JSON_UTF8_VALUE,
       			MediaType.APPLICATION_XML_VALUE })
       	public SampleVO getSample() {
       		return new SampleVO(112, "스타", "로드");
       	}
       ```

3. 컬렉션 타입의 객체 반환

   - 여러 데이터를 한 번에 전송하기 위해서 배열이나 리스트, 맵 타입의 객체를 전송

     - 리스트

     ```JAVA
     	@GetMapping("/getList")
     	public List<SampleVO> getList() {
     		return IntStream.range(1, 10) //1부터 9
                 .mapToObj(i -> new SampleVO(i, i + "First", i + "Last")) 
     			.collect(Collectors.toList());
     	}
     ```

     - 맵

     ```java
     	@GetMapping("/getMap")
     	public Map<String, SampleVO> getMap() {
     
     		Map<String, SampleVO> map = new HashMap<String, SampleVO>();
     		map.put("First", new SampleVO(111, "그루트", "주니어"));
     		map.put("Second", new SampleVO(112, "토니", "스타크"));
     
     		return map;
     	}
     ```

4. ResponseEntity

   - 데이터와 함께 HTTP 헤더의 상태 메세지 등을 같이 전달하는 용도로 사용

     - SampleController

     ```java
     	//반드시 height , weight를 파라미터로 받아야함
     	@GetMapping(value = "/check", params = { "height", "weight" })
     	public ResponseEntity<SampleVO> check(Double height, Double weight) {
     		SampleVO vo = new SampleVO(0, "" + height, "" + weight);
     
     		ResponseEntity<SampleVO> result = null;
     
     		if (height < 150) {
                 //헤더와 바디
     			result = ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(vo);
     		} else {
                 //헤더와 바디
     			result = ResponseEntity.status(HttpStatus.OK).body(vo);
     		}
     
     		return result;
     	}
     ```

### @ ResetController에서 파라미터

- 기존의 @Controller에서 사용하던 일반적인 타입이나 사용자가 정의한 타입을 사용하고 추가로 어노테이션을 사용할 수 있음
  - @PathVariable : 일반 컨트롤러에서도 사용이 가능하지만 REST방식에서 자주 사용 , URL경로의 일부를 파라미터로 사용할 떄
  - @RequestBody : JSON 데이터를 원하는 타입의 객체로 변환해야 하는 경우

1. @PathVariable

   - URL경로의 일부를 파라미터로 사용할 떄
   - URL에서 { }로 처리된 부분은 컨트롤러의 메서드에서 변수로 처리가 가능
   - 값을 얻을 떄는 int , double 같은 기본 자료형은 사용할 수 없음

   ```JAVA
   	@GetMapping("/product/{cat}/{pid}")
   	public String[] getPath(@PathVariable("cat") String cat, @PathVariable("pid") Integer pid) {
   
   		return new String[] { "category: " + cat, "productid:" + pid };
   	}
   ```

2. @RequestBody

   - 전달된 요청의 내용을 이용해서 해당 파라미터의 타입으로 변환을 요구
   - 대부분의 경우에는 JSON 데이터를 서버에 보내서 원하는 타입의 객체로 변환하는 용도로 사용

   ```JAVA
   package org.zerock.domain;
   
   import lombok.Data;
   
   @Data
   public class Ticket {
   	private int tno;
   	private String owner;
   	private String grade;
   }
   
   ```

   ```java
   	@PostMapping("/ticket")
   	public Ticket convert(@RequestBody Ticket ticket) { //HttpBody에 담겨있는 데이터를 처리하기 떄문에 post방식
   
   		log.info("covert....ticket" + ticket);
   
   		return ticket;
   	}
   ```

### REST방식의 테스트

```JAVA
	@Test
	public void testConvert() throws Exception{
		Ticket ticket = new Ticket();
		ticket.setTno(123);
		ticket.setOwner("Admin");
		ticket.setGrade("AAA");
		
		String jsonStr = new Gson().toJson(ticket); //JAVA객체를 JSON데이터로 변환
		
		log.info(jsonStr);
		
		mockMvc.perform(post("/sample/ticket").contentType(MediaType.APPLICATION_JSON).content(jsonStr))
		.andExpect(status().is(200));
	}
```

### 다양한 전송방식

![image](https://user-images.githubusercontent.com/52770718/95045403-f40e7900-071c-11eb-8bab-2cb5f9f87759.png)

