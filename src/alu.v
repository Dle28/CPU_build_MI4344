// ============================================================================
// FILE: src/alu.v
// CHỨC NĂNG: Khối tính toán trung tâm (Arithmetic Logic Unit)
// ============================================================================

`include "cpu_defines.vh"

module alu (
    // -- INPUTS --
    input  wire [`DATA_WIDTH-1:0] a,
    input  wire [`DATA_WIDTH-1:0] b,
    input  wire [3:0]             alu_op,

    // -- OUTPUTS --
    output reg  [`DATA_WIDTH-1:0] result,
    output reg                    negative,
    output reg                    overflow,
    output wire                   zero
);

    // ------------------------------------------------------------------------
    // 1. CỜ ZERO (Chích xuất trực tiếp liên tục)
    // ------------------------------------------------------------------------
    // Mạch NOR khổng lồ: Nếu tất cả các bit của result là 0, cờ zero = 1.
    assign zero = (result == 16'h0000) ? 1'b1 : 1'b0;

    // ------------------------------------------------------------------------
    // 2. KHỐI LOGIC TỔ HỢP ĐA KÊNH (BỘ NÃO ALU)
    // Cú pháp @(*) yêu cầu phần mềm tự động quét mọi thay đổi của a, b, alu_op
    // ------------------------------------------------------------------------
    always @(*) begin
        // Trạng thái mặc định để tránh chốt (latch) sinh ra phần cứng lỗi
        result   = 16'h0000;
        overflow = 1'b0;

        case (alu_op)
            `ALU_ADD: begin
                result = a + b;
                // Bắt lỗi tràn số cộng: Cùng dấu nhưng kết quả ra trái dấu
                overflow = (~a[15] & ~b[15] & result[15]) | (a[15] & b[15] & ~result[15]);
            end

            `ALU_SUB: begin
                result = a - b;
                // Bắt lỗi tràn số trừ: Trừ số âm cho số dương ra số dương, hoặc ngược lại
                overflow = (~a[15] & b[15] & result[15]) | (a[15] & ~b[15] & ~result[15]);
            end

            `ALU_AND: begin
                result = a & b;
            end

            `ALU_OR: begin
                result = a | b;
            end

            `ALU_XOR: begin
                result = a ^ b;
            end

            `ALU_SLT: begin
                // Ép kiểu có dấu ($signed) để so sánh âm dương chuẩn xác
                if ($signed(a) < $signed(b))
                    result = 16'h0001;
                else
                    result = 16'h0000;
            end

            `ALU_SLL: begin
                // Chỉ lấy 4 bit cuối của b làm số lần dịch (vì tối đa dịch 15 bit)
                result = a << b[3:0];
            end

            `ALU_SRL: begin
                result = a >> b[3:0];
            end

            default: begin
                result = 16'h0000;
            end
        endcase

        // --------------------------------------------------------------------
        // 3. CỜ NEGATIVE
        // --------------------------------------------------------------------
        // Cập nhật cờ negative dựa trên bit MSB của kết quả hiện tại
        negative = result[15];
    end

endmodule