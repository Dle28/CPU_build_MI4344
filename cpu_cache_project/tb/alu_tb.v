`timescale 1ns/1ps

module alu_tb;

    reg  [15:0] a;
    reg  [15:0] b;
    reg  [2:0]  alu_op;
    wire [15:0] result;
    wire        zero;

    alu u_alu (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result),
        .zero(zero)
    );

    initial begin
        $display("alu_tb: TODO expand directed ALU tests");
        a = 16'd5;
        b = 16'd3;
        alu_op = 3'h0;
        #1;
        if (result !== 16'd8) begin
            $display("alu_tb: ADD smoke test failed");
        end
        $finish;
    end

endmodule
