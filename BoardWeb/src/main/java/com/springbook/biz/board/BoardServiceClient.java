package com.springbook.biz.board;

import java.util.List;

import org.springframework.context.support.AbstractApplicationContext;
import org.springframework.context.support.GenericXmlApplicationContext;

public class BoardServiceClient {
	public static void main(String[] args) {
		AbstractApplicationContext container = new GenericXmlApplicationContext("applicationContext.xml");
		
		BoardService boardService = (BoardService) container.getBean("boardService");
		
		BoardVO vo = new BoardVO();
		
		vo.setSeq(100);
		vo.setTitle("�ӽ�����");
		vo.setWriter("ȫ�浿");
		vo.setContent("�ӽó���......");
		//boardService.insertBoard(vo);

		
		List<BoardVO> boardList = boardService.getBoardList(vo);
		System.out.println(boardList);
		for(BoardVO board : boardList) {
			System.out.println("==> "+board.toString());
		}
		
		container.close();
	}
}