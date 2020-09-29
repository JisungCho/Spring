package org.zerock.domain;

import java.util.Date;

import org.springframework.format.annotation.DateTimeFormat;

import lombok.Data;

@Data //Getter , setter ,toString 등을 만듬
public class BoardVO {
	private Long bno;
	private String title;
	private String content;
	private String writer;
	
	@DateTimeFormat(pattern = "yyyy-MM-dd")
	private Date regdate;
	@DateTimeFormat(pattern = "yyyy-MM-dd")
	private Date updateDate;
}
