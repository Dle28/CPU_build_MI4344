`timescale 1ns/1ps
`include "cache_config.vh"

module memory_arbiter (
    input wire if_req,
    input wire [`ADDR_WIDTH-1:0] if_addr,
    output reg if_ready,
    output reg [`DATA_WIDTH-1:0] if_instr,

    input wire mem_req,
    input wire mem_we,
    input wire [`ADDR_WIDTH-1:0] mem_addr,
    input wire [`DATA_WIDTH-1:0] mem_wdata,
    output reg mem_ready,
    output reg [`DATA_WIDTH-1:0] mem_rdata,

    output reg cache_req,
    output reg cache_we,
    output reg [`ADDR_WIDTH-1:0] cache_addr,
    output reg [`DATA_WIDTH-1:0] cache_wdata,
    input wire cache_ready,                  
    input wire [`DATA_WIDTH-1:0] cache_rdata 
);

    always @(*) begin
        if_ready = 0; if_instr = 0; mem_ready = 0; mem_rdata = 0;
        cache_req = 0; cache_we = 0; cache_addr = 0; cache_wdata = 0;

        if (mem_req) begin
            // Ưu tiên tầng MEM
            cache_req   = 1;
            cache_we    = mem_we;
            cache_addr  = mem_addr;
            cache_wdata = mem_wdata;
            mem_ready   = cache_ready;
            mem_rdata   = cache_rdata;
        end 
        else if (if_req) begin
            // Phục vụ tầng IF nếu MEM rảnh
            cache_req   = 1;
            cache_we    = 0; 
            cache_addr  = if_addr;
            if_ready    = cache_ready;
            if_instr    = cache_rdata;
        end
    end
endmodule