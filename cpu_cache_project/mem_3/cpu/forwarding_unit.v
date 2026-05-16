`include "cpu_defines.vh"

module forwarding_unit (
    input  wire [2:0] id_ex_rs,
    input  wire [2:0] id_ex_rt,
    input  wire [2:0] ex_mem_rd,
    input  wire [2:0] mem_wb_rd,
    input  wire       ex_mem_reg_write,
    input  wire       mem_wb_reg_write,
    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);

    // ========================================================================
    // MẠCH TỔ HỢP ĐỊNH TUYẾN MUX (COMBINATIONAL ROUTING)
    // ========================================================================
    always @(*) begin
        // 1. Mặc định: Trôi tự nhiên từ thanh ghi (Không bypass)
        forward_a = 2'b00;
        forward_b = 2'b00;

        // ====================================================================
        // 2. TOÁN HẠNG A (Cho id_ex_rs)
        // ====================================================================
        if (ex_mem_reg_write && (ex_mem_rd != 3'b000) && (ex_mem_rd == id_ex_rs)) begin
            // Ưu tiên 1: Lấy dữ liệu nóng nhất vừa tính xong từ EX/MEM
            forward_a = 2'b10;
        end else if (mem_wb_reg_write && (mem_wb_rd != 3'b000) && (mem_wb_rd == id_ex_rs)) begin
            // Ưu tiên 2: Lấy dữ liệu chuẩn bị ghi ngược từ MEM/WB
            forward_a = 2'b01;
        end

        // ====================================================================
        // 3. TOÁN HẠNG B (Cho id_ex_rt)
        // ====================================================================
        if (ex_mem_reg_write && (ex_mem_rd != 3'b000) && (ex_mem_rd == id_ex_rt)) begin
            // Ưu tiên 1: Lấy dữ liệu nóng nhất vừa tính xong từ EX/MEM
            forward_b = 2'b10;
        end else if (mem_wb_reg_write && (mem_wb_rd != 3'b000) && (mem_wb_rd == id_ex_rt)) begin
            // Ưu tiên 2: Lấy dữ liệu chuẩn bị ghi ngược từ MEM/WB
            forward_b = 2'b01;
        end
    end

endmodule