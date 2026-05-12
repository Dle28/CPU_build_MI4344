`timescale 1ns/1ps

// Arbiter for Von Neumann unified cache access.
// MEM-stage requests have priority over IF-stage fetch requests.
module memory_arbiter #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16
) (
    input                   clk,
    input                   rst,

    input                   if_req,
    input  [ADDR_WIDTH-1:0] if_addr,
    output [DATA_WIDTH-1:0] if_rdata,
    output                  if_ready,

    input                   mem_req,
    input                   mem_we,
    input  [ADDR_WIDTH-1:0] mem_addr,
    input  [DATA_WIDTH-1:0] mem_wdata,
    output [DATA_WIDTH-1:0] mem_rdata,
    output                  mem_ready,

    output                  cache_req,
    output                  cache_we,
    output [ADDR_WIDTH-1:0] cache_addr,
    output [DATA_WIDTH-1:0] cache_wdata,
    input  [DATA_WIDTH-1:0] cache_rdata,
    input                   cache_ready
);

    // TODO: latch request owner while cache transaction is outstanding.
    // Current placeholder assumes request remains stable until cache_ready.
    assign cache_req   = mem_req | if_req;
    assign cache_we    = mem_req ? mem_we : 1'b0;
    assign cache_addr  = mem_req ? mem_addr : if_addr;
    assign cache_wdata = mem_req ? mem_wdata : {DATA_WIDTH{1'b0}};

    assign mem_rdata   = cache_rdata;
    assign if_rdata    = cache_rdata;
    assign mem_ready   = mem_req & cache_ready;
    assign if_ready    = (~mem_req) & if_req & cache_ready;

    wire unused_clk = clk;
    wire unused_rst = rst;

endmodule
