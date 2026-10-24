USE master;
GO

-- =============================================
-- 1. ÉP ĐÓNG KẾT NỐI VÀ XÓA DATABASE CŨ
-- =============================================
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'PROJECT_PRJ301')
BEGIN
    ALTER DATABASE PROJECT_PRJ301 SET SINGLE_USER WITH ROLLBACK IMMEDIATE; 
    DROP DATABASE PROJECT_PRJ301;
END
GO

-- =============================================
-- 2. TẠO LẠI DATABASE MỚI
-- =============================================
CREATE DATABASE PROJECT_PRJ301;
GO

USE PROJECT_PRJ301;
GO

-- =============================================
-- 3. TẠO CẤU TRÚC CÁC BẢNG (CHUẨN MVC & KHÓA NGOẠI)
-- =============================================

-- MODULE 1: TÀI KHOẢN (Nguyễn Minh Phát)
CREATE TABLE Users (
    id INT IDENTITY(1,1) PRIMARY KEY, 
    full_name NVARCHAR(100) NOT NULL, 
    email VARCHAR(100) UNIQUE NOT NULL, 
    password VARCHAR(255) NOT NULL, 
    phone VARCHAR(15), 
    address NVARCHAR(255), 
    role INT DEFAULT 0, -- 0: Customer, 1: Admin 
    created_at DATETIME DEFAULT GETDATE() 
);

-- MODULE 2: DANH MỤC & SẢN PHẨM (Nguyễn Trần Khả Nhân)
CREATE TABLE Categories (
    id INT IDENTITY(1,1) PRIMARY KEY, 
    name NVARCHAR(100) NOT NULL, 
    description NVARCHAR(500), 
    parent_id INT FOREIGN KEY REFERENCES Categories(id) NULL, 
    slug VARCHAR(150) UNIQUE, 
    status BIT DEFAULT 1 -- 1: Hoạt động, 0: Khóa 
);

CREATE TABLE Products (
    id INT IDENTITY(1,1) PRIMARY KEY, 
    category_id INT FOREIGN KEY REFERENCES Categories(id), 
    name NVARCHAR(200) NOT NULL, 
    description NVARCHAR(MAX), 
    price DECIMAL(18,2) NOT NULL, 
    brand NVARCHAR(100), 
    image_url VARCHAR(500), 
    slug VARCHAR(250) UNIQUE, 
    stock_quantity INT DEFAULT 0, 
    status INT DEFAULT 1, -- 1: Đang bán, 0: Ngừng kinh doanh, 2: Bản nháp 
    created_at DATETIME DEFAULT GETDATE() 
);

CREATE TABLE Product_Variants (
    id INT IDENTITY(1,1) PRIMARY KEY, 
    product_id INT FOREIGN KEY REFERENCES Products(id) ON DELETE CASCADE, 
    sku VARCHAR(50) UNIQUE, 
    color NVARCHAR(50), 
    storage_capacity NVARCHAR(50), 
    price DECIMAL(18,2) NOT NULL, 
    stock_quantity INT DEFAULT 0, 
    variant_image VARCHAR(500) 
);

CREATE TABLE Product_Images (
    id INT IDENTITY(1,1) PRIMARY KEY, 
    product_id INT FOREIGN KEY REFERENCES Products(id) ON DELETE CASCADE, 
    image_url VARCHAR(500) NOT NULL, 
    is_thumbnail BIT DEFAULT 0 
);

CREATE TABLE Product_Specifications (
    id INT IDENTITY(1,1) PRIMARY KEY, 
    product_id INT FOREIGN KEY REFERENCES Products(id) ON DELETE CASCADE, 
    spec_key NVARCHAR(100) NOT NULL, 
    spec_value NVARCHAR(500) NOT NULL 
);

-- MODULE 3: GIỎ HÀNG (Lê Nguyễn Thành Tài)
CREATE TABLE Carts (
    id INT IDENTITY(1,1) PRIMARY KEY, 
    user_id INT FOREIGN KEY REFERENCES Users(id) UNIQUE, -- Mỗi user 1 giỏ hàng duy nhất 
    guest_token VARCHAR(100), 
    created_at DATETIME DEFAULT GETDATE() 
);

CREATE TABLE Cart_Items (
    id INT IDENTITY(1,1) PRIMARY KEY, 
    cart_id INT FOREIGN KEY REFERENCES Carts(id), 
    product_id INT FOREIGN KEY REFERENCES Products(id), 
    quantity INT NOT NULL DEFAULT 1, 
    variant NVARCHAR(255) 
);

-- MODULE 4: VOUCHER (Trương Anh Tuấn)
CREATE TABLE Vouchers (
    id INT IDENTITY(1,1) PRIMARY KEY, 
    code VARCHAR(50) UNIQUE NOT NULL, 
    discount_percent INT NOT NULL, 
    max_discount DECIMAL(18,2), 
    min_order_value DECIMAL(18,2), 
    expiry_date DATETIME, 
    usage_limit INT DEFAULT 100, 
    used_count INT DEFAULT 0 
);

-- MODULE 5: ĐƠN HÀNG (Đỗ Trần Thiên Phúc)
CREATE TABLE Orders (
    id INT IDENTITY(1,1) PRIMARY KEY, 
    user_id INT FOREIGN KEY REFERENCES Users(id), 
    voucher_id INT FOREIGN KEY REFERENCES Vouchers(id) NULL, 
    total_amount DECIMAL(18,2) NOT NULL, 
    final_amount DECIMAL(18,2) NOT NULL, 
    status NVARCHAR(50) DEFAULT N'Chờ xác nhận', 
    shipping_address NVARCHAR(500) NOT NULL, 
    shipping_phone VARCHAR(15) NOT NULL, 
    created_at DATETIME DEFAULT GETDATE() 
);

CREATE TABLE Order_Details (
    order_id INT FOREIGN KEY REFERENCES Orders(id), 
    product_id INT FOREIGN KEY REFERENCES Products(id), 
    quantity INT NOT NULL, 
    price DECIMAL(18,2) NOT NULL, 
    variant NVARCHAR(255), 
    PRIMARY KEY (order_id, product_id) 
);

-- MODULE 6: ĐÁNH GIÁ (Lương Trung Hiếu)
CREATE TABLE Reviews (
    id INT IDENTITY(1,1) PRIMARY KEY, 
    user_id INT FOREIGN KEY REFERENCES Users(id), 
    product_id INT FOREIGN KEY REFERENCES Products(id), 
    rating INT CHECK (rating >= 1 AND rating <= 5), 
    comment NVARCHAR(MAX), 
    created_at DATETIME DEFAULT GETDATE() 
);

-- TẠO INDEX TỐI ƯU TRUY VẤN
CREATE INDEX idx_products_slug ON Products(slug); 
CREATE INDEX idx_categories_slug ON Categories(slug); 
CREATE INDEX idx_variants_price ON Product_Variants(price); 
GO


-- =============================================
-- 4. CHÈN DỮ LIỆU MẪU (SEED DATA - ĐÃ CHUẨN HÓA THEO DANH MỤC UI)
-- =============================================

-- 4.1 Tài khoản mẫu (Mật khẩu: 123456) (Đã đổi role thành 1 cho em Hiếu  tính năng đánh giá )
INSERT INTO Users (full_name, email, password, phone, address, role)
VALUES (N'Lê Nguyễn Thành Tài', 'tai@fpt.edu.vn', 'e10adc3949ba59abbe56e057f20f883e', '0909123456', N'Cần Thơ', 1);

-- 4.2 Danh mục Gốc (Level 1 - Chuẩn 100% khớp với href trên header)(Tài)
INSERT INTO Categories (name, description, slug, status) VALUES 
(N'Điện thoại', N'Smartphone các hãng', 'dien-thoai', 1),    -- ID 1
(N'Laptop', N'Máy tính xách tay', 'laptop', 1),                -- ID 2
(N'Máy tính bảng', N'iPad, Android Tablet', 'tablet', 1),      -- ID 3
(N'Phụ kiện', N'Tai nghe, sạc dự phòng, ốp lưng', 'phu-kien', 1), -- ID 4
(N'Tivi', N'Smart Tivi 4K, OLED', 'tivi', 1);                  -- ID 5

-- 4.3 Danh sách Sản phẩm (Đã nhét đúng vào từng Category)(Tài)
INSERT INTO Products (category_id, name, brand, description, slug, price, image_url, stock_quantity, status) VALUES 
-- ================= NHÓM 1: ĐIỆN THOẠI (Apple, Samsung, Xiaomi...) =================
(1, N'iPhone 15 Pro Max', 'Apple', N'Thiết kế Titan tự nhiên siêu nhẹ, chip A17 Pro mạnh mẽ.', 'iphone-15-pro-max', 29000000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSO5SEZJ_M3jJxyGTAypI_y4QUP6sK86WcjY4DTim5h-A&s=10', 20, 1),
(1, N'iPhone 14', 'Apple', N'Cấu hình ổn định với chip A15 Bionic, thiết kế nhỏ gọn.', 'iphone-14', 18000000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRoh3yt4lkcmClQZ2pqUIopBfOy1VmwQAZSxHRpr_rU4Q&s', 15, 1),
(1, N'Samsung Galaxy S24 Ultra 5G', 'Samsung', N'Tích hợp Galaxy AI, khung viền Titan, bút S-Pen.', 'samsung-galaxy-s24-ultra', 28000000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRPPGbkp9j0vJUaWBb-GMgbOjTbyupHOvlUPQR1nJ7SLQ&s=10', 15, 1),
(1, N'Xiaomi 14', 'Xiaomi', N'Camera Leica đỉnh cao, thiết kế viền mỏng.', 'xiaomi-14', 19000000, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:0:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/x/i/xiaomi-14-pre-den.png', 10, 1),

-- ================= NHÓM 2: LAPTOP (MacBook, Acer, Asus...) =================
(2, N'MacBook Air M3 2024', 'Apple', N'Chip Apple M3 mới nhất, siêu mỏng nhẹ, pin 18 tiếng.', 'macbook-air-m3-2024', 27000000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT0uwNWfYQ1fP6W9vVUZZC4J_g1kIcRJWxPAlTHniBp3g&s=10', 10, 1),
(2, N'Acer Nitro 5 Tiger', 'Acer', N'Intel Core i5 12500H, RTX 3050Ti, Màn hình 144Hz.', 'acer-nitro-5-tiger', 18000000, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/t/e/text_d_i_1__4_8.png', 12, 1),
(2, N'Laptop Asus Vivobook', 'Asus', N'Core i5, 8GB RAM, mỏng nhẹ phù hợp văn phòng.', 'asus-vivobook', 15000000, 'https://cdn2.fptshop.com.vn/unsafe/750x0/filters:format(webp):quality(75)/asus_gaming_vivobook_k3605_black_1_6dec3a2e8f.png', 20, 1),

-- ================= NHÓM 3: MÁY TÍNH BẢNG (MỚI) =================
(3, N'iPad Pro M4 11-inch (2024)', 'Apple', N'Chip M4 siêu mạnh, màn hình OLED rực rỡ, thiết kế cực mỏng.', 'ipad-pro-m4-11', 28500000, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:0:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/f/r/frame_100_1_2__2_2.png', 10, 1),
(3, N'Samsung Galaxy Tab S9', 'Samsung', N'Chống nước IP68, màn hình Dynamic AMOLED 2X, kèm S-Pen.', 'galaxy-tab-s9', 19500000, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/s/ss-tab-s9_1_.png', 15, 1),

-- ================= NHÓM 4: PHỤ KIỆN (MỚI) =================
(4, N'Tai nghe không dây Baseus Bowie WM01', 'Baseus', N'Âm thanh sắc nét, pin dùng liên tục 5 giờ, thiết kế nhỏ gọn nhẹ tai.', 'baseus-bowie-wm01', 350000, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/g/r/group_161_2.png', 50, 1),
(4, N'AirPods Pro 2', 'Apple', N'Chống ồn chủ động xuất sắc, âm thanh không gian 3D.', 'airpods-pro-2', 5800000, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/a/p/apple-airpods-pro-2-usb-c_1_.png', 30, 1),

-- ================= NHÓM 5: TIVI (MỚI) =================
(5, N'Smart Tivi Samsung 4K 65 inch', 'Samsung', N'Độ phân giải 4K sắc nét, công nghệ màu PurColor rực rỡ.', 'tivi-samsung-4k-65', 12900000, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/m/smart-tivi-samsung-qled-65q6fa-4k-65-inch.png', 8, 1),
(5, N'Smart Tivi LG 4K 55 inch', 'LG', N'Công nghệ AI ThinQ, chuột bay Magic Remote siêu tiện lợi.', 'tivi-lg-4k-55', 10500000, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/m/smart-tivi-lg-uhd-55ua7350-4k-55-inch-2025_1_.png', 5, 1);
GO

-- 5. TỰ ĐỘNG CHÈN ẢNH VÀ BIẾN THỂ CHO CÁC SẢN PHẨM CÒN LẠI (ID TỪ 2 TRỞ ĐI)(Product(Nhân))
INSERT INTO Product_Images (product_id, image_url, is_thumbnail)
SELECT id, image_url, 1 FROM Products WHERE id > 1;

INSERT INTO Product_Variants (product_id, sku, color, storage_capacity, price, stock_quantity, variant_image)
SELECT id, 'SKU-' + CAST(id AS VARCHAR), N'Mặc định', N'Tiêu chuẩn', price, stock_quantity, image_url 
FROM Products WHERE id > 1;
GO

-- 6. CHÈN CHI TIẾT BIẾN THỂ VÀ ẢNH CHO IPHONE 15 PRO MAX (ID = 1) THEO CODE CỦA BẠN EM(Product (Nhân))
INSERT INTO Product_Images (product_id, image_url, is_thumbnail) VALUES 
(1, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-15-pro-max_3.png', 1),
(1, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-15-pro-max-blue-titanium-1.png', 0),
(1, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-15-pro-max-white-titanium-1.png', 0);
GO

INSERT INTO Product_Variants (product_id, sku, color, storage_capacity, price, stock_quantity, variant_image) VALUES 
-- Màu Đen
(1, 'IP15PM-256-DEN', N'Titan Đen', '256GB', 28000000, 10, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-15-pro-max_3.png'),
(1, 'IP15PM-512-DEN', N'Titan Đen', '512GB', 32000000, 5, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-15-pro-max_3.png'),
(1, 'IP15PM-1TB-DEN', N'Titan Đen', '1TB', 36000000, 2, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-15-pro-max_3.png'),
-- Màu Trắng
(1, 'IP15PM-256-TRANG', N'Titan Trắng', '256GB', 28500000, 10, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-15-pro-max-white-titanium-1.png'),
(1, 'IP15PM-512-TRANG', N'Titan Trắng', '512GB', 32500000, 8, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-15-pro-max-white-titanium-1.png'),
(1, 'IP15PM-1TB-TRANG', N'Titan Trắng', '1TB', 36500000, 3, 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-15-pro-max-white-titanium-1.png');
GO

-- 7 . Voucher giảm giá (Tuấn)
INSERT INTO Vouchers (code, discount_percent, max_discount, min_order_value, expiry_date, usage_limit, used_count)
VALUES 
('CUUTUIROIMON', 15, 300000, 0, '2026-12-31 23:59:59', 99, 0),
('FEMBOY', 20, 500000, 0, '2026-12-31 23:59:59', 50, 0),
('GROUP410DIEM', 99, 9999999, 999000000, '2026-12-31 23:59:59', 1, 0),
('NLOVEP', 10, 100000, 0, '2026-12-31 23:59:59', 100, 0),
('NGHEO_CONGAT', 10, 100000, 0, '2026-12-31 23:59:59', 100, 0),
('BIGSALE30', 30, 1500000, 25000000, '2026-12-31 23:59:59', 20, 0),
('WELCOME5', 5, 100000, 0, '2026-12-31 23:59:59', 500, 0),
('SOLDOUT', 10, 200000, 0, '2026-12-31 23:59:59', 10, 10),
('EXPIRED50', 50, 2000000, 0, '2026-01-01 00:00:00', 50, 0);
