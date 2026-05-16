`timescale 1ns / 1ps

module memory_arbiter (
    // Giao tiếp với tầng IF (Instruction Fetch) của CPU
    input  wire [15:0] if_addr,
    input  wire        if_read,
    output wire [15:0] if_rdata,
    output wire        if_stall,

    // Giao tiếp với tầng MEM (Data Memory) của CPU
    input  wire [15:0] mem_addr,
    input  wire [15:0] mem_wdata,
    input  wire        mem_read,
    input  wire        mem_write,
    output wire [15:0] mem_rdata,
    output wire        mem_stall,

    // Giao tiếp với Cache
    output wire [15:0] cache_addr,
    output wire [15:0] cache_wdata,
    output wire        cache_read,
    output wire        cache_write,
    input  wire [15:0] cache_rdata,
    input  wire        cache_stall
);

    // Ưu tiên tầng MEM nếu nó có yêu cầu đọc hoặc ghi
    wire mem_request = mem_read | mem_write;

    // Định tuyến tín hiệu đến Cache
    assign cache_addr  = mem_request ? mem_addr  : if_addr;
    assign cache_wdata = mem_request ? mem_wdata : 16'd0;
    assign cache_read  = mem_request ? mem_read  : if_read;
    assign cache_write = mem_request ? mem_write : 1'b0;

    // Dữ liệu từ Cache trả về cho cả 2 tầng (tầng nào đang request thì tự lấy)
    assign mem_rdata = cache_rdata;
    assign if_rdata  = cache_rdata;

    // Logic sinh tín hiệu Stall (bắt CPU dừng)
    // - Tầng MEM chỉ bị stall khi Cache báo stall.
    // - Tầng IF bị stall khi Cache báo stall HOẶC khi bị tầng MEM giành quyền.
    assign mem_stall = mem_request & cache_stall;
    assign if_stall  = (if_read & mem_request) | (if_read & cache_stall);

endmodule