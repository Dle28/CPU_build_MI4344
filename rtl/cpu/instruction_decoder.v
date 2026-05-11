`timescale 1ns/1ps

// Field extractor for the fixed 16-bit instruction format.
module instruction_decoder (
    input  [15:0] instr,
    output [3:0]  opcode,
    output [2:0]  rs,
    output [2:0]  rt,
    output [2:0]  rd,
    output [2:0]  funct,
    output [5:0]  imm6,
    output [11:0] address
);

    assign opcode  = instr[15:12];
    assign rs      = instr[11:9];
    assign rt      = instr[8:6];
    assign rd      = instr[5:3];
    assign funct   = instr[2:0];
    assign imm6    = instr[5:0];
    assign address = instr[11:0];

endmodule
