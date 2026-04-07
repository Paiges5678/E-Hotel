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
    <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>


<h1 style = "text-align: center;">Customer Bookings</h1>
<p style="text-align:center;">Hello <%= customerName %>!</p>
<p style = "text-align:center;">Customer ID: <%= customerId %> </p>

<a href="index.jsp">← Return to login</a>
<div class="section">
    <h2>Search Available Rooms</h2>
    <form action="customer.jsp" method="post">
        <!--checkin and checkout date select-->
        <label for ="checkin"> Check-in date: </label>
        <input type = "date" id ="checkin" name ="checkin" required>
        <br>
        <label for ="checkin"> Check-out date: </label>
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
            <option value="1">1</option>
            <option value="2">2</option>
            <option value="3">3</option>
            <option value="4">4</option>
            <option value="5">5</option>
        </select>
        <br>

        <!--other things-->
        <label for="view">Room View:</label>
        <select id="view" name="view">
            <option value="">Any / None</option>
            <option value="sea">Sea View</option>
            <option value="mountain">Mountain View</option>
        </select>
        <br>

        <label for="extendable">Extendable:</label>
        <input type="checkbox" id="extendable" name="extendable" value="yes">
        <br>

        <br>
        <button type="submit" name="action" value="search">Search Available Rooms</button>
    </form>
</div>

<!--SEARCH results-->
<%
    String action = request.getParameter("action");
    if("search".equals(action)) {
        String checkin = request.getParameter("checkin");
        String checkout = request.getParameter("checkout");

        //Check for valid checkin and checkout date
        java.time.LocalDate start = java.time.LocalDate.parse(checkin);
        java.time.LocalDate end = java.time.LocalDate.parse(checkout);
        java.time.LocalDate today = java.time.LocalDate.now();

        if (start.isAfter(end)) {
%>
<p style="color:red; font-weight:bold;">Error: Check-in date cannot be after the check-out date.</p>
<%
} else if (start.isBefore(today)) {
%>
<p style="color:red; font-weight:bold;">Error: You cannot search for dates in the past.</p>
<%
} else {
    // Only run the search if dates are valid
    try {
        String city = request.getParameter("city");
        String capacity = request.getParameter("capacity");
        String priceStr = request.getParameter("price");
        String view = request.getParameter("view");
        String extend = request.getParameter("extendable");
        String starStr = request.getParameter("star-rating");
        String chain = request.getParameter("chain");

        List<String[]> rooms = RoomDAO.searchRooms(checkin, checkout, city, capacity, priceStr, view, extend, starStr, chain);
%>
<div class = "section">
    <h2>Available Rooms</h2>
    <%
        if (rooms.isEmpty()){
    %>
    <p>No rooms found matching these criteria.</p>
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
    <% for (String[] room : rooms) {
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
                    <button>Book</button>
                </a>
            </td>
        </tr>
        <%      } %>
    </table>
    <%              }
    } catch (Exception e) {
    %>
    <p style="color:red;">Search error: <%= e.getMessage() %></p>
    <%
                }
            } //close else
        }//close if
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
</div>

    <div class ="section">
    <h2>Book a Room</h2>
    <form action="customer.jsp" method="post">
        <input type="hidden" name="action" value="book">

        <label for="hotel-id">Hotel ID:</label>
        <input type="number" id="hotel-id" name="hotel-id" value="<%= selectedHotel %>" required>
        <span class="form-hint">(Find Hotel IDs by searching for Available Rooms)</span>
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
                    // Parse dates for validation
                    java.time.LocalDate bStart = java.time.LocalDate.parse(bookCheckin);
                    java.time.LocalDate bEnd   = java.time.LocalDate.parse(bookCheckout);
                    java.time.LocalDate today  = java.time.LocalDate.now();

                    // Validation rules
                    if (bStart.isBefore(today)) {
                        throw new Exception("Check-in date cannot be in the past.");
                    }
                    if (!bEnd.isAfter(bStart)) {
                        throw new Exception("Check-out date must be after the check-in date.");
                    }

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
    </div>

<%--current Bookings--%>
<div class = section>
    <h2>Your Bookings</h2>
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
            <th>Hotel Address</th>
            <th>Room #</th>
            <th>Check-in date</th>
            <th>Check-out date</th>
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
</div>
</body>
</html>

