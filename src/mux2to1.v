// ============================================================================
// FILE: src/mux2to1.v
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