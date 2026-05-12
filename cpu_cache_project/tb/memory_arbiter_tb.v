`timescale 1ns/1ps

module memory_arbiter_tb;

    reg         clk;
    reg         rst;
    reg         if_req;
    reg  [15:0] if_addr;
    wire [15:0] if_rdata;
    wire        if_ready;
    reg         mem_req;
    reg         mem_we;
    reg  [15:0] mem_addr;
    reg  [15:0] mem_wdata;
    wire [15:0] mem_rdata;
    wire        mem_ready;
    wire        cache_req;
    wire        cache_we;
    wire [15:0] cache_addr;
    wire [15:0] cache_wdata;
    reg  [15:0] cache_rdata;
    reg         cache_ready;

    memory_arbiter u_memory_arbiter (
        .clk(clk),
        .rst(rst),
        .if_req(if_req),
        .if_addr(if_addr),
        .if_rdata(if_rdata),
        .if_ready(if_ready),
        .mem_req(mem_req),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready),
        .cache_req(cache_req),
        .cache_we(cache_we),
        .cache_addr(cache_addr),
        .cache_wdata(cache_wdata),
        .cache_rdata(cache_rdata),
        .cache_ready(cache_ready)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("memory_arbiter_tb: TODO verify MEM priority over IF");
        rst = 1'b1;
        if_req = 1'b0;
        if_addr = 16'h0000;
        mem_req = 1'b0;
        mem_we = 1'b0;
        mem_addr = 16'h0000;
        mem_wdata = 16'h0000;
        cache_rdata = 16'hABCD;
        cache_ready = 1'b0;
        #20;
        rst = 1'b0;
        if_req = 1'b1;
        if_addr = 16'h0004;
        mem_req = 1'b1;
        mem_addr = 16'h0020;
        cache_ready = 1'b1;
        #20;
        $finish;
    end

endmodule
