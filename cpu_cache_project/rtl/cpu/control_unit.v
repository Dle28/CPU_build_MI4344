`timescale 1ns/1ps

// Main decode/control block for the 16-bit ISA.
// TODO: carry these control signals through the pipeline registers.
module control_unit (
    input  [3:0] opcode,
    input  [2:0] funct,
    output reg   reg_write,
    output reg   mem_read,
    output reg   mem_write,
    output reg   branch_eq,
    output reg   branch_ne,
    output reg   jump,
    output reg   alu_src_imm,
    output reg   sign_ext,
    output reg   mem_to_reg,
    output reg   halt,
    output reg [3:0] alu_op
);

    `include "cpu_defines.vh"

    localparam OP_RTYPE = 4'h0;
    localparam OP_ADDI  = 4'h1;
    localparam OP_LW    = 4'h2;
    localparam OP_SW    = 4'h3;
    localparam OP_BEQ   = 4'h4;
    localparam OP_BNE   = 4'h5;
    localparam OP_J     = 4'h6;
    localparam OP_HALT  = 4'hF;

    always @(*) begin
        reg_write   = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        branch_eq   = 1'b0;
        branch_ne   = 1'b0;
        jump        = 1'b0;
        alu_src_imm = 1'b0;
        sign_ext    = `EXT_ZERO;
        mem_to_reg  = 1'b0;
        halt        = 1'b0;
        alu_op      = `ALU_ADD;

        case (opcode)
            OP_RTYPE: begin
                reg_write = 1'b1;
                alu_op    = {1'b0, funct};
            end
            OP_ADDI: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;
                sign_ext    = `EXT_SIGN;
                alu_op      = `ALU_ADD;
            end
            OP_LW: begin
                reg_write   = 1'b1;
                mem_read    = 1'b1;
                alu_src_imm = 1'b1;
                mem_to_reg  = 1'b1;
                sign_ext    = `EXT_SIGN;
                alu_op      = `ALU_ADD;
            end
            OP_SW: begin
                mem_write   = 1'b1;
                alu_src_imm = 1'b1;
                sign_ext    = `EXT_SIGN;
                alu_op      = `ALU_ADD;
            end
            OP_BEQ: begin
                branch_eq = 1'b1;
                sign_ext  = `EXT_SIGN;
                alu_op    = `ALU_SUB;
            end
            OP_BNE: begin
                branch_ne = 1'b1;
                sign_ext  = `EXT_SIGN;
                alu_op    = `ALU_SUB;
            end
            OP_J: begin
                jump = 1'b1;
            end
            OP_HALT: begin
                halt = 1'b1;
            end
            default: begin
                // Undefined opcodes behave as NOP during bring-up.
            end
        endcase
    end

endmodule
