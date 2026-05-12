`timescale 1ns/1ps

module control_unit_tb;

    reg  [3:0] opcode;
    reg  [2:0] funct;
    wire       reg_write;
    wire       mem_read;
    wire       mem_write;
    wire       branch_eq;
    wire       branch_ne;
    wire       jump;
    wire       alu_src_imm;
    wire       mem_to_reg;
    wire       halt;
    wire [2:0] alu_op;

    control_unit u_control_unit (
        .opcode(opcode),
        .funct(funct),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch_eq(branch_eq),
        .branch_ne(branch_ne),
        .jump(jump),
        .alu_src_imm(alu_src_imm),
        .mem_to_reg(mem_to_reg),
        .halt(halt),
        .alu_op(alu_op)
    );

    initial begin
        $display("control_unit_tb: TODO expand opcode/funct decode checks");
        opcode = 4'h0;
        funct = 3'h0;
        #1;
        opcode = 4'h2;
        #1;
        opcode = 4'hF;
        #1;
        $finish;
    end

endmodule
