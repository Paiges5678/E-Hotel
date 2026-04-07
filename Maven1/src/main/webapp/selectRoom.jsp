<%@ page import="java.sql.*, java.util.*, connect.connection" %>
<%@ page import="java.sql.Date" %>
<%
    //We need to set local variables for the data we from the session (sent from employeeDashboard.jsp)
    List<Map<String, Object>> availableRooms = (List<Map<String, Object>>) session.getAttribute("availableRooms");
    String customerSin =(String) session.getAttribute("customerSin");
    Integer sessionCustomerId = (Integer) session.getAttribute("customerId");
    String customerName =(String) session.getAttribute("customerName");
    String customerAddress= (String) session.getAttribute("customerAddress");
    String customerPhone = (String) session.getAttribute("customerPhone");
    Date checkinDate= (Date) session.getAttribute("checkinDate");
    Date checkoutDate =(Date) session.getAttribute("checkoutDate");
    double paymentAmount = (Double) session.getAttribute("paymentAmount");
    int hotelId =(Integer) session.getAttribute("employeeHotelId");
    int employeeId= (Integer) session.getAttribute("employeeId");
    String action = request.getParameter("action");
    String message = "";
    String error = "";

    //Flow: All of the available rooms are displayed, then employee can click on which one they wanna rent out
    //When a room is selected we check if the custome is in the database or not (if not we add them)
    if ("selectRoom".equals(action)) {
        int selectedRoom=Integer.parseInt(request.getParameter("selectedRoom"));
        Connection conn=null;
        PreparedStatement ps=null;
        ResultSet rs=null;
        try {
            conn= connection.getConnection();
            // Checking if customer exists
            int customerId = -1;
            ps = conn.prepareStatement("SELECT CustomerID FROM Customer WHERE sin_number = ?");
            ps.setString(1, customerSin);
            rs = ps.executeQuery();
            if (rs.next()) {
                customerId = rs.getInt("CustomerID");
            } else {
                //If the customer doesnt already exist well add a new one
                customerId = sessionCustomerId;
                ps = conn.prepareStatement(
                    "INSERT INTO Customer (CustomerID, full_name, sin_number, CustAddress, date_of_registration, phone_number) " +
                    "VALUES (?, ?, ?, ?, CURRENT_DATE, ?)"
                );
                ps.setInt(1, customerId);
                ps.setString(2, customerName);
                ps.setString(3, customerSin);
                ps.setString(4, customerAddress);
                ps.setString(5, customerPhone);
                ps.executeUpdate();

            }

            //Now that customer has been updated we can Create a new rental
            ps = conn.prepareStatement(
                "INSERT INTO Renting (CustomerID, BookID, HotelID, RoomNumber, EmployeeID, CheckinDate, CheckoutDate, PaymentAmount) " +
                "VALUES (?, NULL, ?, ?, ?, ?, ?, ?)"
            );
            ps.setInt(1, customerId);
            ps.setInt(2, hotelId);
            ps.setInt(3, selectedRoom);
            ps.setInt(4, employeeId);
            ps.setDate(5, checkinDate);
            ps.setDate(6, checkoutDate);
            ps.setDouble(7, paymentAmount);
            ps.executeUpdate();

            message = "Success! Rental created for " + customerName + " in Room " + selectedRoom;

        } catch (SQLException e) {
            error = "Database error: " + e.getMessage();
        } finally {
              if (rs != null) try { rs.close(); } catch (SQLException e) {}
              if (ps != null) try { ps.close(); } catch (SQLException e) {}
              if (conn != null) try { conn.close(); } catch (SQLException e) {}
          }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Select Room</title>
    <style>
        .room-card { border: 1px solid #ccc; padding: 15px; margin: 10px 0; border-radius: 5px; }
        button { padding: 10px; background-color: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; }
        .success { color: green; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>Select a Room</h1>

    <% if (!message.isEmpty()) { %>
        <p class="success"><%= message %></p>
        <a href="employee.jsp">Back to Dashboard</a>
    <% } else if (!error.isEmpty()) { %>
        <p class="error"><%= error %></p>
        <a href="employee.jsp">Try Again</a>
    <% } else { %>
        <p><strong>Customer:</strong> <%= customerName %></p>
        <p><strong>Dates:</strong> <%= checkinDate %> to <%= checkoutDate %></p>

        <!--Display all the available rooms as buttons that once clicked on can be rented out-->
        <% for (Map<String, Object> room : availableRooms) { %>
            <div class="room-card">
                <p><strong>Room <%= room.get("roomNumber") %></strong> - $<%= room.get("price") %> per night</p>
                <p>Capacity: <%= room.get("capacity") %> people | View: <%= room.get("view") %></p>

                <%-- This form makes the room clickable --%>
                <form method="post">
                    <input type="hidden" name="action" value="selectRoom">
                    <input type="hidden" name="selectedRoom" value="<%= room.get("roomNumber") %>">
                    <button type="submit">Select This Room</button>
                </form>
            </div>
        <% } %>
    <% } %>
</body>
</html>