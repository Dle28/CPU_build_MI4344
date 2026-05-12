`timescale 1ns/1ps

module register_file_tb;

    reg         clk;
    reg         rst;
    reg         we;
    reg  [2:0]  waddr;
    reg  [15:0] wdata;
    reg  [2:0]  raddr1;
    reg  [2:0]  raddr2;
    wire [15:0] rdata1;
    wire [15:0] rdata2;

    register_file u_register_file (
        .clk(clk),
        .rst(rst),
        .we(we),
        .waddr(waddr),
        .wdata(wdata),
        .raddr1(raddr1),
        .raddr2(raddr2),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("register_file_tb: TODO expand R0 and register write/read checks");
        rst = 1'b1;
        we = 1'b0;
        waddr = 3'd0;
        wdata = 16'h0000;
        raddr1 = 3'd0;
        raddr2 = 3'd1;
        #20;
        rst = 1'b0;
        we = 1'b1;
        waddr = 3'd1;
        wdata = 16'h00AA;
        #10;
        we = 1'b1;
        waddr = 3'd0;
        wdata = 16'hFFFF;
        #10;
        we = 1'b0;
        raddr1 = 3'd0;
        raddr2 = 3'd1;
        #10;
        $finish;
    end

endmodule
