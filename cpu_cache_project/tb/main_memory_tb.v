`timescale 1ns/1ps

module main_memory_tb;

    reg         clk;
    reg         rst;
    reg         req;
    reg         we;
    reg  [15:0] addr;
    reg  [15:0] wdata;
    wire [15:0] rdata;
    wire        ready;

    main_memory #(
        .DELAY_CYCLES(2)
    ) u_main_memory (
        .clk(clk),
        .rst(rst),
        .req(req),
        .we(we),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .ready(ready)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("main_memory_tb: TODO verify delayed read/write timing");
        rst = 1'b1;
        req = 1'b0;
        we = 1'b0;
        addr = 16'h0000;
        wdata = 16'h0000;
        #20;
        rst = 1'b0;
        req = 1'b1;
        we = 1'b1;
        addr = 16'h0020;
        wdata = 16'h1234;
        #10;
        req = 1'b0;
        #80;
        $finish;
    end

endmodule
