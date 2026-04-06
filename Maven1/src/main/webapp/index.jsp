<%@page language="java" contentType="text/html; charset=utf-8" pageEncoding="UTF-8"%>
<%@ page import="connection" %>

<html>
<head>
    <title>E-Hotel</title>
</head>
<body>
    <h1>E-Hotel System</h1>
    <%
        String msg = connection.test();
        out.println("<p>" + msg + "</p>");
    %>
</body>
</html>