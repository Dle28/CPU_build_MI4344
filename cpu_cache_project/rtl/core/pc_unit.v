`timescale 1ns/1ps
`include "cpu_defines.vh"

module pc_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,        // Cho phép PC hoạt động (= start từ cpu_core)
    input  wire        stall,
    input  wire        branch_taken,
    input  wire        jump,
    input  wire [15:0] branch_target,
    input  wire [15:0] jump_target,
    output reg  [15:0] pc_out,
    output wire [15:0] pc_next
);

    // ========================================================================
    // MẠCH TỔ HỢP TÍNH TOÁN (COMBINATIONAL)
    // Tính toán sẵn địa chỉ lệnh tiếp theo (Chạy song song, không đợi clock)
    // Tăng 1 Word (16-bit addressing), không phải tăng 2 Bytes.
    // ========================================================================
    assign pc_next = pc_out + 16'd1;

    // ========================================================================
    // BỘ ĐỊNH TUYẾN ƯU TIÊN & CHỐT TRẠNG THÁI (SEQUENTIAL MULTIPLEXER)
    // ========================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Ưu tiên Tuyệt đối 1: Reset hệ thống
            pc_out <= 16'h0000;
        end else if (!enable) begin
            // Ưu tiên 2: CPU chưa bắt đầu — đóng băng PC tại 0x0000
            // (start=0 → chờ lệnh kích hoạt từ bên ngoài)
            pc_out <= pc_out;
        end else if (stall) begin
            // Ưu tiên 3: Khóa cứng (Đóng băng Pipeline do Hazard hoặc Cache Miss)
            // Triệt tiêu mọi nỗ lực rẽ nhánh hay nhảy lệnh nếu hệ thống đang kẹt
            pc_out <= pc_out;
        end else if (branch_taken) begin
            // Ưu tiên 4: Lệnh rẽ nhánh có điều kiện (EX stage, lệnh cũ hơn)
            pc_out <= branch_target;
        end else if (jump) begin
            // Ưu tiên 5: Lệnh nhảy tuyệt đối (ID stage, lệnh mới hơn)
            pc_out <= jump_target;
        end else begin
            // Ưu tiên chót (Mặc định): Trôi tuột theo ống lệnh
            pc_out <= pc_next;
        end
    end

endmodule