// ============================================================================
// FILE   : tb/alu_tb.v
// MODULE : alu_tb
// AUTHOR : Le Hoang Dung  (Thanh vien 4 - Verification & Tooling)
// DATE   : 2026-05-13
//
// MUC DICH:
//   Testbench doc lap cho module alu.v.
//   Kiem tra toan bo 8 phep tinh va 4 co trang thai (zero, negative, overflow).
//   Chien luoc kiem tra:
//     1. Directed tests : cac gia tri bien, truong hop dac biet (overflow, zero flag)
//     2. Overflow directed : kiem tra sat vung so nguyen co dau 16-bit
//     3. Randomized sanity: 200 vector ngau nhien ket hop voi mo hinh phan mem
//
// KET QUA MONG DOI:
//   - In "alu_tb: PASS" neu toan bo test pass.
//   - In thong bao FAIL + goi $fatal(1) ngay khi co loi.
//   - Ghi waveform ra build/alu_tb.vcd de xem tren GTKWave.
//
// CACH CHAY (Icarus Verilog):
//   Buoc 1: Tao thu muc build neu chua co
//             mkdir build
//   Buoc 2: Compile
//             iverilog -g2012 -I include/ -o build/alu_tb.vvp rtl/cpu/alu.v tb/alu_tb.v
//   Buoc 3: Chay simulation
//             vvp build/alu_tb.vvp
//   Buoc 4: (Tuy chon) Xem waveform
//             gtkwave build/alu_tb.vcd
//
// tick: da xong
// ============================================================================

`timescale 1ns/1ps

// Nap dinh nghia ALU_ADD, ALU_SUB, ... truoc khi khai bao module
// de cac hang so co the su dung trong function/task/initial ben duoi.
// LUU Y: Phai dat TRUOC 'module' de tranh loi phan giai ten khi dung
//        `include ben trong module tren mot so trinh bien dich.
`include "cpu_defines.vh"

module alu_tb;

    // ========================================================================
    // 1. KHAI BAO TIN HIEU KET NOI VOI DUT (Device Under Test = alu.v)
    // ========================================================================
    reg  [15:0] a;        // Toan hang A (port vao cua ALU)
    reg  [15:0] b;        // Toan hang B (port vao cua ALU)
    reg  [3:0]  alu_op;   // Ma phep tinh (tu cpu_defines.vh)

    wire [15:0] result;   // Ket qua tinh toan (ra)
    wire        zero;     // Co bang 0: result == 16'h0000
    wire        negative; // Co am: result[15] == 1
    wire        overflow; // Co tran so: chi co y nghia voi ADD/SUB signed

    // ========================================================================
    // 2. KHOI TAO DUT
    // ========================================================================
    alu u_alu (
        .a       (a),
        .b       (b),
        .alu_op  (alu_op),
        .result  (result),
        .zero    (zero),
        .negative(negative),
        .overflow(overflow)
    );

    // ========================================================================
    // 3. MO HINH PHAN MEM (Software Reference Model)
    //    Dung de tinh ket qua MONG DOI doc lap voi RTL,
    //    sau do so sanh voi ket qua thuc te tu u_alu.
    // ========================================================================

    // Ham tinh ket qua 16-bit mong doi theo phep tinh op_in
    function [15:0] model_result;
        input [15:0] a_in;
        input [15:0] b_in;
        input [3:0]  op_in;
        begin
            case (op_in)
                `ALU_ADD: model_result = a_in + b_in;                               // Phep cong
                `ALU_SUB: model_result = a_in - b_in;                               // Phep tru
                `ALU_AND: model_result = a_in & b_in;                               // AND bitwise
                `ALU_OR:  model_result = a_in | b_in;                               // OR bitwise
                `ALU_XOR: model_result = a_in ^ b_in;                               // XOR bitwise
                `ALU_SLT: model_result = ($signed(a_in) < $signed(b_in)) ? 16'h0001 : 16'h0000; // Set Less Than (co dau)
                `ALU_SLL: model_result = a_in << b_in[3:0];                         // Shift Left Logical (chi dung 4 bit thap cua b)
                `ALU_SRL: model_result = a_in >> b_in[3:0];                         // Shift Right Logical
                default:  model_result = 16'h0000;                                  // Op khong xac dinh -> 0 (khop voi RTL)
            endcase
        end
    endfunction

    // Ham tinh co tran so (overflow) mong doi - chi co y nghia cho ADD/SUB signed
    //   ADD overflow: hai so cung dau nhung ket qua lai khac dau
    //   SUB overflow: tru so am cho so duong ma ra am, hoac nguoc lai
    function model_overflow;
        input [15:0] a_in;
        input [15:0] b_in;
        input [15:0] r_in;  // Ket qua da tinh (truyen vao de giam truong hop tinh lai)
        input [3:0]  op_in;
        begin
            case (op_in)
                `ALU_ADD: model_overflow = (~a_in[15] & ~b_in[15] & r_in[15])   // (+)+(+)=(-)
                                         | ( a_in[15] &  b_in[15] & ~r_in[15]); // (-)+(-)=(+)
                `ALU_SUB: model_overflow = (~a_in[15] &  b_in[15] & r_in[15])   // (+)-(-)=(-)
                                         | ( a_in[15] & ~b_in[15] & ~r_in[15]); // (-)-(+)=(+)
                default:  model_overflow = 1'b0; // Cac phep con lai khong co overflow
            endcase
        end
    endfunction

    // ========================================================================
    // 4. TASK KIEM TRA MOT VECTOR (check_vec)
    //    Nhan vao: a_in, b_in, op_in
    //    Quy trinh:
    //      1. Tinh ket qua mong doi tu model phan mem
    //      2. Ap vao DUT va cho 1ns on dinh
    //      3. So sanh ca 4 ngo ra: result, zero, negative, overflow
    //      4. Neu sai -> in thong bao FAIL va goi $fatal de dung ngay
    // ========================================================================
    // Bo dem so vector da pass (de in tong ket)
    integer pass_count;

    task check_vec;
        input [15:0] a_in;
        input [15:0] b_in;
        input [3:0]  op_in;

        // Bien cuc bo chua ket qua mong doi
        reg [15:0] exp;
        reg        exp_zero;
        reg        exp_negative;
        reg        exp_overflow;
        begin
            // --- Tinh ket qua mong doi bang model phan mem ---
            exp          = model_result(a_in, b_in, op_in);
            exp_zero     = (exp == 16'h0000);
            exp_negative = exp[15];
            exp_overflow = model_overflow(a_in, b_in, exp, op_in);

            // --- Ap tin hieu vao DUT, cho 1ns on dinh (mach to hop) ---
            a      = a_in;
            b      = b_in;
            alu_op = op_in;
            #1;

            // --- So sanh result ---
            if (result !== exp) begin
                $display("[FAIL] result | op=%0d a=%h b=%h => got=%h exp=%h",
                         op_in, a_in, b_in, result, exp);
                $fatal(1);
            end

            // --- So sanh co zero ---
            if (zero !== exp_zero) begin
                $display("[FAIL] zero   | op=%0d a=%h b=%h => got=%b exp=%b (result=%h)",
                         op_in, a_in, b_in, zero, exp_zero, result);
                $fatal(1);
            end

            // --- So sanh co negative ---
            if (negative !== exp_negative) begin
                $display("[FAIL] neg    | op=%0d a=%h b=%h => got=%b exp=%b (result=%h)",
                         op_in, a_in, b_in, negative, exp_negative, result);
                $fatal(1);
            end

            // --- So sanh co overflow ---
            if (overflow !== exp_overflow) begin
                $display("[FAIL] ovfl   | op=%0d a=%h b=%h => got=%b exp=%b (result=%h)",
                         op_in, a_in, b_in, overflow, exp_overflow, result);
                $fatal(1);
            end

            // Vector nay da pass
            pass_count = pass_count + 1;
        end
    endtask

    // ========================================================================
    // 5. CHUOI KIEM TRA CHINH
    // ========================================================================
    integer i; // Bien vong lap cho phan random

    initial begin
        // --- Khoi tao waveform dump (de xem tren GTKWave) ---
        $dumpfile("build/alu_tb.vcd");
        $dumpvars(0, alu_tb); // Dump toan bo tin hieu trong module nay

        pass_count = 0;
        $display("============================================================");
        $display("  alu_tb : BAT DAU KIEM TRA");
        $display("============================================================");

        // ----------------------------------------------------------------
        // NHOM A: Directed Tests - Phep tinh co ban
        // Muc dich: Xac nhan moi phep tinh cho ket qua dung,
        //           va co zero duoc set dung khi ket qua = 0.
        // ----------------------------------------------------------------
        $display("[GROUP A] Directed - Phep tinh co ban");

        // ADD: 5 + 3 = 8, zero=0, negative=0, overflow=0
        check_vec(16'h0005, 16'h0003, `ALU_ADD);

        // SUB: 5 - 3 = 2, zero=0, negative=0, overflow=0
        check_vec(16'h0005, 16'h0003, `ALU_SUB);

        // AND: 1010...1010 & 0101...0101 = 0 -> zero=1
        check_vec(16'hAAAA, 16'h5555, `ALU_AND);

        // OR: 0000_1111_0000_1111 | 0000_0000_1111_0000 = 0000_1111_1111_1111
        check_vec(16'h0F0F, 16'h00F0, `ALU_OR);

        // XOR: F0F0 ^ F0F0 = 0000 -> zero=1
        check_vec(16'hF0F0, 16'hF0F0, `ALU_XOR);

        // ----------------------------------------------------------------
        // NHOM B: Directed Tests - SLT (Set Less Than, so sanh co dau)
        // ----------------------------------------------------------------
        $display("[GROUP B] Directed - SLT (so sanh co dau)");

        // -1 < 1 (true) -> result = 1
        check_vec(16'hFFFF, 16'h0001, `ALU_SLT);

        // 1 < -1 (false) -> result = 0, zero=1
        check_vec(16'h0001, 16'hFFFF, `ALU_SLT);

        // 0 < 0 (false) -> result = 0, zero=1
        check_vec(16'h0000, 16'h0000, `ALU_SLT);

        // ----------------------------------------------------------------
        // NHOM C: Directed Tests - SLL / SRL (shift logic)
        // Luu y: Chi lay 4 bit thap cua b lam so lan dich (b[3:0])
        // ----------------------------------------------------------------
        $display("[GROUP C] Directed - SLL / SRL");

        // SLL: 0001 << 4 = 0010
        check_vec(16'h0001, 16'h0004, `ALU_SLL);

        // SRL: 8000 >> 1 = 4000 (dich phai logic, bit MSB them 0)
        check_vec(16'h8000, 16'h0001, `ALU_SRL);

        // SRL: dich 0 buoc -> giu nguyen
        check_vec(16'h1234, 16'h0000, `ALU_SRL);

        // SLL: b = 0x0014 = 20 dec, nhung b[3:0] = 4 -> dich 4 buoc
        //      0001 << 4 = 0010  (kiem tra chi dung 4 bit thap)
        check_vec(16'h0001, 16'h0014, `ALU_SLL);

        // ----------------------------------------------------------------
        // NHOM D: Directed Tests - Overflow signed ADD / SUB
        // Muc dich: Kiem tra co overflow set dung tai bien sat vung
        // ----------------------------------------------------------------
        $display("[GROUP D] Directed - Overflow (bien sat vung 16-bit signed)");

        // ADD: 0x7FFF + 1 = 0x8000 -> overflow! duong + duong = am
        check_vec(16'h7FFF, 16'h0001, `ALU_ADD);

        // SUB: 0x8000 - 1 = 0x7FFF -> overflow! am - duong = duong
        check_vec(16'h8000, 16'h0001, `ALU_SUB);

        // ADD: (-1) + (-1) = -2 -> no overflow (van la am)
        check_vec(16'hFFFF, 16'hFFFF, `ALU_ADD);

        // SUB: 0 - 0 = 0 -> zero=1, no overflow
        check_vec(16'h0000, 16'h0000, `ALU_SUB);

        // ----------------------------------------------------------------
        // NHOM E: Randomized Sanity Check
        // Muc dich: 200 vector ngau nhien, so sanh toan bo voi model.
        //           op co the la 0-15; cac op khong xac dinh (8-15)
        //           thi ca model lan DUT deu tra ve 0 -> van khop.
        // ----------------------------------------------------------------

        $display("[GROUP E] Randomized - 100 vector ngau nhien");
        for (i = 0; i < 100; i = i + 1) begin
            check_vec($random, $random, $random);
        end


        // ----------------------------------------------------------------
        // TONG KET
        // ----------------------------------------------------------------
        $display("============================================================");
        $display("  alu_tb : PASS  (%0d vectors kiem tra thanh cong)", pass_count);
        $display("  Waveform : build/alu_tb.vcd");
        $display("============================================================");
        $finish;
    end

endmodule
