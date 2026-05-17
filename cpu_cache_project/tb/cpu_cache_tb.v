`timescale 1ns/1ps

module cpu_cache_tb;

    // =========================================================================
    // KHAI BÁO TÍN HIỆU
    // =========================================================================
    reg  clk;
    reg  rst;
    reg  start;           // FIX #1: Thêm tín hiệu start bị thiếu

    wire        halted;
    wire [15:0] debug_pc;
    wire [15:0] debug_instr;
    wire        debug_reg_write;
    wire [2:0]  debug_wb_reg;
    wire [15:0] debug_wb_data;

    // =========================================================================
    // KHỞI TẠO DUT
    // FIX #2: Tên parameter đúng là INIT_FILE, không phải MEM_INIT_FILE
    // FIX #1: Kết nối đủ tất cả các port (start + 5 debug outputs)
    // =========================================================================
    cpu_cache_top #(
        .INIT_FILE("mem/test_arithmetic.mem")
    ) u_top (
        .clk            (clk),
        .rst            (rst),
        .start          (start),
        .halted         (halted),
        .debug_pc       (debug_pc),
        .debug_instr    (debug_instr),
        .debug_reg_write(debug_reg_write),
        .debug_wb_reg   (debug_wb_reg),
        .debug_wb_data  (debug_wb_data)
    );

    // =========================================================================
    // CLOCK: Chu kỳ 10ns (100 MHz)
    // =========================================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // =========================================================================
    // RESET + START
    // start phải được set TẠI NEGEDGE (giữa 2 posedge) để tránh race condition
    // với pc_unit đọc enable tại posedge. Giữ HIGH liên tục.
    // =========================================================================
    initial begin
        rst   = 1'b1;
        start = 1'b0;
        repeat (3) @(posedge clk);
        rst   = 1'b0;
        @(negedge clk);         // Set start giữa 2 posedge — ổn định trước posedge tiếp
        start = 1'b1;           // Giữ HIGH đến hết simulation
    end

    // =========================================================================
    // RUN & CHECK
    // =========================================================================
    integer cycles;

    initial begin
        cycles = 0;
        $display("cpu_cache_tb: simulation start");

        // Đợi reset xong
        wait (rst == 1'b0);
        repeat (2) @(posedge clk);

        // Timeout safety: 2000 chu kỳ clock
        while (halted !== 1'b1 && cycles < 2000) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        if (halted !== 1'b1) begin
            $display("cpu_cache_tb: FAIL — timeout at pc=%h (after %0d cycles)", debug_pc, cycles);
            $fatal(1);
        end

        // =====================================================================
        // KIỂM TRA GIÁ TRỊ THANH GHI
        // FIX #3: Đường dẫn phân cấp đúng là u_cpu_core.u_regfile
        //         (cpu_core.v instantiate register_file TRỰC TIẾP, không qua datapath wrapper)
        // =====================================================================
        if (u_top.u_cpu_core.u_regfile.registers[1] !== 16'h0005) begin
            $display("cpu_cache_tb: FAIL R1 — got=%h, exp=0005",
                     u_top.u_cpu_core.u_regfile.registers[1]);
            $fatal(1);
        end
        if (u_top.u_cpu_core.u_regfile.registers[2] !== 16'h0003) begin
            $display("cpu_cache_tb: FAIL R2 — got=%h, exp=0003",
                     u_top.u_cpu_core.u_regfile.registers[2]);
            $fatal(1);
        end
        if (u_top.u_cpu_core.u_regfile.registers[3] !== 16'h0008) begin
            $display("cpu_cache_tb: FAIL R3 — got=%h, exp=0008",
                     u_top.u_cpu_core.u_regfile.registers[3]);
            $fatal(1);
        end
        if (u_top.u_cpu_core.u_regfile.registers[4] !== 16'h0003) begin
            $display("cpu_cache_tb: FAIL R4 — got=%h, exp=0003",
                     u_top.u_cpu_core.u_regfile.registers[4]);
            $fatal(1);
        end

        $display("cpu_cache_tb: PASS — cycles=%0d, final_pc=%h", cycles, debug_pc);
        $finish;
    end

endmodule
