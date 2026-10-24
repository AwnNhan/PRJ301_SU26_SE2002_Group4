package controller;

import dao.CartDAO;
import dao.OrderDAO;
import dao.VoucherDAO;
import model.*;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

@WebServlet(name = "OrderServlet", urlPatterns = {"/order", "/checkout"})
public class OrderServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("account");
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/auth?action=loginForm");
            return;
        }

        OrderDAO orderDAO = new OrderDAO();
        request.setAttribute("orderList", orderDAO.getOrdersByUserId(user.getId()));
        request.getRequestDispatcher("/WEB-INF/views/client/order/orderHistory.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("account");

        String guestToken = null;
        if (request.getCookies() != null) {
            for (Cookie c : request.getCookies()) {
                if (c.getName().equals("guest_token")) {
                    guestToken = c.getValue();
                }
            }
        }

        CartDAO cartDAO = new CartDAO();
        OrderDAO orderDAO = new OrderDAO();
        VoucherDAO voucherDAO = new VoucherDAO();
        String path = request.getServletPath();
        // ===============================================
        // THÊM LUỒNG XỬ LÝ TRẢ HÀNG VÀ QUAY VỀ HOME
        // ===============================================
        String action = request.getParameter("action");
        if (action != null) {
            int orderId = 0;
            try {
                orderId = Integer.parseInt(request.getParameter("orderId"));
            } catch (Exception e) {
            }

            if ("return".equals(action)) {
                orderDAO.updateStatus(orderId, "Đã trả hàng");
                session.setAttribute("message", "Đã trả hàng thành công!");
                response.sendRedirect(request.getContextPath() + "/order");
                return; // BẮT BUỘC CÓ DÒNG NÀY
            } else if ("complete".equals(action)) {
                orderDAO.updateStatus(orderId, "Hoàn thành");
                session.setAttribute("message", "Đã xác nhận nhận hàng thành công!");
                response.sendRedirect(request.getContextPath() + "/order");
                return; // BẮT BUỘC CÓ DÒNG NÀY
            }
        }
        // ===============================================
        // LUỒNG 1: HIỂN THỊ TRANG XÁC NHẬN THANH TOÁN
        // ===============================================
        if (path.equals("/checkout")) {
            if (user == null) {
                response.sendRedirect(request.getContextPath() + "/auth?action=loginForm");
                return;
            }

            List<CartItem> cartItems = cartDAO.getCartItems(user.getId(), guestToken);
            if (cartItems == null || cartItems.isEmpty()) {
                response.sendRedirect(request.getContextPath() + "/cart");
                return;
            }

            double totalPrice = cartItems.stream().mapToDouble(i -> i.getProduct().getPrice() * i.getQuantity()).sum();
            double discountAmount = 0;

            String voucherCodeRaw = request.getParameter("voucherCode");
            if (voucherCodeRaw != null && !voucherCodeRaw.trim().isEmpty()) {
                String[] codes = voucherCodeRaw.split(",");
                int totalDiscountPercent = 0;
                for (String code : codes) {
                    Voucher v = voucherDAO.getVoucherByCode(code.trim().toUpperCase());
                    if (v != null) {
                        totalDiscountPercent += v.getDiscountPercent();
                    }
                }
                if (totalDiscountPercent > 100) {
                    totalDiscountPercent = 100;
                }

                discountAmount = totalPrice * totalDiscountPercent / 100;
                totalPrice = totalPrice - discountAmount;

                session.setAttribute("checkoutVouchers", voucherCodeRaw);
            } else {
                session.removeAttribute("checkoutVouchers");
            }

            request.setAttribute("cartItems", cartItems);
            request.setAttribute("totalPrice", totalPrice);
            request.setAttribute("discountAmount", discountAmount);
            request.getRequestDispatcher("/WEB-INF/views/client/order/checkout.jsp").forward(request, response);
        } // ===============================================
        // LUỒNG 2: XỬ LÝ LƯU ĐƠN HÀNG XUỐNG DATABASE
        // ===============================================
        else if (path.equals("/order")) {
            if (user == null) {
                response.sendRedirect(request.getContextPath() + "/auth?action=loginForm");
                return;
            }

            int userId = user.getId();
            String address = request.getParameter("address");
            String phone = request.getParameter("phone");

            try {
                List<CartItem> cartItems = cartDAO.getCartItems(userId, guestToken);

                if (cartItems == null || cartItems.isEmpty()) {
                    request.setAttribute("errorMsg", "Giỏ hàng rỗng, không thể tiến hành thanh toán!");
                    request.getRequestDispatcher("/WEB-INF/views/client/order/checkout.jsp").forward(request, response);
                    return;
                }

                double finalTotalPrice = cartItems.stream().mapToDouble(i -> i.getProduct().getPrice() * i.getQuantity()).sum();

                String appliedVouchers = (String) session.getAttribute("checkoutVouchers");
                if (appliedVouchers != null && !appliedVouchers.trim().isEmpty()) {
                    String[] codes = appliedVouchers.split(",");
                    int totalDiscountPercent = 0;
                    for (String code : codes) {
                        Voucher v = voucherDAO.getVoucherByCode(code.trim().toUpperCase());
                        if (v != null) {
                            totalDiscountPercent += v.getDiscountPercent();
                        }
                    }
                    if (totalDiscountPercent > 100) {
                        totalDiscountPercent = 100;
                    }

                    finalTotalPrice = finalTotalPrice - (finalTotalPrice * totalDiscountPercent / 100);
                }

                // Gọi hàm placeOrder truyền sang file OrderDAO
                boolean success = orderDAO.placeOrder(userId, address, phone, cartItems, finalTotalPrice);

                if (success) {
                    if (appliedVouchers != null && !appliedVouchers.trim().isEmpty()) {
                        String[] codes = appliedVouchers.split(",");
                        for (String code : codes) {
                            Voucher v = voucherDAO.getVoucherByCode(code.trim().toUpperCase());
                            if (v != null) {
                                voucherDAO.increaseUsedCount(v.getId());
                            }
                        }
                    }
                    session.removeAttribute("checkoutVouchers");
                    session.setAttribute("voucherCount", voucherDAO.getAvailableVouchersCount());
                    response.sendRedirect(request.getContextPath() + "/order");
                } else {
                    request.setAttribute("errorMsg", "Lưu đơn hàng thất bại. Vui lòng kiểm tra lại kết nối Database!");
                    quayLaiCheckoutTrang(request, response, cartItems, session, voucherDAO);
                }
            } catch (Exception e) {
                e.printStackTrace();
                try {
                    List<CartItem> cartItems = cartDAO.getCartItems(userId, guestToken);
                    request.setAttribute("errorMsg", "Hệ thống gặp lỗi: " + e.getMessage());
                    quayLaiCheckoutTrang(request, response, cartItems, session, voucherDAO);
                } catch (Exception ex) {
                    response.sendRedirect(request.getContextPath() + "/cart");
                }
            }
        }

    }

    private void quayLaiCheckoutTrang(HttpServletRequest request, HttpServletResponse response,
            List<CartItem> cartItems, HttpSession session, VoucherDAO voucherDAO) throws ServletException, IOException {
        double totalPrice = cartItems.stream().mapToDouble(i -> i.getProduct().getPrice() * i.getQuantity()).sum();
        double discountAmount = 0;
        String appliedVouchers = (String) session.getAttribute("checkoutVouchers");
        if (appliedVouchers != null && !appliedVouchers.trim().isEmpty()) {
            String[] codes = appliedVouchers.split(",");
            int totalDiscountPercent = 0;
            for (String code : codes) {
                Voucher v = voucherDAO.getVoucherByCode(code.trim().toUpperCase());
                if (v != null) {
                    totalDiscountPercent += v.getDiscountPercent();
                }
            }
            if (totalDiscountPercent > 100) {
                totalDiscountPercent = 100;
            }
            discountAmount = totalPrice * totalDiscountPercent / 100;
            totalPrice = totalPrice - discountAmount;
        }
        request.setAttribute("cartItems", cartItems);
        request.setAttribute("totalPrice", totalPrice);
        request.setAttribute("discountAmount", discountAmount);
        request.getRequestDispatcher("/WEB-INF/views/client/order/checkout.jsp").forward(request, response);
    }
}
