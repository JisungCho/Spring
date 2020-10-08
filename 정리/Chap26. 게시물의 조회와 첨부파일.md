# Chap26. 게시물의 조회와 첨부파일

- 게시물의 정보는 tbl_board테이블에 기록 , 첨부파일의 정보는 tbl_attach에 기록되어있기 때문에 화면에서 두 테이블에 있는 정보를 사용하기 위해서는 다음과 같은 방식 고려
  1. BoardVO객체를 가져올 때 join을 처리해서 한꺼번에 게시물과 첨부파일의 정보를 같이 처리
  2. jsp에서 첨부파일의 정보는 Ajax를 이용해서 처리

1. BoardService와 BoardController 수정

   - BoardService

     ```java
     package org.zerock.service;
     
     import java.util.List;
     
     import org.zerock.domain.BoardAttachVO;
     import org.zerock.domain.BoardVO;
     import org.zerock.domain.Criteria;
     
     public interface BoardService {
     	....
     	....
     	...
     	public List<BoardAttachVO> getAttachList(Long bno);
     }
     ```

   - BoardServiceImpl

     ```java
     
     	@Override
     	public List<BoardAttachVO> getAttachList(Long bno) {
     
     		log.info("get Attach list by bno"+bno);
     		
     		return attachMapper.findByBno(bno);
     	}
     ```

### BoardController의 변경과 화면 처리

- BoardController

  ```java
  	@GetMapping(value = "/getAttachList" ,produces = MediaType.APPLICATION_JSON_UTF8_VALUE)
  	@ResponseBody
  	public ResponseEntity<List<BoardAttachVO>> getAttachList(Long bno){
  		
  		log.info("getAttachList : "+bno);
  		
  		return new ResponseEntity<List<BoardAttachVO>>(service.getAttachList(bno), HttpStatus.OK);
          //List<BoardAttachVO>반환
  	}
  ```

1. 게시물 조회 화면의 처리

   - get.jsp

     ```jsp
     <script>
      $(document).ready(function() {
     	(function() { //즉시실행함수
     		
     		var bno = "${board.bno}";
     		
     		$.getJSON("/board/getAttachList", {bno : bno}, function(arr) { //JSON데이터 읽어오기
     			console.log(arr);
     			
     		});
     	})();
     })
     </script>
     ```

     ```JSP
     <style>
     .uploadResult {
     	width: 100%;
     	background-color: gray;
     }
     
     .uploadResult ul {
     	display: flex;
     	flex-flow: row;
     	justify-content: center;
     	align-items: center;
     }
     
     .uploadResult ul li {
     	list-style: none;
     	padding: 10px;
     	align-content: center;
     	text-align: center;
     }
     
     .uploadResult ul li img {
     	width: 100px;
     }
     
     .uploadResult ul li span{
     	color:white;
     }
     
     .bigPictureWrapper{
     	position: absolute;
     	display: none;
     	justify-content: center;
     	align-items: center;
     	top: 0%;
     	width: 100%;
     	height: 100%;
     	background-color: gray;
     	z-index: 100;
     	background: rgba(255,255,255,0.5);
     }
     .bigPicture{
     	position: relative;
     	display: flex;
     	justify-content: center;
     	align-items: center;
     }
     
     .bigPicture img{
     	width:600px;
     }
     </style>
     
     
     <div class="bigPictureWrapper">
     	<div class="bigPicture">
     	</div>
     </div>
     <div class="row">
     	<div class="col-lg-12">
     		<div class="panel panel-default">
     			<div class="panel-heading">Files</div>
     			<div class="panel-body">
     				<div class="uploadResult">
     					<ul>
     					</ul>
     				</div>
     			</div>
     		</div>
     	</div>
     </div>
     ```

2. 첨부파일 보여주기

   - get.jsp

     ```jsp
     <script>
      $(document).ready(function() {
     	(function() {
     		
     		var bno = "${board.bno}";
     		
     		$.getJSON("/board/getAttachList", {bno : bno}, function(arr) {
     			console.log(arr);
     			
     			var str = "";
     			
     			$(arr).each(function(i,attach) {
     				//image Type
     				if(attach.fileType){ //이미지이면
     					var fileCallPath = encodeURIComponent(attach.uploadPath+"/s_"+attach.uuid+"_"+attach.fileName);
     					
     					str += "<li data-path='"+attach.uploadPath+"'";
     					str += " data-uuid='"+attach.uuid+"' data-filename='"+attach.fileName+"' data-type='"+attach.image+"'><div>";
     					str += "<img src='/display?fileName="+fileCallPath+"'>";
     					str += "</div>";
     					str += "</li>";
     				}else{ //이미지가아니면
     					str += "<li data-path='"+attach.uploadPath+"'";
     					str += " data-uuid='"+attach.uuid+"' data-filename='"+attach.fileName+"' data-type='"+attach.image+"'><div>";
     					str += "<span>"+attach.fileName+"</span><br/>";
     					str += "<img src='/resources/img/attach.png'>";
     					str += "</div>";
     					str += "</li>";
     				}
     			});
     			$(".uploadResult ul").html(str);
     		});
     	})();
     })
     </script>
     ```

3. 첨부파일 클릭 시 이벤트 처리

   ```js
   		function showImage(fileCallPath) {
   			alert(fileCallPath);
   			
   			$(".bigPictureWrapper").css("display","flex").show();
   			
   			$(".bigPicture").html("<img src='/display?fileName="+fileCallPath+"'>").animate({width: "100%", height: "100%"}, 1000);			
   		
   		}
   		
   		
   		$(".uploadResult").on("click","li",function(e){
   			
   			console.log("view Image");
   			
   			var liObj = $(this);
   			
   			var path = encodeURIComponent(liObj.data("path")+"/"+liObj.data("uuid")+"_"+liObj.data("filename"));
   			
   			if(liObj.data("type")){ //이미지이면 원본 이미지보여줌
   				showImage(path.replace(new RegExp(/\\/g),"/"));
   			}else{ //파일 다운로드
   				self.location = "/download?fileName"+path;
   			}
   		})
   ```

4. 원본 이미지창 닫기

   ```js
   			$(".bigPictureWrapper").on("click",function(e){
   				$(".bigPicture").animate({width: "0%", height: "0%"}, 1000);
   				setTimeout(function() {
   					$(".bigPictureWrapper").hide();
   				}, 1000);
   			})
   ```

   

