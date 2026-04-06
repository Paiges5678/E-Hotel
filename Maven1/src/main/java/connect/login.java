package connect;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.*;

@WebServlet("/LoginServlet")
public class login extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        String role   = request.getParameter("role");   // customer or employee

        try (Connection db = connection.getConnection()) {

            if ("signup".equals(action)) {
                handleSignup(request, response, db);

            } else if ("login".equals(action)) {
                if ("customer".equals(role)) {
                    handleCustomerLogin(request, response, db);
                } else if ("employee".equals(role)) {
                    handleEmployeeLogin(request, response, db);
                } else {
                    forwardError(request, response, "Unknown role: " + role);
                }

            } else {
                forwardError(request, response, "Unknown action.");
            }

        } catch (Exception e) {
            e.printStackTrace();
            forwardError(request, response,
                    "Database connection failed: " + e.getMessage()
                            + " — check that your JDBC driver jar is in WEB-INF/lib "
                            + "and that connection.getConnection() has the right URL/user/password.");
        }
    }

    // Customer login — look up by CustomerID
    private void handleCustomerLogin(HttpServletRequest request,
                                     HttpServletResponse response,
                                     Connection db)
            throws ServletException, IOException, SQLException {

        String idStr = request.getParameter("id");
        if (idStr == null || idStr.isEmpty()) {
            forwardError(request, response, "Please enter your Customer ID.");
            return;
        }

        int id = Integer.parseInt(idStr);
        System.out.println("DEBUG customerLogin: id=" + id);

        PreparedStatement ps = db.prepareStatement(
                "SELECT CustomerID, full_name FROM Customer WHERE CustomerID = ?"
        );
        ps.setInt(1, id);
        ResultSet rs = ps.executeQuery();

        if (rs.next()) {
            HttpSession session = request.getSession();
            session.setAttribute("customerId",   rs.getInt("CustomerID"));
            session.setAttribute("customerName", rs.getString("full_name"));
            session.setAttribute("role",         "customer");
            System.out.println("DEBUG customerLogin: found " + rs.getString("full_name"));
            response.sendRedirect("customer.jsp");
        } else {
            System.out.println("DEBUG customerLogin: not found");
            forwardError(request, response, "No customer found with ID " + id + ".");
        }
    }

    // Employee login — look up by EmployeeID, enforce IsManager if toggle
    private void handleEmployeeLogin(HttpServletRequest request,
                                     HttpServletResponse response,
                                     Connection db)
            throws ServletException, IOException, SQLException {

        String idStr   = request.getParameter("id");
        String empRole = request.getParameter("empRole"); // manager or employee

        if (idStr == null || idStr.isEmpty()) {
            forwardError(request, response, "Please enter your Employee ID.");
            return;
        }

        int id = Integer.parseInt(idStr);
        boolean wantsManager = "manager".equalsIgnoreCase(empRole);
        System.out.println("DEBUG employeeLogin: id=" + id + " wantsManager=" + wantsManager);

        PreparedStatement ps = db.prepareStatement(
                "SELECT EmployeeID, full_name, IsManager, HotelID FROM Employee WHERE EmployeeID = ?"
        );
        ps.setInt(1, id);
        ResultSet rs = ps.executeQuery();

        if (!rs.next()) {
            forwardError(request, response, "No employee found with ID " + id + ".");
            return;
        }

        boolean isManager = rs.getBoolean("IsManager");

        // Block if Manager is toggled but isManager is false
        if (wantsManager && !isManager) {
            forwardError(request, response,
                    "Employee #" + id + " does not have manager privileges.");
            return;
        }

        HttpSession session = request.getSession();
        session.setAttribute("employeeId", rs.getInt("EmployeeID"));
        session.setAttribute("employeeName", rs.getString("full_name"));
        session.setAttribute("hotelId", rs.getInt("HotelID"));
        session.setAttribute("isManager",isManager);
        session.setAttribute("role", wantsManager ? "manager" : "employee");

        System.out.println("DEBUG employeeLogin: found " + rs.getString("full_name")
                + " isManager=" + isManager);

        // Send managers to a different page if you have one otherwise both go to employee.jsp
        response.sendRedirect(wantsManager ? "manager.jsp" : "employee.jsp");
    }

    // Customer sign-Up — insert new row into customer table
    private void handleSignup(HttpServletRequest request,
                              HttpServletResponse response,
                              Connection db)
            throws ServletException, IOException, SQLException {

        // Parse and validate inputs
        String customerIDStr = request.getParameter("customerID");
        String fullName = request.getParameter("fullName");
        String sin = request.getParameter("sin");
        String address = request.getParameter("address");
        String dateReg = request.getParameter("dateOfRegistration");
        String phone= request.getParameter("phone");

        if (customerIDStr == null || fullName == null || sin == null
                || address == null || dateReg == null || phone == null
                || fullName.trim().isEmpty() || sin.trim().isEmpty()) {
            forwardError(request, response, "All fields are required.");
            return;
        }

        int customerID = Integer.parseInt(customerIDStr);

        // Check for duplicate id or sin before inserting
        PreparedStatement checkPs = db.prepareStatement(
                "SELECT 1 FROM Customer WHERE CustomerID = ? OR sin_number = ?"
        );
        checkPs.setInt(1, customerID);
        checkPs.setString(2, sin);
        ResultSet checkRs = checkPs.executeQuery();
        if (checkRs.next()) {
            forwardError(request, response,
                    "A customer with that ID or SIN already exists.");
            return;
        }

        // Insert the new customer
        PreparedStatement ps = db.prepareStatement(
                "INSERT INTO Customer (CustomerID, full_name, sin_number, CustAddress, " +
                        "date_of_registration, phone_number) VALUES (?, ?, ?, ?, ?, ?)"
        );
        ps.setInt(1, customerID);
        ps.setString(2, fullName);
        ps.setString(3, sin);
        ps.setString(4, address);
        ps.setDate(5, Date.valueOf(dateReg));
        ps.setString(6, phone);
        ps.executeUpdate();

        System.out.println("DEBUG signup: created customer id=" + customerID);

        // Auto-login the new customer
        HttpSession session = request.getSession();
        session.setAttribute("customerId",   customerID);
        session.setAttribute("customerName", fullName);
        session.setAttribute("role",         "customer");
        response.sendRedirect("customer.jsp");
    }

    // attach error message and forward back to index.jsp
    private void forwardError(HttpServletRequest request,
                              HttpServletResponse response,
                              String message)
            throws ServletException, IOException {
        request.setAttribute("error", message);
        request.getRequestDispatcher("index.jsp").forward(request, response);
    }
}