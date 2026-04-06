package connect;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class RoomDAO {
    public static List<String[]> searchRooms(String checkin, String checkout, String city,
                                             String capacity, String priceStr,
                                             String seaview, String mountain, String extend,
                                             String starStr, String chain) throws SQLException {
        List<String[]> results = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT r.HotelID, r.RoomNumber, h.HotelAddress, r.Capacity, r.Price, r.RoomNumber, r.ExtendableStatus, h.StarRating " +
                        "FROM Room r " +
                        "JOIN Hotel h ON r.HotelID = h.HotelID " +
                        "WHERE r.ProblemDamageSTatus = FALSE " +
                        "AND NOT EXISTS(" +
                        "SELECT 1 FROM BOOKING b " +
                        "WHERE b.HotelID = r.HotelID AND b.RoomBumber = r.RoomNumber " +
                        "AND (b.StartDate, b.EndDate) OVERLAPS(?,?)" + ") "
        );
        if (city != null && !city.isEmpty())
            sql.append("AND h.HotelAddress LIKE ? ");
        if (capacity != null && !capacity.isEmpty())
            sql.append("AND r.Capacity >= ? ");
        if (priceStr != null && !priceStr.isEmpty())
            sql.append("AND r.Price <= ? ");
        if (starStr != null && !starStr.isEmpty())
            sql.append("AND h.StarRating >= ? ");
        if (chain != null && !chain.isEmpty())
            sql.append("AND h.ChainID = ? ");
        if ("yes".equals(seaview) && !"yes".equals(mountain))
            sql.append("AND r.RoomView = 'sea' ");
        else if ("yes".equals(mountain) && !"yes".equals(seaview))
            sql.append("AND r.RoomView = 'mountain' ");
        if ("yes".equals(extend))
            sql.append("AND r.ExtendableStatus = TRUE ");
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
        String sql = "INSERT INTO Booking (CustomerID, HotelID, RoomNumber, BookingDate, StartDate, EndDate) " +
                "VALUES (?, ?, ?, CURRENT_DATE, ?, ?)";

        try (Connection db = connection.getConnection();
             PreparedStatement ps =db.prepareStatement(sql)) {
            ps.setInt(1, customerId);
            ps.setInt(2, hotelId);
            ps.setInt(3, roomNumber);
            ps.setDate(4, java.sql.Date.valueOf(checkin));
            ps.setDate(5, java.sql.Date.valueOf(checkout));
            ps.executeUpdate();
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
