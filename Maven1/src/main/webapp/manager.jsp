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

    int defaultEmployeeId = 101;

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
            session.setAttribute("employeeHotelId", 11);
        }
    } catch (Exception e) {
        session.setAttribute("employeeHotelId", 11);
    } finally {
          if (rs != null) try { rs.close(); } catch (SQLException e) {}
          if (ps != null) try { ps.close(); } catch (SQLException e) {}
          if (conn != null) try { conn.close(); } catch (SQLException e) {}
      }

    if (!isManager) {
        response.sendRedirect("employee.jsp");
        return;
    }
%>

<%
    try {
        conn = connection.getConnection();

        // First: Adding a hotel
        if ("addHotel".equals(action)) {
            try{
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
        }//closing the try
        catch (NumberFormatException e) {
                        error = "Please enter valid numbers for Hotel ID, Chain ID, and Star Rating.";
                    } catch (SQLException e) {
                        String sqlError = e.getMessage();
                        if (sqlError.contains("duplicate key")) {
                            error = "Hotel ID already exists. Please use a different ID.";
                        } else if (sqlError.contains("foreign key")) {
                            error = "Chain ID does not exist. Please use a valid Chain ID.";
                        } else {
                            error = "Database error: " + e.getMessage();
                        }
                    }
                   }//close the original if

        //Second: Deleting a hotel
        else if ("deleteHotel".equals(action)) {
        try{
            int hotelId = Integer.parseInt(request.getParameter("hotelId"));
            ps = conn.prepareStatement("DELETE FROM Hotel WHERE HotelID = ?");
            ps.setInt(1, hotelId);
            int rowsDeleted = ps.executeUpdate();
                if (rowsDeleted > 0) {
                    message = "Hotel " + hotelId + " deleted successfully!";
                } else {
                    error = "Hotel ID " + hotelId + " not found.";
                }
            } catch (NumberFormatException e) {
                error = "Please enter a valid Hotel ID.";
            } catch (SQLException e) {
                String sqlError = e.getMessage();
                if (sqlError.contains("foreign key")) {
                    error = "Cannot delete this hotel. It has rooms or other linked records. Delete those first.";
                } else {
                    error = "Database error: " + e.getMessage();
                }
            }
        }//closes the else it

        //Third: Adding a room
        else if ("addRoom".equals(action)) {
        try{
            int hotelId = Integer.parseInt(request.getParameter("hotelId"));
            int roomNumber = Integer.parseInt(request.getParameter("roomNumber"));
            double price = Double.parseDouble(request.getParameter("price"));
            int capacity = Integer.parseInt(request.getParameter("capacity"));
            String roomView = request.getParameter("roomView");
            boolean extendableStatus = Boolean.parseBoolean(request.getParameter("extendableStatus"));

            //check for number formatting:
            if (price < 0) {
                                error = "Price cannot be negative.";
                            } else if (capacity < 1) {
                                error = "Capacity must be at least 1.";
                            } else {

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
        } catch (NumberFormatException e) {
                        error = "Please enter valid numbers for Hotel ID, Room Number, Price, and Capacity.";
                    } catch (SQLException e) {
                        String sqlError = e.getMessage();
                        if (sqlError.contains("duplicate key")) {
                            error = "Room already exists in this hotel. Use a different room number.";
                        } else if (sqlError.contains("foreign key")) {
                            error = "Hotel ID does not exist. Please use a valid Hotel ID.";
                        } else {
                            error = "Database error: " + e.getMessage();
                        }
                    }
                }

        //Fourth: Deleting a room
        else if ("deleteRoom".equals(action)) {
        try{
            int hotelId = Integer.parseInt(request.getParameter("hotelId"));
            int roomNumber = Integer.parseInt(request.getParameter("roomNumber"));

            ps = conn.prepareStatement("DELETE FROM Room WHERE HotelID = ? AND RoomNumber = ?");
            ps.setInt(1, hotelId);
            ps.setInt(2, roomNumber);
        int rowsDeleted = ps.executeUpdate();
                        if (rowsDeleted > 0) {
                            message = "Room " + roomNumber + " deleted from Hotel " + hotelId;
                        } else {
                            error = "Room " + roomNumber + " not found in Hotel " + hotelId;
                        }
                    } catch (NumberFormatException e) {
                        error = "Please enter valid numbers for Hotel ID and Room Number.";
                    } catch (SQLException e) {
                        String sqlError = e.getMessage();
                        if (sqlError.contains("foreign key")) {
                            error = "Cannot delete this room. It has existing bookings or rentals.";
                        } else {
                            error = "Database error: " + e.getMessage();
                        }
                    }
                }

        //Fifth: Adding an employee
        else if ("addEmployee".equals(action)) {
        try{
            int employeeId = Integer.parseInt(request.getParameter("employeeId"));
            String fullName = request.getParameter("full_name");
            String sinNumber = request.getParameter("sin_number");
            String empAddress = request.getParameter("EmpAddress");
            double salary = Double.parseDouble(request.getParameter("salary"));
            String empPosition = request.getParameter("EmpPosition");
            boolean isManagerEmp = "true".equals(request.getParameter("isManager"));
            int hotelId = Integer.parseInt(request.getParameter("HotelID"));

            if (fullName == null || fullName.isEmpty()) {
                error = "Please enter employee name.";
            } else if (sinNumber == null || sinNumber.isEmpty()) {
                error = "Please enter SIN number.";
            } else if (salary < 0) {
                error = "Salary cannot be negative.";
            } else {

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
        } catch (NumberFormatException e) {
                        error = "Please enter valid numbers for Employee ID, Salary, and Hotel ID.";
                    } catch (SQLException e) {
                        String sqlError = e.getMessage();
                        if (sqlError.contains("duplicate key")) {
                            error = "Employee ID already exists. Please use a different ID.";
                        } else if (sqlError.contains("foreign key")) {
                            error = "Hotel ID does not exist. Please use a valid Hotel ID.";
                        } else {
                            error = "Database error: " + e.getMessage();
                        }
                    }
                }

        //Sixth: Deleting an employee
        else if ("deleteEmployee".equals(action)) {
            try{
            int employeeId = Integer.parseInt(request.getParameter("employeeId"));
            ps = conn.prepareStatement("DELETE FROM Employee WHERE EmployeeID = ?");
            ps.setInt(1, employeeId);
            int rowsDeleted = ps.executeUpdate();
                            if (rowsDeleted > 0) {
                                message = "Employee " + employeeId + " deleted successfully!";
                            } else {
                                error = "Employee ID " + employeeId + " not found.";
                            }
                        } catch (NumberFormatException e) {
                            error = "Please enter a valid Employee ID.";
                        } catch (SQLException e) {
                            String sqlError = e.getMessage();
                            if (sqlError.contains("foreign key")) {
                                error = "Cannot delete this employee as they have either rentals or bookings.";
                            } else {
                                error = "Database error: " + e.getMessage();
                            }
                        }
                    }

        //Seventh: Promoting or demoting an emplyoee
        else if ("updateEmployeeManager".equals(action)) {
            try {
                int employeeId = Integer.parseInt(request.getParameter("employeeId"));
                String managerStatus = request.getParameter("isManager");

                if (managerStatus == null) {
                    error = "Please select either Promote or Demote.";
                } else {
                    boolean isManagerEmp = "true".equals(managerStatus);

                    // Check if employee exists
                    ps = conn.prepareStatement("SELECT IsManager, HotelID FROM Employee WHERE EmployeeID = ?");
                    ps.setInt(1, employeeId);
                    rs = ps.executeQuery();

                    if (!rs.next()) {
                        error = "Employee ID " + employeeId + " not found.";
                    } else {

                        // Demotion logic
                        if (!isManagerEmp && rs.getBoolean("IsManager")) {
                            int hotelId = rs.getInt("HotelID");

                            ps = conn.prepareStatement("SELECT COUNT(*) FROM Employee WHERE HotelID = ? AND IsManager = TRUE");
                            ps.setInt(1, hotelId);
                            ResultSet rs2 = ps.executeQuery();
                            rs2.next();
                            int managerCount = rs2.getInt(1);
                            rs2.close();

                            if (managerCount <= 1) {
                                error = "Cannot demote the last manager of a hotel.";
                            } else {
                                ps = conn.prepareStatement("UPDATE Employee SET IsManager = ? WHERE EmployeeID = ?");
                                ps.setBoolean(1, isManagerEmp);
                                ps.setInt(2, employeeId);
                                ps.executeUpdate();
                                message = "Employee " + employeeId + " demoted successfully!";
                            }

                        } else {
                            // Promotion or normal update
                            ps = conn.prepareStatement("UPDATE Employee SET IsManager = ? WHERE EmployeeID = ?");
                            ps.setBoolean(1, isManagerEmp);
                            ps.setInt(2, employeeId);

                            int rowsUpdated = ps.executeUpdate();
                            if (rowsUpdated > 0) {
                                message = "Employee " + employeeId + " promoted successfully!";
                            } else {
                                error = "Employee ID " + employeeId + " not found.";
                            }
                        }
                    }
                }

            } catch (NumberFormatException e) {
                error = "Please enter a valid Employee ID.";
            } catch (SQLException e) {
                String sqlError = e.getMessage();
                if (sqlError.contains("must have at least one manager")) {
                    error = "Cannot demote the last manager of a hotel.";
                } else {
                    error = "Database error: " + e.getMessage();
                }
            }
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
        Manager ID: <%= session.getAttribute("employeeId") != null ? session.getAttribute("employeeId") : "101" %> |
        Hotel ID: <%= session.getAttribute("employeeHotelId") != null ? session.getAttribute("employeeHotelId") : "11" %>
    </div>
    <a href="employee.jsp">Go to Employee Dashboard</a>
    <a href="index.jsp">Back to Login Page</a>

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
            Demote Manager: <input type="checkbox" name="isManager" value="false"><br>
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
