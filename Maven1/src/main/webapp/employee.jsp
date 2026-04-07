<%@ page import="connect.connection" %>
<%@ page import="java.sql.*, java.util.*, java.text.SimpleDateFormat, java.time.LocalDate" %>
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
    int defaultEmployeeId = 101; // or whatever employee ID you want to use for now

    // Set default employee info in session if not already set
    if (session.getAttribute("employeeId") == null) {
        session.setAttribute("employeeId", defaultEmployeeId);
    }
    if (session.getAttribute("employeeHotelId") == null) {
        session.setAttribute("employeeHotelId", 11); // Use a valid hotel ID that has rooms
    }
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
            session.setAttribute("employeeHotelId", 11); // fallback
        }
        } catch (Exception e) {
            session.setAttribute("employeeHotelId", 11);
        } finally {
            if (tempConn != null) try { tempConn.close(); } catch (SQLException e) {}
        }

    try {// go through all of the possible employee actions!
        conn=connection.getConnection();

        //First: Checking in a customer that already had a booking
        //Employee inputs bookID, customerID and their emplotee number and we should be able to find a booking
        if("checkin".equals(action)){
        try{
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
        } catch (NumberFormatException e) {  // INNER CATCH
                  error = "Please enter valid numbers for all fields.";
              }
             }

        //Second: Wlk in rental
        //Flow One: If a cutomer walks in and is not in the system we add customer first then add a rental
        //Flow Two: If a customer is already in the sequence then all that is needed is to add then rental
        //First step, we check if the room they want is even available or if we at capacity
        else if ("walkin".equals(action)) {
            try{
            // Get employee info saved in the session
            int employeeId = (Integer) session.getAttribute("employeeId");
            int hotelId = (Integer) session.getAttribute("employeeHotelId");

            //give customer info given in through a form their own variables
            String customerSin = request.getParameter("customerSin");
            int customerId = Integer.parseInt(request.getParameter("customerId"));
            String customerName = request.getParameter("customerName");
            String customerAddress = request.getParameter("customerAddress");
            String customerPhone = request.getParameter("customerPhone");

            //Get what type of room the customer wants
            int desiredCapacity = Integer.parseInt(request.getParameter("desiredCapacity"));
            String preferredView = request.getParameter("preferredView");
            Date checkinDate = Date.valueOf(request.getParameter("checkinDate"));
            Date checkoutDate = Date.valueOf(request.getParameter("checkoutDate"));
            double paymentAmount = Double.parseDouble(request.getParameter("paymentAmount"));

            // Date validation
                if (checkinDate.after(checkoutDate)) {
                    error = "Check-in date cannot be after check-out date.";
                } else if (checkinDate.before(java.sql.Date.valueOf(LocalDate.now()))) {                    error = "Check-in date cannot be in the past.";
                } else {

            //Query to fin which rooms are available based on the customers prefernce
            ps = conn.prepareStatement(
                "SELECT r.HotelID, r.RoomNumber, r.Price, r.Capacity, r.RoomView " + "FROM Room r " + "WHERE r.HotelID = ? " + "AND r.Capacity >= ? " +
                "AND r.RoomView = ? " + "AND r.ProblemDamageStatus = FALSE " + "AND NOT EXISTS ( " +"SELECT 1 FROM Renting rt " +
                "WHERE rt.HotelID = r.HotelID " +"AND rt.RoomNumber = r.RoomNumber " +"AND rt.CheckinDate < ? " + "AND rt.CheckoutDate > ?" +
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
                session.setAttribute("customerId", customerId);
                session.setAttribute("customerName", customerName);
                session.setAttribute("customerAddress", customerAddress);
                session.setAttribute("customerPhone", customerPhone);
                session.setAttribute("checkinDate", checkinDate);
                session.setAttribute("checkoutDate", checkoutDate);
                session.setAttribute("paymentAmount", paymentAmount);

                //Now when the employee goes to display the available rooms, theyll be shown in selectRoom.jsp where well finish the rental!!
                response.sendRedirect("selectRoom.jsp");
                return;
            }
        }
       } catch (NumberFormatException e) {
                       error = "Please enter valid numbers for Customer ID, Capacity, and Payment.";
                   } catch (IllegalArgumentException e) {
                       error = "Invalid date format. Please use the calender to pick a date.";
                   }
               }

    //Third: Adding a payment separate from the rental
    //Since in the database payment is a notnull feature, add payment will be to update the payment section for if a customer wants to pay more later(maybe if they extended their stay?)
    // Add Payment section UPDATES existing payment
    else if ("addPayment".equals(action)) {
        try{
        int rentingId = Integer.parseInt(request.getParameter("rentingId"));
        double amount = Double.parseDouble(request.getParameter("amount"));
        if (amount < 0) {
                            error = "Payment amount cannot be negative.";
                        } else {
        ps = conn.prepareStatement("UPDATE Renting SET paymentamount = ? WHERE RentingID = ?");
        ps.setDouble(1, amount);
        ps.setInt(2, rentingId);
        int rowsUpdated = ps.executeUpdate();
                            if (rowsUpdated > 0) {
                                message = "Payment updated for Renting #" + rentingId;
                            } else {
                                error = "Renting ID " + rentingId + " not found.";
                            }
                        }
                    } catch (NumberFormatException e) {
                        error = "Please enter valid numbers for Renting ID and Amount.";
                    }
                }
    //Fourth: Looking up a customer using SIN number
    //Employees can quickly find a customer by looking them up
    else if ("lookupCustomer".equals(action)) {
        String sin = request.getParameter("sin");
        if (sin == null || sin.isEmpty()) {
                        error = "Please enter a SIN number.";
                    } else {
        ps = conn.prepareStatement("SELECT * FROM Customer WHERE sin_number = ?");
        ps.setString(1, sin);
        rs = ps.executeQuery();
        if (rs.next()) {
            request.setAttribute("foundCustomer", rs);
        } else {
            error = "Customer with SIN " + sin + " not found";
        }
    }
    }

    //Fifth: Adding a new customer
    //Employee can add a new customer without a rental being there (just adding them to the database manually)
    else if ("addCustomer".equals(action)) {
        try {
        int customerId = Integer.parseInt(request.getParameter("customerId"));
        String fullName = request.getParameter("full_name");
        String sinNumber = request.getParameter("sin_number");
        String custAddress = request.getParameter("CustAddress");
        Date regDate = Date.valueOf(request.getParameter("date_of_registration"));
        String phoneNumber = request.getParameter("phone_number");

         if (fullName == null || fullName.isEmpty()) {
                            error = "Please enter customer name.";
                        } else if (sinNumber == null || sinNumber.isEmpty()) {
                            error = "Please enter SIN number.";
                        } else {
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
    }} catch (NumberFormatException e) {
                    error = "Please enter a valid Customer ID (number).";
                } catch (IllegalArgumentException e) {
                    error = "Invalid date format. Please use the date picker.";
                } catch (SQLException e) {
                              String sqlError = e.getMessage();
                              if (sqlError.contains("duplicate key") || sqlError.contains("unique constraint")) {
                                  error = "Customer ID already exists. Please use a different ID.";
                              } else {
                                  error = "Database error: " + e.getMessage();
                              }
                          }
                      }

    //Seventh: Editing already existing customer info
    //Employee can update any customers info
    else if ("editCustomer".equals(action)) {
        try{
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
        int rowsUpdated = ps.executeUpdate();
                if (rowsUpdated > 0) {
                    message = "Customer " + fullName + " (ID: " + customerId + ") updated successfully!";
                } else {
                    error = "Customer ID " + customerId + " not found.";
                }
            } catch (NumberFormatException e) {
                error = "Please enter a valid Customer ID.";
            }
        }

    //Eigth: Deleting a customer
    //Employee can delete a customer from the databasse
    else if ("deleteCustomer".equals(action)) {
    try{
        int customerId = Integer.parseInt(request.getParameter("customerId"));
        ps = conn.prepareStatement("SELECT full_name FROM Customer WHERE CustomerID = ?");
        ps.setInt(1, customerId);
        rs = ps.executeQuery();
        String customerName = rs.next() ? rs.getString("full_name") : "Unknown";
        ps = conn.prepareStatement("DELETE FROM Customer WHERE CustomerID = ?");
        ps.setInt(1, customerId);
        int rowsDeleted = ps.executeUpdate();
        if (rowsDeleted > 0) {
                            message = "Customer " + customerName + " (ID: " + customerId + ") deleted successfully!";
                        } else {
                            error = "Customer ID " + customerId + " not found.";
                        }
                    } catch (NumberFormatException e) {
                        error = "Please enter a valid Customer ID.";
                    } catch (SQLException e) {
                                  String sqlError = e.getMessage();
                                  if (sqlError.contains("foreign key constraint")) {
                                      error = "Cannot delete this customer as they have an existing rental or booking.";
                                  } else {
                                      error = "Database error: " + e.getMessage();
                                  }
                              }
                }

    //Ninth: Viewing Total capacity
    //Employe can see the total capacity of that hotel
    else if ("viewCapacity".equals(action)) {
        Statement stmt = conn.createStatement();
        rs = stmt.executeQuery("SELECT * FROM HotelTotalCapacity");
        request.setAttribute("capacityData", rs);
        message = "Capacity data refreshed.";
    }

    //Tenth: Searching for available rooms
    else if ("customerSearch".equals(action)) {
        String checkin = request.getParameter("checkin");
        String checkout = request.getParameter("checkout");

        if (checkin == null || checkin.isEmpty()) {
                        error = "Please select check-in date.";
                    } else if (checkout == null || checkout.isEmpty()) {
                        error = "Please select check-out date.";
                    } else {
                        try {
                        java.time.LocalDate start = java.time.LocalDate.parse(checkin);
                            java.time.LocalDate end = java.time.LocalDate.parse(checkout);
                            java.time.LocalDate today = java.time.LocalDate.now();

                            if (start.isAfter(end)) {
                                error = "Check-in date cannot be after check-out date.";
                            } else if (start.isBefore(today)) {
                                error = "Cannot search for dates in the past.";
                            } else {

        String city = request.getParameter("city");
        String capacity = request.getParameter("capacity");
        String priceStr = request.getParameter("price");
        String view = request.getParameter("view");
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
        if (view != null && !view.isEmpty()) {
            sql += " AND r.RoomView = '" + view + "'";
        }

        if ("yes".equals(extendable)) {
            sql += " AND r.ExtendableStatus = TRUE";
        }

        sql += " ORDER BY r.Price LIMIT 20";

        ps = conn.prepareStatement(sql);
        ps.setDate(1, java.sql.Date.valueOf(checkout));
        ps.setDate(2, java.sql.Date.valueOf(checkin));
        rs = ps.executeQuery();
        request.setAttribute("searchResults", rs);
    }

    } catch (Exception e) {
                        error = "Invalid date format. Please use the date picker.";
                    }
                }
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
        Employee ID: <%= session.getAttribute("employeeId") != null ? session.getAttribute("employeeId") : "101" %> |
        Hotel ID: <%= session.getAttribute("employeeHotelId") != null ? session.getAttribute("employeeHotelId") : "11" %>
    </div>
    <a href="index.jsp">Back to login</a>

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
            CustomerID: <input type="text" name="customerId" required><br>
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
           <div style="margin-top: 10px; padding: 10px; border: 1px solid green; background-color: #e8f5e9;">
               <p><strong>ID:</strong> <%= found.getInt("CustomerID") %></p>
               <p><strong>Name:</strong> <%= found.getString("full_name") %></p>
               <p><strong>SIN:</strong> <%= found.getString("sin_number") %></p>
               <p><strong>Address:</strong> <%= found.getString("CustAddress") %></p>
               <p><strong>Phone:</strong> <%= found.getString("phone_number") %></p>
           </div>
       <%
           } else {
       %>
           <p style="color: red; margin-top: 10px;">No customer found with that SIN.</p>
       <%
           }
       } %>
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

        <form action="employee.jsp" method="post">
            <input type="hidden" name="action" value="customerSearch">

            <label for="checkin">Check-in date:</label>
            <input type="date" id="checkin" name="checkin" required>
            <br>

            <label for="checkout">Check-out date:</label>
            <input type="date" id="checkout" name="checkout" required>
            <br>

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

            <label for="capacity">Minimum Capacity:</label>
            <input type="number" id="capacity" name="capacity" min="1" max="10" placeholder="e.g. 2">
            <br>

            <label for="starRating">Minimum Star Rating (1-5):</label>
            <input type="number" id="starRating" name="starRating" min="1" max="5" placeholder="e.g. 3">
            <br>

            <label for="price">Max Price per night ($):</label>
            <input type="number" id="price" name="price" max = "2000" placeholder="e.g. 200">
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
                <button type="submit">Search Available Rooms</button></form>
    </div>

 <!-- SEARCH RESULTS SECTION -->
 <%
     if ("customerSearch".equals(action)) {
         String checkin = request.getParameter("checkin");
         String checkout = request.getParameter("checkout");

         // Date validation
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
             // Only show results if dates are valid and search was performed
             if (request.getAttribute("searchResults") != null) {
                 ResultSet searchRs = (ResultSet) request.getAttribute("searchResults");
 %>
         <div class="section">
             <h2>Available Rooms</h2>
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
 <%
             }
         }
     }
 %>


</body>
</html>

