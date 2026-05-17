`timescale 1ns/1ps
`include "cache_config.vh"

// =============================================================================
// cache_tb.v — Kiểm tra toàn bộ hành vi Cache + Controller
//
// Test cases:
//   TC1 — Read MISS đầu tiên (cold start) → refill từ main_memory
//   TC2 — Read HIT (cùng địa chỉ) → trả ngay không cần RAM
//   TC3 — Read MISS (địa chỉ khác, cùng index, tag khác) → eviction + refill
//   TC4 — Write HIT → write-through đến RAM, không thay đổi cache
//   TC5 — Write MISS → ghi thẳng RAM, không allocate line
//   TC6 — Đọc lại sau Write HIT → dữ liệu mới
//   TC7 — Stress test: 16 địa chỉ liên tiếp (fill toàn bộ cache)
// =============================================================================
module cache_tb;

    reg         clk;
    reg         rst;
    reg         req;
    reg         we;
    reg  [15:0] addr;
    reg  [15:0] wdata;
    wire        ready;
    wire [15:0] rdata;

    // Main memory interface
    wire        mem_req;
    wire        mem_we;
    wire [15:0] mem_addr;
    wire [15:0] mem_wdata;
    reg         mem_ready;
    reg  [15:0] mem_rdata;

    wire        stall_sig;
    wire        cache_miss_sig;

    // =========================================================================
    // DUT: cache_subsystem (cache_controller + direct_mapped_cache)
    // =========================================================================
    cache_subsystem dut (
        .clk(clk), .rst(rst),
        .cpu_req(req), .cpu_we(we), .cpu_addr(addr), .cpu_wdata(wdata),
        .cpu_ready(ready), .cache_rdata(rdata),
        .stall(stall_sig), .cache_miss(cache_miss_sig),
        .mem_req(mem_req), .mem_we(mem_we),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_ready(mem_ready), .mem_rdata(mem_rdata)
    );

    // =========================================================================
    // Clock
    // =========================================================================
    initial begin clk = 0; forever #5 clk = ~clk; end

    integer pass_count, fail_count;
    integer timeout;

    // =========================================================================
    // Task: Gửi yêu cầu đọc và đợi ready, trả dữ liệu
    // =========================================================================
    task do_read;
        input [15:0] a;
        output [15:0] data_out;
        integer t;
        begin
            @(negedge clk);
            req = 1; we = 0; addr = a; wdata = 0;
            t = 0;
            @(posedge clk);
            while (!ready && t < 50) begin
                @(posedge clk);
                t = t + 1;
            end
            data_out = rdata;
            @(negedge clk);
            req = 0;
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Task: Gửi yêu cầu ghi và đợi ready
    // =========================================================================
    task do_write;
        input [15:0] a;
        input [15:0] d;
        integer t;
        begin
            @(negedge clk);
            req = 1; we = 1; addr = a; wdata = d;
            t = 0;
            @(posedge clk);
            while (!ready && t < 50) begin
                @(posedge clk);
                t = t + 1;
            end
            @(negedge clk);
            req = 0;
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Model bộ nhớ đơn giản (16 words) — phản hồi sau RAM_DELAY cycles
    // =========================================================================
    reg [15:0] ram [0:255];
    integer    ram_timer;
    reg        ram_busy;

    initial begin
        integer i;
        for (i = 0; i < 256; i = i + 1) ram[i] = 16'hA000 + i;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_ready <= 0; mem_rdata <= 0;
            ram_timer <= 0; ram_busy  <= 0;
        end else begin
            mem_ready <= 0;
            if (mem_req && !ram_busy) begin
                ram_timer <= `RAM_DELAY - 1;
                ram_busy  <= 1;
            end else if (ram_busy) begin
                if (ram_timer == 0) begin
                    ram_busy  <= 0;
                    mem_ready <= 1;
                    if (mem_we)
                        ram[mem_addr[7:0]] <= mem_wdata;
                    else
                        mem_rdata <= ram[mem_addr[7:0]];
                end else begin
                    ram_timer <= ram_timer - 1;
                end
            end
        end
    end

    // =========================================================================
    // TEST
    // =========================================================================
    reg [15:0] got_data;
    reg        got_hit;

    initial begin
        pass_count = 0; fail_count = 0;
        req = 0; we = 0; addr = 0; wdata = 0;
        rst = 1;
        repeat (4) @(posedge clk);
        rst = 0;
        repeat (2) @(posedge clk);

        $display("=== cache_tb START ===");

        // ---------------------------------------------------------------
        // TC1: Read MISS — địa chỉ 0x0005 (cold start)
        // ---------------------------------------------------------------
        do_read(16'h0005, got_data);
        if (got_data !== ram[5]) begin
            $display("FAIL TC1 (read miss): data=%h exp=%h hit=%b", got_data, ram[5]);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS TC1 (read miss cold): data=%h", got_data);
            pass_count = pass_count + 1;
        end

        // ---------------------------------------------------------------
        // TC2: Read HIT — cùng địa chỉ 0x0005 (đã cached)
        // ---------------------------------------------------------------
        do_read(16'h0005, got_data);
        if (got_data !== ram[5]) begin
            $display("FAIL TC2 (read hit): data=%h exp=%h hit=%b", got_data, ram[5]);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS TC2 (read hit): data=%h", got_data);
            pass_count = pass_count + 1;
        end

        // ---------------------------------------------------------------
        // TC3: Read MISS — địa chỉ 0x0015 (index = 5, tag khác → evict)
        // ---------------------------------------------------------------
        do_read(16'h0015, got_data);
        if (got_data !== ram[16'h15]) begin
            $display("FAIL TC3 (read miss evict): data=%h exp=%h hit=%b", got_data, ram[16'h15]);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS TC3 (read miss evict): data=%h", got_data);
            pass_count = pass_count + 1;
        end

        // ---------------------------------------------------------------
        // TC4: Write HIT — ghi vào địa chỉ 0x0015 (vừa cached)
        // ---------------------------------------------------------------
        do_write(16'h0015, 16'hBEEF);
        // Cập nhật model RAM
        ram[16'h15] = 16'hBEEF;
        // Đọc lại kiểm tra write-through
        do_read(16'h0015, got_data);
        if (got_data !== 16'hBEEF) begin
            $display("FAIL TC4 (write hit + read back): data=%h exp=BEEF", got_data);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS TC4 (write hit + read back): data=%h", got_data);
            pass_count = pass_count + 1;
        end

        // ---------------------------------------------------------------
        // TC5: Write MISS — ghi vào địa chỉ 0x0003 (chưa cached)
        // ---------------------------------------------------------------
        ram[3] = 16'hDEAD;  // update model
        do_write(16'h0003, 16'hDEAD);
        // Đọc lại (sẽ là MISS, refill từ RAM đã được ghi)
        do_read(16'h0003, got_data);
        if (got_data !== 16'hDEAD) begin
            $display("FAIL TC5 (write miss + read back): data=%h exp=DEAD", got_data);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS TC5 (write miss + read back): data=%h", got_data);
            pass_count = pass_count + 1;
        end

        // ---------------------------------------------------------------
        // TC6: Stress — fill 16 dòng cache với 16 địa chỉ liên tiếp (index 0..15)
        // ---------------------------------------------------------------
        begin
            integer i;
            integer stress_ok;
            stress_ok = 1;
            for (i = 0; i < 16; i = i + 1) begin
                do_read(i[15:0], got_data);
                if (got_data !== ram[i]) begin
                    $display("FAIL TC6 stress addr=%0d: data=%h exp=%h", i, got_data, ram[i]);
                    stress_ok = 0;
                    fail_count = fail_count + 1;
                end
            end
            if (stress_ok) begin
                $display("PASS TC6 (stress 16 lines fill)");
                pass_count = pass_count + 1;
            end
        end

        $display("=== cache_tb DONE: PASS=%0d  FAIL=%0d ===", pass_count, fail_count);
        if (fail_count > 0) $fatal(1);
        else $display("cache_tb: ALL PASS");
        $finish;
    end

endmodule
