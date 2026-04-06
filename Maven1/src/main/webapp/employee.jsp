<%@ page import="connect.connection" %>
<%@ page import="java.sql.*, java.util.*, java.text.SimpleDateFormat" %>
<%@ page import="java.util.List, java.util.Map, java.util.ArrayList, java.util.HashMap" %>
<%@ page import="java.sql.Date" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String message = "";
    String error = "";
    //Have the page save the role of employee in a session
    session.setAttribute("role", "employee"); //saves like a key in a dictionary
    String action= request.getParameter("action"); // gets the result of what was clicked on in the UI
    Connection conn = null; //make a connection (but wait to assign a value until were in the try block
    PreparedStatement ps = null; // makes a variable for the query and adds val in try block
    ResultSet rs = null;

    //STILL NEED TO ADD A WAY TO GET THE EMPLOYEE NUMBER FROM THE LOGIN PAGE
    //Adding default for now TAKE THIS OUT LATER LACIA!!!
    int defaultEmployeeId = 9001; // or whatever employee ID you want to use for now

    // Look up their hotel ID (for when we add new customers and need the hotel ID we can just get it from the employee number
    Connection tempConn = null;
    PreparedStatement tempPs = null;
    ResultSet tempRs = null;
    try {
        tempConn = connection.getConnection();
        tempPs = tempConn.prepareStatement("SELECT HotelID FROM Employee WHERE EmployeeID = ?");
        tempPs.setInt(1, defaultEmployeeId);
        tempRs = tempPs.executeQuery();
        if (tempRs.next()) {
            session.setAttribute("employeeHotelId", tempRs.getInt("HotelID"));
        } else {
            session.setAttribute("employeeHotelId", 101); // fallback
        }
        } catch (Exception e) {
            session.setAttribute("employeeHotelId", 101);
        } finally {
            if (tempConn != null) try { tempConn.close(); } catch (SQLException e) {}
        }

    try {// go through all of the possible employee actions!
        conn=connection.getConnection();

        //First: Checking in a customer that already had a booking
        //Employee inputs bookID, customerID and their emplotee number and we should be able to find a booking
        if("checkin".equals(action)){
            int customerId=Integer.parseInt(request.getParameter("customerId"));
            int bookId=Integer.parseInt(request.getParameter("bookId"));
            int employeeId=Integer.parseInt(request.getParameter("employeeId"));

            //check that the booking really does belong to this customer
            ps = conn.prepareStatement("SELECT b.HotelID, b.RoomNumber, b.StartDate, b.EndDate, c.full_name FROM Booking b JOIN Customer c ON b.CustomerID = c.CustomerID WHERE b.BookID = ? AND b.CustomerID = ?");
            ps.setInt(1, bookId);
            ps.setInt(2, customerId);
            rs=ps.executeQuery();//data received from the quet is put into the result set
            if(rs.next()){ //Now we inseert the values received into the rentin gtable
                //First we give each result a variable
                String customerName = rs.getString("full_name"); // Get customer name
                int hotelId = rs.getInt("HotelID");
                int roomNumber = rs.getInt("RoomNumber");
                Date startDate = rs.getDate("StartDate");
                Date endDate = rs.getDate("EndDate");

                ps=conn.prepareStatement( "INSERT INTO Renting (CustomerID, BookID, HotelID, RoomNumber, EmployeeID, CheckinDate, CheckoutDate, PaymentAmount)"+ "VALUES (?,?,?,?,?,?,?,?)");
                ps.setInt(1, customerId);
                ps.setInt(2, bookId);
                ps.setInt(3, hotelId);
                ps.setInt(4, roomNumber);
                ps.setInt(5, employeeId);
                ps.setDate(6, startDate);
                ps.setDate(7, endDate);
                ps.setDouble(8, 0.00);
                ps.executeUpdate();

                //Send the booking to the booking archive by activating the trigger on delete
                ps = conn.prepareStatement("DELETE FROM Booking WHERE BookID = ?");
                ps.setInt(1, bookId);
                ps.executeUpdate();

                message = customerName + " (ID: " + customerId + ") checked in successfully!";
            } else {
                error = "Booking ID " + bookId + " not found for Customer " + customerId;
            }
        }

        //Second: Wlk in rental
        //Flow One: If a cutomer walks in and is not in the system we add customer first then add a rental
        //Flow Two: If a customer is already in the sequence then all that is needed is to add then rental
        //First step, we check if the room they want is even available or if we at capacity
        else if ("walkin".equals(action)) {
            // Get employee info saved in the session
            int employeeId = (Integer) session.getAttribute("employeeId");
            int hotelId = (Integer) session.getAttribute("employeeHotelId");

            //give customer info given in through a form their own variables
            String customerSin = request.getParameter("customerSin");
            String customerName = request.getParameter("customerName");
            String customerAddress = request.getParameter("customerAddress");
            String customerPhone = request.getParameter("customerPhone");

            //Get what type of room the customer wants
            int desiredCapacity = Integer.parseInt(request.getParameter("desiredCapacity"));
            String preferredView = request.getParameter("preferredView");
            Date checkinDate = Date.valueOf(request.getParameter("checkinDate"));
            Date checkoutDate = Date.valueOf(request.getParameter("checkoutDate"));
            double paymentAmount = Double.parseDouble(request.getParameter("paymentAmount"));

            //Query to fin which rooms are available based on the customers prefernce
            ps = conn.prepareStatement(
                "SELECT r.HotelID, r.RoomNumber, r.Price, r.Capacity, r.RoomView " + "FROM Room r " + "WHERE r.HotelID = ? " + "AND r.Capacity >= ? " +
                "AND r.RoomView = ? " + "AND r.ProblemDamageStatus = FALSE " + "AND NOT EXISTS ( " +"SELECT 1 FROM Renting rt " +
                "WHERE rt.HotelID = r.HotelID " +"AND rt.RoomNumber = r.RoomNumber " +"AND rt.CheckinDate < ?" +"AND rt.CheckoutDate > ?" +
                ")" + "ORDER BY r.Price LIMIT 10"
            );
            ps.setInt(1, hotelId);
            ps.setInt(2, desiredCapacity);
            ps.setString(3, preferredView);
            ps.setDate(4, checkoutDate);
            ps.setDate(5, checkinDate);
            rs = ps.executeQuery();

            // Put the results found in a list (availableRooms)
            List<Map<String, Object>> availableRooms = new ArrayList<Map<String, Object>>();
            while (rs.next()) {
                Map<String, Object> room = new HashMap<String, Object>();
                room.put("roomNumber", rs.getInt("RoomNumber"));
                room.put("price", rs.getDouble("Price"));
                room.put("capacity", rs.getInt("Capacity"));
                room.put("view", rs.getString("RoomView"));
                availableRooms.add(room);
            }

            if (availableRooms.isEmpty()) {//fallback for when were at capacity
                error = "No available rooms matching your criteria for the selected dates.";
            } else {
                //Store all the available rooms (the rooms in the list) in session before heading to selectRoom.jsp
                session.setAttribute("availableRooms", availableRooms);
                session.setAttribute("customerSin", customerSin);
                session.setAttribute("customerName", customerName);
                session.setAttribute("customerAddress", customerAddress);
                session.setAttribute("customerPhone", customerPhone);
                session.setAttribute("checkinDate", checkinDate);
                session.setAttribute("checkoutDate", checkoutDate);
                session.setAttribute("paymentAmount", paymentAmount);

                //Now when the emplyoee goes to display the available rooms, theyll be shown in selectRoom.jsp where well finish the rental!!
                response.sendRedirect("selectRoom.jsp");
                return;
            }
        }

    //Third: Adding a payment separate from the rental
    //Since in the database payment is a notnull feature, add payment will be to update the payment section for if a customer wants to pay more later(maybe if they extended their stay?)
    // Add Payment section - UPDATES existing payment
    else if ("addPayment".equals(action)) {
        int rentingId = Integer.parseInt(request.getParameter("rentingId"));
        double amount = Double.parseDouble(request.getParameter("amount"));
        ps = conn.prepareStatement("UPDATE Renting SET PaymentAmount = ? WHERE RentingID = ?");
        ps.setDouble(1, amount);
        ps.setInt(2, rentingId);
        ps.executeUpdate();
        message = "Payment updated for Renting #" + rentingId;
    }
    //Fourth: Looking up a customer using SIN number
    //Employees can quickly find a customer by looking them up
    else if ("lookupCustomer".equals(action)) {
        String sin = request.getParameter("sin");
        ps = conn.prepareStatement("SELECT * FROM Customer WHERE sin_number = ?");
        ps.setString(1, sin);
        rs = ps.executeQuery();
        if (rs.next()) {
            request.setAttribute("foundCustomer", rs);
        } else {
            error = "Customer with SIN " + sin + " not found";
        }
    }

    //Fifth: Adding a new customer
    //Employee can add a new customer without a rental being there (just adding them to the database manually)
    else if ("addCustomer".equals(action)) {
        int customerId = Integer.parseInt(request.getParameter("customerId"));
        String fullName = request.getParameter("full_name");
        String sinNumber = request.getParameter("sin_number");
        String custAddress = request.getParameter("CustAddress");
        Date regDate = Date.valueOf(request.getParameter("date_of_registration"));
        String phoneNumber = request.getParameter("phone_number");

        ps = conn.prepareStatement(
            "INSERT INTO Customer (CustomerID, full_name, sin_number, CustAddress, date_of_registration, phone_number) " +
            "VALUES (?, ?, ?, ?, ?, ?)"
        );
        ps.setInt(1, customerId);
        ps.setString(2, fullName);
        ps.setString(3, sinNumber);
        ps.setString(4, custAddress);
        ps.setDate(5, regDate);
        ps.setString(6, phoneNumber);
        ps.executeUpdate();

        message = "Customer " + fullName + " added successfully!";
    }

    //Seventh: Editing already existing customer info
    //Employee can update any customers info
    else if ("editCustomer".equals(action)) {
        int customerId = Integer.parseInt(request.getParameter("customerId"));
        String fullName = request.getParameter("full_name");
        String sinNumber = request.getParameter("sin_number");
        String custAddress = request.getParameter("CustAddress");
        String phoneNumber = request.getParameter("phone_number");

        ps = conn.prepareStatement(
            "UPDATE Customer SET full_name=?, sin_number=?, CustAddress=?, phone_number=? WHERE CustomerID=?"
        );
        ps.setString(1, fullName);
        ps.setString(2, sinNumber);
        ps.setString(3, custAddress);
        ps.setString(4, phoneNumber);
        ps.setInt(5, customerId);
        ps.executeUpdate();

        message = "Customer " + fullName + " (ID: " + customerId + ") updated successfully!";
    }

    //Eigth: Deleting a customer
    //Employee can delete a customer from the databasse
    else if ("deleteCustomer".equals(action)) {
        int customerId = Integer.parseInt(request.getParameter("customerId"));
        ps = conn.prepareStatement("SELECT full_name FROM Customer WHERE CustomerID = ?");
        ps.setInt(1, customerId);
        rs = ps.executeQuery();
        String customerName = rs.next() ? rs.getString("full_name") : "Unknown";
        ps = conn.prepareStatement("DELETE FROM Customer WHERE CustomerID = ?");
        ps.setInt(1, customerId);
        ps.executeUpdate();
        message = "Customer " + customerName + " (ID: " + customerId + ") deleted successfully!";
    }

    //Ninth: Viewing Total capacity
    //Employe can see the total capacity of that hotel
    else if ("viewCapacity".equals(action)) {
        Statement stmt = conn.createStatement();
        rs = stmt.executeQuery("SELECT * FROM HotelTotalCapacity");
        request.setAttribute("capacityData", rs);
    }

    //Tenth: Searching for available rooms
    else if ("customerSearch".equals(action)) {
        String checkin = request.getParameter("checkin");
        String checkout = request.getParameter("checkout");
        String city = request.getParameter("city");
        String capacity = request.getParameter("capacity");
        String priceStr = request.getParameter("price");
        String seaView = request.getParameter("sea");
        String mountainView = request.getParameter("mountain");
        String extendable = request.getParameter("extendable");
        String starRating = request.getParameter("starRating");
        String chain = request.getParameter("chain");

        int price = (priceStr != null && !priceStr.isEmpty()) ? Integer.parseInt(priceStr) : Integer.MAX_VALUE;

        String sql = "SELECT r.HotelID, r.RoomNumber, r.Price, r.Capacity, r.RoomView, r.ExtendableStatus, " +
                     "h.HotelAddress, h.StarRating " +
                     "FROM Room r " +
                     "JOIN Hotel h ON r.HotelID = h.HotelID " +
                     "WHERE r.ProblemDamageStatus = FALSE " +
                     "AND NOT EXISTS (SELECT 1 FROM Booking b WHERE b.HotelID = r.HotelID AND b.RoomNumber = r.RoomNumber " +
                     "AND b.StartDate < ? AND b.EndDate > ?) ";

        if (city != null && !city.isEmpty()) {
            sql += " AND h.HotelAddress LIKE '%" + city + "%'";
        }
        if (capacity != null && !capacity.isEmpty()) {
            sql += " AND r.Capacity >= " + capacity;
        }
        if (priceStr != null && !priceStr.isEmpty()) {
            sql += " AND r.Price <= " + price;
        }
        if (starRating != null && !starRating.isEmpty()) {
            sql += " AND h.StarRating >= " + starRating;
        }
        if (chain != null && !chain.isEmpty()) {
            sql += " AND h.ChainID = " + chain;
        }
        if ("yes".equals(seaView)) {
            sql += " AND r.RoomView = 'sea'";
        }
        if ("yes".equals(mountainView)) {
            sql += " AND r.RoomView = 'mountain'";
        }
        if ("yes".equals(extendable)) {
            sql += " AND r.ExtendableStatus = TRUE";
        }

        sql += " ORDER BY r.Price LIMIT 20";

        ps = conn.prepareStatement(sql);
        ps.setString(1, checkout);
        ps.setString(2, checkin);
        rs = ps.executeQuery();
        request.setAttribute("searchResults", rs);
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
    <title>Employee Dashboard</title>
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

    <h1>Employee Dashboard</h1>
    <div class="info-bar">
        Employee ID: <%= session.getAttribute("employeeId") != null ? session.getAttribute("employeeId") : "9001" %> |
        Hotel ID: <%= session.getAttribute("employeeHotelId") != null ? session.getAttribute("employeeHotelId") : "101" %>
    </div>
    <a href="index.jsp">← Switch to Customer View</a>

    <% if (!message.isEmpty()) { %>
        <p class="success"><%= message %></p>
    <% } %>
    <% if (!error.isEmpty()) { %>
        <p class="error"><%= error %></p>
    <% } %>

    <!-- CHECK-IN -->
    <div class="section">
        <h2>Check-In (Booking to Renting)</h2>
        <form method="post">
            <input type="hidden" name="action" value="checkin">
            Customer ID: <input type="number" name="customerId" required><br>
            Booking ID: <input type="number" name="bookId" required><br>
            Employee ID: <input type="number" name="employeeId" required><br>
            <button type="submit">Check In</button>
        </form>
    </div>

    <!-- WALK-IN RENTAL -->
    <div class="section">
        <h2>Walk-in Rental</h2>
        <form method="post">
            <input type="hidden" name="action" value="walkin">
            SIN: <input type="text" name="customerSin" required><br>
            Full Name: <input type="text" name="customerName" required><br>
            Address: <input type="text" name="customerAddress" required><br>
            Phone: <input type="text" name="customerPhone" required><br>
            Capacity:
            <select name="desiredCapacity">
                <option value="1">1</option><option value="2">2</option>
                <option value="3">3</option><option value="4">4</option><option value="5">5+</option>
            </select><br>
            View:
            <select name="preferredView">
                <option value="sea">Sea</option><option value="mountain">Mountain</option>
            </select><br>
            Check-in: <input type="date" name="checkinDate" required><br>
            Check-out: <input type="date" name="checkoutDate" required><br>
            Payment: $<input type="number" step="0.01" name="paymentAmount" required><br>
            <button type="submit">Find Rooms</button>
        </form>
    </div>

    <!-- ADD PAYMENT -->
    <div class="section">
        <h2>Add/Update Payment</h2>
        <form method="post">
            <input type="hidden" name="action" value="addPayment">
            Renting ID: <input type="number" name="rentingId" required>
            Amount: $<input type="number" step="0.01" name="amount" required>
            <button type="submit">Update Payment</button>
        </form>
    </div>

    <!-- LOOKUP CUSTOMER -->
    <div class="section">
        <h2>Lookup Customer by SIN</h2>
        <form method="post">
            <input type="hidden" name="action" value="lookupCustomer">
            SIN: <input type="text" name="sin" required>
            <button type="submit">Search</button>
        </form>
        <% if (request.getAttribute("foundCustomer") != null) {
            ResultSet found = (ResultSet) request.getAttribute("foundCustomer");
            if (found.next()) {
        %>
            <p><strong>ID:</strong> <%= found.getInt("CustomerID") %></p>
            <p><strong>Name:</strong> <%= found.getString("full_name") %></p>
            <p><strong>SIN:</strong> <%= found.getString("sin_number") %></p>
            <p><strong>Address:</strong> <%= found.getString("CustAddress") %></p>
            <p><strong>Phone:</strong> <%= found.getString("phone_number") %></p>
        <% } } %>
    </div>

    <!-- CUSTOMER MANAGEMENT -->
    <div class="section">
        <h2>Customer Management</h2>

        <h3>Add Customer</h3>
        <form method="post">
            <input type="hidden" name="action" value="addCustomer">
            ID: <input type="number" name="customerId" required><br>
            Name: <input type="text" name="full_name" required><br>
            SIN: <input type="text" name="sin_number" required><br>
            Address: <input type="text" name="CustAddress" required><br>
            Reg Date: <input type="date" name="date_of_registration" required><br>
            Phone: <input type="text" name="phone_number" required><br>
            <button type="submit">Add Customer</button>
        </form>

        <h3>Edit Customer</h3>
        <form method="post">
            <input type="hidden" name="action" value="editCustomer">
            ID: <input type="number" name="customerId" required><br>
            Name: <input type="text" name="full_name" required><br>
            SIN: <input type="text" name="sin_number" required><br>
            Address: <input type="text" name="CustAddress" required><br>
            Phone: <input type="text" name="phone_number" required><br>
            <button type="submit">Update Customer</button>
        </form>

        <h3>Delete Customer</h3>
        <form method="post" onsubmit="return confirm('Delete this customer?');">
            <input type="hidden" name="action" value="deleteCustomer">
            ID: <input type="number" name="customerId" required>
            <button type="submit">Delete Customer</button>
        </form>
    </div>

    <!-- VIEW CAPACITY -->
    <div class="section">
        <h2>Total Capacity Per Hotel</h2>
        <form method="post">
            <input type="hidden" name="action" value="viewCapacity">
            <button type="submit">Refresh</button>
        </form>
        <% if (request.getAttribute("capacityData") != null) {
            ResultSet capData = (ResultSet) request.getAttribute("capacityData");
        %>
            <table>
                <tr><th>Hotel ID</th><th>Total Capacity</th></tr>
                <% while (capData.next()) { %>
                    <tr><td><%= capData.getInt("HotelID") %></td><td><%= capData.getInt("TotalCapacity") %></td></tr>
                <% } %>
            </table>
        <% } %>
    </div>

    <!-- CUSTOMER SEARCH SECTION (copied from customer.jsp) -->
    <div class="section">
        <h2>Search Available Rooms</h2>

        <form action="employeeDashboard.jsp" method="post">
            <input type="hidden" name="action" value="customerSearch">

            <label for="checkin">Check-in date:</label>
            <input type="date" id="checkin" name="checkin" required>
            <br>

            <label for="checkout">Check-out date:</label>
            <input type="date" id="checkout" name="checkout" required>
            <br>

            <label for="city">City:</label>
            <select id="city" name="city">
                <option value="">Select City</option>
                <option value="Toronto">Toronto</option>
                <option value="Ottawa">Ottawa</option>
                <option value="Hamilton">Hamilton</option>
                <option value="London">London</option>
                <option value="Vancouver">Vancouver</option>
                <option value="Montreal">Montreal</option>
                <option value="Calgary">Calgary</option>
                <option value="Edmonton">Edmonton</option>
            </select>
            <br>

            <label for="capacity">Minimum Capacity:</label>
            <input type="number" id="capacity" name="capacity" min="1" max="10" placeholder="e.g. 2">
            <br>

            <label for="starRating">Minimum Star Rating (1-5):</label>
            <input type="number" id="starRating" name="starRating" min="1" max="5" placeholder="e.g. 3">
            <br>

            <label for="price">Max Price per night ($):</label>
            <input type="number" id="price" name="price" placeholder="e.g. 200">
            <br>

            <label for="chain">Hotel Chain:</label>
            <select id="chain" name="chain">
                <option value="">Select Chain</option>
                <option value="1">Chain 1</option>
                <option value="2">Chain 2</option>
                <option value="3">Chain 3</option>
                <option value="4">Chain 4</option>
                <option value="5">Chain 5</option>
            </select>
            <br>

            <label>Extras:</label>
            <input type="checkbox" name="sea" value="yes"> Sea View
            <input type="checkbox" name="mountain" value="yes"> Mountain View
            <input type="checkbox" name="extendable" value="yes"> Extendable
            <br><br>

            <button type="submit" name="action" value="customerSearch">Search Available Rooms</button>
        </form>
    </div>

 <!-- SEARCH RESULTS SECTION -->
 <% if (request.getAttribute("searchResults") != null) {
     ResultSet searchRs = (ResultSet) request.getAttribute("searchResults");
 %>
     <div class="section">
         <h2>Search Results</h2>
         <% if (!searchRs.isBeforeFirst()) { %>
             <p>No rooms found matching your criteria.</p>
         <% } else { %>
             <table border="1">
                 <tr>
                     <th>Hotel ID</th>
                     <th>Room #</th>
                     <th>Address</th>
                     <th>Capacity</th>
                     <th>Price/Night</th>
                     <th>View</th>
                     <th>Extendable</th>
                     <th>Stars</th>
                 </tr>
                 <% while (searchRs.next()) { %>
                     <tr>
                         <td><%= searchRs.getInt("HotelID") %></td>
                         <td><%= searchRs.getInt("RoomNumber") %></td>
                         <td><%= searchRs.getString("HotelAddress") %></td>
                         <td><%= searchRs.getInt("Capacity") %></td>
                         <td>$<%= searchRs.getDouble("Price") %></td>
                         <td><%= searchRs.getString("RoomView") %></td>
                         <td><%= searchRs.getBoolean("ExtendableStatus") ? "Yes" : "No" %></td>
                         <td><%= searchRs.getInt("StarRating") %></td>
                     </tr>
                 <% } %>
             </table>
         <% } %>
     </div>
 <% } %>


</body>
</html>

