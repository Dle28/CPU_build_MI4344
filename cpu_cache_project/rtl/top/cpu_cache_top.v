`timescale 1ns/1ps

// Top-level integration:
// cpu_core -> memory_arbiter -> direct_mapped_cache -> delayed main_memory
module cpu_cache_top #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16,
    parameter MEMORY_DELAY = 5,
    parameter MEM_INIT_FILE = ""
) (
    input                   clk,
    input                   rst,
    output                  halted,
    output [ADDR_WIDTH-1:0] debug_pc
);

    wire                  if_req;
    wire [ADDR_WIDTH-1:0] if_addr;
    wire [DATA_WIDTH-1:0] if_rdata;
    wire                  if_ready;

    wire                  core_mem_req;
    wire                  core_mem_we;
    wire [ADDR_WIDTH-1:0] core_mem_addr;
    wire [DATA_WIDTH-1:0] core_mem_wdata;
    wire [DATA_WIDTH-1:0] core_mem_rdata;
    wire                  core_mem_ready;

    wire                  cache_req;
    wire                  cache_we;
    wire [ADDR_WIDTH-1:0] cache_addr;
    wire [DATA_WIDTH-1:0] cache_wdata;
    wire [DATA_WIDTH-1:0] cache_rdata;
    wire                  cache_ready;
    wire                  cache_hit;
    wire                  cache_miss;

    wire                  ram_req;
    wire                  ram_we;
    wire [ADDR_WIDTH-1:0] ram_addr;
    wire [DATA_WIDTH-1:0] ram_wdata;
    wire [DATA_WIDTH-1:0] ram_rdata;
    wire                  ram_ready;

    cpu_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_cpu_core (
        .clk(clk),
        .rst(rst),
        .if_req(if_req),
        .if_addr(if_addr),
        .if_rdata(if_rdata),
        .if_ready(if_ready),
        .mem_req(core_mem_req),
        .mem_we(core_mem_we),
        .mem_addr(core_mem_addr),
        .mem_wdata(core_mem_wdata),
        .mem_rdata(core_mem_rdata),
        .mem_ready(core_mem_ready),
        .halted(halted),
        .debug_pc(debug_pc)
    );

    memory_arbiter #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_memory_arbiter (
        .clk(clk),
        .rst(rst),
        .if_req(if_req),
        .if_addr(if_addr),
        .if_rdata(if_rdata),
        .if_ready(if_ready),
        .mem_req(core_mem_req),
        .mem_we(core_mem_we),
        .mem_addr(core_mem_addr),
        .mem_wdata(core_mem_wdata),
        .mem_rdata(core_mem_rdata),
        .mem_ready(core_mem_ready),
        .cache_req(cache_req),
        .cache_we(cache_we),
        .cache_addr(cache_addr),
        .cache_wdata(cache_wdata),
        .cache_rdata(cache_rdata),
        .cache_ready(cache_ready)
    );

    direct_mapped_cache #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_LINES(16),
        .INDEX_WIDTH(4),
        .TAG_WIDTH(12)
    ) u_direct_mapped_cache (
        .clk(clk),
        .rst(rst),
        .req(cache_req),
        .we(cache_we),
        .addr(cache_addr),
        .wdata(cache_wdata),
        .rdata(cache_rdata),
        .ready(cache_ready),
        .hit(cache_hit),
        .miss(cache_miss),
        .mem_req(ram_req),
        .mem_we(ram_we),
        .mem_addr(ram_addr),
        .mem_wdata(ram_wdata),
        .mem_rdata(ram_rdata),
        .mem_ready(ram_ready)
    );

    main_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_DEPTH(65536),
        .DELAY_CYCLES(MEMORY_DELAY),
        .INIT_FILE(MEM_INIT_FILE)
    ) u_main_memory (
        .clk(clk),
        .rst(rst),
        .req(ram_req),
        .we(ram_we),
        .addr(ram_addr),
        .wdata(ram_wdata),
        .rdata(ram_rdata),
        .ready(ram_ready)
    );

    wire unused_cache_status = cache_hit | cache_miss;

endmodule
