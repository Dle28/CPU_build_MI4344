`timescale 1ns/1ps
`include "cpu_defines.vh"

module instruction_decoder (
    input  wire [15:0] instr,
    output wire [3:0]  opcode,
    output wire [2:0]  rs,
    output wire [2:0]  rt,
    output wire [2:0]  rd,
    output wire [2:0]  funct,
    output wire [5:0]  imm6,
    output wire [11:0] jump_addr
);

    // ========================================================================
    // MẠCH BÓC TÁCH MÃ LỆNH (COMBINATIONAL DECODING)
    // ========================================================================
    
    assign opcode    = instr[15:12]; // 4 bit cao nhất chỉ định loại lệnh
    assign rs        = instr[11:9];  // 3 bit địa chỉ thanh ghi nguồn 1
    assign rt        = instr[8:6];   // 3 bit địa chỉ thanh ghi nguồn 2
    assign rd        = instr[5:3];   // 3 bit địa chỉ thanh ghi đích (R-Type)
    assign funct     = instr[2:0];   // 3 bit chức năng ALU (R-Type)
    assign imm6      = instr[5:0];   // 6 bit hằng số / offset (I-Type)
    assign jump_addr = instr[11:0];  // 12 bit địa chỉ đích (J-Type)

endmodule