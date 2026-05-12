`timescale 1ns/1ps

module cpu_cache_tb;

    reg         clk;
    reg         rst;
    wire        halted;
    wire [15:0] debug_pc;

    cpu_cache_top #(
        .MEMORY_DELAY(2)
    ) u_top (
        .clk(clk),
        .rst(rst),
        .halted(halted),
        .debug_pc(debug_pc)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("cpu_cache_tb: TODO load mem/*.mem and verify full-system behavior");
        rst = 1'b1;
        #20;
        rst = 1'b0;
        #200;
        $finish;
    end

endmodule
