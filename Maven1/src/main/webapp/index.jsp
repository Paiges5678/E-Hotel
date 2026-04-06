<%@page language="java" contentType="text/html; charset=utf-8" pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html>
<head><title>E-Hotel Login</title></head>
<body>

<h1 style="text-align:center;">E-Hotel</h1>
<h2 style="text-align:center;">Login</h2>

<%
    String error = (String) request.getAttribute("error");
    if (error != null) {
%>
<p style="color:red;"><%= error %></p>
<%  } %>

<form action="LoginServlet" method="post">
    <label for="role">Login as:</label>
    <select id="role" name="role">
        <option value="customer">Customer</option>
        <option value="employee">Employee</option>
    </select>
    <br><br>
    <label for="id">ID Number:</label>
    <input type="number" id="id" name="id" required>
    <br><br>

    <button type="submit">Login</button>
</form>

</body>
</html>