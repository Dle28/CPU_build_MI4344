`timescale 1ns/1ps

// tick: đã xong

module alu_tb;

    reg  [15:0] a;
    reg  [15:0] b;
    reg  [3:0]  alu_op;
    wire [15:0] result;
    wire        zero;
    wire        negative;
    wire        overflow;

    `include "cpu_defines.vh"

    alu u_alu (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result),
        .zero(zero),
        .negative(negative),
        .overflow(overflow)
    );

    function [15:0] model_result;
        input [15:0] a_in;
        input [15:0] b_in;
        input [3:0]  op_in;
        begin
            case (op_in)
                `ALU_ADD: model_result = a_in + b_in;
                `ALU_SUB: model_result = a_in - b_in;
                `ALU_AND: model_result = a_in & b_in;
                `ALU_OR:  model_result = a_in | b_in;
                `ALU_XOR: model_result = a_in ^ b_in;
                `ALU_SLT: model_result = ($signed(a_in) < $signed(b_in)) ? 16'h0001 : 16'h0000;
                `ALU_SLL: model_result = a_in << b_in[3:0];
                `ALU_SRL: model_result = a_in >> b_in[3:0];
                default: model_result = 16'h0000;
            endcase
        end
    endfunction

    function model_overflow;
        input [15:0] a_in;
        input [15:0] b_in;
        input [15:0] r_in;
        input [3:0]  op_in;
        begin
            case (op_in)
                `ALU_ADD: model_overflow = (~a_in[15] & ~b_in[15] & r_in[15]) | (a_in[15] & b_in[15] & ~r_in[15]);
                `ALU_SUB: model_overflow = (~a_in[15] & b_in[15] & r_in[15]) | (a_in[15] & ~b_in[15] & ~r_in[15]);
                default:  model_overflow = 1'b0;
            endcase
        end
    endfunction

    task check_vec;
        input [15:0] a_in;
        input [15:0] b_in;
        input [3:0]  op_in;
        reg   [15:0] exp;
        reg          exp_zero;
        reg          exp_negative;
        reg          exp_overflow;
        begin
            exp = model_result(a_in, b_in, op_in);
            exp_zero = (exp == 16'h0000);
            exp_negative = exp[15];
            exp_overflow = model_overflow(a_in, b_in, exp, op_in);

            a = a_in;
            b = b_in;
            alu_op = op_in;
            #1;

            if (result !== exp) begin
                $display("alu_tb: FAIL op=%0d a=%h b=%h => got %h exp %h", op_in, a_in, b_in, result, exp);
                $fatal(1);
            end
            if (zero !== exp_zero) begin
                $display("alu_tb: FAIL zero op=%0d a=%h b=%h => got %b exp %b (result=%h)", op_in, a_in, b_in, zero, exp_zero, result);
                $fatal(1);
            end
            if (negative !== exp_negative) begin
                $display("alu_tb: FAIL negative op=%0d a=%h b=%h => got %b exp %b (result=%h)", op_in, a_in, b_in, negative, exp_negative, result);
                $fatal(1);
            end
            if (overflow !== exp_overflow) begin
                $display("alu_tb: FAIL overflow op=%0d a=%h b=%h => got %b exp %b (result=%h)", op_in, a_in, b_in, overflow, exp_overflow, result);
                $fatal(1);
            end
        end
    endtask

    integer i;

    initial begin
        $dumpfile("build/alu_tb.vcd");
        $dumpvars(0, alu_tb);

        $display("alu_tb: start");

        // Directed tests
        check_vec(16'h0005, 16'h0003, `ALU_ADD);
        check_vec(16'h0005, 16'h0003, `ALU_SUB);
        check_vec(16'hAAAA, 16'h5555, `ALU_AND); // -> zero=1
        check_vec(16'h0F0F, 16'h00F0, `ALU_OR);
        check_vec(16'hF0F0, 16'hF0F0, `ALU_XOR); // -> zero=1
        check_vec(16'hFFFF, 16'h0001, `ALU_SLT); // -1 < 1
        check_vec(16'h0001, 16'hFFFF, `ALU_SLT); // 1 < -1 (false)
        check_vec(16'h0001, 16'h0004, `ALU_SLL); // 1 << 4
        check_vec(16'h8000, 16'h0001, `ALU_SRL); // logical shift right
        check_vec(16'h1234, 16'h0000, `ALU_SRL);
        check_vec(16'h0001, 16'h0014, `ALU_SLL); // shift amount uses b[3:0] (=4)

        // Overflow directed
        check_vec(16'h7FFF, 16'h0001, `ALU_ADD);
        check_vec(16'h8000, 16'h0001, `ALU_SUB);

        // Randomized sanity
        for (i = 0; i < 200; i = i + 1) begin
            check_vec($random, $random, $random);
        end

        $display("alu_tb: PASS");
        $finish;
    end

endmodule
