`timescale 1ns/1ps

// =============================================================================
// cpu_core_tb.v — Kiểm tra toàn bộ pipeline với 3 chương trình độc lập
//
// Test 1: Arithmetic   (mem/test_arithmetic.mem)
//   R1=5, R2=3, R3=8 (R1+R2), R4=3
//
// Test 2: Branch + Jump (mem/program_02_branch.mem)
//   R2=3 (đếm vòng lặp), R5=5 (landmark)
//
// Test 3: Load + Store  (mem/program_03_loadstore.mem)
//   R1=20, R2=31, R3=20
// =============================================================================
module cpu_core_tb;

    // =========================================================================
    // 1. TEST ARITHMETIC
    // =========================================================================
    reg  clk1, rst1, start1;
    wire halted1;
    wire [15:0] debug_pc1, debug_instr1, debug_wb_data1;
    wire        debug_reg_write1;
    wire [2:0]  debug_wb_reg1;

    cpu_cache_top #(.INIT_FILE("mem/test_arithmetic.mem")) u_arith (
        .clk(clk1), .rst(rst1), .start(start1), .halted(halted1),
        .debug_pc(debug_pc1), .debug_instr(debug_instr1),
        .debug_reg_write(debug_reg_write1),
        .debug_wb_reg(debug_wb_reg1), .debug_wb_data(debug_wb_data1)
    );

    initial begin clk1 = 0; forever #5 clk1 = ~clk1; end

    // =========================================================================
    // 2. TEST BRANCH + JUMP
    // =========================================================================
    reg  clk2, rst2, start2;
    wire halted2;
    wire [15:0] debug_pc2, debug_instr2, debug_wb_data2;
    wire        debug_reg_write2;
    wire [2:0]  debug_wb_reg2;

    cpu_cache_top #(.INIT_FILE("mem/program_02_branch.mem")) u_branch (
        .clk(clk2), .rst(rst2), .start(start2), .halted(halted2),
        .debug_pc(debug_pc2), .debug_instr(debug_instr2),
        .debug_reg_write(debug_reg_write2),
        .debug_wb_reg(debug_wb_reg2), .debug_wb_data(debug_wb_data2)
    );

    initial begin clk2 = 0; forever #5 clk2 = ~clk2; end

    // =========================================================================
    // 3. TEST LOAD + STORE
    // =========================================================================
    reg  clk3, rst3, start3;
    wire halted3;
    wire [15:0] debug_pc3, debug_instr3, debug_wb_data3;
    wire        debug_reg_write3;
    wire [2:0]  debug_wb_reg3;

    cpu_cache_top #(.INIT_FILE("mem/program_03_loadstore.mem")) u_ldst (
        .clk(clk3), .rst(rst3), .start(start3), .halted(halted3),
        .debug_pc(debug_pc3), .debug_instr(debug_instr3),
        .debug_reg_write(debug_reg_write3),
        .debug_wb_reg(debug_wb_reg3), .debug_wb_data(debug_wb_data3)
    );

    initial begin clk3 = 0; forever #5 clk3 = ~clk3; end

    // =========================================================================
    // Helper task: Reset + Start một instance CPU
    // =========================================================================
    // Lưu ý: Verilog-2001 không cho phép task với ref port động,
    // mỗi instance dùng 1 initial block riêng

    integer total_pass, total_fail;

    // =========================================================================
    // RUN TEST 1 — ARITHMETIC
    // =========================================================================
    integer cycles1;
    initial begin
        rst1 = 1; start1 = 0;
        repeat (3) @(posedge clk1);
        rst1 = 0;
        @(negedge clk1);
        start1 = 1;
    end

    // =========================================================================
    // RUN TEST 2 — BRANCH
    // =========================================================================
    integer cycles2;
    initial begin
        rst2 = 1; start2 = 0;
        repeat (3) @(posedge clk2);
        rst2 = 0;
        @(negedge clk2);
        start2 = 1;
    end

    // =========================================================================
    // RUN TEST 3 — LOAD/STORE
    // =========================================================================
    integer cycles3;
    initial begin
        rst3 = 1; start3 = 0;
        repeat (3) @(posedge clk3);
        rst3 = 0;
        @(negedge clk3);
        start3 = 1;
    end

    // =========================================================================
    // KIỂM TRA KẾT QUẢ — chạy tuần tự sau khi tất cả halt
    // =========================================================================
    initial begin
        total_pass = 0; total_fail = 0;

        // --- Đợi Test 1 HALT ---
        cycles1 = 0;
        wait (rst1 == 0);
        repeat (2) @(posedge clk1);
        while (halted1 !== 1 && cycles1 < 3000) begin
            @(posedge clk1); cycles1 = cycles1 + 1;
        end

        $display("=== cpu_core_tb TEST1 (Arithmetic) cycles=%0d ===", cycles1);
        if (halted1 !== 1) begin
            $display("FAIL T1: timeout"); total_fail = total_fail + 1;
        end else begin
            if (u_arith.u_cpu_core.u_regfile.registers[1] !== 16'h0005) begin
                $display("FAIL T1 R1: got=%h exp=0005", u_arith.u_cpu_core.u_regfile.registers[1]);
                total_fail = total_fail + 1;
            end else begin
                $display("PASS T1 R1=0005"); total_pass = total_pass + 1;
            end
            if (u_arith.u_cpu_core.u_regfile.registers[2] !== 16'h0003) begin
                $display("FAIL T1 R2: got=%h exp=0003", u_arith.u_cpu_core.u_regfile.registers[2]);
                total_fail = total_fail + 1;
            end else begin
                $display("PASS T1 R2=0003"); total_pass = total_pass + 1;
            end
            if (u_arith.u_cpu_core.u_regfile.registers[3] !== 16'h0008) begin
                $display("FAIL T1 R3: got=%h exp=0008", u_arith.u_cpu_core.u_regfile.registers[3]);
                total_fail = total_fail + 1;
            end else begin
                $display("PASS T1 R3=0008"); total_pass = total_pass + 1;
            end
            if (u_arith.u_cpu_core.u_regfile.registers[4] !== 16'h0003) begin
                $display("FAIL T1 R4: got=%h exp=0003", u_arith.u_cpu_core.u_regfile.registers[4]);
                total_fail = total_fail + 1;
            end else begin
                $display("PASS T1 R4=0003"); total_pass = total_pass + 1;
            end
        end

        // --- Đợi Test 2 HALT ---
        cycles2 = 0;
        wait (rst2 == 0);
        repeat (2) @(posedge clk2);
        while (halted2 !== 1 && cycles2 < 5000) begin
            @(posedge clk2); cycles2 = cycles2 + 1;
        end

        $display("=== cpu_core_tb TEST2 (Branch+Jump) cycles=%0d ===", cycles2);
        if (halted2 !== 1) begin
            $display("FAIL T2: timeout"); total_fail = total_fail + 1;
        end else begin
            if (u_branch.u_cpu_core.u_regfile.registers[2] !== 16'h0003) begin
                $display("FAIL T2 R2: got=%h exp=0003", u_branch.u_cpu_core.u_regfile.registers[2]);
                total_fail = total_fail + 1;
            end else begin
                $display("PASS T2 R2=0003 (loop counter)"); total_pass = total_pass + 1;
            end
            if (u_branch.u_cpu_core.u_regfile.registers[5] !== 16'h0005) begin
                $display("FAIL T2 R5: got=%h exp=0005 (jump landmark)",
                    u_branch.u_cpu_core.u_regfile.registers[5]);
                total_fail = total_fail + 1;
            end else begin
                $display("PASS T2 R5=0005 (jump landmark)"); total_pass = total_pass + 1;
            end
        end

        // --- Đợi Test 3 HALT ---
        cycles3 = 0;
        wait (rst3 == 0);
        repeat (2) @(posedge clk3);
        while (halted3 !== 1 && cycles3 < 5000) begin
            @(posedge clk3); cycles3 = cycles3 + 1;
        end

        $display("=== cpu_core_tb TEST3 (Load+Store) cycles=%0d ===", cycles3);
        if (halted3 !== 1) begin
            $display("FAIL T3: timeout"); total_fail = total_fail + 1;
        end else begin
            if (u_ldst.u_cpu_core.u_regfile.registers[1] !== 16'd20) begin
                $display("FAIL T3 R1: got=%h exp=0014 (20)", u_ldst.u_cpu_core.u_regfile.registers[1]);
                total_fail = total_fail + 1;
            end else begin
                $display("PASS T3 R1=20 (load after store)"); total_pass = total_pass + 1;
            end
            if (u_ldst.u_cpu_core.u_regfile.registers[2] !== 16'd31) begin
                $display("FAIL T3 R2: got=%h exp=001F (31)", u_ldst.u_cpu_core.u_regfile.registers[2]);
                total_fail = total_fail + 1;
            end else begin
                $display("PASS T3 R2=31 (load after store)"); total_pass = total_pass + 1;
            end
            if (u_ldst.u_cpu_core.u_regfile.registers[3] !== 16'd20) begin
                $display("FAIL T3 R3: got=%h exp=0014 (20)", u_ldst.u_cpu_core.u_regfile.registers[3]);
                total_fail = total_fail + 1;
            end else begin
                $display("PASS T3 R3=20 (read same addr as R1)"); total_pass = total_pass + 1;
            end
        end

        // ---------------------------------------------------------------
        // TỔNG KẾT
        // ---------------------------------------------------------------
        $display("=== cpu_core_tb DONE: PASS=%0d  FAIL=%0d ===", total_pass, total_fail);
        if (total_fail > 0) $fatal(1);
        else $display("cpu_core_tb: ALL PASS");
        $finish;
    end

endmodule
