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

        String role = request.getParameter("role");
        String idStr = request.getParameter("id");

        if (idStr == null || idStr.isEmpty()) {
            request.setAttribute("error", "Please enter your ID.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
            return;
        }

        int id = Integer.parseInt(idStr);

        try (Connection db = connection.getConnection()) {

            if ("customer".equals(role)) {
                PreparedStatement ps = db.prepareStatement(
                        "SELECT CustomerID, full_name FROM Customer WHERE CustomerID = ?"
                );
                ps.setInt(1, id);
                ResultSet rs = ps.executeQuery();

                if (rs.next()) {
                    HttpSession session = request.getSession();
                    session.setAttribute("customerId", rs.getInt("CustomerID"));
                    session.setAttribute("customerName", rs.getString("full_name"));
                    session.setAttribute("role", "customer");
                    response.sendRedirect("customer.jsp");
                } else {
                    request.setAttribute("error", "Customer ID not found.");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                }

            } else if ("employee".equals(role)) {
                PreparedStatement ps = db.prepareStatement(
                        "SELECT EmployeeID, full_name FROM Employee WHERE EmployeeID = ?"
                );
                ps.setInt(1, id);
                ResultSet rs = ps.executeQuery();

                if (rs.next()) {
                    HttpSession session = request.getSession();
                    session.setAttribute("employeeId", rs.getInt("EmployeeID"));
                    session.setAttribute("employeeName", rs.getString("full_name"));
                    session.setAttribute("role", "employee");
                    response.sendRedirect("employee.jsp");
                } else {
                    request.setAttribute("error", "Employee ID not found.");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                }
            }

        } catch (SQLException e) {
            request.setAttribute("error", "Database error: " + e.getMessage());
            request.getRequestDispatcher("login.jsp").forward(request, response);
        }
    }
}