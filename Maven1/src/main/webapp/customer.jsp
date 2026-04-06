<%@page language="java" contentType="text/html; charset=utf-8" pageEncoding="UTF-8"%>
<%@ page import="connect.connection" %>
<%@ page import ="java.sql.*" %>
<%@ page import ="java.util.ArrayList"%>

<html>
<head>
    <title>E-Hotel - Customer</title>
</head>
<body>


<h1 style = "text-align: center;">Customer View</h1>
<h2>Search rooms</h2>
<form action="customer.jsp" method="post">
    <!--checkin and checkout date select-->
    <label for ="checkin"> Checkin date: </label>
    <input type = "date" id ="checkin" name ="checkin" required>
    <br>
    <label for ="checkin"> Checkout date: </label>
    <input type = "date" id ="checkout" name ="checkout" required>
    <br>

    <!--city select-->
    <label for ="city">City:</label>
    <select id = "city" name="city">
        <option value="">Select City</option>
        <option value="Ottawa">Ottawa</option>
        <option value="Toronto">Toronto</option>
        <option value="Hamilton">Hamilton</option>
        <option value="London">London</option>
        <option value="Windsor">Windsor</option>
        <option value="Barrie">Barrie</option>
        <option value="Kingston">Kingston</option>
        <option value="Vancouver">Vancouver</option>
        <option value="Victoria">Victoria</option>
        <option value="Kelowna">Kelowna</option>
        <option value="Surrey">Surrey</option>
        <option value="Burnaby">Burnaby</option>
        <option value="Richmond">Richmond</option>
        <option value="Coquitlam">Coquitlam</option>
        <option value="Nanaimo">Nanaimo</option>
        <option value="Montreal">Montreal</option>
        <option value="Quebec City">Quebec City</option>
        <option value="Laval">Laval</option>
        <option value="Longueuil">Longueuil</option>
        <option value="Gatineau">Gatineau</option>
        <option value="Trois-Rivières">Trois-Rivières</option>
        <option value="Sherbrooke">Sherbrooke</option>
        <option value="Saguenay">Saguenay</option>
        <option value="Calgary">Calgary</option>
        <option value="Edmonton">Edmonton</option>
        <option value="Red Deer">Red Deer</option>
        <option value="Lethbridge">Lethbridge</option>
        <option value="Medicine Hat">Medicine Hat</option>
        <option value="Fort McMurray">Fort McMurray</option>
        <option value="Canmore">Canmore</option>
        <option value="Banff">Banff</option>
        <option value="North Bay">North Bay</option>
        <option value="Belleville">Belleville</option>
        <option value="Sudbury">Sudbury</option>
        <option value="Peterborough">Peterborough</option>
    </select>
    <br>

    <!--room capacity-->
    <label for ="capacity">Minimum Capacity:</label>
    <input type = "number" id = "capacity" name ="capacity" min = "1" max = "10" placeholder = "e.g. 1, 2, 3...">
    <br>

    <!--room size-->
    <label for ="size">Size:</label>
    <select id = "size" name="size">
        <option value="">Select Size</option>
        <option value="Single">Single</option>
        <option value="Double">Double</option>
    </select>
    <br>

    <!--minimum star rating-->
    <label for="star-rating">Minimum star rating (1-5):</label>
    <input type="number" id="star-rating" name="star-rating" min = "1" max = "5" placeholder="e.g. 1">
    <br>

    <!--price range-->
    <label for="price">Max Price per night ($):</label>
    <input type="number" id="price" name="price" max = "2000" placeholder="e.g. 200">
    <br>

    <!--Chain-->
    <label for ="chain">Chain:</label>
    <select id = "chain" name="chain">
        <option value="">Select Chain</option>
        <option value="one">1</option>
        <option value="two">2</option>
        <option value="three">3</option>
        <option value="four">4</option>
        <option value="five">5</option>
    </select>
    <br>

    <!--other things-->
    <label>Other: </label>
    <input type = "checkbox" id = sea" name = "sea" value = "yes">
    <label for ="sea">Sea View</label>
    <input type = "checkbox" id = mountain" name = "mountain" value = "yes">
    <label for ="mountain">Mountain View</label>
    <input type = "checkbox" id = "extendable" name = "extendable" value = "yes">
    <label for ="extendable">Extendable</label>
    <br>
    <br>
    <button type="submit" name="action" value="search">Search Available Rooms</button>

</form>

<!--SEARCH results-->
<%
    String action = request.getParameter("action");
    if("search".equals(action)) {
        String checkin = request.getParameter("checkin");
        String checkout = request.getParameter("checkout");
        String city = request.getParameter("city");
        String capacity = request.getParameter("capacity");
        String priceStr = request.getParameter("price");
        String seaview = request.getParameter("sea");
        String mountain = request.getParameter("mountain");
        String extend = request.getParameter("extendable");
        int price = (priceStr != null && !priceStr.isEmpty()) ? Integer.parseInt(priceStr) : Integer.MAX_VALUE;
        // TODO: replace with real DB call
        // rooms = connection.roomSearch(checkin, checkout, capacity, city, price, seaview, mountain, extend);
    }
    else{}
%>

</body>