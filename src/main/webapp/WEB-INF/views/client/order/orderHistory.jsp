<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<jsp:include page="/WEB-INF/views/include/header.jsp" />

<div class="container mt-4 mb-5" style="min-height: 65vh;">
    <h2 class="mb-4 fw-bold text-center text-primary">
        <i class="fa-solid fa-history me-2"></i>LỊCH SỬ ĐƠN HÀNG CỦA BẠN
    </h2>

    <c:choose>
        <%-- TRƯỜNG HỢP: KHÔNG CÓ ĐƠN HÀNG NÀO --%>
        <c:when test="${empty orderList}">
            <div class="alert alert-info text-center shadow-sm py-4">
                <p class="mb-3 fs-5 text-secondary">Bạn chưa có đơn hàng nào trong hệ thống.</p>
                <a href="${pageContext.request.contextPath}/" class="btn btn-primary fw-bold">MUA SẮM NGAY</a>
            </div>
        </c:when>

        <%-- TRƯỜNG HỢP: CÓ DANH SÁCH ĐƠN HÀNG --%>
        <c:otherwise>
            <div class="table-responsive bg-white rounded shadow-sm p-3">
                <table class="table table-bordered table-hover text-center align-middle mb-0">
                    <thead class="table-dark">
                        <tr>
                            <th style="width: 10%;">Mã Đơn</th>
                            <th style="width: 20%;">Ngày đặt</th>
                            <th class="text-center" style="width: 30%;">Địa chỉ giao hàng</th>
                            <th style="width: 15%;">Số điện thoại</th>
                            <th style="width: 13%;">Tổng tiền</th>
                            <th style="width: 12%;">Trạng thái</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach items="${orderList}" var="order">
                            <tr>
                                <!-- 1. Mã Đơn -->
                                <td class="fw-bold text-secondary">#ORD-${order.id}</td>

                                <!-- 2. Ngày đặt -->
                                <td>
                                    <fmt:formatDate value="${order.createdAt}" pattern="dd/MM/yyyy HH:mm" />
                                </td>

                                <!-- 3. Địa chỉ giao hàng (Đã căn giữa hoàn toàn) -->
                                <td class="text-center">${order.shippingAddress}</td>

                                <!-- 4. Số điện thoại -->
                                <td>${order.shippingPhone}</td>

                                <!-- 5. Tổng tiền (Đã sửa hiển thị giá trị sau khi giảm giá của Voucher) -->
                                <td class="text-danger fw-bold">
                                    <fmt:formatNumber value="${order.finalAmount}" type="number" pattern="#,###" />đ
                                </td>

                                <!-- 6. Trạng thái đơn hàng kèm Badge màu sắc và Nút trả hàng -->
                                <td>
                                    <c:choose>
                                        <%-- TRẠNG THÁI: CHỜ XÁC NHẬN HOẶC ĐANG GIAO --%>
                                        <c:when test="${order.status eq 'Chờ xác nhận' or order.status eq 'Đang giao'}">
                                            <span class="badge ${order.status eq 'Chờ xác nhận' ? 'bg-warning text-dark' : 'bg-info text-white'} px-3 py-2 mb-2 d-inline-block">
                                                ${order.status}
                                            </span>

                                            <%-- Form bấm xác nhận Đã nhận hàng --%>
                                            <form action="${pageContext.request.contextPath}/order" method="post" class="m-0">
                                                <!-- Ở Servlet bạn cần bắt action="complete" để cập nhật DB -->
                                                <input type="hidden" name="action" value="complete">
                                                <input type="hidden" name="orderId" value="${order.id}">
                                                <button type="submit" class="btn btn-outline-success btn-sm fw-bold w-100 shadow-sm"
                                                        onclick="return confirm('Xác nhận bạn đã nhận được đơn hàng #ORD-${order.id} an toàn?');">
                                                    <i class="fa-solid fa-check me-1"></i>Đã nhận hàng
                                                </button>
                                            </form>
                                        </c:when>

                                        <%-- TRẠNG THÁI: HOÀN THÀNH --%>
                                        <c:when test="${order.status eq 'Đã giao' or order.status eq 'Hoàn thành'}">
                                            <span class="badge bg-success text-white px-3 py-2 mb-2 d-inline-block">${order.status}</span>

                                            <%-- Form trả hàng chỉ hiện khi đã nhận xong --%>
                                            <form action="${pageContext.request.contextPath}/order" method="post" class="m-0">
                                                <input type="hidden" name="action" value="return">
                                                <input type="hidden" name="orderId" value="${order.id}">
                                                <button type="submit" class="btn btn-outline-danger btn-sm fw-bold w-100 shadow-sm"
                                                        onclick="return confirm('Bạn có chắc chắn muốn trả hàng cho đơn #ORD-${order.id} không?');">
                                                    <i class="fa-solid fa-rotate-left me-1"></i>Trả hàng
                                                </button>
                                            </form>
                                        </c:when>

                                        <%-- CÁC TRẠNG THÁI KHÁC --%>
                                        <c:when test="${order.status eq 'Đã trả hàng' or order.status eq 'Yêu cầu trả hàng'}">
                                            <span class="badge bg-danger text-white px-3 py-2">${order.status}</span>
                                        </c:when>

                                        <c:otherwise>
                                            <span class="badge bg-secondary text-white px-3 py-2">${order.status}</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<jsp:include page="/WEB-INF/views/include/footer.jsp" />