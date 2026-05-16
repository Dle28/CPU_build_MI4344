// ============================================================================
// FILE: tb/register_file_tb.v
// CHỨC NĂNG: Testbench đầy đủ cho module register_file (8x16-bit)
//
// CÁC TEST CASE:
//   TC1 : Reset đồng bộ - tất cả thanh ghi phải về 0 sau reset
//   TC2 : Ghi/Đọc cơ bản - ghi và đọc lại R1..R7
//   TC3 : R0 hard-wired zero - thử ghi R0, phải bị bỏ qua
//   TC4 : Đọc hai cổng đồng thời (dual-port read)
//   TC5 : reg_write = 0 - dữ liệu không được ghi khi không có phép
//   TC6 : Ghi nhiều lần - ghi đè giá trị cũ của cùng một thanh ghi
//   TC7 : Kiểm tra từng thanh ghi R1..R7 với giá trị độc lập
//   TC8 : rs_addr = rt_addr = rd_addr (cùng địa chỉ, ghi & đọc hai cổng)
//   TC9 : Giá trị biên - 0x0000 và 0xFFFF
//   TC10: Reset giữa chừng xoá hết giá trị đã ghi
// ============================================================================

`timescale 1ns/1ps
`include "cpu_defines.vh"

module register_file_tb;

    // -------------------------------------------------------------------------
    // 0. KHAI BÁO TÍN HIỆU
    // -------------------------------------------------------------------------
    reg                         clk;
    reg                         rst;
    reg  [`REG_ADDR_WIDTH-1:0]  rs_addr;
    reg  [`REG_ADDR_WIDTH-1:0]  rt_addr;
    reg  [`REG_ADDR_WIDTH-1:0]  rd_addr;
    reg  [`DATA_WIDTH-1:0]      rd_wdata;
    reg                         reg_write;
    wire [`DATA_WIDTH-1:0]      rs_data;
    wire [`DATA_WIDTH-1:0]      rt_data;

    // Bộ đếm kết quả
    integer pass_cnt;
    integer fail_cnt;
    integer test_num;

    // -------------------------------------------------------------------------
    // 1. KHỞI TẠO DUT
    // -------------------------------------------------------------------------
    register_file u_dut (
        .clk      (clk),
        .rst      (rst),
        .rs_addr  (rs_addr),
        .rt_addr  (rt_addr),
        .rd_addr  (rd_addr),
        .rd_wdata (rd_wdata),
        .reg_write(reg_write),
        .rs_data  (rs_data),
        .rt_data  (rt_data)
    );

    // -------------------------------------------------------------------------
    // 2. TẠO XUNG NHỊP  (chu kỳ 10 ns, f = 100 MHz)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // 3. TÁC VỤ TIỆN ÍCH
    // -------------------------------------------------------------------------

    // Ghi một giá trị vào thanh ghi rd và chờ posedge tiếp theo
    task write_reg;
        input [2:0]  addr;
        input [15:0] data;
        begin
            rd_addr   = addr;
            rd_wdata  = data;
            reg_write = 1'b1;
            @(posedge clk); #1;
            reg_write = 1'b0;
        end
    endtask

    // Kiểm tra rs_data sau khi đặt rs_addr
    task check_rs;
        input [2:0]  addr;
        input [15:0] expected;
        input [63:0] tc_id;   // số test để in ra khi fail
        begin
            rs_addr = addr;
            #1;
            if (rs_data === expected) begin
                $display("  [PASS] TC%0d  rs[R%0d] = 0x%04X  (ok)", tc_id, addr, rs_data);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] TC%0d  rs[R%0d] = 0x%04X, expected 0x%04X",
                          tc_id, addr, rs_data, expected);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // Kiểm tra rt_data sau khi đặt rt_addr
    task check_rt;
        input [2:0]  addr;
        input [15:0] expected;
        input [63:0] tc_id;
        begin
            rt_addr = addr;
            #1;
            if (rt_data === expected) begin
                $display("  [PASS] TC%0d  rt[R%0d] = 0x%04X  (ok)", tc_id, addr, rt_data);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] TC%0d  rt[R%0d] = 0x%04X, expected 0x%04X",
                          tc_id, addr, rt_data, expected);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // 4. LUỒNG KIỂM TRA CHÍNH
    // -------------------------------------------------------------------------
    initial begin
        // Khởi tạo
        pass_cnt  = 0;
        fail_cnt  = 0;
        rs_addr   = 3'd0;
        rt_addr   = 3'd0;
        rd_addr   = 3'd0;
        rd_wdata  = 16'h0000;
        reg_write = 1'b0;
        rst       = 1'b1;

        // Tạo waveform (nếu trình mô phỏng hỗ trợ)
        $dumpfile("register_file_tb.vcd");
        $dumpvars(0, register_file_tb);

        $display("=============================================================");
        $display(" register_file_tb : BẮT ĐẦU");
        $display("=============================================================");

        // -----------------------------------------------------------------
        // TC1: RESET - Giữ rst = 1 qua 3 posedge, kiểm tra R0..R7 đều = 0
        // -----------------------------------------------------------------
        $display("\n--- TC1: Reset đồng bộ ---");
        repeat (3) @(posedge clk); #1;
        rst = 1'b0;

        begin : tc1_check
            integer r;
            for (r = 0; r < 8; r = r + 1) begin
                rs_addr = r[2:0];
                #1;
                if (rs_data === 16'h0000) begin
                    $display("  [PASS] TC1  R%0d = 0x0000 sau reset  (ok)", r);
                    pass_cnt = pass_cnt + 1;
                end else begin
                    $display("  [FAIL] TC1  R%0d = 0x%04X sau reset, expected 0x0000", r, rs_data);
                    fail_cnt = fail_cnt + 1;
                end
            end
        end

        // -----------------------------------------------------------------
        // TC2: Ghi/Đọc cơ bản  R1 = 0x00AA
        // -----------------------------------------------------------------
        $display("\n--- TC2: Ghi/Đọc cơ bản ---");
        write_reg(3'd1, 16'h00AA);
        check_rs(3'd1, 16'h00AA, 2);

        // -----------------------------------------------------------------
        // TC3: R0 hard-wired zero
        // -----------------------------------------------------------------
        $display("\n--- TC3: R0 hard-wired zero ---");
        write_reg(3'd0, 16'hFFFF);      // Cố tình ghi vào R0
        check_rs(3'd0, 16'h0000, 3);   // Phải vẫn là 0
        check_rt(3'd0, 16'h0000, 3);

        // -----------------------------------------------------------------
        // TC4: Đọc hai cổng đồng thời
        // -----------------------------------------------------------------
        $display("\n--- TC4: Đọc hai cổng (dual-port) ---");
        write_reg(3'd7, 16'hBEEF);
        rs_addr = 3'd7;  rt_addr = 3'd1;  #1;
        if (rs_data === 16'hBEEF && rt_data === 16'h00AA) begin
            $display("  [PASS] TC4  rs[R7]=0x%04X  rt[R1]=0x%04X  (ok)", rs_data, rt_data);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] TC4  rs[R7]=0x%04X (exp BEEF)  rt[R1]=0x%04X (exp 00AA)",
                      rs_data, rt_data);
            fail_cnt = fail_cnt + 1;
        end

        // -----------------------------------------------------------------
        // TC5: reg_write = 0, dữ liệu không được ghi
        // -----------------------------------------------------------------
        $display("\n--- TC5: reg_write = 0 ---");
        rd_addr   = 3'd2;
        rd_wdata  = 16'h1234;
        reg_write = 1'b0;
        @(posedge clk); #1;
        check_rs(3'd2, 16'h0000, 5);   // Phải còn là 0 (chưa ghi bao giờ)

        // -----------------------------------------------------------------
        // TC6: Ghi đè nhiều lần cùng thanh ghi
        // -----------------------------------------------------------------
        $display("\n--- TC6: Ghi đè nhiều lần R3 ---");
        write_reg(3'd3, 16'hAAAA);
        write_reg(3'd3, 16'h5555);
        write_reg(3'd3, 16'hDEAD);
        check_rs(3'd3, 16'hDEAD, 6);

        // -----------------------------------------------------------------
        // TC7: Ghi độc lập R1..R7 với giá trị duy nhất
        // -----------------------------------------------------------------
        $display("\n--- TC7: Ghi tất cả R1..R7 ---");
        begin : tc7_write
            integer r;
            reg [15:0] val;
            for (r = 1; r < 8; r = r + 1) begin
                val = r[15:0] * 16'h0111;  // Giá trị khác nhau: 0111, 0222, ...
                write_reg(r[2:0], val);
            end
        end
        // Đọc lại toàn bộ
        begin : tc7_read
            integer r;
            reg [15:0] expected;
            for (r = 1; r < 8; r = r + 1) begin
                expected = r[15:0] * 16'h0111;
                rs_addr  = r[2:0];
                #1;
                if (rs_data === expected) begin
                    $display("  [PASS] TC7  R%0d = 0x%04X  (ok)", r, rs_data);
                    pass_cnt = pass_cnt + 1;
                end else begin
                    $display("  [FAIL] TC7  R%0d = 0x%04X, expected 0x%04X", r, rs_data, expected);
                    fail_cnt = fail_cnt + 1;
                end
            end
        end

        // -----------------------------------------------------------------
        // TC8: rs_addr = rt_addr = rd_addr (cùng thanh ghi, hai cổng đọc)
        // -----------------------------------------------------------------
        $display("\n--- TC8: rs / rt cùng địa chỉ với rd ---");
        write_reg(3'd4, 16'hCAFE);
        rs_addr = 3'd4;  rt_addr = 3'd4;  #1;
        if (rs_data === 16'hCAFE && rt_data === 16'hCAFE) begin
            $display("  [PASS] TC8  rs=rt=0x%04X  (ok)", rs_data);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] TC8  rs=0x%04X rt=0x%04X, expected 0xCAFE both", rs_data, rt_data);
            fail_cnt = fail_cnt + 1;
        end

        // -----------------------------------------------------------------
        // TC9: Giá trị biên 0x0000 và 0xFFFF
        // -----------------------------------------------------------------
        $display("\n--- TC9: Giá trị biên ---");
        write_reg(3'd5, 16'h0000);
        check_rs(3'd5, 16'h0000, 9);
        write_reg(3'd5, 16'hFFFF);
        check_rs(3'd5, 16'hFFFF, 9);

        // -----------------------------------------------------------------
        // TC10: Reset giữa chừng xoá hết giá trị đã ghi
        // -----------------------------------------------------------------
        $display("\n--- TC10: Reset giữa chừng ---");
        // Ghi vài thanh ghi trước
        write_reg(3'd6, 16'hABCD);
        write_reg(3'd5, 16'h1234);
        // Kéo rst lên
        rst = 1'b1;
        repeat (2) @(posedge clk); #1;
        rst = 1'b0;
        // Kiểm tra mọi thanh ghi phải về 0
        begin : tc10_check
            integer r;
            for (r = 0; r < 8; r = r + 1) begin
                rs_addr = r[2:0];
                #1;
                if (rs_data === 16'h0000) begin
                    $display("  [PASS] TC10  R%0d = 0x0000 sau reset  (ok)", r);
                    pass_cnt = pass_cnt + 1;
                end else begin
                    $display("  [FAIL] TC10  R%0d = 0x%04X sau reset, expected 0x0000", r, rs_data);
                    fail_cnt = fail_cnt + 1;
                end
            end
        end

        // -----------------------------------------------------------------
        // KẾT QUẢ TỔNG KẾT
        // -----------------------------------------------------------------
        $display("\n=============================================================");
        $display(" KẾT QUẢ: %0d PASS | %0d FAIL", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display(" >>> TỔNG KẾT: TẤT CẢ TEST ĐỀU PASS ✓");
        else
            $display(" >>> TỔNG KẾT: CÓ %0d TEST BỊ FAIL ✗", fail_cnt);
        $display("=============================================================");

        $finish;
    end

endmodule
