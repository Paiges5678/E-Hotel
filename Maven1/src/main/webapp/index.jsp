<%@page language="java" contentType="text/html; charset=utf-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head><title>E-Hotel Login</title></head>
<body>

<h1>E-Hotel</h1>

<%
    String error = (String) request.getAttribute("error");
    if (error != null) {
%>
<p style="color:red;"><%= error %></p>
<% } %>

<h2>Customer Login</h2>
<form action="LoginServlet" method="post">
    <input type="hidden" name="role"   value="customer">
    <input type="hidden" name="action" value="login">
    <label>Customer ID: <input type="number" name="id" required></label><br><br>
    <button type="submit">Sign In</button>
</form>

<hr>

<h2>New Customer</h2>
<form action="LoginServlet" method="post">
    <input type="hidden" name="role"   value="customer">
    <input type="hidden" name="action" value="signup">
    <label>Customer ID: <input type="number" name="customerID" required></label><br>
    <label>Full Name: <input type="text" name="fullName" required></label><br>
    <label>SIN Number: <input type="text" name="sin" maxlength="9" required></label><br>
    <label>Address: <input type="text" name="address" required></label><br>
    <label>Date of Registration: <input type="date" name="dateOfRegistration" required></label><br>
    <label>Phone: <input type="tel" name="phone" required></label><br><br>
    <button type="submit">Create Account</button>
</form>

<hr>

<h2>Employee Login</h2>
<form action="LoginServlet" method="post">
    <input type="hidden" name="role"    value="employee">
    <input type="hidden" name="action"  value="login">
    <input type="hidden" name="empRole" id="empRoleHidden" value="employee">
    <label>Employee ID: <input type="number" name="id" required></label><br><br>
    <label><input type="radio" name="empRole" value="employee" checked> Employee</label>
    <label><input type="radio" name="empRole" value="manager"> Manager</label><br><br>
    <button type="submit">Sign In</button>
</form>

</body>
</html>