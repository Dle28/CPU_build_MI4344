`timescale 1ns/1ps

module cache_tb;

    reg         clk;
    reg         rst;
    reg         req;
    reg         we;
    reg  [15:0] addr;
    reg  [15:0] wdata;
    wire [15:0] rdata;
    wire        ready;
    wire        hit;
    wire        miss;

    wire        mem_req;
    wire        mem_we;
    wire [15:0] mem_addr;
    wire [15:0] mem_wdata;
    wire [15:0] mem_rdata;
    wire        mem_ready;

    direct_mapped_cache u_cache (
        .clk(clk),
        .rst(rst),
        .req(req),
        .we(we),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .ready(ready),
        .hit(hit),
        .miss(miss),
        .mem_req(mem_req),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );

    main_memory #(
        .DELAY_CYCLES(2)
    ) u_memory (
        .clk(clk),
        .rst(rst),
        .req(mem_req),
        .we(mem_we),
        .addr(mem_addr),
        .wdata(mem_wdata),
        .rdata(mem_rdata),
        .ready(mem_ready)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("cache_tb: TODO verify read miss, refill, read hit, write-through, no-write-allocate");
        rst = 1'b1;
        req = 1'b0;
        we = 1'b0;
        addr = 16'h0000;
        wdata = 16'h0000;
        #20;
        rst = 1'b0;
        req = 1'b1;
        addr = 16'h0010;
        #60;
        req = 1'b0;
        #20;
        $finish;
    end

endmodule
