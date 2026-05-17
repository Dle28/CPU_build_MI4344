`timescale 1ns/1ps
module tb_branch_debug;
    reg clk, rst, start;
    wire halted;
    wire [15:0] debug_pc, debug_instr, debug_wb_data;
    wire debug_reg_write;
    wire [2:0] debug_wb_reg;

    cpu_cache_top #(.INIT_FILE("mem/program_02_branch.mem")) u_top (
        .clk(clk), .rst(rst), .start(start), .halted(halted),
        .debug_pc(debug_pc), .debug_instr(debug_instr),
        .debug_reg_write(debug_reg_write),
        .debug_wb_reg(debug_wb_reg), .debug_wb_data(debug_wb_data)
    );
    initial begin clk=0; forever #5 clk=~clk; end
    initial begin
        rst=1; start=0;
        repeat(3) @(posedge clk);
        rst=0; @(negedge clk); start=1;
    end

    always @(posedge clk)
        if (!rst)
            $display("t=%0d | IF: pc=%h instr=%h | WB: wreg=%0d wdata=%h wr=%b | R2=%h R4=%h R5=%h",
                $time, debug_pc, debug_instr, debug_wb_reg, debug_wb_data, debug_reg_write,
                u_top.u_cpu_core.u_regfile.registers[2],
                u_top.u_cpu_core.u_regfile.registers[4],
                u_top.u_cpu_core.u_regfile.registers[5]);


    integer c;
    initial begin
        c=0; wait(rst==0); repeat(2) @(posedge clk);
        while(halted!==1 && c<200) begin @(posedge clk); c=c+1; end
        $display("DONE cycles=%0d halted=%b R2=%h R4=%h R5=%h",
            c, halted,
            u_top.u_cpu_core.u_regfile.registers[2],
            u_top.u_cpu_core.u_regfile.registers[4],
            u_top.u_cpu_core.u_regfile.registers[5]);
        $finish;
    end
endmodule
