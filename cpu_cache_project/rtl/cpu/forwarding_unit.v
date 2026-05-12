`timescale 1ns/1ps

// Forwarding selector unit for EX-stage operands and store data.
// Encoding:
//   2'b00: use register-file/ID_EX value
//   2'b10: forward from EX/MEM
//   2'b01: forward from MEM/WB
module forwarding_unit (
    input  [2:0] id_ex_rs,
    input  [2:0] id_ex_rt,
    input  [2:0] ex_mem_rd,
    input        ex_mem_reg_write,
    input  [2:0] mem_wb_rd,
    input        mem_wb_reg_write,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b,
    output reg [1:0] forward_store
);

    always @(*) begin
        forward_a     = 2'b00;
        forward_b     = 2'b00;
        forward_store = 2'b00;

        if (ex_mem_reg_write && (ex_mem_rd != 3'd0) && (ex_mem_rd == id_ex_rs)) begin
            forward_a = 2'b10;
        end else if (mem_wb_reg_write && (mem_wb_rd != 3'd0) && (mem_wb_rd == id_ex_rs)) begin
            forward_a = 2'b01;
        end

        if (ex_mem_reg_write && (ex_mem_rd != 3'd0) && (ex_mem_rd == id_ex_rt)) begin
            forward_b     = 2'b10;
            forward_store = 2'b10;
        end else if (mem_wb_reg_write && (mem_wb_rd != 3'd0) && (mem_wb_rd == id_ex_rt)) begin
            forward_b     = 2'b01;
            forward_store = 2'b01;
        end
    end

endmodule
