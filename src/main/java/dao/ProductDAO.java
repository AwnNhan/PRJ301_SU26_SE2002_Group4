/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package dao;

import db.DBContext;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.Category;
import model.Product;
import model.ProductVariant;

/**
 *
 * @author ADMIN
 */
public class ProductDAO extends DBContext {

    // Hàm lấy danh sách sản phẩm mới nhất để hiển thị ở Trang chủ
    public List<Product> getLatestProducts(int limit, boolean isAdmin) {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT TOP (?) p.id, p.name, p.description, p.slug, p.brand, p.category_id, p.status,"
                + "(SELECT MIN(price) FROM Product_Variants WHERE product_id = p.id AND stock_quantity > 0) AS display_price, "
                + "(SELECT TOP 1 image_url FROM Product_Images WHERE product_id = p.id AND is_thumbnail = 1) AS display_image "
                + "FROM Products p "
                + (isAdmin ? "" : "WHERE p.status = 1 ")
                + "ORDER BY p.created_at DESC";

        try {
            PreparedStatement statement = this.getConnection().prepareCall(sql);

            statement.setInt(1, limit);

            ResultSet rs = statement.executeQuery();
            while (rs.next()) {
                Product p = new Product();
                p.setId(rs.getInt("id"));
                p.setCategoryId(rs.getInt("category_id"));
                p.setName(rs.getString("name"));
                p.setDescription(rs.getString("description"));
                p.setBrand(rs.getString("brand"));
                p.setSlug(rs.getString("slug"));
                p.setStatus(rs.getInt("status"));
                double price = rs.getDouble("display_price");
                p.setDisplayPrice(rs.wasNull() ? 0 : price);

                p.setDisplayImageUrl(rs.getString("display_image"));

                list.add(p);
            }

        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, null, ex);
            System.err.println("Lỗi tại getLatestProducts: " + ex.getMessage());
        }

        return list;
    }

    public Product getProductBySlug(String slug) {

        Product p = null;

        String sqlProduct = "select p.*, c.name AS category_name\n"
                + "from Products p \n"
                + "JOIN Categories c ON c.id = p.category_id\n"
                + "WHERE p.slug = ? AND p.status = 1";

        String sqlVariant = "SELECT * FROM Product_Variants WHERE product_id = ?";

        String sqlImages = "SELECT image_url FROM Product_Images WHERE product_id = ? ORDER BY is_thumbnail DESC";

        try {
            PreparedStatement statementProduct = this.getConnection().prepareStatement(sqlProduct);

            statementProduct.setString(1, slug);

            ResultSet rsProduct = statementProduct.executeQuery();

            if (rsProduct.next()) {
                p = new Product();
                p.setId(rsProduct.getInt("id"));
                p.setCategoryId(rsProduct.getInt("category_id"));
                p.setName(rsProduct.getString("name"));
                p.setDescription(rsProduct.getString("description"));
                p.setBrand(rsProduct.getString("brand"));
                p.setSlug(rsProduct.getString("slug"));
                p.setStockQuantity(rsProduct.getInt("stock_quantity"));

                Category cat = new Category();
                cat.setId(rsProduct.getInt("category_id"));
                cat.setName(rsProduct.getString("category_name"));
                p.setCategory(cat);
            }

            if (p != null) {
                PreparedStatement statementVariant = this.getConnection().prepareStatement(sqlVariant);

                statementVariant.setInt(1, p.getId());

                ResultSet rsVariant = statementVariant.executeQuery();

                List<ProductVariant> variants = new ArrayList<>();

                while (rsVariant.next()) {
                    ProductVariant pv = new ProductVariant();
                    pv.setId(rsVariant.getInt("id"));
                    pv.setProductId(rsVariant.getInt("product_id"));
                    pv.setSku(rsVariant.getString("sku"));
                    pv.setColor(rsVariant.getString("color"));
                    pv.setStorageCapacity(rsVariant.getString("storage_capacity"));
                    pv.setPrice(rsVariant.getDouble("price"));
                    pv.setStockQuantity(rsVariant.getInt("stock_quantity"));
                    pv.setVariantImage(rsVariant.getString("variant_image"));

                    variants.add(pv);
                }

                p.setVariants(variants);

                PreparedStatement statementImage = this.getConnection().prepareStatement(sqlImages);

                statementImage.setInt(1, p.getId());

                ResultSet rsImage = statementImage.executeQuery();

                List<String> imageGallery = new ArrayList<>();

                while (rsImage.next()) {
                    imageGallery.add(rsImage.getString("image_url"));
                }

                p.setImages(imageGallery);
            }
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, null, ex);
            System.err.println("Lỗi tại getProductBySlug: " + ex.getMessage());

        }

        return p;
    }

    public List<Product> getProductByCategorySlug(String categorySlug, int page, int pageSize) {

        List<Product> list = new ArrayList<>();

        if (page < 1) {
            page = 1;
        }

        String sql = "SELECT p.id, p.[name], p.slug, p.brand,\n"
                + "       (SELECT MIN(pr.price) FROM Product_Variants pr WHERE pr.product_id = p.id AND pr.stock_quantity > 0) as diisplay_price,\n"
                + "       (SELECT TOP 1 proImg.image_url FROM Product_Images proImg WHERE proImg.product_id = p.id AND proImg.is_thumbnail = 1) as dislpay_image\n"
                + "FROM Products p\n"
                + "JOIN Categories c ON p.category_id = c.id\n"
                + "WHERE p.[status] = 1 AND c.slug = ?\n"
                + "ORDER BY p.created_at DESC\n"
                + "OFFSET ? ROWS\n"
                + "FETCH NEXT ? ROWS ONLY";

        try {
            PreparedStatement statement = this.getConnection().prepareCall(sql);

            statement.setString(1, categorySlug);
            statement.setInt(2, (page - 1) * pageSize);
            statement.setInt(3, pageSize);

            ResultSet rs = statement.executeQuery();

            while (rs.next()) {
                Product product = new Product();
                product.setId(rs.getInt("id"));
                product.setName(rs.getString("name"));
                product.setSlug(rs.getString("slug"));
                product.setBrand(rs.getString("brand"));

                double price = rs.getDouble("display_price");
                if (rs.wasNull()) {
                    product.setDisplayPrice(0);
                } else {
                    product.setDisplayPrice(price);
                }

                product.setDisplayImageUrl(rs.getString("display_image"));

                list.add(product);
            }
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, null, ex);
            System.err.println("Lỗi tại getProductByCategorySlug: " + ex.getMessage());
        }

        return list;
    }

    public int getTotalProductsByCategorySlug(String categorySlug) {
        String sql = "SELECT COUNT(p.id) FROM Products p "
                + "JOIN Categories c ON p.category_id = c.id "
                + "WHERE p.status = 1 AND c.slug = ?";
        try {
            PreparedStatement statement = this.getConnection().prepareCall(sql);

            statement.setString(1, categorySlug);

            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        } catch (SQLException e) {
            System.err.println("Lỗi đếm sản phẩm: " + e.getMessage());
        }
        return 0;
    }

    public List<Product> getRelatedProduct(int categoryId, int currentProductId, int limit) {
        List<Product> list = new ArrayList<>();

        String sql = "SELECT TOP (?) p.id, p.[name], p.brand, p.slug, p.category_id,\n"
                + "        (SELECT MIN(price) from Product_Variants pr WHERE pr.product_id = p.id AND pr.stock_quantity > 0),\n"
                + "        (SELECT TOP 1 proImg.image_url FROM Product_Images proImg WHERE proImg.product_id = p.id AND proImg.is_thumbnail = 1)\n"
                + "FROM Products p\n"
                + "JOIN Categories c ON p.category_id = c.id\n"
                + "WHERE p.id = ? AND p.category_id = ? AND p.[status] = 1\n"
                + "ORDER BY NEWID()";

        try {
            PreparedStatement statement = this.getConnection().prepareCall(sql);

            statement.setInt(1, limit);
            statement.setInt(2, currentProductId);
            statement.setInt(3, categoryId);

            ResultSet rs = statement.executeQuery();

            while (rs.next()) {
                Product product = new Product();
                product.setId(rs.getInt("id"));
                product.setCategoryId(rs.getInt("category_id"));
                product.setName(rs.getString("name"));
                product.setBrand(rs.getString("brand"));
                product.setSlug(rs.getString("slug"));

                double price = rs.getDouble("display_price");
                if (rs.wasNull()) {
                    product.setDisplayPrice(0);
                } else {
                    product.setDisplayPrice(price);
                }

                product.setDisplayImageUrl(rs.getString("display_image"));
                list.add(product);
            }
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, null, ex);
            System.err.println("Lỗi tại getRelatedProducts: " + ex.getMessage());
        }

        return list;
    }

    // Đếm tổng số sản phẩm tìm được
    public int countSearchProducts(String keyword) {
        String sql = "SELECT COUNT(*) FROM Products WHERE name LIKE ?";
        try {
            PreparedStatement ps = getConnection().prepareStatement(sql);
            ps.setString(1, "%" + keyword + "%");
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    // Hàm lấy danh sách sản phẩm theo từ khóa (phân trang)
    public List<Product> searchProducts(String keyword, int page, int pageSize) {
        List<Product> list = new ArrayList<>();
        // Lưu ý: Dùng alias display_price và display_image để khớp với JSP
        String sql = "SELECT p.*, "
                + "(SELECT MIN(price) FROM Product_Variants WHERE product_id = p.id) as display_price, "
                + "(SELECT TOP 1 image_url FROM Product_Images WHERE product_id = p.id AND is_thumbnail = 1) as display_image "
                + "FROM Products p WHERE p.name LIKE ? AND p.status = 1 "
                + "ORDER BY p.id DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";
        try {
            PreparedStatement ps = getConnection().prepareStatement(sql);
            ps.setString(1, "%" + keyword + "%");
            ps.setInt(2, (page - 1) * pageSize);
            ps.setInt(3, pageSize);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Product p = new Product();
                p.setId(rs.getInt("id"));
                p.setSlug(rs.getString("slug"));
                p.setName(rs.getString("name"));
                p.setDisplayPrice(rs.getDouble("display_price"));
                p.setDisplayImageUrl(rs.getString("display_image"));
                list.add(p);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    // Hàm lấy chi tiết sản phẩm theo ID
    public Product getProductById(int id) {
        String sql = "SELECT p.*, "
                + "(SELECT MIN(price) FROM Product_Variants WHERE product_id = p.id) as display_price, "
                + "(SELECT TOP 1 image_url FROM Product_Images WHERE product_id = p.id AND is_thumbnail = 1) as display_image "
                + "FROM Products p WHERE p.id = ?";
        try {
            PreparedStatement ps = getConnection().prepareStatement(sql);
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                Product p = new Product();
                p.setId(rs.getInt("id"));
                p.setName(rs.getString("name"));
                p.setDescription(rs.getString("description"));
                p.setDisplayPrice(rs.getDouble("display_price"));
                p.setDisplayImageUrl(rs.getString("display_image"));
                return p;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<ProductVariant> getVariantsByProductId(int id) {
        List<ProductVariant> list = new ArrayList<>();

        try {
            String sql = "SELECT * FROM Product_Variants WHERE product_id = ?";
            PreparedStatement statement = this.getConnection().prepareStatement(sql);
            statement.setInt(1, id);

            ResultSet rs = statement.executeQuery();
            while (rs.next()) {
                ProductVariant pv = new ProductVariant();
                pv.setId(rs.getInt("id"));
                pv.setProductId(rs.getInt("product_id"));
                pv.setSku(rs.getString("sku"));
                pv.setColor(rs.getString("color"));
                pv.setStorageCapacity(rs.getString("storage_capacity"));
                pv.setPrice(rs.getDouble("price"));
                pv.setStockQuantity(rs.getInt("stock_quantity"));
                pv.setVariantImage(rs.getString("variant_image"));
                list.add(pv);
            }

        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, null, ex);
        }
        return list;
    }

    public void deleteAllVariantsByProductId(int productId) {
        String sql = "DELETE FROM Product_Variants WHERE product_id = ?";

        try {
            PreparedStatement statement = this.getConnection().prepareStatement(sql);
            statement.setInt(1, productId);
            int rows = statement.executeUpdate();
            System.out.println("=== [DAO] Đã làm sạch " + rows + " biến thể cũ của sản phẩm ID: " + productId + " ===");
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, null, ex);
        }

    }

    public int insertProduct(Product p) {
        String sql = "INSERT INTO Products (category_id, name, description, price, brand, image_url, slug, stock_quantity, status, created_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE())";

        // FIX 1: Thêm cờ java.sql.Statement.RETURN_GENERATED_KEYS để lấy ID tự tăng
        // FIX 2: Bọc PreparedStatement vào try-with-resources để tự động đóng
        try (PreparedStatement statement = this.getConnection().prepareStatement(sql, java.sql.Statement.RETURN_GENERATED_KEYS)) {

            statement.setInt(1, p.getCategoryId());
            statement.setString(2, p.getName());
            statement.setString(3, p.getDescription());
            statement.setDouble(4, p.getPrice());
            statement.setString(5, p.getBrand());
            statement.setString(6, p.getDisplayImageUrl());
            statement.setString(7, p.getSlug());
            statement.setInt(8, p.getStockQuantity());
            statement.setInt(9, p.getStatus());

            int affectedRows = statement.executeUpdate();
            if (affectedRows > 0) {
                // Lấy ID vừa được tạo ra
                try (ResultSet rs = statement.getGeneratedKeys()) {
                    if (rs.next()) {
                        return rs.getInt(1); // Trả về ID của sản phẩm mới chèn
                    }
                }
            }
        } catch (SQLException ex) {
            ex.printStackTrace();
            System.err.println("Lỗi tại insertProduct: " + ex.getMessage());
        }
        return 0;
    }

    public boolean updateProduct(Product p) {
        String sql = "UPDATE Products SET category_id = ?, name = ?, description = ?, price = ?, "
                + "brand = ?, image_url = ?, slug = ?, stock_quantity = ?, status = ? WHERE id = ?";

        try (PreparedStatement statement = this.getConnection().prepareStatement(sql)) {

            statement.setInt(1, p.getCategoryId());
            statement.setString(2, p.getName());
            statement.setString(3, p.getDescription());
            statement.setDouble(4, p.getPrice());
            statement.setString(5, p.getBrand());
            statement.setString(6, p.getDisplayImageUrl());
            statement.setString(7, p.getSlug());
            statement.setInt(8, p.getStockQuantity());
            statement.setInt(9, p.getStatus());
            statement.setInt(10, p.getId());

            return statement.executeUpdate() > 0;
        } catch (SQLException ex) {
            ex.printStackTrace();
            System.err.println("Lỗi tại updateProduct: " + ex.getMessage());
        }
        return false;
    }

    // Hàm ẩn/ngừng kinh doanh sản phẩm (Xóa mềm)
    public boolean deleteProductSoft(int id) {
        String sql = "UPDATE Products SET status = 0 WHERE id = ?";

        try {
            PreparedStatement statement = this.getConnection().prepareStatement(sql);
            statement.setInt(1, id);

            return statement.executeUpdate() > 0;
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, null, ex);
            System.err.println("Lỗi tại deleteProductSoft: " + ex.getMessage());
        }
        return false;
    }

    public boolean restoreProduct(int id) {
        String sql = "UPDATE Products SET status = 1 WHERE id = ?";
        try {
            PreparedStatement statement = this.getConnection().prepareStatement(sql);
            statement.setInt(1, id);
            return statement.executeUpdate() > 0;
        } catch (SQLException ex) {
            java.util.logging.Logger.getLogger(ProductDAO.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
            System.err.println("Lỗi tại restoreProduct: " + ex.getMessage());
        }
        return false;
    }

    // Hàm thêm mới một biến thể sản phẩm (Màu, dung lượng, giá riêng)
    public boolean insertVariant(ProductVariant pv) {
        String sql = "INSERT INTO Product_Variants (product_id, sku, color, storage_capacity, price, stock_quantity, variant_image) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try {
            PreparedStatement statement = this.getConnection().prepareStatement(sql);

            statement.setInt(1, pv.getProductId());
            statement.setString(2, pv.getSku());
            statement.setString(3, pv.getColor());
            statement.setString(4, pv.getStorageCapacity());
            statement.setDouble(5, pv.getPrice());
            statement.setInt(6, pv.getStockQuantity());
            statement.setString(7, pv.getVariantImage());

            return statement.executeUpdate() > 0;
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, null, ex);
            System.err.println("Lỗi tại insertVariant: " + ex.getMessage());
        }
        return false;
    }

    // Hàm thêm ảnh phụ vào bộ sưu tập sản phẩm
    public boolean insertProductImage(int productId, String imageUrl, boolean isThumbnail) {
        String sql = "INSERT INTO Product_Images (product_id, image_url, is_thumbnail) VALUES (?, ?, ?)";
        try {
            PreparedStatement statement = this.getConnection().prepareStatement(sql);

            statement.setInt(1, productId);
            statement.setString(2, imageUrl);
            statement.setBoolean(3, isThumbnail);

            return statement.executeUpdate() > 0;
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, null, ex);
            System.err.println("Lỗi tại insertProductImage: " + ex.getMessage());
        }
        return false;
    }

    // Hàm xóa toàn bộ biến thể cũ của một sản phẩm để chuẩn bị cập nhật lại
    public boolean deleteVariantsByProductId(int productId) {
        String sql = "DELETE FROM Product_Variants WHERE product_id = ?";
        try {
            PreparedStatement statement = this.getConnection().prepareStatement(sql);
            statement.setInt(1, productId);

            return statement.executeUpdate() >= 0; // Trả về true kể cả khi sản phẩm chưa có variant nào
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, null, ex);
            System.err.println("Lỗi tại deleteVariantsByProductId: " + ex.getMessage());
        }
        return false;
    }
// Hàm 1: Đếm số sản phẩm của một danh mục (để chia trang)

    public int countProductsByCategory(String categorySlug) {
        String sql = "SELECT COUNT(*) FROM Products p JOIN Categories c ON p.category_id = c.id WHERE p.[status] = 1 AND c.slug = ?";
        try {
            PreparedStatement ps = getConnection().prepareStatement(sql);
            ps.setString(1, categorySlug);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    // Hàm 2: Lấy danh sách sản phẩm theo danh mục (có phân trang)
    public List<Product> getProductsByCategory(String categorySlug, int page, int pageSize) {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT p.id, p.[name], p.slug, p.brand, "
                + "(SELECT MIN(pr.price) FROM Product_Variants pr WHERE pr.product_id = p.id AND pr.stock_quantity > 0) as display_price, "
                + "(SELECT TOP 1 proImg.image_url FROM Product_Images proImg WHERE proImg.product_id = p.id AND proImg.is_thumbnail = 1) as display_image "
                + "FROM Products p JOIN Categories c ON p.category_id = c.id "
                + "WHERE p.[status] = 1 AND c.slug = ? "
                + "ORDER BY p.created_at DESC "
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";
        try {
            PreparedStatement ps = getConnection().prepareStatement(sql);
            ps.setString(1, categorySlug);
            ps.setInt(2, (page - 1) * pageSize);
            ps.setInt(3, pageSize);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Product p = new Product();
                p.setId(rs.getInt("id"));
                p.setName(rs.getString("name"));
                p.setBrand(rs.getString("brand"));
                p.setSlug(rs.getString("slug"));
                p.setDisplayPrice(rs.getDouble("display_price"));
                p.setDisplayImageUrl(rs.getString("display_image"));
                list.add(p);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
    // Giữ nguyên các hàm khác của bạn Nhân (getLatestProducts, countSearchProducts...)

    public boolean softDeleteProduct(int id) {
        String sql = "UPDATE Products SET status = 0 WHERE id = ?";

        try {
            PreparedStatement statement = this.getConnection().prepareStatement(sql);
            statement.setInt(1, id);
            int result = statement.executeUpdate();
            return result > 0;
        } catch (SQLException ex) {
            Logger.getLogger(ProductDAO.class.getName()).log(Level.SEVERE, null, ex);
        }

        return false;
    }

    public boolean checkProductSlugExist(String slug) {
        String sql = "SELECT COUNT(*) FROM Products WHERE slug = ?";
        try (PreparedStatement ps = this.getConnection().prepareStatement(sql)) {
            ps.setString(1, slug.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException ex) {
            ex.printStackTrace();
        }
        return false;
    }

    public boolean checkProductSlugExistForUpdate(int id, String slug) {
        String sql = "SELECT COUNT(*) FROM Products WHERE slug = ? AND id <> ?";
        try (PreparedStatement ps = this.getConnection().prepareStatement(sql)) {
            ps.setString(1, slug.trim());
            ps.setInt(2, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException ex) {
            ex.printStackTrace();
        }
        return false;
    }

    public List<Product> getAdminProducts(int categoryId) {
        List<Product> list = new ArrayList<>();

        String sql = "SELECT p.id, p.name, p.description, p.slug, p.brand, p.category_id, p.status, "
                + "(SELECT MIN(price) FROM Product_Variants WHERE product_id = p.id) AS display_price, "
                + "(SELECT TOP 1 image_url FROM Product_Images WHERE product_id = p.id AND is_thumbnail = 1) AS display_image "
                + "FROM Products p ";

        // Nếu categoryId > 0 tức là Admin đang muốn lọc
        if (categoryId > 0) {
            sql += "WHERE p.category_id = ? ";
        }

        sql += "ORDER BY p.created_at DESC";

        try (java.sql.Connection conn = this.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            if (categoryId > 0) {
                ps.setInt(1, categoryId);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Product p = new Product();
                    p.setId(rs.getInt("id"));
                    p.setCategoryId(rs.getInt("category_id"));
                    p.setName(rs.getString("name"));
                    p.setDescription(rs.getString("description"));
                    p.setBrand(rs.getString("brand"));
                    p.setSlug(rs.getString("slug"));
                    p.setStatus(rs.getInt("status"));
                    p.setDisplayPrice(rs.getDouble("display_price"));
                    p.setDisplayImageUrl(rs.getString("display_image"));
                    list.add(p);
                }
            }
        } catch (SQLException ex) {
            ex.printStackTrace();
        }
        return list;
    }
}
