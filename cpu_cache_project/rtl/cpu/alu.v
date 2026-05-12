`timescale 1ns/1ps

// 16-bit ALU for the locked compact ISA.
// ALU op encoding follows the R-type funct table for simple reuse.
module alu #(
    parameter DATA_WIDTH = 16
) (
    input  [DATA_WIDTH-1:0] a,
    input  [DATA_WIDTH-1:0] b,
    input  [2:0]            alu_op,
    output reg [DATA_WIDTH-1:0] result,
    output                  zero
);

    localparam ALU_ADD = 3'h0;
    localparam ALU_SUB = 3'h1;
    localparam ALU_AND = 3'h2;
    localparam ALU_OR  = 3'h3;
    localparam ALU_XOR = 3'h4;
    localparam ALU_SLT = 3'h5;
    localparam ALU_SLL = 3'h6;
    localparam ALU_SRL = 3'h7;

    always @(*) begin
        case (alu_op)
            ALU_ADD: result = a + b;
            ALU_SUB: result = a - b;
            ALU_AND: result = a & b;
            ALU_OR:  result = a | b;
            ALU_XOR: result = a ^ b;
            ALU_SLT: result = ($signed(a) < $signed(b)) ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : {DATA_WIDTH{1'b0}};
            ALU_SLL: result = a << b[3:0];
            ALU_SRL: result = a >> b[3:0];
            default: result = {DATA_WIDTH{1'b0}};
        endcase
    end

    assign zero = (result == {DATA_WIDTH{1'b0}});

endmodule
