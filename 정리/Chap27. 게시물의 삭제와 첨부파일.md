# Chap27. 게시물의 삭제와 첨부파일

1. 첨부파일 삭제 처리

   - BoardAttachMapper

     ```java
     package org.zerock.mapper;
     
     import java.util.List;
     
     import org.zerock.domain.BoardAttachVO;
     
     public interface BoardAttachMapper {
     	public void insert(BoardAttachVO vo);
     	
     	public void delete(String uuid);
     	
     	public List<BoardAttachVO> findByBno(Long bno);
     	
     	public void deleteAll(Long bno);
     	
     }
     
     ```

   - BoardAttachMapper.xml

     ```xml
     	<delete id="deleteAll">
     		delete From tbl_attach where bno = #{bno}
     	</delete>
     <!--해당게시물 번호와같은 첨부파일은 모두삭제-->
     ```

   1. BoardServiceImpl의 변경

      ```java
      	@Transactional
      	@Override
      	public boolean remove(Long bno) {
      		log.info("remove......"+bno);
      		
      		attachMapper.deleteAll(bno);
      		return mapper.delete(bno) == 1;
      	}
      ```

   2. BoardController의 파일 삭제

      - 해당 게시물의 첨부파일 정보를 미리 준비

      - 데이터베이스 상에서 해당 게시물과 첨부파일 데이터 삭제

      - 첨부파일 목록을 이용해서 해당 폴더에서 섬네일 이미지와 일반 파일을 삭제

      - Criteria 수정

        ```java
        	public String getListLink() {
        		UriComponentsBuilder builder = UriComponentsBuilder.fromPath("")
        				.queryParam("pageNum", this.getPageNum())
        				.queryParam("amount", this.getAmount())
        				.queryParam("type", this.getType())
        				.queryParam("keyword", this.getKeyword());
        		return builder.toUriString();
        	}
        ```

      - 파일삭제처리

        - BoardController

          ```java
          	private void deleteFiles(List<BoardAttachVO> attachList) { //폴더에서 파일삭제
          		if(attachList == null || attachList.size() == 0) {
          			return;
          		}
          		
          		log.info("delete attach files............");
          		log.info(attachList);
          		
          		attachList.forEach(attach -> {
          			Path file = Paths.get("C:\\upload\\"+attach.getUploadPath()+"\\"+attach.getUuid()+"_"+attach.getFileName()); //원본파일가져오기
          			
          			try {
          				Files.deleteIfExists(file); // 파일삭제
          				
          				if(Files.probeContentType(file).startsWith("image")) { //이미지이면
          					Path thumbNail = Paths.get("C:\\upload\\"+attach.getUploadPath()+"\\s_"+attach.getUuid()+"_"+attach.getFileName()); //섬네일
          				
          					Files.delete(thumbNail); //섬네일 삭제
          				}
          			} catch (IOException e) {
          				log.error("delete file error " +e.getMessage());
          			}
          		});
          	}
          ```

          ```java
          	@PostMapping("/remove")
          	public String remove(@RequestParam("bno") Long bno,RedirectAttributes rttr,Criteria cri) {
          		log.info("remove...."+bno);
          		
          		List<BoardAttachVO> attachList = service.getAttachList(bno);
          		
          		if(service.remove(bno)) { //데이터베이스에서 삭제 성공
          			//delete Attach Files
          			deleteFiles(attachList); //실제폴더에서 파일삭제
          			
          			rttr.addFlashAttribute("result", "success");
          		}
          		return "redirect:/board/list"+cri.getListLink();
          	}
          ```

          

   