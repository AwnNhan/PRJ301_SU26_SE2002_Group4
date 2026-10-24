<%-- 
    Document   : product-list
    Created on : Jul 6, 2026, 10:13:46 PM
    Author     : LENOVO
--%>

<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<jsp:include page="/WEB-INF/views/include/header.jsp" />

<div class="container mt-5 mb-5">
    <c:if test="${param.error == 'category_in_use'}">
        <div class="alert alert-danger py-2 fw-bold shadow-sm">
            ⚠ Lỗi: Không thể ẩn danh mục này vì vẫn còn sản phẩm thuộc danh mục đang được bán!
        </div>
    </c:if>   
    <c:if test="${param.error == 'empty_name'}">
        <div class="alert alert-danger py-2 fw-bold shadow-sm mb-3">
            ⚠ Lỗi: Tên sản phẩm không được bỏ trống!
        </div>
    </c:if>

    <c:if test="${param.error == 'duplicate_name'}">
        <div class="alert alert-warning py-2 fw-bold shadow-sm mb-3">
            ⚠ Lỗi: Tên sản phẩm này đã được sử dụng (trùng đường dẫn URL)! Vui lòng nhập tên khác.
        </div>
    </c:if>

    <c:if test="${param.error == 'exception'}">
        <div class="alert alert-danger py-2 shadow-sm mb-3">
            ⚠ Lỗi hệ thống: Không thể thực hiện thao tác lúc này!
        </div>
    </c:if>

    <div class="d-flex justify-content-between align-items-center mb-3 bg-white p-3 rounded shadow-sm">
        <div>
            <h2 class="fw-bold text-dark m-0">Quản Lý Kho Hàng Tổng Hợp</h2>
            <small class="text-muted">Quản lý kho hàng và danh mục phân loại</small>
        </div>


        <div class="dropdown">
            <button class="btn btn-primary btn-lg dropdown-toggle fw-bold shadow-sm" type="button" id="adminAddDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                + Thêm Mới
            </button>
            <ul class="dropdown-menu dropdown-menu-end shadow border-0" aria-labelledby="adminAddDropdown">
                <li>
                    <a class="dropdown-menu-item dropdown-item py-2 fw-bold" href="${pageContext.request.contextPath}/adminProduct?action=add">
                        📦 Thêm Sản Phẩm Mới
                    </a>
                </li>
                <li><hr class="dropdown-divider"></li>
                <!-- LỰA CHỌN 2: Đi tới Form thêm Danh mục (Em sẽ phát triển tiếp Servlet/Action cho nó) -->
                <li>
                    <!-- Luồng thêm danh mục độc lập gửi sang AdminCategoryServlet -->
                    <a class="dropdown-menu-item dropdown-item py-2 fw-bold text-success" href="${pageContext.request.contextPath}/adminCategory?action=add">
                        📁 Thêm Danh Mục Mới
                    </a>
                </li>
            </ul>
        </div>
    </div>
</div>


<div class="row g-4 container-fluid px-4">

    <!-- CỘT TRÁI: BẢNG SẢN PHẨM (CHIẾM 9 PHẦN) -->
    <div class="col-12 col-xl-9">
        <div class="card shadow-sm border-0">
            <div class="card-header bg-dark text-white py-3">
                <h5 class="m-0 fw-bold">📦 DANH SÁCH SẢN PHẨM</h5>
            </div>
            <div class="card-body p-0">
                <table class="table table-hover mb-0 align-middle">
                    <thead class="table-light text-center fs-6">
                    <th width="20%">Hình ảnh</th>
                    <th width="30%">Tên Sản Phẩm</th>
                    <th width="15%">Thương Hiệu</th>
                    <th width="15%">Giá Cơ Sở</th>
                    <th width="10%">Trạng thái</th>
                    <th width="10%">Hành Động</th>
                    </thead>
                    <tbody>
                        <c:forEach items="${adminProductList}" var="p">
                            <tr>
                                <td class="text-center">
                                    <img src="${p.displayImageUrl}" alt="${p.slug}" class="img-thumbnail shadow-sm rounded" 
                                         style="width: 100px; height: 100px; object-fit: cover; background-color: #fff;">
                                </td>
                                <td>
                                    <span class="fw-bold text-primary">${p.name}</span>
                                    <br>
                                    <small class="text-muted">Slug: ${p.slug}</small>
                                </td>
                                <td class="text-center">
                                    <span class="badge bg-secondary px-2 py-1">${p.brand}</span>
                                </td>
                                <td class="text-danger fw-bold text-end pe-4">
                                    <fmt:formatNumber value="${p.displayPrice}" pattern="#,###"/>₫
                                </td>
                                <td class="text-center">
                                    <c:choose>
                                        <c:when test="${p.status == 1}">
                                            <span class="badge bg-success text-white px-2 py-1">Đang bán</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge bg-danger text-white px-2 py-1">Đã ẩn</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="text-center">
                                    <div class="d-flex flex-column gap-1 justify-content-center align-items-center">
                                        <a href="${pageContext.request.contextPath}/adminProduct?action=edit&id=${p.id}" 
                                           class="btn btn-sm btn-outline-warning fw-bold w-100">Sửa</a>
                                        <c:choose>
                                            <c:when test="${p.status == 1}">
                                                <a href="${pageContext.request.contextPath}/adminProduct?action=delete&id=${p.id}" 
                                                   class="btn btn-sm btn-danger fw-bold w-100" 
                                                   onclick="return confirm('Em có chắc muốn tạm ẩn sản phẩm này không?');">Ẩn</a>
                                            </c:when>
                                            <c:otherwise>
                                                <a href="${pageContext.request.contextPath}/adminProduct?action=restore&id=${p.id}" 
                                                   class="btn btn-sm btn-success fw-bold text-white w-100">Mở lại</a>
                                            </c:otherwise>
                                        </c:choose>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty adminProductList}">
                            <tr>
                                <td colspan="6" class="text-center p-5 text-muted">🌟 Chưa có sản phẩm nào trong hệ thống!</td>
                            </tr>
                        </c:if>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- CỘT PHẢI: BẢNG DANH MỤC (CHIẾM 3 PHẦN) -->
    <div class="col-12 col-xl-3">
        <div class="card shadow-sm border-0">
            <div class="card-header bg-success text-white py-3 d-flex justify-content-between align-items-center">
                <h5 class="m-0 fw-bold">📁 CÁC DANH MỤC</h5>
                <div>
                    <a href="${pageContext.request.contextPath}/adminProduct?action=list" class="btn btn-sm btn-warning fw-bold text-dark me-1">Tất cả SP</a>
                    <a href="${pageContext.request.contextPath}/adminCategory?action=add" class="btn btn-sm btn-light fw-bold text-success">+ Thêm</a>
                </div>
            </div>
            <div class="card-body p-0">
                <table class="table table-hover mb-0 align-middle">
                    <thead class="table-light">
                        <tr>
                            <th width="30%" class="text-center">Mã ID</th>
                            <th width="70%">Tên phân loại</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach items="${adminCategoryList}" var="cat">
                            <tr>
                                <td class="text-center fw-bold text-muted">${cat.id}</td>
                                <td>
                                    <div class="d-flex justify-content-between align-items-center">
                                        <div>
                                            <a href="${pageContext.request.contextPath}/adminProduct?action=list&categoryId=${cat.id}" 
                                               class="fw-bold text-decoration-none ${currentCategoryId == cat.id ? 'text-primary fs-5' : 'text-dark'}">
                                                ${cat.name}
                                            </a>
                                            <small class="text-muted d-block" style="font-size: 11px;">Slug: ${cat.slug}</small>

                                            <c:choose>
                                                <c:when test="${cat.status}">
                                                    <span class="badge bg-success" style="font-size: 10px;">Hoạt động</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge bg-danger" style="font-size: 10px;">Đã ẩn</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </div>

                                        <!-- Cụm nút hành động: Sửa | Ẩn/Mở lại -->
                                        <div class="d-flex gap-1 align-items-center">
                                            <a href="${pageContext.request.contextPath}/adminCategory?action=edit&id=${cat.id}" 
                                               class="btn btn-sm btn-outline-warning py-0 px-2 fw-bold" style="font-size: 12px;">Sửa</a>

                                            <c:choose>
                                                <c:when test="${cat.status}">
                                                    <a href="${pageContext.request.contextPath}/adminCategory?action=delete&id=${cat.id}" 
                                                       class="btn btn-sm btn-outline-danger py-0 px-2 fw-bold" style="font-size: 12px;"
                                                       onclick="return confirm('Em có chắc muốn tạm ẩn danh mục [${cat.name}] không?');">Ẩn</a>
                                                </c:when>
                                                <c:otherwise>
                                                    <a href="${pageContext.request.contextPath}/adminCategory?action=restore&id=${cat.id}" 
                                                       class="btn btn-sm btn-outline-success py-0 px-2 fw-bold" style="font-size: 12px;">Mở</a>
                                                </c:otherwise>
                                            </c:choose>
                                        </div>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty adminCategoryList}">
                            <tr>
                                <td colspan="2" class="text-center p-4 text-muted">Chưa có danh mục nào!</td>
                            </tr>
                        </c:if>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<jsp:include page="/WEB-INF/views/include/footer.jsp" />