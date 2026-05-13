`timescale 1ns/1ps

// tick: đã xong

// ============================================================================
// FILE: rtl/cpu/mux.v
// CHỨC NĂNG: Bộ định tuyến 2 kênh (Độ rộng 16-bit)
// ============================================================================

`include "cpu_defines.vh"

module mux2to1 (
    // -- INPUTS --
    input  wire [`DATA_WIDTH-1:0] d0,   // Luồng dữ liệu số 0
    input  wire [`DATA_WIDTH-1:0] d1,   // Luồng dữ liệu số 1
    input  wire                   sel,  // Chốt bẻ ghi (0 chọn d0, 1 chọn d1)

    // -- OUTPUTS --
    output wire [`DATA_WIDTH-1:0] y     // Luồng dữ liệu được đi tiếp
);

    // ------------------------------------------------------------------------
    // MẠCH CHUYỂN MẠCH VẬT LÝ
    // Sử dụng gán liên tục và toán tử 3 ngôi để ép tổng hợp ra cổng logic MUX
    // ------------------------------------------------------------------------
    assign y = sel ? d1 : d0;

endmodule


// ============================================================================
// FILE: rtl/cpu/mux.v
// CHỨC NĂNG: Bộ định tuyến 3 kênh phục vụ Forwarding Unit (Chống kẹt đường ống)
// ============================================================================

module mux3to1 (
    // -- INPUTS --
    input  wire [`DATA_WIDTH-1:0] d0,   // Dữ liệu cũ (từ ID/EX)
    input  wire [`DATA_WIDTH-1:0] d1,   // Dữ liệu luân chuyển từ tầng WB
    input  wire [`DATA_WIDTH-1:0] d2,   // Dữ liệu luân chuyển từ tầng MEM
    input  wire [1:0]             sel,  // Chốt điều hướng 2-bit (00, 01, 10)

    // -- OUTPUTS --
    // Phải khai báo là 'reg' vì nó được gán giá trị bên trong khối 'always'
    output reg  [`DATA_WIDTH-1:0] y
);

    // ------------------------------------------------------------------------
    // MẠCH CHUYỂN MẠCH 3 HƯỚNG
    // Sử dụng always @(*) để thiết lập mạch tổ hợp.
    // BẮT BUỘC phải có trạng thái default để ngăn chặn Latch vật lý.
    // ------------------------------------------------------------------------
    always @(*) begin
        case (sel)
            2'b00: y = d0;  // Không có xung đột, chạy bình thường
            2'b01: y = d1;  // Lấy dữ liệu từ tương lai (tầng WB)
            2'b10: y = d2;  // Lấy dữ liệu từ tương lai gần (tầng MEM)

            // Xử lý trạng thái 11 (Vùng tối của phần cứng)
            default: y = 16'h0000;
        endcase
    end

endmodule
