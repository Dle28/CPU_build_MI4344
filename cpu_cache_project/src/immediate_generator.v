// ============================================================================
// FILE: src/immediate_generator.v
// CHỨC NĂNG: Khối kéo giãn hằng số 6-bit thành 16-bit (Zero/Sign Extension)
// ============================================================================

`include "cpu_defines.vh"

module immediate_generator (
    // -- INPUTS --
    input  wire [5:0]             imm6,      // Hằng số 6-bit trích từ lệnh
    input  wire                   sign_ext,  // Công tắc chọn chế độ mở rộng

    // -- OUTPUTS --
    output wire [`DATA_WIDTH-1:0] imm16      // Kết quả 16-bit đẩy vào ALU
);

    // ------------------------------------------------------------------------
    // MẠCH GHÉP DÂY ĐIỆN VẬT LÝ
    // Dùng toán tử ghép nối {} và nhân bản {{}} của Verilog
    // Kết hợp với Multiplexer (toán tử ? :) để điều hướng dòng điện
    // ------------------------------------------------------------------------
    assign imm16 = sign_ext ? { {10{imm6[5]}}, imm6 }   // Sign Extend: Nhân bản bit dấu
                            : { 10'b0000000000, imm6 }; // Zero Extend: Chèn 10 số 0

endmodule