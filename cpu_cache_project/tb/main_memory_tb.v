`timescale 1ns/1ps

// =============================================================================
// main_memory_tb.v — Kiểm tra RAM 64K×16-bit với độ trễ
//
// Test cases:
//   TC1 — Write 4 địa chỉ, đọc lại kiểm tra
//   TC2 — Đọc địa chỉ chưa ghi (giá trị từ $readmemh = 0x0000)
//   TC3 — Ghi liên tiếp không nghỉ giữa các request
// =============================================================================
module main_memory_tb;

    reg         clk;
    reg         rst;
    reg         req;
    reg         we;
    reg  [15:0] addr;
    reg  [15:0] wdata;
    wire        ready;
    wire [15:0] rdata;

    main_memory dut (
        .clk(clk), .rst(rst),
        .mem_req(req), .mem_we(we), .mem_addr(addr), .mem_wdata(wdata),
        .mem_ready(ready), .mem_rdata(rdata)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    integer pass_count, fail_count;

    // =========================================================================
    // Task: ghi 1 word, đợi ready
    // =========================================================================
    task mem_write;
        input [15:0] a;
        input [15:0] d;
        integer t;
        begin
            @(negedge clk);
            req = 1; we = 1; addr = a; wdata = d;
            t = 0;
            @(posedge clk);
            while (!ready && t < 30) begin @(posedge clk); t = t + 1; end
            @(negedge clk); req = 0; we = 0;
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Task: đọc 1 word, đợi ready, trả dữ liệu
    // =========================================================================
    task mem_read;
        input  [15:0] a;
        output [15:0] d;
        integer t;
        begin
            @(negedge clk);
            req = 1; we = 0; addr = a; wdata = 0;
            t = 0;
            @(posedge clk);
            while (!ready && t < 30) begin @(posedge clk); t = t + 1; end
            d = rdata;
            @(negedge clk); req = 0;
            @(posedge clk);
        end
    endtask

    reg [15:0] got;

    initial begin
        pass_count = 0; fail_count = 0;
        req = 0; we = 0; addr = 0; wdata = 0;
        rst = 1; repeat (4) @(posedge clk); rst = 0;
        repeat (2) @(posedge clk);

        $display("=== main_memory_tb START ===");

        // TC1: Ghi 4 địa chỉ, đọc lại
        mem_write(16'h0000, 16'hAAAA);
        mem_write(16'h0001, 16'hBBBB);
        mem_write(16'h00FF, 16'hCCCC);
        mem_write(16'hFFFE, 16'hDDDD);

        mem_read(16'h0000, got);
        if (got !== 16'hAAAA) begin $display("FAIL TC1a: addr=0000 got=%h exp=AAAA", got); fail_count=fail_count+1; end
        else begin $display("PASS TC1a: addr=0000 data=%h", got); pass_count=pass_count+1; end

        mem_read(16'h0001, got);
        if (got !== 16'hBBBB) begin $display("FAIL TC1b: addr=0001 got=%h exp=BBBB", got); fail_count=fail_count+1; end
        else begin $display("PASS TC1b: addr=0001 data=%h", got); pass_count=pass_count+1; end

        mem_read(16'h00FF, got);
        if (got !== 16'hCCCC) begin $display("FAIL TC1c: addr=00FF got=%h exp=CCCC", got); fail_count=fail_count+1; end
        else begin $display("PASS TC1c: addr=00FF data=%h", got); pass_count=pass_count+1; end

        mem_read(16'hFFFE, got);
        if (got !== 16'hDDDD) begin $display("FAIL TC1d: addr=FFFE got=%h exp=DDDD", got); fail_count=fail_count+1; end
        else begin $display("PASS TC1d: addr=FFFE data=%h", got); pass_count=pass_count+1; end

        // TC2: Ghi rồi ghi đè, đọc lại phải thấy giá trị mới nhất
        mem_write(16'h0010, 16'h1111);
        mem_write(16'h0010, 16'h2222);
        mem_read(16'h0010, got);
        if (got !== 16'h2222) begin $display("FAIL TC2 (overwrite): got=%h exp=2222", got); fail_count=fail_count+1; end
        else begin $display("PASS TC2 (overwrite): data=%h", got); pass_count=pass_count+1; end

        // TC3: Kiểm tra độ trễ — ready phải assert sau đúng RAM_DELAY cycles
        begin
            integer delay;
            @(negedge clk);
            req = 1; we = 0; addr = 16'h0000; wdata = 0;
            delay = 0;
            @(posedge clk);
            while (!ready && delay < 20) begin
                @(posedge clk);
                delay = delay + 1;
            end
            @(negedge clk); req = 0;
            // Độ trễ phải >= RAM_DELAY-1 (tính từ lúc req)
            if (delay < 4) begin
                $display("FAIL TC3 (latency): delay=%0d (too fast, expected >= 4)", delay);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS TC3 (latency): delay=%0d cycles", delay);
                pass_count = pass_count + 1;
            end
            @(posedge clk);
        end

        $display("=== main_memory_tb DONE: PASS=%0d  FAIL=%0d ===", pass_count, fail_count);
        if (fail_count > 0) $fatal(1);
        else $display("main_memory_tb: ALL PASS");
        $finish;
    end

endmodule
