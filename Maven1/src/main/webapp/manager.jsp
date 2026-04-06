<%@ page import="java.sql.*, java.util.*, java.text.SimpleDateFormat, connect.connection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String message = "";
    String error = "";
    session.setAttribute("role", "manager");
    String action = request.getParameter("action");
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    int defaultEmployeeId = 9001;

    // Get employee info from session or default
    Integer employeeIdObj = (Integer) session.getAttribute("employeeId");
    int currentEmployeeId = (employeeIdObj != null) ? employeeIdObj : defaultEmployeeId;

    // Check if the user is actually a manager
    boolean isManager = false;
    Connection checkConn = null;
    PreparedStatement checkPs = null;
    ResultSet checkRs = null;
    try {
        checkConn = connection.getConnection();
        checkPs = checkConn.prepareStatement("SELECT HotelID, IsManager FROM Employee WHERE EmployeeID = ?");
        checkPs.setInt(1, currentEmployeeId);
        checkRs = checkPs.executeQuery();
        if (checkRs.next()) {
            session.setAttribute("employeeHotelId", checkRs.getInt("HotelID"));
            isManager = checkRs.getBoolean("IsManager");
            session.setAttribute("isManager", isManager);
        } else {
            session.setAttribute("employeeHotelId", 101);
        }
    } catch (Exception e) {
        session.setAttribute("employeeHotelId", 101);
    } finally {
          if (rs != null) try { rs.close(); } catch (SQLException e) {}
          if (ps != null) try { ps.close(); } catch (SQLException e) {}
          if (conn != null) try { conn.close(); } catch (SQLException e) {}
      }

    if (!isManager) {
        response.sendRedirect("employeeDashboard.jsp");
        return;
    }
%>

<%
    try {
        conn = connection.getConnection();

        // Adding a hotel
        if ("addHotel".equals(action)) {
            int hotelId = Integer.parseInt(request.getParameter("hotelId"));
            int chainId = Integer.parseInt(request.getParameter("chainId"));
            int starRating = Integer.parseInt(request.getParameter("starRating"));
            String hotelAddress = request.getParameter("hotelAddress");

            ps = conn.prepareStatement("INSERT INTO Hotel (HotelID, ChainID, StarRating, HotelAddress) VALUES (?, ?, ?, ?)");
            ps.setInt(1, hotelId);
            ps.setInt(2, chainId);
            ps.setInt(3, starRating);
            ps.setString(4, hotelAddress);
            ps.executeUpdate();
            message = "Hotel " + hotelId + " added successfully!";
        }

        //Deleting a hotel
        else if ("deleteHotel".equals(action)) {
            int hotelId = Integer.parseInt(request.getParameter("hotelId"));
            ps = conn.prepareStatement("DELETE FROM Hotel WHERE HotelID = ?");
            ps.setInt(1, hotelId);
            ps.executeUpdate();
            message = "Hotel " + hotelId + " deleted successfully!";
        }

        //Adding a room
        else if ("addRoom".equals(action)) {
            int hotelId = Integer.parseInt(request.getParameter("hotelId"));
            int roomNumber = Integer.parseInt(request.getParameter("roomNumber"));
            double price = Double.parseDouble(request.getParameter("price"));
            int capacity = Integer.parseInt(request.getParameter("capacity"));
            String roomView = request.getParameter("roomView");
            boolean extendableStatus = Boolean.parseBoolean(request.getParameter("extendableStatus"));

            ps = conn.prepareStatement("INSERT INTO Room (HotelID, RoomNumber, Price, Capacity, RoomView, ExtendableStatus, ProblemDamageStatus) VALUES (?, ?, ?, ?, ?, ?, FALSE)");
            ps.setInt(1, hotelId);
            ps.setInt(2, roomNumber);
            ps.setDouble(3, price);
            ps.setInt(4, capacity);
            ps.setString(5, roomView);
            ps.setBoolean(6, extendableStatus);
            ps.executeUpdate();
            message = "Room " + roomNumber + " added to Hotel " + hotelId;
        }

        // Deleting a room
        else if ("deleteRoom".equals(action)) {
            int hotelId = Integer.parseInt(request.getParameter("hotelId"));
            int roomNumber = Integer.parseInt(request.getParameter("roomNumber"));

            ps = conn.prepareStatement("DELETE FROM Room WHERE HotelID = ? AND RoomNumber = ?");
            ps.setInt(1, hotelId);
            ps.setInt(2, roomNumber);
            ps.executeUpdate();
            message = "Room " + roomNumber + " deleted from Hotel " + hotelId;
        }

        //Adding an employee
        else if ("addEmployee".equals(action)) {
            int employeeId = Integer.parseInt(request.getParameter("employeeId"));
            String fullName = request.getParameter("full_name");
            String sinNumber = request.getParameter("sin_number");
            String empAddress = request.getParameter("EmpAddress");
            double salary = Double.parseDouble(request.getParameter("salary"));
            String empPosition = request.getParameter("EmpPosition");
            boolean isManagerEmp = "true".equals(request.getParameter("isManager"));
            int hotelId = Integer.parseInt(request.getParameter("HotelID"));

            ps = conn.prepareStatement("INSERT INTO Employee (EmployeeID, full_name, sin_number, EmpAddress, salary, EmpPosition, IsManager, HotelID) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
            ps.setInt(1, employeeId);
            ps.setString(2, fullName);
            ps.setString(3, sinNumber);
            ps.setString(4, empAddress);
            ps.setDouble(5, salary);
            ps.setString(6, empPosition);
            ps.setBoolean(7, isManagerEmp);
            ps.setInt(8, hotelId);
            ps.executeUpdate();
            message = "Employee " + fullName + " added successfully!";
        }

        //Deleting an employee
        else if ("deleteEmployee".equals(action)) {
            int employeeId = Integer.parseInt(request.getParameter("employeeId"));
            ps = conn.prepareStatement("DELETE FROM Employee WHERE EmployeeID = ?");
            ps.setInt(1, employeeId);
            ps.executeUpdate();
            message = "Employee " + employeeId + " deleted successfully!";
        }

        //Promoting or demoting an emplyoee
        else if ("updateEmployeeManager".equals(action)) {
            int employeeId = Integer.parseInt(request.getParameter("employeeId"));
            boolean isManagerEmp = "true".equals(request.getParameter("isManager"));

            ps = conn.prepareStatement("UPDATE Employee SET IsManager = ? WHERE EmployeeID = ?");
            ps.setBoolean(1, isManagerEmp);
            ps.setInt(2, employeeId);
            ps.executeUpdate();
            message = "Employee " + employeeId + " updated successfully!";
        }
        else if ("viewAllEmployees".equals(action)) {
            ps = conn.prepareStatement("SELECT * FROM Employee");
            rs = ps.executeQuery();
            request.setAttribute("allEmployees", rs);
        }
        else if ("viewAllHotels".equals(action)) {
            ps = conn.prepareStatement("SELECT * FROM Hotel");
            rs = ps.executeQuery();
            request.setAttribute("allHotels", rs);
        }
        else if ("viewAllRooms".equals(action)) {
            ps = conn.prepareStatement("SELECT * FROM Room");
            rs = ps.executeQuery();
            request.setAttribute("allRooms", rs);
        }
           } catch (SQLException e) {
               error = "Database error: " + e.getMessage();
           } catch (Exception e) {
               error = "Error: " + e.getMessage();
           } finally {
               if (conn != null) try { conn.close(); } catch (SQLException e) {}
           }
       %>
<!DOCTYPE html>
<html>
<head>
    <title>Manager Dashboard</title>
    <style>
        body { font-family: Arial; margin: 20px; }
        .section { border: 1px solid #ccc; padding: 15px; margin-bottom: 20px; }
        .section h2 { margin-top: 0; }
        input, select { margin: 5px; padding: 5px; }
        button { padding: 5px 15px; margin: 5px; }
        .error { color: red; }
        .success { color: green; }
        table { border-collapse: collapse; margin-top: 10px; }
        th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
        .info-bar { background-color: #eee; padding: 10px; margin-bottom: 20px; }
    </style>
</head>
<body>

    <h1>Manager Dashboard</h1>
    <div class="info-bar">
        Manager ID: <%= session.getAttribute("employeeId") != null ? session.getAttribute("employeeId") : "9001" %> |
        Hotel ID: <%= session.getAttribute("employeeHotelId") != null ? session.getAttribute("employeeHotelId") : "101" %>
    </div>
    <a href="employeeDashboard.jsp">← Go to Employee Dashboard</a>
    <a href="index.jsp">Switch to Customer View</a>

    <% if (!message.isEmpty()) { %>
        <p class="success"><%= message %></p>
    <% } %>
    <% if (!error.isEmpty()) { %>
        <p class="error"><%= error %></p>
    <% } %>

    <!-- HOTEL MANAGEMENT -->
    <div class="section">
        <h2>Hotel Management</h2>

        <h3>Add Hotel</h3>
        <form method="post">
            <input type="hidden" name="action" value="addHotel">
            Hotel ID: <input type="number" name="hotelId" required><br>
            Chain ID: <input type="number" name="chainId" required><br>
            Star Rating:
            <select name="starRating">
                <option value="1">1 Star</option>
                <option value="2">2 Stars</option>
                <option value="3">3 Stars</option>
                <option value="4">4 Stars</option>
                <option value="5">5 Stars</option>
            </select><br>
            Address: <input type="text" name="hotelAddress" required><br>
            <button type="submit">Add Hotel</button>
        </form>

        <h3>Delete Hotel</h3>
        <form method="post" onsubmit="return confirm('Delete this hotel? All rooms will be deleted!');">
            <input type="hidden" name="action" value="deleteHotel">
            Hotel ID: <input type="number" name="hotelId" required>
            <button type="submit">Delete Hotel</button>
        </form>
    </div>

    <!-- ROOM MANAGEMENT -->
    <div class="section">
        <h2>Room Management</h2>

        <h3>Add Room</h3>
        <form method="post">
            <input type="hidden" name="action" value="addRoom">
            Hotel ID: <input type="number" name="hotelId" required><br>
            Room Number: <input type="number" name="roomNumber" required><br>
            Price: $<input type="number" step="0.01" name="price" required><br>
            Capacity:
            <select name="capacity">
                <option value="1">1 person</option>
                <option value="2">2 people</option>
                <option value="3">3 people</option>
                <option value="4">4 people</option>
                <option value="5">5+ people</option>
            </select><br>
            View:
            <select name="roomView">
                <option value="sea">Sea View</option>
                <option value="mountain">Mountain View</option>
            </select><br>
            Extendable:
            <input type="radio" name="extendableStatus" value="true"> Yes
            <input type="radio" name="extendableStatus" value="false" checked> No<br>
            <button type="submit">Add Room</button>
        </form>

        <h3>Delete Room</h3>
        <form method="post" onsubmit="return confirm('Delete this room?');">
            <input type="hidden" name="action" value="deleteRoom">
            Hotel ID: <input type="number" name="hotelId" required><br>
            Room Number: <input type="number" name="roomNumber" required>
            <button type="submit">Delete Room</button>
        </form>
    </div>

    <!-- EMPLOYEE MANAGEMENT -->
    <div class="section">
        <h2>Employee Management</h2>

        <h3>Add Employee</h3>
        <form method="post">
            <input type="hidden" name="action" value="addEmployee">
            Employee ID: <input type="number" name="employeeId" required><br>
            Full Name: <input type="text" name="full_name" required><br>
            SIN: <input type="text" name="sin_number" required><br>
            Address: <input type="text" name="EmpAddress" required><br>
            Salary: $<input type="number" step="0.01" name="salary" required><br>
            Position: <input type="text" name="EmpPosition" required><br>
            Is Manager: <input type="checkbox" name="isManager" value="true"><br>
            Hotel ID: <input type="number" name="HotelID" required><br>
            <button type="submit">Add Employee</button>
        </form>

        <h3>Delete Employee</h3>
        <form method="post" onsubmit="return confirm('Delete this employee?');">
            <input type="hidden" name="action" value="deleteEmployee">
            Employee ID: <input type="number" name="employeeId" required>
            <button type="submit">Delete Employee</button>
        </form>

        <h3>Promote/Demote Employee</h3>
        <form method="post">
            <input type="hidden" name="action" value="updateEmployeeManager">
            Employee ID: <input type="number" name="employeeId" required><br>
            Make Manager: <input type="checkbox" name="isManager" value="true"><br>
            <button type="submit">Update Employee</button>
        </form>
    </div>

    <!-- VIEW ALL EMPLOYEES -->
    <div class="section">
        <h2>All Employees</h2>
        <form method="post">
            <input type="hidden" name="action" value="viewAllEmployees">
            <button type="submit">Refresh Employee List</button>
        </form>
        <% if (request.getAttribute("allEmployees") != null) {
            ResultSet allEmps = (ResultSet) request.getAttribute("allEmployees");
        %>
            <table>
                <tr><th>ID</th><th>Name</th><th>Position</th><th>Manager?</th><th>Hotel ID</th></tr>
                <% while (allEmps.next()) { %>
                    <tr>
                        <td><%= allEmps.getInt("EmployeeID") %></td>
                        <td><%= allEmps.getString("full_name") %></td>
                        <td><%= allEmps.getString("EmpPosition") %></td>
                        <td><%= allEmps.getBoolean("IsManager") ? "Yes" : "No" %></td>
                        <td><%= allEmps.getInt("HotelID") %></td>
                    </tr>
                <% } %>
            </table>
        <% } %>
    </div>

    <!-- VIEW ALL HOTELS -->
    <div class="section">
        <h2>All Hotels</h2>
        <form method="post">
            <input type="hidden" name="action" value="viewAllHotels">
            <button type="submit">Refresh Hotel List</button>
        </form>
        <% if (request.getAttribute("allHotels") != null) {
            ResultSet allHotels = (ResultSet) request.getAttribute("allHotels");
        %>
            <table>
                <tr><th>ID</th><th>Chain ID</th><th>Star Rating</th><th>Address</th></tr>
                <% while (allHotels.next()) { %>
                    <tr>
                        <td><%= allHotels.getInt("HotelID") %></td>
                        <td><%= allHotels.getInt("ChainID") %></td>
                        <td><%= allHotels.getInt("StarRating") %></td>
                        <td><%= allHotels.getString("HotelAddress") %></td>
                    </tr>
                <% } %>
            </table>
        <% } %>
    </div>

    <!-- VIEW ALL ROOMS -->
    <div class="section">
        <h2>All Rooms</h2>
        <form method="post">
            <input type="hidden" name="action" value="viewAllRooms">
            <button type="submit">Refresh Room List</button>
        </form>
        <% if (request.getAttribute("allRooms") != null) {
            ResultSet allRooms = (ResultSet) request.getAttribute("allRooms");
        %>
            <table>
                <tr><th>Hotel ID</th><th>Room #</th><th>Price</th><th>Capacity</th><th>View</th><th>Extendable</th><th>Damaged</th></tr>
                <% while (allRooms.next()) { %>
                    <tr>
                        <td><%= allRooms.getInt("HotelID") %></td>
                        <td><%= allRooms.getInt("RoomNumber") %></td>
                        <td>$<%= allRooms.getDouble("Price") %></td>
                        <td><%= allRooms.getInt("Capacity") %></td>
                        <td><%= allRooms.getString("RoomView") %></td>
                        <td><%= allRooms.getBoolean("ExtendableStatus") ? "Yes" : "No" %></td>
                        <td><%= allRooms.getBoolean("ProblemDamageStatus") ? "Yes" : "No" %></td>
                    </tr>
                <% } %>
            </table>
        <% } %>
    </div>

</body>
</html>
