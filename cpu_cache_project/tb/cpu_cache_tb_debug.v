`timescale 1ns/1ps

// =============================================================================
// Debug testbench: Trace chi tiết ID stage để tìm root cause WB_reg=R0
// =============================================================================
module cpu_cache_tb_debug;

    reg  clk, rst, start;
    wire halted;
    wire [15:0] debug_pc, debug_instr;
    wire        debug_reg_write;
    wire [2:0]  debug_wb_reg;
    wire [15:0] debug_wb_data;

    cpu_cache_top #(.INIT_FILE("mem/test_arithmetic.mem")) u_top (
        .clk(clk), .rst(rst), .start(start), .halted(halted),
        .debug_pc(debug_pc), .debug_instr(debug_instr),
        .debug_reg_write(debug_reg_write),
        .debug_wb_reg(debug_wb_reg), .debug_wb_data(debug_wb_data)
    );

    initial begin clk = 1'b0; forever #5 clk = ~clk; end
    initial begin
        rst = 1'b1; start = 1'b0;
        repeat (3) @(posedge clk);
        rst = 1'b0;
        @(negedge clk);
        start = 1'b1;
    end

    initial begin
        $dumpfile("build/cpu_cache_debug.vcd");
        $dumpvars(0, cpu_cache_tb_debug);
    end

    // Trace chi tiết tất cả tín hiệu quan trọng
    always @(posedge clk) begin
        if (!rst) $display(
            "t=%0t | IF: pc=%h req=%b rdy=%b instr=%h | ID: instr=%h op=%h rs=%0d rt=%0d rd=%0d regdst=%b wr=%b | EX: wreg=%0d | WB: wreg=%0d data=%h wr=%b | stall=%b cstall=%b | R1=%h R2=%h R3=%h R4=%h",
            $time,
            // IF stage
            u_top.u_cpu_core.if_pc,
            u_top.u_cpu_core.if_req,
            u_top.u_cpu_core.if_ready,
            u_top.u_cpu_core.if_instr_in,
            // ID stage
            u_top.u_cpu_core.id_instr,
            u_top.u_cpu_core.id_opcode,
            u_top.u_cpu_core.id_rs,
            u_top.u_cpu_core.id_rt,
            u_top.u_cpu_core.id_rd,
            u_top.u_cpu_core.id_reg_dst,
            u_top.u_cpu_core.id_reg_write,
            // EX stage
            u_top.u_cpu_core.ex_write_reg,
            // WB stage
            u_top.u_cpu_core.wb_write_reg,
            u_top.u_cpu_core.wb_write_data,
            u_top.u_cpu_core.wb_reg_write,
            // Stall
            u_top.u_cpu_core.stall_out,
            u_top.u_cpu_core.cache_stall,
            // Registers
            u_top.u_cpu_core.u_regfile.registers[1],
            u_top.u_cpu_core.u_regfile.registers[2],
            u_top.u_cpu_core.u_regfile.registers[3],
            u_top.u_cpu_core.u_regfile.registers[4]
        );
    end

    integer cycles;
    initial begin
        cycles = 0;
        wait (rst == 1'b0);
        repeat (2) @(posedge clk);
        while (halted !== 1'b1 && cycles < 60) begin
            @(posedge clk); cycles = cycles + 1;
        end
        $display("DONE: cycles=%0d halted=%b R1=%h R2=%h R3=%h R4=%h",
            cycles, halted,
            u_top.u_cpu_core.u_regfile.registers[1],
            u_top.u_cpu_core.u_regfile.registers[2],
            u_top.u_cpu_core.u_regfile.registers[3],
            u_top.u_cpu_core.u_regfile.registers[4]);
        $finish;
    end

endmodule
