`include "cpu_defines.vh"

module hazard_detection_unit (
    input  wire [2:0] id_rs,
    input  wire [2:0] id_rt,
    input  wire [2:0] ex_rt,
    input  wire       ex_mem_read,
    input  wire       cache_stall,
    input  wire       if_mem_conflict,
    input  wire       branch_taken,
    input  wire       jump,
    output wire       pc_stall,
    output wire       if_id_stall,
    output wire       id_ex_flush,
    output wire       if_id_flush
);

    // ========================================================================
    // 1. PHÁT HIỆN ĐỤNG ĐỘ DỮ LIỆU CHÍ MẠNG (LOAD-USE HAZARD)
    // ========================================================================
    // Xảy ra khi: Lệnh ngay trước đó ở tầng EX là lệnh LW (ex_mem_read = 1)
    // VÀ thanh ghi đích của LW đó (ex_rt) lại chính là nguồn mà lệnh ở ID đang cần.
    // Loại trừ thanh ghi R0 vì R0 luôn bằng 0, không bao giờ thay đổi.
    wire load_use_hazard;
    assign load_use_hazard = ex_mem_read && (ex_rt != 3'b000) && 
                             ((ex_rt == id_rs) || (ex_rt == id_rt));

    // ========================================================================
    // 2. BỘ ĐIỀU HƯỚNG TÍN HIỆU (CONTROL SIGNAL ROUTING)
    // ========================================================================
    
    // ĐÓNG BĂNG (STALL): Khóa chặt PC và IF/ID, không cho nạp lệnh mới.
    // Kích hoạt khi:
    // - Dính Load-Use Hazard (Đợi dữ liệu từ Memory trồi lên).
    // - Cache báo bận (Miss) đang phải Refill từ Main Memory.
    // - Xung đột cấu trúc Von Neumann (Tầng MEM đang mượn Cache, tầng IF phải nhường).
    assign pc_stall    = load_use_hazard | cache_stall | if_mem_conflict;
    assign if_id_stall = load_use_hazard | cache_stall | if_mem_conflict;

    // TIÊU HỦY LỆNH (FLUSH): Xóa sạch dữ liệu trong thanh ghi Pipeline, biến thành NOP.
    // Kích hoạt khi:
    // - Lệnh ở tầng EX quyết định rẽ nhánh hoặc nhảy (Xóa sạch các lệnh đi sai đường 
    //   đang nằm ở IF và ID).
    // - Dính Load-Use Hazard: Phải chèn 1 bong bóng (bubble) vào thanh ghi ID/EX 
    //   để tách khoảng cách 2 lệnh ra.
    assign if_id_flush = branch_taken | jump;
    assign id_ex_flush = load_use_hazard | branch_taken | jump;

endmodule