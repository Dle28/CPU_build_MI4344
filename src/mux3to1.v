// ============================================================================
// FILE: src/mux3to1.v
// CHỨC NĂNG: Bộ định tuyến 3 kênh phục vụ Forwarding Unit (Chống kẹt đường ống)
// ============================================================================

`include "cpu_defines.vh"

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