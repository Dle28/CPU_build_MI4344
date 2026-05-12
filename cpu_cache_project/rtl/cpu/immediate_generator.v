`timescale 1ns/1ps

// Immediate expansion for the locked instruction formats.
module immediate_generator #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16
) (
    input  [5:0]            imm6,
    input  [11:0]           address12,
    output [DATA_WIDTH-1:0] imm6_sext,
    output [ADDR_WIDTH-1:0] branch_offset,
    output [ADDR_WIDTH-1:0] jump_target
);

    assign imm6_sext     = {{(DATA_WIDTH-6){imm6[5]}}, imm6};
    assign branch_offset = {{(ADDR_WIDTH-6){imm6[5]}}, imm6};
    assign jump_target   = {{(ADDR_WIDTH-12){1'b0}}, address12};

endmodule
