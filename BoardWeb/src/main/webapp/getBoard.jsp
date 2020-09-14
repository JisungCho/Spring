<%@page import="java.util.List"%>
<%@page import="com.springbook.biz.impl.BoardDAO"%>
<%@page import="com.springbook.biz.board.BoardVO"%>
<%@page import="com.springbook.biz.user.impl.UserDAO"%>
<%@page import="com.springbook.biz.user.UserVO"%>
<%@ page language="java" contentType="text/html; charset=EUC-KR"
	pageEncoding="EUC-KR"%>
<%
	BoardVO board = (BoardVO)session.getAttribute("board");
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="EUC-KR">
<title>�� ��</title>
</head>
<body>
	<h1>�� ��</h1>
	<a href="logout.do">Log-out</a>
	<hr>

	<form action="updateBoard.do" method="post">
	<input type="hidden" name="seq" value="${board.seq}">
		<table border="1" cellpadding="0" cellspacing="0">
			<tr>
				<td bgcolor="orange" width="70">����</td>
				<td align="left"><input name="title" type="text"
					value="${board.title}"></td>
			</tr>
			<tr>
				<td bgcolor="orange">�ۼ���</td>
				<td align="left">${board.writer}</td>
			</tr>
			<tr>
				<td bgcolor="orange">����</td>
				<td align="left"><textarea name="content" cols="40" rows="10">${board.content}</textarea></td>
			</tr>
			<tr>
				<td bgcolor="orange">�����</td>
				<td align="left">${board.regDate}</td>
			</tr>
			<tr>
				<td bgcolor="orange">��ȸ��</td>
				<td align="left">${board.cnt}</td>
			</tr>
			<tr>
				<td colspan="2" align="center">
					<input type="submit" value="�� ����">
				</td>
			</tr>
		</table>
	</form>
	<br>
	<a href="insertBoard.do">���� ���</a>
	<a href="deleteBoard.do?seq=${board.seq}">�� ����</a>
	<a href="getBoardList.do">�� ���</a>
</body>
</html>