<%@page import="java.util.List"%>
<%@page import="com.springbook.biz.impl.BoardDAO"%>
<%@page import="com.springbook.biz.board.BoardVO"%>
<%@page import="com.springbook.biz.user.impl.UserDAO"%>
<%@page import="com.springbook.biz.user.UserVO"%>
<%@ page language="java" contentType="text/html; charset=EUC-KR"
	pageEncoding="EUC-KR"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="EUC-KR">
<title>글 상세</title>
</head>
<body>
	<h1>글 상세</h1>
	<a href="logout_proc.jsp">Log-out</a>
	<hr>

	<form action="insertBoard.do" method="post">
		<table border="1" cellpadding="0" cellspacing="0">
			<tr>
				<td bgcolor="orange" width="70">제목</td>
				<td align="left"><input name="title" type="text"></td>
			</tr>
			<tr>
				<td bgcolor="orange">작성자</td>
				<td align="left"><input type="text" name="writer" size="10"></td>
			</tr>
			<tr>
				<td bgcolor="orange">내용</td>
				<td align="left"><textarea name="content" cols="40" rows="10"></textarea></td>
			</tr>
			<tr>
				<td colspan="2" align="center">
					<input type="submit" value="글 등록">
				</td>
			</tr>
		</table>
	</form>
	<br>
	<a href="getBoardList.do">글 목록</a>
</body>
</html>