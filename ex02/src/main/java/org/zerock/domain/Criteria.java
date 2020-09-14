package org.zerock.domain;

import lombok.Data;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Setter
@Getter
@ToString
public class Criteria {
	//페이지 번호
	private int pageNum;
	//한 페이지당 보여줄 데이터양
	private int amount;
	
	public Criteria() {
		this(1,10);
	}
	public Criteria(int pageNum,int amount) {
		this.pageNum = pageNum;
		this.amount = amount;
	}
}
