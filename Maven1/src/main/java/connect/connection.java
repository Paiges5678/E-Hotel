package connect;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class connection {
    private static final String URL = "jdbc:postgresql://localhost:5432/ehotels_db";
    private static final String USER = "postgres";
    private static final String PASSWORD = "M4rc1a32!!";

    public static Connection getConnection() throws SQLException {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
            throw new SQLException("PostgreSQL JDBC Driver not found!");
        }
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }

    // Add this method
    public static String test() {
        return "Connection class is working!";
    }
}