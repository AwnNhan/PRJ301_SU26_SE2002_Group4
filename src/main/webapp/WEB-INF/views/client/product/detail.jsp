<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<jsp:include page="/WEB-INF/views/include/header.jsp" />

<div class="container my-5 bg-white p-4 rounded shadow-sm">
    <div class="row">

        <!-- CỘT HIỂN THỊ HÌNH ẢNH SẢN PHẨM -->
        <div class="col-12 col-md-5 mb-4">
            <div class="card border-0 shadow-sm mb-3 text-center p-3">
                <c:choose>
                    <%-- Nếu là link ngoài (bắt đầu bằng http), hiển thị trực tiếp --%>
                    <c:when test="${product.images[0].startsWith('http')}">
                        <img id="main-product-image" src="${product.images[0]}" class="img-fluid rounded" style="max-height: 400px; object-fit: contain;">
                    </c:when>
                    <%-- Nếu là link nội bộ, mới thêm pageContext.request.contextPath --%>
                    <c:otherwise>
                        <img id="main-product-image" src="${pageContext.request.contextPath}/${product.images[0]}" class="img-fluid rounded" style="max-height: 400px; object-fit: contain;">
                    </c:otherwise>
                </c:choose>
            </div>

            <c:if test="${not empty product.images}">
                <div class="d-flex gap-2 overflow-auto py-2">
                    <c:forEach items="${product.images}" var="img">
                        <img src="${pageContext.request.contextPath}/${img}" class="img-thumbnail" 
                             style="width: 80px; height: 80px; object-fit: contain; cursor: pointer;" 
                             onclick="document.getElementById('main-product-image').src = this.src">
                    </c:forEach>
                </div>
            </c:if>
        </div>

        <!-- CỘT THÔNG TIN VÀ CHỌN BIẾN THỂ -->
        <div class="col-12 col-md-7">
            <h2 class="fw-bold mb-2">${product.name}</h2>
            <p class="text-muted mb-2">Thương hiệu: <span class="fw-bold text-dark">${product.brand}</span> | Danh mục: <span class="fw-bold text-dark">${product.category.name}</span></p>

            <h3 class="text-danger fw-bold my-3" id="display-price">
                <fmt:formatNumber value="${product.displayPrice}" pattern="#,##0"/> đ
            </h3>

            <div class="card border-0 bg-light p-3 mb-4">
                <p class="mb-0">${product.description}</p>
            </div>

            <h6 class="fw-bold mb-2 mt-4">Chọn dung lượng:</h6>
            <div class="d-flex flex-wrap gap-2 mb-3" id="capacity-container">
                <!-- Nút dung lượng sẽ tự động hiển thị ở đây qua JS -->
            </div>

            <h6 class="fw-bold mb-2">Chọn màu sắc:</h6>
            <div class="d-flex flex-wrap gap-2 mb-4" id="color-container">
                <!-- Nút màu sắc sẽ tự động hiển thị ở đây qua JS -->
            </div>

            <!-- FORM GỬI DỮ LIỆU ĐẾN CART -->
            <form action="${pageContext.request.contextPath}/cart" method="post" class="d-flex align-items-center gap-3">
                <input type="hidden" name="action" value="add">
                <input type="hidden" name="id" value="${product.id}">

                <!-- Lưu chuỗi thông tin variant gửi sang CartServlet (Ví dụ: "Titan Đen - 256GB") -->
                <input type="hidden" name="variant" id="selected-variant-id" value="">

                <div class="input-group" style="width: 130px;">
                    <span class="input-group-text bg-white">SL</span>
                    <input type="number" name="quantity" id="order-quantity" class="form-control text-center" value="1" min="1">
                </div>

                <button type="submit" class="btn btn-danger btn-lg px-4 fw-bold shadow-sm" id="btn-add-cart">
                    THÊM VÀO GIỎ HÀNG
                </button>
            </form>

            <div class="mt-4 pt-3 border-top">
                <a href="${pageContext.request.contextPath}/review?productId=${product.id}&slug=${product.slug}" class="btn btn-outline-dark w-100 fw-bold">
                    ⭐ Xem & Viết Đánh Giá Sản Phẩm
                </a>
            </div> 
        </div>
    </div>
</div>

<!-- ĐỊNH NGHĨA MẢNG BIẾN THỂ TỪ DATABASE XUỐNG JS -->
<script>
    const variants = [
    <c:forEach items="${product.variants}" var="v" varStatus="status">
    {
    id: ${v.id},
            color: "${v.color}",
            capacity: "${v.storageCapacity}",
            price: ${v.price},
            stock: ${v.stockQuantity}
    }<c:if test="${not status.last}">,</c:if>
    </c:forEach>
    ];
</script>

<!-- LOGIC TỰ ĐỘNG VẼ NÚT VÀ LẤY GIÁ BIẾN THỂ -->
<script>
    document.addEventListener("DOMContentLoaded", function () {
        if (!variants || variants.length === 0)
            return;

        const capacityContainer = document.getElementById("capacity-container");
        const colorContainer = document.getElementById("color-container");
        const priceDisplay = document.getElementById("display-price");
        const variantInput = document.getElementById("selected-variant-id");

        // Trích xuất danh sách duy nhất các dung lượng và màu sắc có sẵn
        const capacities = [...new Set(variants.map(v => v.capacity))];
        const colors = [...new Set(variants.map(v => v.color))];

        let selectedCapacity = capacities[0] || "";
        let selectedColor = colors[0] || "";

        // Vẽ giao diện các nút chọn Dung lượng
        capacities.forEach((cap, index) => {
            const btn = document.createElement("button");
            btn.type = "button";
            btn.className = "btn btn-outline-secondary variant-btn py-1 px-3 fw-bold" + (index === 0 ? " active" : "");
            btn.innerText = cap;
            btn.onclick = function () {
                capacityContainer.querySelectorAll(".variant-btn").forEach(b => b.classList.remove("active"));
                btn.classList.add("active");
                selectedCapacity = cap;
                updateSelectedVariant();
            };
            capacityContainer.appendChild(btn);
        });

        // Vẽ giao diện các nút chọn Màu sắc
        colors.forEach((col, index) => {
            const btn = document.createElement("button");
            btn.type = "button";
            btn.className = "btn btn-outline-secondary variant-btn py-1 px-3 fw-bold" + (index === 0 ? " active" : "");
            btn.innerText = col;
            btn.onclick = function () {
                colorContainer.querySelectorAll(".variant-btn").forEach(b => b.classList.remove("active"));
                btn.classList.add("active");
                selectedColor = col;
                updateSelectedVariant();
            };
            colorContainer.appendChild(btn);
        });

        // Hàm cập nhật lại giá tiền và giá trị chuỗi variant gửi đi
        function updateSelectedVariant() {
            const match = variants.find(v => v.capacity === selectedCapacity && v.color === selectedColor);
            if (match) {
                // Định dạng lại hiển thị tiền tệ VNĐ
                priceDisplay.innerText = new Intl.NumberFormat('vi-VN').format(match.price) + " đ";
                // Set chuỗi giá trị gửi sang Cart để lưu vào database Order_Details
                variantInput.value = match.color + " - " + match.capacity;
            } else {
                // Trường hợp không có biến thể kết hợp chính xác, lấy đại diện thông tin đã chọn
                variantInput.value = selectedColor + " - " + selectedCapacity;
            }
        }

        // Chạy kích hoạt lần đầu khi load trang
        updateSelectedVariant();
    });
</script>

<style>
    .variant-btn.active {
        background-color: #dc3545 !important;
        color: white !important;
        border-color: #dc3545 !important;
    }
</style>

<jsp:include page="/WEB-INF/views/include/footer.jsp" />