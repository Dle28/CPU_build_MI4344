`timescale 1ns/1ps
`include "cache_config.vh"

// =============================================================================
// memory_arbiter_tb.v — Kiểm tra ưu tiên MEM > IF
//
// Test cases:
//   TC1 — Chỉ IF request → cache phục vụ IF
//   TC2 — Chỉ MEM request (read) → cache phục vụ MEM
//   TC3 — Chỉ MEM request (write) → cache phục vụ MEM
//   TC4 — IF + MEM đồng thời → MEM được ưu tiên, IF bị hủy
//   TC5 — Sau khi MEM xong, IF mới được phục vụ
// =============================================================================
module memory_arbiter_tb;

    reg         if_req;
    reg  [15:0] if_addr;
    wire        if_ready;
    wire [15:0] if_instr;

    reg         mem_req;
    reg         mem_we;
    reg  [15:0] mem_addr;
    reg  [15:0] mem_wdata;
    wire        mem_ready;
    wire [15:0] mem_rdata;

    wire        cache_req;
    wire        cache_we;
    wire [15:0] cache_addr;
    wire [15:0] cache_wdata;
    reg         cache_ready;
    reg  [15:0] cache_rdata;

    memory_arbiter dut (
        .if_req(if_req), .if_addr(if_addr), .if_ready(if_ready), .if_instr(if_instr),
        .mem_req(mem_req), .mem_we(mem_we), .mem_addr(mem_addr),
        .mem_wdata(mem_wdata), .mem_ready(mem_ready), .mem_rdata(mem_rdata),
        .cache_req(cache_req), .cache_we(cache_we), .cache_addr(cache_addr),
        .cache_wdata(cache_wdata), .cache_ready(cache_ready), .cache_rdata(cache_rdata)
    );

    integer pass_count, fail_count;

    task check_comb;
        input [63:0] tc_name;
        input exp_cache_req, exp_cache_we;
        input [15:0] exp_cache_addr;
        begin
            #1;
            if (cache_req  !== exp_cache_req  ||
                cache_we   !== exp_cache_we   ||
                cache_addr !== exp_cache_addr) begin
                $display("FAIL [TC %s]: cache_req=%b we=%b addr=%h | exp req=%b we=%b addr=%h",
                    tc_name, cache_req, cache_we, cache_addr,
                    exp_cache_req, exp_cache_we, exp_cache_addr);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [TC %s]: cache_req=%b we=%b addr=%h", tc_name, cache_req, cache_we, cache_addr);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        if_req = 0; if_addr = 0;
        mem_req = 0; mem_we = 0; mem_addr = 0; mem_wdata = 0;
        cache_ready = 0; cache_rdata = 0;

        $display("=== memory_arbiter_tb START ===");

        // ---------------------------------------------------------------
        // TC1: Chỉ IF request → cache phục vụ IF (req=1, we=0, addr=if_addr)
        // ---------------------------------------------------------------
        if_req = 1; if_addr = 16'h0010;
        mem_req = 0;
        check_comb("TC1 IF only ", 1, 0, 16'h0010);

        // ---------------------------------------------------------------
        // TC2: Chỉ MEM read → cache phục vụ MEM
        // ---------------------------------------------------------------
        if_req = 0;
        mem_req = 1; mem_we = 0; mem_addr = 16'h0020; mem_wdata = 0;
        check_comb("TC2 MEM read", 1, 0, 16'h0020);

        // ---------------------------------------------------------------
        // TC3: Chỉ MEM write → cache phục vụ MEM (we=1)
        // ---------------------------------------------------------------
        if_req = 0;
        mem_req = 1; mem_we = 1; mem_addr = 16'h0030; mem_wdata = 16'hABCD;
        check_comb("TC3 MEM writ", 1, 1, 16'h0030);

        // ---------------------------------------------------------------
        // TC4: IF + MEM đồng thời → MEM PHẢI thắng
        // ---------------------------------------------------------------
        if_req = 1; if_addr = 16'h0010;
        mem_req = 1; mem_we = 0; mem_addr = 16'h0050;
        check_comb("TC4 conflict", 1, 0, 16'h0050); // addr phải là MEM addr
        // Kiểm tra thêm: if_ready PHẢI = 0 khi MEM đang dùng bus
        #1;
        if (if_ready !== 0) begin
            $display("FAIL TC4b: if_ready=%b khi MEM chiếm bus (exp=0)", if_ready);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS TC4b: if_ready=0 khi MEM chiếm bus");
            pass_count = pass_count + 1;
        end

        // ---------------------------------------------------------------
        // TC5: Không có request nào → cache_req = 0
        // ---------------------------------------------------------------
        if_req = 0; mem_req = 0;
        check_comb("TC5 idle    ", 0, 0, 16'h0000);

        // ---------------------------------------------------------------
        // TC6: ready từ cache phải forward đúng port
        // ---------------------------------------------------------------
        cache_ready = 1; cache_rdata = 16'hFACE;

        // Khi MEM active: mem_ready phải = 1, if_ready phải = 0
        if_req = 0; mem_req = 1; mem_we = 0; mem_addr = 16'h0001;
        #1;
        if (mem_ready !== 1 || if_ready !== 0) begin
            $display("FAIL TC6a (MEM gets ready): mem_ready=%b if_ready=%b", mem_ready, if_ready);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS TC6a: mem_ready=1 if_ready=0 (MEM active)");
            pass_count = pass_count + 1;
        end
        if (mem_rdata !== 16'hFACE) begin
            $display("FAIL TC6b (MEM rdata): got=%h exp=FACE", mem_rdata);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS TC6b: mem_rdata=FACE");
            pass_count = pass_count + 1;
        end

        // Khi IF active: if_ready phải = 1, mem_ready phải = 0
        if_req = 1; if_addr = 16'h0002; mem_req = 0;
        #1;
        if (if_ready !== 1 || mem_ready !== 0) begin
            $display("FAIL TC6c (IF gets ready): if_ready=%b mem_ready=%b", if_ready, mem_ready);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS TC6c: if_ready=1 mem_ready=0 (IF active)");
            pass_count = pass_count + 1;
        end
        if (if_instr !== 16'hFACE) begin
            $display("FAIL TC6d (IF instr): got=%h exp=FACE", if_instr);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS TC6d: if_instr=FACE");
            pass_count = pass_count + 1;
        end

        $display("=== memory_arbiter_tb DONE: PASS=%0d  FAIL=%0d ===", pass_count, fail_count);
        if (fail_count > 0) $fatal(1);
        else $display("memory_arbiter_tb: ALL PASS");
        $finish;
    end

endmodule
