package connect;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.time.*;

public class RoomDAO {
    public static List<String[]> searchRooms(String checkin, String checkout, String city,
                                             String capacity, String priceStr,
                                             String view, String extend,
                                             String starStr, String chain) throws SQLException {
        List<String[]> results = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT r.HotelID, r.RoomNumber, h.HotelAddress, r.Capacity, r.Price, r.RoomView, r.ExtendableStatus, h.StarRating " +
                        "FROM Room r " +
                        "JOIN Hotel h ON r.HotelID = h.HotelID " +
                        "WHERE r.ProblemDamageSTatus = FALSE " +
                        "AND NOT EXISTS(" +
                        "SELECT 1 FROM BOOKING b " +
                        "WHERE b.HotelID = r.HotelID AND b.RoomNumber = r.RoomNumber " +
                        "AND (b.StartDate, b.EndDate) OVERLAPS (?,?)" + ") "
        );
        if (city != null && !city.isEmpty())
            sql.append("AND h.HotelAddress LIKE ? ");
        if (capacity != null && !capacity.isEmpty())
            sql.append("AND r.Capacity >= ? ");
        if (priceStr != null && !priceStr.isEmpty())
            sql.append("AND r.Price <= ? ");
        if (starStr != null && !starStr.isEmpty())
            sql.append("AND h.StarRating >= ? ");
        if (chain != null && !chain.isEmpty()) sql.append("AND h.ChainID = ? ");

        if ("sea".equals(view)) {
            sql.append("AND r.RoomView = 'sea' ");
        } else if ("mountain".equals(view)) {
            sql.append("AND r.RoomView = 'mountain' ");
        }

        if ("yes".equals(extend)) sql.append("AND r.ExtendableStatus = TRUE ");
        sql.append("ORDER BY r.Price ASC");
        try (Connection db = connection.getConnection();
             PreparedStatement ps = db.prepareStatement(sql.toString())) {
            int idx = 1;
            ps.setDate(idx++, java.sql.Date.valueOf(checkin));
            ps.setDate(idx++, java.sql.Date.valueOf(checkout));
            if (city != null && !city.isEmpty())
                ps.setString(idx++, "%, " + city);
            if (capacity != null && !capacity.isEmpty())
                ps.setInt(idx++, Integer.parseInt(capacity));
            if (priceStr != null && !priceStr.isEmpty())
                ps.setDouble(idx++, Double.parseDouble(priceStr));
            if (starStr != null && !starStr.isEmpty())
                ps.setInt(idx++, Integer.parseInt(starStr));
            if (chain != null && !chain.isEmpty())
                ps.setInt(idx++, Integer.parseInt(chain));

            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                results.add(new String[]{
                        String.valueOf(rs.getInt("HotelID")),
                        String.valueOf(rs.getInt("RoomNumber")),
                        rs.getString("HotelAddress"),
                        String.valueOf(rs.getInt("Capacity")),
                        String.valueOf(rs.getDouble("Price")),
                        rs.getString("RoomView"),
                        rs.getBoolean("ExtendableStatus") ? "Yes" : "No",
                        String.valueOf(rs.getInt("StarRating"))
                });
            }
        }
        return results;
    }

    public static void bookRoom(int customerId, int hotelId, int roomNumber,
                                String checkin, String checkout) throws SQLException {
        LocalDate today = LocalDate.now();
        LocalDate start = LocalDate.parse(checkin);
        LocalDate end = LocalDate.parse(checkout);

        if(start.isBefore(today)){
            throw new SQLException("Check-in date cannot be in the past.");
        }
        if(!end.isAfter(start)){
            throw new SQLException("Check-out date must be after the check-in date.");
        }

        try (Connection db = connection.getConnection()) {
            // check if the room exists
            String checkExistSql = "SELECT 1 FROM Room WHERE HotelID = ? AND RoomNumber = ?";
            try (PreparedStatement psExist = db.prepareStatement(checkExistSql)) {
                psExist.setInt(1, hotelId);
                psExist.setInt(2, roomNumber);
                ResultSet rsExist = psExist.executeQuery();
                if (!rsExist.next()) {
                    throw new SQLException("Invalid Hotel ID or Room Number. Please select a valid room.");
                }
            }

            // check if the room is avail for the specific dates
            String checkOverlapSql = "SELECT 1 FROM Booking WHERE HotelID = ? AND RoomNumber = ? " +
                    "AND (StartDate, EndDate) OVERLAPS (?, ?)";
            try (PreparedStatement psOverlap = db.prepareStatement(checkOverlapSql)) {
                psOverlap.setInt(1, hotelId);
                psOverlap.setInt(2, roomNumber);
                psOverlap.setDate(3, java.sql.Date.valueOf(checkin));
                psOverlap.setDate(4, java.sql.Date.valueOf(checkout));
                ResultSet rsOverlap = psOverlap.executeQuery();
                if (rsOverlap.next()) {
                    throw new SQLException("This room is already booked for the selected dates. Please choose different dates or a different room.");
                }
            }

            // THEN insert
            String insertSql = "INSERT INTO Booking (CustomerID, HotelID, RoomNumber, BookingDate, StartDate, EndDate) " +
                    "VALUES (?, ?, ?, CURRENT_DATE, ?, ?)";
            try (PreparedStatement psInsert = db.prepareStatement(insertSql)) {
                psInsert.setInt(1, customerId);
                psInsert.setInt(2, hotelId);
                psInsert.setInt(3, roomNumber);
                psInsert.setDate(4, java.sql.Date.valueOf(checkin));
                psInsert.setDate(5, java.sql.Date.valueOf(checkout));
                psInsert.executeUpdate();
            }
        }
    }

    public static List<String[]> getBookingsByCustomer(int customerId) throws SQLException {
        List<String[]> results = new ArrayList<>();
        String sql = "SELECT b.BookID, h.HotelAddress, b.RoomNumber, b.StartDate, b.EndDate " +
                "FROM Booking b " +
                "JOIN Hotel h ON b.HotelID = h.HotelID " +
                "WHERE b.CustomerID = ? " +
                "ORDER BY b.StartDate ASC";

        try (Connection db = connection.getConnection();
             PreparedStatement ps = db.prepareStatement(sql)) {
            ps.setInt(1, customerId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                results.add(new String[]{
                        String.valueOf(rs.getInt("BookID")),
                        rs.getString("HotelAddress"),
                        String.valueOf(rs.getInt("RoomNumber")),
                        rs.getDate("StartDate").toString(),
                        rs.getDate("EndDate").toString()
                });
            }
        }
        return results;
    }


}
