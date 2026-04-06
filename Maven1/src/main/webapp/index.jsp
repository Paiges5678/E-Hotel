<%@page language="java" contentType="text/html; charset=utf-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>E-Hotel Login</title>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>

<h1>E-Hotel Dashboard</h1>

<%
    String error = (String) request.getAttribute("error");
    if (error != null) {
%>
<p style="color:red;"><%= error %></p>
<% } %>

<div class="section">
    <h2>Customer Login</h2>
    <form action="LoginServlet" method="post">
        <input type="hidden" name="role"   value="customer">
        <input type="hidden" name="action" value="login">
        <label>Customer ID: <input type="number" name="id" required></label><br><br>
        <button type="submit">Sign In</button>
    </form>
</div>

<div class="section">
    <h2>New Customer</h2>
    <form action="LoginServlet" method="post">
        <input type="hidden" name="role"   value="customer">
        <input type="hidden" name="action" value="signup">
        <label>Customer ID: <input type="number" name="customerID" placeholder ="e.g. 1001" required>
            <span class="form-hint">(Please choose a unique ID number)</span>
        </label><br>
        <label>Full Name: <input type="text" name="fullName" required></label><br>
        <label>SIN Number: <input type="text" name="sin" maxlength="9" required></label><br>
        <label>Address: <input type="text" name="address" required></label><br>
        <label>Phone: <input type="tel" name="phone" placeholder ="e.g. 123-456-7890" required></label><br><br>

        <%java.time.LocalDate today = java.time.LocalDate.now();%>
        <label>Date of Registration: <%=today%> </label><br>
        <input type = "hidden" name = "dateOfRegistration" value = "<%=today%>">

        <button type="submit">Create Account</button>
    </form>
</div>

<div class="section">
    <h2>Employee Login</h2>
    <form action="LoginServlet" method="post">
        <input type="hidden" name="role" value="employee">
        <input type="hidden" name="action" value="login">
        <label>Employee ID: <input type="number" name="id" required></label><br><br>
        <label><input type="radio" name="empRole" value="employee" checked> Employee</label>
        <label><input type="radio" name="empRole" value="manager"> Manager</label><br><br>
        <button type="submit">Sign In</button>
    </form>
</div>

</body>
</html>