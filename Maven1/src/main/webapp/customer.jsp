<%@page language="java" contentType="text/html; charset=utf-8" pageEncoding="UTF-8"%>
<%@ page import="connect.RoomDAO" %>
<%@ page import ="java.sql.*" %>
<%@ page import ="java.util.List"%>
<%
    Integer customerId = (Integer) session.getAttribute("customerId");
    String customerName = (String) session.getAttribute("customerName");
    if (customerId == null) {
        response.sendRedirect("index.jsp");
        return;
    }
%>
<html>
<head>
    <title>Customer Booking and Viewing</title>
</head>
<body>


<h1 style = "text-align: center;">Customer View</h1>
<p style="text-align:center;">Hi, <%= customerName %> (ID: <%= customerId %>)</p>
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
        String starStr = request.getParameter("star-rating");
        int price = (priceStr != null && !priceStr.isEmpty()) ? Integer.parseInt(priceStr) : Integer.MAX_VALUE;
        String chain = request.getParameter("chain");
        try{
            List<String[]> rooms = RoomDAO.searchRooms(checkin,checkout,city,capacity,priceStr,seaview,mountain,extend,starStr,chain);
%>
<h2>Available Rooms</h2>
<%
    if (rooms.isEmpty()){
%>
<p>No rooms found matching thiese criteria.</p>
<%
    } else {
%>
<table border = "1">
    <tr>
        <th>Hotel ID</th>
        <th>Room #</th>
        <th>Address</th>
        <th>Capacity</th>
        <th>Price/Night</th>
        <th>View</th>
        <th>Extendable</th>
        <th>Stars</th>
        <th>Action</th>
    </tr>
<%for (String[] room : rooms) {
            // room[0]=HotelID, room[1]=RoomNumber, room[2]=Address,
            // room[3]=Capacity, room[4]=Price, room[5]=View,
            // room[6]=Extendable, room[7]=StarRating
%>

    <tr>
        <td><%= room[0] %></td>
        <td><%= room[1] %></td>
        <td><%= room[2] %></td>
        <td><%= room[3] %></td>
        <td>$<%= room[4] %></td>
        <td><%= room[5] %></td>
        <td><%= room[6] %></td>
        <td><%= room[7] %></td>
        <td>
            <a href="customer.jsp?action=select&hotelId=<%= room[0] %>&roomNum=<%= room[1] %>&checkin=<%= checkin %>&checkout=<%= checkout %>">
                <button>Select</button>
            </a>
        </td>
    </tr>
    <%      } %>
</table>
<%  } %>
<%
} catch (Exception e) {
%>
<p style="color:red;">Search error: <%= e.getMessage() %></p>
<%
        }
    }
%>

<%
    String selectedHotel = request.getParameter("hotelId");
    String selectedRoom  = request.getParameter("roomNum");
    String preCheckin    = request.getParameter("checkin");
    String preCheckout   = request.getParameter("checkout");

    if (selectedHotel == null) selectedHotel = "";
    if (selectedRoom  == null) selectedRoom  = "";
    if (preCheckin    == null) preCheckin    = "";
    if (preCheckout   == null) preCheckout   = "";
%>

<h2>Book a Room</h2>
<form action="customer.jsp" method="post">
    <input type="hidden" name="action" value="book">

    <label for="hotel-id">Hotel ID:</label>
    <input type="number" id="hotel-id" name="hotel-id" value="<%= selectedHotel %>" required>
    <br>

    <label for="room-id">Room Number:</label>
    <input type="number" id="room-id" name="room-id" value="<%= selectedRoom %>" required>
    <br>

    <label for="booking-checkin">Check-in Date:</label>
    <input type="date" id="booking-checkin" name="booking-checkin" value="<%= preCheckin %>" required>
    <br>

    <label for="booking-checkout">Check-out Date:</label>
    <input type="date" id="booking-checkout" name="booking-checkout" value="<%= preCheckout %>" required>
    <br><br>

    <button type="submit">Book Room</button>
</form>

    <%
    if ("book".equals(action)) {
        String hotelIdStr   = request.getParameter("hotel-id");
        String roomIdStr    = request.getParameter("room-id");
        String bookCheckin  = request.getParameter("booking-checkin");
        String bookCheckout = request.getParameter("booking-checkout");

        if (hotelIdStr != null && roomIdStr != null) {
            try {
                RoomDAO.bookRoom(
                        customerId,
                    Integer.parseInt(hotelIdStr),
                    Integer.parseInt(roomIdStr),
                    bookCheckin,
                    bookCheckout
                );
%>
<p style="color:green;">
    Booking confirmed! Hotel <%= hotelIdStr %>, Room <%= roomIdStr %>
    from <%= bookCheckin %> to <%= bookCheckout %>.
</p>
    <%
            } catch (Exception e) {
%>
<p style="color:red;">Booking failed: <%= e.getMessage() %></p>
    <%
            }
        }
    }
%>

<%--current Bookings--%>
<h2>Your Current Bookings</h2>
<%
    try {
        List<String[]> bookings = RoomDAO.getBookingsByCustomer(customerId);
        if (bookings.isEmpty()) {
%>
<p>You have no current bookings.</p>
<%
} else {
%>
<table border="1">
    <tr>
        <th>Booking ID</th>
        <th>Hotel</th>
        <th>Room #</th>
        <th>Check-in</th>
        <th>Check-out</th>
    </tr>
    <%
        for (String[] b : bookings) {
            // b[0]=BookID, b[1]=HotelAddress, b[2]=RoomNumber, b[3]=StartDate, b[4]=EndDate
    %>
    <tr>
        <td><%= b[0] %></td>
        <td><%= b[1] %></td>
        <td><%= b[2] %></td>
        <td><%= b[3] %></td>
        <td><%= b[4] %></td>
    </tr>
    <%
        }
    %>
</table>
<%
    }
} catch (Exception e) {
%>
<p style="color:red;">Error loading bookings: <%= e.getMessage() %></p>
<%  } %>

<br>
<a href="index.jsp">← Return</a>
</body>
</html>

