`timescale 1ns/1ps

module cpu_core_tb;

    reg         clk;
    reg         rst;
    wire        if_req;
    wire [15:0] if_addr;
    reg  [15:0] if_rdata;
    reg         if_ready;
    wire        mem_req;
    wire        mem_we;
    wire [15:0] mem_addr;
    wire [15:0] mem_wdata;
    reg  [15:0] mem_rdata;
    reg         mem_ready;
    wire        halted;
    wire [15:0] debug_pc;

    cpu_core u_cpu_core (
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
        .halted(halted),
        .debug_pc(debug_pc)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(*) begin
        if_rdata = (if_addr == 16'h0002) ? 16'hF000 : 16'h0000;
    end

    initial begin
        $display("cpu_core_tb: TODO replace smoke test with pipeline ISA tests");
        rst = 1'b1;
        if_ready = 1'b0;
        mem_ready = 1'b0;
        mem_rdata = 16'h0000;
        #20;
        rst = 1'b0;
        if_ready = 1'b1;
        #80;
        $finish;
    end

endmodule
