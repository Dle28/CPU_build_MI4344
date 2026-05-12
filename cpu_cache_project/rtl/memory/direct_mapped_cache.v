`timescale 1ns/1ps

// Unified direct-mapped cache skeleton.
// Locked cache decision:
//   16 lines, 1 word per line, 16-bit word address, write-through,
//   no-write-allocate on write miss, read-allocate on read miss.
module direct_mapped_cache #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16,
    parameter NUM_LINES  = 16,
    parameter INDEX_WIDTH = 4,
    parameter TAG_WIDTH = 12
) (
    input                   clk,
    input                   rst,

    input                   req,
    input                   we,
    input  [ADDR_WIDTH-1:0] addr,
    input  [DATA_WIDTH-1:0] wdata,
    output [DATA_WIDTH-1:0] rdata,
    output                  ready,
    output                  hit,
    output                  miss,

    output                  mem_req,
    output                  mem_we,
    output [ADDR_WIDTH-1:0] mem_addr,
    output [DATA_WIDTH-1:0] mem_wdata,
    input  [DATA_WIDTH-1:0] mem_rdata,
    input                   mem_ready
);

    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0]   tag;

    reg                    valid_array [0:NUM_LINES-1];
    reg [TAG_WIDTH-1:0]    tag_array   [0:NUM_LINES-1];
    reg [DATA_WIDTH-1:0]   data_array  [0:NUM_LINES-1];

    assign index = addr[3:0];
    assign tag   = addr[15:4];

    // TODO: replace this pass-through placeholder with cache_controller FSM,
    // tag compare, valid check, read refill, write-through, and no-write-allocate.
    assign mem_req   = req;
    assign mem_we    = we;
    assign mem_addr  = addr;
    assign mem_wdata = wdata;
    assign rdata     = mem_rdata;
    assign ready     = mem_ready;
    assign hit       = 1'b0;
    assign miss      = req & ~mem_ready;

    // Keep arrays and decoded fields visible to waveform/lint during skeleton stage.
    wire unused_clk = clk;
    wire unused_rst = rst;
    wire unused_index_bit = |index;
    wire unused_tag_bit = |tag;

endmodule
