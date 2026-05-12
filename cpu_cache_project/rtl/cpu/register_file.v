`timescale 1ns/1ps

// 8 x 16-bit register file.
// R0 is hardwired to zero: reads return zero and writes are ignored.
module register_file #(
    parameter DATA_WIDTH = 16,
    parameter REG_COUNT  = 8,
    parameter REG_ADDR_WIDTH = 3
) (
    input                         clk,
    input                         rst,
    input                         we,
    input  [REG_ADDR_WIDTH-1:0]   waddr,
    input  [DATA_WIDTH-1:0]       wdata,
    input  [REG_ADDR_WIDTH-1:0]   raddr1,
    input  [REG_ADDR_WIDTH-1:0]   raddr2,
    output [DATA_WIDTH-1:0]       rdata1,
    output [DATA_WIDTH-1:0]       rdata2
);

    reg [DATA_WIDTH-1:0] regs [0:REG_COUNT-1];
    integer i;

    assign rdata1 = (raddr1 == {REG_ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : regs[raddr1];
    assign rdata2 = (raddr2 == {REG_ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : regs[raddr2];

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < REG_COUNT; i = i + 1) begin
                regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if (we && (waddr != {REG_ADDR_WIDTH{1'b0}})) begin
            regs[waddr] <= wdata;
        end
    end

endmodule
