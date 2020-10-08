# Chap25. 프로젝트의 첨부파일-등록

### 첨부파일 정보를 위한 준비

- 가장 먼저 진행해야 하는 일은 게시물과 첨부파일의 관계를 저장하는 테이블 설계

- 게시물을 등록할 때 첨부파일 테이블 역시 같이 insert 작업이 진행되어야하므로 트랜잭션 처리가필요

  ```sql
  create table tbl_attach(
  	uuid varchar2(100) not null,
  	uploadPath varchar2(200) not null,
  	fileName varchar2(100) not null,
  	filetype char(1) default 'I',
  	bno number(10,0)
  );
  
  alter table tbl_attach add constraint pk_attach primary key(uuid);
  
  alter table tbl_attach add constraint fk_board_attach foreign key (bno) refererncess tbl_board(bno);
  ```

- BoardAttachVO

  ```java
  package org.zerock.domain;
  
  import lombok.Data;
  
  @Data
  public class BoardAttachVO {
  	private String uuid; // UUID가 포함된 이름
  	private String uploadPath; // 실제 파일이 업로드된경로
  	private String fileName; //파일이름 
  	private boolean fileType; //이미지인지 아닌지
  	
  	private Long bno; //해당 게시물 번호
  }
  
  ```

- BoardVO

  ```java
  package org.zerock.domain;
  
  import java.util.Date;
  import java.util.List;
  
  import org.springframework.format.annotation.DateTimeFormat;
  
  import lombok.Data;
  
  @Data
  public class BoardVO {
  	private Long bno;
  	private String title;
  	private String content;
  	private String writer;
  	
  	@DateTimeFormat(pattern = "yyyy-MM-dd")
  	private Date regdate;
  	@DateTimeFormat(pattern = "yyyy-MM-dd")
  	private Date updateDate;
  	
  	private int replyCnt;
  	
  	private List<BoardAttachVO> attachList;
  }
  
  ```

1. 첨부파일 처리를 위한 Mapper처리

   - BoardAttachMapper 인터페이스

     ```
     package org.zerock.mapper;
     
     import java.util.List;
     
     import org.zerock.domain.BoardAttachVO;
     
     public interface BoardAttachMapper {
     	public void insert(BoardAttachVO vo);
     	
     	public void delete(String uuid);
     	
     	public List<BoardAttachVO> findByBno(Long bno);
     
     }
     ```

   - BoardAttachMapper.xml

     ```xml
     <?xml version="1.0" encoding="UTF-8" ?>
     <!DOCTYPE mapper
       PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
       "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
     <mapper namespace="org.zerock.mapper.BoardAttachMapper">
     	<insert id="insert">
     		insert into tbl_attach(uuid,uploadPath,filename,filetype,bno)
     		values(#{uuid},#{uploadPath},#{fileName},#{fileType},#{bno})
     	</insert>
     	
     	<delete id="delete">
     		delete from tbl_attach where uuid = #{uuid}
     	</delete>
     	
     	<select id="findByBno" resultType="org.zerock.domain.BoardAttachVO">
     		select * from tbl_attach where bno = #{bno}
     	</select>
     </mapper>
     ```

     

### 등록을 위한 화면처리

- register.jsp

  ```jsp
  <!-- /.row -->
  <div class="row">
  	<div class="col-lg-12">
  		<div class="panel panel-default">
  			<div class="panel-heading">File Attach</div>
  			<!-- /.panel-heading -->
  			<div class="panel-body">
  				<div class="form-group uploadDiv">
  					<input type="file" name="uploadFile" multiple="multiple">
  				</div>
  				<div class="uploadResult">
  					<ul>
  					</ul>
  				</div>
  			</div>
  		</div>
  	</div>
  </div>
  ```

1. JavaScript처리

   ```js
   <script>
   	$(document).ready(function(e){
       	var formObj = $("from[role='form']");
       	
       $("button[type='submit']").on("click",function(e){
           e.preventDefault();
           
           console.log("submit clicked");
       }); 
   });
   </script>
   ```

   ```js
   var regex = new RegExp("(.*?)\.(exe|sh|zip|alz)$");
   var maxSize = 5242880; //5mb
   
   		function checkExtension(fileName,fileSize) {
   			if(fileSize >= maxSize){
   				alert("파일 사이즈 초과 ");
   				return false;
   			}
   			if(regex.test(fileName)){
   				alert("해당종류의 파일은 업로드할 수 없습니다.");
   				return false;
   			}
   			return true;
   		}
   
   $("input[type=\'file\']").change(function(e) { //파일을 첨부할때
   		    var formData = new FormData();
   		    var inputFile = $("input[name='uploadFile']");
   		    var files = inputFile[0].files;
   		    
   		    for(var i = 0; i < files.length; i++){
   		      if(!checkExtension(files[i].name, files[i].size) ){
   		        return false;
   		      }
   		      formData.append("uploadFile", files[i]);
   		    }
   			
   			
   			$.ajax({
   				url:'/uploadAjaxAction',
   				processData: false,
   				contentType: false,
   				data:formData,
   				type: "POST",
   				dataType: 'json',
   				success: function(result) {
   					console.log(result);
   					showUploadResult(result);
   				}
   			});
   		});
   
   function showUploadResult(uploadResultArr){
   			if(!uploadResultArr || uploadResultArr.length == 0){ //파일이없으면 함수 빠져나감
   				return;
   			}
   			var uploadUL = $(".uploadResult ul");
   			var str = "";
       
   			$(uploadResultArr).each(function(i,obj){ //첨부파일 목록
   				if(obj.image){ //이미지인경우
   					var fileCallPath = encodeURIComponent(obj.uploadPath+"/s_"+obj.uuid+"_"+obj.fileName);
   					
   					str += "<li><div>";
   					str += "<span> "+obj.fileName+"</span>";
   					str += "<button type='button' data-file=\'"+fileCallPath+"\' data-type='image' class='btn btn-warning btn-circle'>";
   					str += "<i class='fa fa-times'></i></button></br>";
   					str += "<img src='/display?fileName="+fileCallPath+"'>";
   					str += "</div>";
   					str += "</li>";
   					
   				}else{ //이미지가 아닌 경우
   					var fileCallPath = encodeURIComponent(obj.uploadPath+"/"+obj.uuid+"_"+obj.fileName);
   					var fileLink = fileCallPath.replace(new RegExp(/\\/g),"/");
   					
   					str += "<li data-path='"+obj.uploadPath+"'";
   					str += " data-uuid='"+obj.uuid+"' data-filename='"+obj.fileName+"' data-type='"+obj.image+"'><div>";
   					str += "<a><button type='button' data-file=\'"+fileCallPath+"\' data-type='file' class='btn btn-warning btn-circle'>";
   					str += "<i class='fa fa-times'></i></button></br>";
   					str += "<img src='/resources/img/attach.png'></a>";
   					str += "</div>";
   					str += "</li>";
   				}
   			});
   			uploadUL.append(str);
   		}
   ```

   ```js
   $(".uploadResult").on("click","button",function(e){
   			console.log("delete file");
   			
   			var targetFile = $(this).data("file");
   			var type = $(this).data("type");
   			
   			var targetLi = $(this).closest("li");
   			
   			$.ajax({
   				url:'/deleteFile',
   				data : {
   					fileName : targetFile,
   					type: type
   				},
   				dataType: 'text',
   				type:'POST',
   				success:function(result){
   					alert(result);
   					targetLi.remove();
   				}
   			});
   		});
   ```

2. 게시물의 등록과 첨부파일의 데이터베이스 처리

   - 게시물이 등록될 때 첨부파일과 관련된 자료를 같이 전송하고 이를 데이터베이스에 업로드

   ```js
   			$(uploadResultArr).each(function(i,obj){
   				if(obj.image){
   					var fileCallPath = encodeURIComponent(obj.uploadPath+"/s_"+obj.uuid+"_"+obj.fileName);
   					
   					str += "<li data-path='"+obj.uploadPath+"'";
   					str += " data-uuid='"+obj.uuid+"' data-filename='"+obj.fileName+"' data-type='"+obj.image+"'><div>";
   					str += "<span> "+obj.fileName+"</span>";
   					str += "<button type='button' data-file=\'"+fileCallPath+"\' data-type='image' class='btn btn-warning btn-circle'>";
   					str += "<i class='fa fa-times'></i></button></br>";
   					str += "<img src='/display?fileName="+fileCallPath+"'>";
   					str += "</div>";
   					str += "</li>";
   					
   				}else{
   					var fileCallPath = encodeURIComponent(obj.uploadPath+"/"+obj.uuid+"_"+obj.fileName);
   					var fileLink = fileCallPath.replace(new RegExp(/\\/g),"/");
   					
   					str += "<li data-path='"+obj.uploadPath+"'";
   					str += " data-uuid='"+obj.uuid+"' data-filename='"+obj.fileName+"' data-type='"+obj.image+"'><div>";
   					str += "<a><button type='button' data-file=\'"+fileCallPath+"\' data-type='file' class='btn btn-warning btn-circle'>";
   					str += "<i class='fa fa-times'></i></button></br>";
   					str += "<img src='/resources/img/attach.png'></a>";
   					str += "</div>";
   					str += "</li>";
   				}
   			});
   ```

   - register.jsp	

     ```js
     		$("button[type=\'submit\']").on("click",function(e){
     			e.preventDefault();
     			
     			console.log("submit clicked");
     			
     			var str = "";
     			
     			$(".uploadResult ul li").each(function(i,obj){
     
     				
     			      var jobj = $(obj); //순수한 DOM객체를 감싸고있는 객체
     			      
     			      console.dir(jobj);
     			      console.log("-------------------------");
     			      console.log(jobj.data("filename"));				
     				
     					
     					
     				 str += "<input type='hidden' name='attachList["+i+"].fileName' value='"+jobj.data("filename")+"'>";
     			     str += "<input type='hidden' name='attachList["+i+"].uuid' value='"+jobj.data("uuid")+"'>";
     			     str += "<input type='hidden' name='attachList["+i+"].uploadPath' value='"+jobj.data("path")+"'>";
     			     str += "<input type='hidden' name='attachList["+i+"].fileType' value='"+jobj.data("type")+"'>";
     			     
     			});
     			formObj.append(str).submit();
     		});
     ```

### BoardController , BoardService처리

- BoardController

  ```java
  	
  	@PostMapping("/register")
  	public String register(BoardVO board, RedirectAttributes rttr) {//BoardVO의 List<AttachBoardVO>에 set됨
  		log.info("=============================");
  		
  		log.info("register: "+board);
  		
  		if(board.getAttachList() != null) { //attachList 출력
  			board.getAttachList().forEach(attach -> log.info(attach));
  			
  		}
  		
  		//service.register(board);
  		
  		//rttr.addFlashAttribute("result", board.getBno());
  		
  		return "redirect:/board/list";
  	}
  ```

1. BoardServiceImple 처리

   ```java
   @Log4j
   @Service
   @AllArgsConstructor
   public class BoardServiceImpl implements BoardService {
   	
   	@Autowired
   	private BoardMapper mapper;
   	
   	@Autowired
   	private BoardAttachMapper attachMapper;
   	
   	@Transactional  //테이블 양쪽에 접근하기 때문에 트랜잭션 처리필요
   	@Override
   	public void register(BoardVO board) {
   		log.info("register........");
   		
   		mapper.insertSelectKey(board);
   		
   		if(board.getAttachList() == null || board.getAttachList().size() == 0) {
   			return;
   		}
   		
   		board.getAttachList().forEach(attach -> {
   			attach.setBno(board.getBno()); //해당 게시물번호 설정
   			attachMapper.insert(attach);
   		});
   	}
   ```

   