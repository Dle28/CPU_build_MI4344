`timescale 1ns/1ps
`include "cpu_defines.vh"

// =============================================================================
// control_unit_tb.v — Kiểm tra toàn bộ bảng giải mã lệnh
// Mỗi test case kiểm tra một opcode/funct và so sánh với giá trị mong đợi.
// =============================================================================
module control_unit_tb;

    reg  [3:0] opcode;
    reg  [2:0] funct;
    wire       reg_dst, alu_src, mem_to_reg, reg_write;
    wire       mem_read, mem_write, branch, branch_ne, jump, halt;
    wire [3:0] alu_op;

    control_unit dut (
        .opcode(opcode), .funct(funct),
        .reg_dst(reg_dst), .alu_src(alu_src), .mem_to_reg(mem_to_reg),
        .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
        .branch(branch), .branch_ne(branch_ne), .jump(jump),
        .alu_op(alu_op), .halt(halt)
    );

    integer pass_count, fail_count;

    // =========================================================================
    // Task kiểm tra 1 lệnh
    // =========================================================================
    task check;
        input [63:0] tc_name;  // không dùng string để tránh issue compatibility
        input exp_reg_dst, exp_alu_src, exp_mem_to_reg, exp_reg_write;
        input exp_mem_read, exp_mem_write, exp_branch, exp_branch_ne;
        input exp_jump, exp_halt;
        input [3:0] exp_alu_op;
        begin
            #1;
            if (reg_dst    !== exp_reg_dst    ||
                alu_src    !== exp_alu_src    ||
                mem_to_reg !== exp_mem_to_reg ||
                reg_write  !== exp_reg_write  ||
                mem_read   !== exp_mem_read   ||
                mem_write  !== exp_mem_write  ||
                branch     !== exp_branch     ||
                branch_ne  !== exp_branch_ne  ||
                jump       !== exp_jump       ||
                halt       !== exp_halt       ||
                alu_op     !== exp_alu_op) begin
                $display("FAIL [op=%h funct=%h]: got alu_op=%b reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_read=%b mem_write=%b branch=%b branch_ne=%b jump=%b halt=%b",
                    opcode, funct, alu_op, reg_dst, alu_src, mem_to_reg,
                    reg_write, mem_read, mem_write, branch, branch_ne, jump, halt);
                $display("       exp alu_op=%b reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_read=%b mem_write=%b branch=%b branch_ne=%b jump=%b halt=%b",
                    exp_alu_op, exp_reg_dst, exp_alu_src, exp_mem_to_reg,
                    exp_reg_write, exp_mem_read, exp_mem_write,
                    exp_branch, exp_branch_ne, exp_jump, exp_halt);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== control_unit_tb START ===");

        // ---------------------------------------------------------------
        // R-TYPE (opcode = 0x0)
        // reg_dst=1, reg_write=1, alu_src=0, mem_to_reg=0
        // mem_read=0, mem_write=0, branch=0, branch_ne=0, jump=0, halt=0
        // ---------------------------------------------------------------
        // ADD  — funct 000 → alu_op = ALU_ADD (0000)
        opcode = 4'h0; funct = 3'h0;
        check("ADD", 1,0,0,1, 0,0,0,0, 0,0, `ALU_ADD);

        // SUB  — funct 001 → alu_op = ALU_SUB (0001)
        opcode = 4'h0; funct = 3'h1;
        check("SUB", 1,0,0,1, 0,0,0,0, 0,0, `ALU_SUB);

        // AND  — funct 010 → alu_op = ALU_AND (0010)
        opcode = 4'h0; funct = 3'h2;
        check("AND", 1,0,0,1, 0,0,0,0, 0,0, `ALU_AND);

        // OR   — funct 011 → alu_op = ALU_OR  (0011)
        opcode = 4'h0; funct = 3'h3;
        check("OR ", 1,0,0,1, 0,0,0,0, 0,0, `ALU_OR);

        // XOR  — funct 100 → alu_op = ALU_XOR (0100)
        opcode = 4'h0; funct = 3'h4;
        check("XOR", 1,0,0,1, 0,0,0,0, 0,0, `ALU_XOR);

        // SLT  — funct 101 → alu_op = ALU_SLT (0101)
        opcode = 4'h0; funct = 3'h5;
        check("SLT", 1,0,0,1, 0,0,0,0, 0,0, `ALU_SLT);

        // SLL  — funct 110 → alu_op = ALU_SLL (0110)
        opcode = 4'h0; funct = 3'h6;
        check("SLL", 1,0,0,1, 0,0,0,0, 0,0, `ALU_SLL);

        // SRL  — funct 111 → alu_op = ALU_SRL (0111)
        opcode = 4'h0; funct = 3'h7;
        check("SRL", 1,0,0,1, 0,0,0,0, 0,0, `ALU_SRL);

        // ---------------------------------------------------------------
        // ADDI (opcode = 0x1)
        // alu_src=1, reg_write=1, alu_op=ADD, còn lại = 0
        // ---------------------------------------------------------------
        opcode = 4'h1; funct = 3'h0;
        check("ADDI", 0,1,0,1, 0,0,0,0, 0,0, `ALU_ADD);

        // ---------------------------------------------------------------
        // LW (opcode = 0x2)
        // alu_src=1, mem_to_reg=1, reg_write=1, mem_read=1, alu_op=ADD
        // ---------------------------------------------------------------
        opcode = 4'h2; funct = 3'h0;
        check("LW  ", 0,1,1,1, 1,0,0,0, 0,0, `ALU_ADD);

        // ---------------------------------------------------------------
        // SW (opcode = 0x3)
        // alu_src=1, mem_write=1, alu_op=ADD, reg_write=0
        // ---------------------------------------------------------------
        opcode = 4'h3; funct = 3'h0;
        check("SW  ", 0,1,0,0, 0,1,0,0, 0,0, `ALU_ADD);

        // ---------------------------------------------------------------
        // BEQ (opcode = 0x4)
        // branch=1, alu_op=SUB, còn lại = 0
        // ---------------------------------------------------------------
        opcode = 4'h4; funct = 3'h0;
        check("BEQ ", 0,0,0,0, 0,0,1,0, 0,0, `ALU_SUB);

        // ---------------------------------------------------------------
        // BNE (opcode = 0x5)
        // branch_ne=1, alu_op=SUB, còn lại = 0
        // ---------------------------------------------------------------
        opcode = 4'h5; funct = 3'h0;
        check("BNE ", 0,0,0,0, 0,0,0,1, 0,0, `ALU_SUB);

        // ---------------------------------------------------------------
        // J (opcode = 0x6)
        // jump=1, còn lại = 0
        // ---------------------------------------------------------------
        opcode = 4'h6; funct = 3'h0;
        check("J   ", 0,0,0,0, 0,0,0,0, 1,0, `ALU_ADD);

        // ---------------------------------------------------------------
        // HALT (opcode = 0xF)
        // halt=1, còn lại = 0
        // ---------------------------------------------------------------
        opcode = 4'hF; funct = 3'h0;
        check("HALT", 0,0,0,0, 0,0,0,0, 0,1, `ALU_ADD);

        // ---------------------------------------------------------------
        // NOP / unknown opcode → tất cả = 0
        // ---------------------------------------------------------------
        opcode = 4'h7; funct = 3'h0;
        check("NOP ", 0,0,0,0, 0,0,0,0, 0,0, `ALU_ADD);

        // ---------------------------------------------------------------
        // Tổng kết
        // ---------------------------------------------------------------
        $display("=== control_unit_tb DONE: PASS=%0d  FAIL=%0d ===", pass_count, fail_count);
        if (fail_count > 0) $fatal(1);
        else $display("control_unit_tb: ALL PASS");
        $finish;
    end

endmodule
