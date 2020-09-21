<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<script src="http://code.jquery.com/jquery-latest.min.js"></script>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
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
	padding: 10px
}

.uploadResult ul li img {
	width: 20px;
}
</style>
</head>
<body>
	<h1>Upload with Ajax</h1>

	<div class="uploadDiv">
		<input type="file" name="uploadFile" multiple>
	</div>
	<div class="uploadResult">
		<ul>

		</ul>
	</div>

	<button id="uploadBtn">Upload</button>

	<script>
		$(document).ready(function() {
			
			var uploadResult = $(".uploadResult ul");
			
			function showUploadedFile(uploadResultArr) {
				var str = "";
				
				$(uploadResultArr).each(
					function(i,obj) {
						if(!obj.image){
							str += "<li><img src='/resources/img/attach.png'>"+obj.fileName+"</li>";
						}else{
							//str += "<li>"+obj.fileName+"</li>";
							var fileCallPath = encodeURIComponent(obj.uploadPath+"/s_"+obj.uuid+"_"+obj.fileName);
							str += "<li><img src='/display?fileName="+fileCallPath+"'></li>";
						}
					});
				uploadResult.append(str);
			}
			

			var regex = new RegExp("(.*?)\.(exe|sh|zip|alz)$");
			var maxSize = 5242880; // 5MB

			$('#uploadBtn').on("click", function(e) {
				function checkExtension(fileName, fileSize) {
					if (fileSize >= maxSize) {
						alert("파일 사이즈 초과");
						return false;
					}

					if (regex.test(fileName)) {
						alert("해당 종류의 파일은 업로드할 수 없습니다.");
						return false;
					}
					return true;
				}
				
				var cloneObj = $(".uploadDiv").clone();
				var formData = new FormData();

				var inputFile = $("input[name='uploadFile']");

				var files = inputFile[0].files;

				console.log(files);

				//add filedate to formdate
				for (var i = 0; i < files.length; i++) {
					
					if(!checkExtension(files[i].name, files[i].size)){
						return false;
					}
					
					formData.append("uploadFile", files[i]);
				}

				$.ajax({
					url : '/uploadAjaxAction',
					processData : false,
					contentType : false,
					data : formData,
					type : 'POST',
					success : function(result) {
						console.log(result);
						showUploadedFile(result);
						$(".uploadDiv").html(cloneObj.html());
					}
				});
			});
		});
	</script>
</body>
</html>