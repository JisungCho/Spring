# Chap10. 프레젠테이션 계층의 CRUD구현

### Controller의 작성

- 스프링 MVC의 Controller는 하나의 클래스 내에서 여러 메서드를 작성하고, @requestMapping등을 이용해서 URL을 분기하는 구조로 작성할 수 있다.

1. BoardController 분석

   ![image](https://user-images.githubusercontent.com/52770718/94511638-d6d93680-0254-11eb-9909-7fdcfb1d6ad7.png)

### BoardController의 작성

- ```java
  package org.zerock.controller;
  
  import org.springframework.stereotype.Controller;
  import org.springframework.ui.Model;
  import org.springframework.web.bind.annotation.GetMapping;
  import org.springframework.web.bind.annotation.ModelAttribute;
  import org.springframework.web.bind.annotation.PostMapping;
  import org.springframework.web.bind.annotation.RequestMapping;
  import org.springframework.web.bind.annotation.RequestParam;
  import org.springframework.web.servlet.mvc.support.RedirectAttributes;
  import org.zerock.domain.BoardVO;
  import org.zerock.domain.Criteria;
  import org.zerock.domain.PageDTO;
  import org.zerock.service.BoardService;
  
  import lombok.AllArgsConstructor;
  import lombok.extern.log4j.Log4j;
  
  @Controller
  @Log4j
  @RequestMapping("/board/*")
  @AllArgsConstructor
  public class BoardController {
  	
  	
  }
  
  ```

1. 목록에 대한 처리와 테스트

   - ```java
     package org.zerock.controller;
     
     import org.springframework.stereotype.Controller;
     import org.springframework.ui.Model;
     import org.springframework.web.bind.annotation.GetMapping;
     import org.springframework.web.bind.annotation.ModelAttribute;
     import org.springframework.web.bind.annotation.PostMapping;
     import org.springframework.web.bind.annotation.RequestMapping;
     import org.springframework.web.bind.annotation.RequestParam;
     import org.springframework.web.servlet.mvc.support.RedirectAttributes;
     import org.zerock.domain.BoardVO;
     import org.zerock.domain.Criteria;
     import org.zerock.domain.PageDTO;
     import org.zerock.service.BoardService;
     
     import lombok.AllArgsConstructor;
     import lombok.extern.log4j.Log4j;
     
     @Controller
     @Log4j
     @RequestMapping("/board/*")
     @AllArgsConstructor //자동주입하기 위해 사용
     public class BoardController {
     	
     	//변수가 하나인 경우 자동주입됨 , 생성자를 통해서
         //의존성 처리
     	private BoardService service;
     	
     	@GetMapping("/list")
     	public void list(Model model) {
     		log.info("list: ");
             //게시글 목록을 model에 담아서 전달
     		model.addAttribute("list",service.getList());
     	}// list.jsp로 이동
     }
     
     ```

   - Tomcat을 실행하지 않고도 스프링과 웹 url을 테스트 할 수 있음

     - ```java
       package org.zerock.controller;
       
       import org.junit.Before;
       import org.junit.Test;
       import org.junit.runner.RunWith;
       import org.springframework.beans.factory.annotation.Autowired;
       import org.springframework.test.context.ContextConfiguration;
       import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
       import org.springframework.test.context.web.WebAppConfiguration;
       import org.springframework.test.web.servlet.MockMvc;
       import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
       import org.springframework.test.web.servlet.setup.MockMvcBuilders;
       import org.springframework.web.context.WebApplicationContext;
       
       import lombok.Setter;
       import lombok.extern.log4j.Log4j;
       
       @RunWith(SpringJUnit4ClassRunner.class)
       @WebAppConfiguration //Servlet의 ServletContext를 이용하기 위해서 설정
       @ContextConfiguration({
       	"file:src/main/webapp/WEB-INF/spring/appServlet/servlet-context.xml",
       	"file:src/main/webapp/WEB-INF/spring/root-context.xml"
       })
       @Log4j
       public class BoardControllerTests {
       	
       	@Setter(onMethod_ = {@Autowired} )
       	private WebApplicationContext ctx;
       	
       	private MockMvc mockMvc; //가짜 mvc, 가짜로 URL과 파라미터등을 브라우저에서 사용하는 것처럼 만들어서 Controller를 실행
       	
       	@Before //모든 테스트전에 매번 실행되는 메서드로 지정
       	public void setup() {
       		this.mockMvc = MockMvcBuilders.webAppContextSetup(ctx).build();
       	}
       	
       	@Test 
       	public void testList() throws Exception{
       		log.info(
                   	//get방식 호출
       				mockMvc.perform(MockMvcRequestBuilders.get("/board/list"))
       				.andReturn()
       				.getModelAndView()
       				.getModelMap()); //모델에 어떤 데이터가 담겨 있는지 확인
       	}
       	
       }
       
       ```

2. 등록 처리와 테스트

   - ```java
     	@PostMapping("/register")
     	public String register(BoardVO board, RedirectAttributes rttr) {
     		log.info("register: "+board);
     		
     		service.register(board);
     		
     		rttr.addFlashAttribute("result", board.getBno()); //등록된 게시물의 번호 전달
     		
     		return "redirect:/board/list"; //response.sendredirect와 같은 역활
     	}
     ```

     ```java
     	@Test
     	public void testRegister() throws Exception{
     		String resultPage = 	        mockMvc.perform(MockMvcRequestBuilders.post("/board/register")//post방식 호출
             .param("title", "테스트 새글 제목") //파라미터 전달
             .param("content", "테스트 새글 내용")
             .param("writer", "user00"))
             .andReturn().getModelAndView().getViewName();
     		
     		log.info(resultPage);
     	}
     ```

3. 조회 처리와 테스트

   - ```java
     	@GetMapping("/get")
     	public void get(@RequestParam("bno") Long bno, Model model) {
     		
     		log.info("/get");
     		model.addAttribute("board",service.get(bno));
     	}
     ```

     ```java
     	@Test
     	public void testGet() throws Exception{
     		log.info(
     			mockMvc.perform(MockMvcRequestBuilders.get("/board/get")
     			.param("bno", "1"))
                 .andReturn().getModelAndView().getModelMap());	
     	}
     ```

4. 수정 처리와 테스트

   - ```java
     	@PostMapping("/modify")
     	public String modify(BoardVO board,RedirectAttributes rttr) {
     		log.info("modify.."+board);
     		
     		if(service.modify(board)) { //수정이 되었으면
     			rttr.addFlashAttribute("result", "success"); //success를 전달
     		}
     		return "redirect:/board/list";
     	}
     ```

     ```java
     	@Test
     	public void testModify() throws Exception{
     		String resultPage = mockMvc.perform(MockMvcRequestBuilders.post("/board/modify")
     				.param("bno", "1")
     				.param("title", "수정된 테스트 새글 제목")
     				.param("content", "수정된 테스트 새글 내용")
     				.param("writer", "user00"))
     				.andReturn().getModelAndView().getViewName();
     		log.info(resultPage);
     	}
     ```

5. 삭제 처리와 테스트

   - ```java
     	@PostMapping("/remove")
     	public String remove(@RequestParam("bno") Long bno,RedirectAttributes rttr) {
     		log.info("remove...."+bno);
     		if(service.remove(bno)) { //삭제가 성공했으면
     			rttr.addFlashAttribute("result", "success");
     		}
     		return "redirect:/board/list";
     	}
     ```

     ```java
     	@Test
     	public void testRemove() throws Exception{
     		
     		String resultPage = mockMvc.perform(MockMvcRequestBuilders.post("/board/remove")
                 .param("bno", "1"))
                 .andReturn().getModelAndView().getViewName();
     		
     		log.info(resultPage);
     	}
     ```

     

