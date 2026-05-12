`timescale 1ns/1ps

// Word-addressed PC. Normal increment is +1 instruction word.
module pc_unit #(
    parameter ADDR_WIDTH = 16
) (
    input                   clk,
    input                   rst,
    input                   stall,
    input                   flush,
    input  [ADDR_WIDTH-1:0] target_pc,
    output reg [ADDR_WIDTH-1:0] pc
);

    always @(posedge clk) begin
        if (rst) begin
            pc <= {ADDR_WIDTH{1'b0}};
        end else if (!stall) begin
            if (flush) begin
                pc <= target_pc;
            end else begin
                pc <= pc + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
            end
        end
    end

endmodule
