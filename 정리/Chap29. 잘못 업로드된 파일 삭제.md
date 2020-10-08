# Chap29. 잘못 업로드된 파일 삭제

- 첨부파일만을 등록하고 게시물을 등록하지 않았을때의 문제
- 게시물을 수정할 때 파일을 삭제했지만 실제로 폴더에서 기존 파일은 삭제되지 않은 문제

### 잘못 업로드된 파일의 정리

- 만일 사용자가 게시물을 등록하거나 수정하기 위해서 첨부파일을 등록했지만 ,최종적으로 submit 하지 않은 경우에는 폴더에 파일들은 업로드되지만 ,데이터베이스에는 아무런 변화가 없다.
  - 해결방법
    1. 어제 날짜로 등록된 첨부파일의 목록을 구한다
    2. 어제 업로드 되었지만 데이터베이스에는 존재하지 않는 파일들을 찾는다.
    3. 데이터베이스와 비교해서 필요없는 파일들을 삭제한다.
- 주기적으로 스케쥴링 할 수 있는 Quartz 라이브러리 사용

### Quartz 라이브러리 설정

- Quartz 라이브러리는 일반적으로 스케쥴러를 구성하기 위해서 사용

- pom.xml에 라이브러리 추가

  ```xml
  		<!-- https://mvnrepository.com/artifact/org.quartz-scheduler/quartz -->
  		<dependency>
  			<groupId>org.quartz-scheduler</groupId>
  			<artifactId>quartz</artifactId>
  			<version>2.3.0</version>
  		</dependency>
  		<!-- https://mvnrepository.com/artifact/org.quartz-scheduler/quartz-jobs -->
  		<dependency>
  			<groupId>org.quartz-scheduler</groupId>
  			<artifactId>quartz-jobs</artifactId>
  			<version>2.3.0</version>
  		</dependency
  ```

- root-context.xml에 네임스페이스에 task 항목 체크

- root-context.xml에 < task:anotation-driven>을 추가

1. Task 작업의 처리

   - FileCheckTask 클래스

     ```java
     package org.zerock.task;
     
     import java.io.File;
     import java.nio.file.Path;
     import java.nio.file.Paths;
     import java.text.SimpleDateFormat;
     import java.util.Calendar;
     import java.util.Date;
     import java.util.List;
     import java.util.stream.Collector;
     import java.util.stream.Collectors;
     
     import org.springframework.beans.factory.annotation.Autowired;
     import org.springframework.scheduling.annotation.Scheduled;
     import org.springframework.stereotype.Component;
     import org.zerock.domain.BoardAttachVO;
     import org.zerock.mapper.BoardAttachMapper;
     
     import lombok.extern.log4j.Log4j;
     
     @Log4j
     @Component //빈 등록을 위해
     public class FileCheckTask {
     	
         //cron속성을 부여해서 주기를 제어
     	@Scheduled(cron = "0 * * * * *") //매분 0초마다 동작
     	public void checkFiles() throws Exception{
     		log.warn("File Check Task run...................");
     		
     		log.warn("====================================================");
     
     	}
     }
     
     ```

     ```xml
     	
     	<context:component-scan base-package="org.zerock.task"></context:component-scan>
     	<task:annotation-driven/>
     ```

### BoardAttachMapper수정

- 첨부파일 목록을 가져오는 메서드 추가

  - BoardAttachMapper

    ```java
    package org.zerock.mapper;
    
    import java.util.List;
    
    import org.zerock.domain.BoardAttachVO;
    
    public interface BoardAttachMapper {
    	...
    	
    	public List<BoardAttachVO> getOldFiles();
    }
    ```

  - BoardAttachMapper.xml

    ```xml
    	<select id="getOldFiles" resultType="org.zerock.domain.BoardAttachVO">
    		select * from tbl_attach where uploadPath = to_char(sysdate-1,'yyyy\mm\dd')
    		
    	</select>
    	
    ```

  ### cron 설정과 삭제 처리

  - cronmaker라는 사이트 이용

  1. 파일의 목록 처리

     1. 데이터베이스에서 어제 사용된 파일의 목록을 얻어오고
     2. 해당 폴더의 파일 목록에서 데이터베이스 없는 파일을 찾아냄
     3. 이후 데이터베이스에 없는 파일들을 삭제

     ```java
     package org.zerock.task;
     
     import java.io.File;
     import java.nio.file.Path;
     import java.nio.file.Paths;
     import java.text.SimpleDateFormat;
     import java.util.Calendar;
     import java.util.Date;
     import java.util.List;
     import java.util.stream.Collector;
     import java.util.stream.Collectors;
     
     import org.springframework.beans.factory.annotation.Autowired;
     import org.springframework.scheduling.annotation.Scheduled;
     import org.springframework.stereotype.Component;
     import org.zerock.domain.BoardAttachVO;
     import org.zerock.mapper.BoardAttachMapper;
     
     import lombok.extern.log4j.Log4j;
     
     @Log4j
     @Component
     public class FileCheckTask {
     	
     	@Autowired
     	private BoardAttachMapper attachMapper;
     	
     	private String getFolderYesterDay() { //어제 폴더이름 
     		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
     		
     		Calendar cal = Calendar.getInstance(); //현재날짜와 시간으로 초기화된 캘린더
     		
     		cal.add(Calendar.DATE, -1); //현재날짜에서 하루 뺌
     		
     		String str =  sdf.format(cal.getTime());
     		
     		return str.replace("-", File.separator); // 2020/10/07같은 형식으로 만듬
     	}
     	
     	
     	@Scheduled(cron = "0 0 2 * * *")
     	public void checkFiles() throws Exception{
     		log.warn("File Check Task run...................");
     		
     		log.warn(new Date());
     		//file list in db
     		List<BoardAttachVO> fileList = attachMapper.getOldFiles();//DB에 경로가 어제날짜인 BoardAttachVO를가져옴
     		
     		//ready for check file in directory with db file list
     		List<Path> fileListPaths = fileList.stream().map(vo -> Paths.get("C:\\upload",vo.getUploadPath(),vo.getUuid()+"_"+vo.getFileName()))
     				.collect(Collectors.toList()); //어제폴더의경로로 만듬
             //ex) c:\\upload/2020/10/09/uuid_파일이름
     		
     		//image file has thumbnail file
     		fileList.stream().filter(vo->vo.isFileType() == true).map(vo -> Paths.get("C:\\upload",vo.getUploadPath(),"s_"+vo.getUuid()+"_"+vo.getFileName()))
     				.forEach(p -> fileListPaths.add(p)); // c:\\upload/2020/10/09/s_uuid_파일이름
     		
     		log.warn("====================================================");
     		
     		fileListPaths.forEach(p->log.warn(p));
     		
     		//files in yesterday directory
     		File targetDir = Paths.get("C:\\upload",getFolderYesterDay()).toFile(); //어제 폴더의 파일을 가져옴
     		
     		File[] removeFiles = targetDir.listFiles(file -> fileListPaths.contains(file.toPath())==false);
             //db와 폴더를 비교해서 중복되지않는것을 가져옴
     		
     		log.warn("-----------------------------------------------");
     		for(File file : removeFiles) {
     			log.warn(file.getAbsolutePath());
     			file.delete(); //중복되지않는것 삭제
     		}
     	}
     }
     
     ```

     

