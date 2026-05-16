`timescale 1ns / 1ps // Định nghĩa đơn vị thời gian mô phỏng là 1ns, độ chính xác (bước nhảy) là 1ps

`include "cpu_defines.vh" // Nhúng thư viện hằng số chung của toàn hệ thống (để lấy DATA_WIDTH)

module immediate_generator_tb;

    // =========================================================================
    // 1. KHAI BÁO BIẾN CHO TESTBENCH
    // =========================================================================
    
    // Trong testbench, các tín hiệu ĐẦU VÀO của module cần test (UUT) phải được
    // khai báo là kiểu 'reg' vì chúng ta cần chủ động gán giá trị (drive) cho chúng
    // trong khối 'initial'.
    reg [5:0] imm6;       // Hằng số 6-bit trích xuất từ lệnh (Instruction[5:0])
    reg       sign_ext;   // Cờ điều khiển: 1 = Sign-Extend (Có dấu), 0 = Zero-Extend (Không dấu)

    // Các tín hiệu ĐẦU RA từ UUT sẽ được khai báo là kiểu 'wire' vì chúng 
    // liên tục nhận tín hiệu được truyền trực tiếp từ module UUT ra ngoài.
    wire [`DATA_WIDTH-1:0] imm16; // Hằng số 16-bit sau khi đã được kéo giãn

    // =========================================================================
    // 2. KHỞI TẠO MODULE CẦN KIỂM THỬ (Unit Under Test - UUT)
    // =========================================================================
    immediate_generator uut (
        .imm6(imm6),         // Nối biến imm6 của testbench vào cổng imm6 của module
        .sign_ext(sign_ext), // Nối cờ sign_ext vào module
        .imm16(imm16)        // Lấy đầu ra từ cổng imm16 đưa vào biến dây dẫn imm16
    );

    // =========================================================================
    // 3. BIẾN THEO DÕI VÀ CÔNG CỤ TỰ ĐỘNG KIỂM TRA (TASK)
    // =========================================================================
    integer pass_count = 0; // Bộ đếm số lượng test case đúng
    integer fail_count = 0; // Bộ đếm số lượng test case sai

    // Task là một khối lệnh có thể tái sử dụng (giống hàm trong phần mềm).
    // Dùng task để gom chung logic in kết quả, giúp code phần test gọn gàng hơn.
    task check_result;
        input [`DATA_WIDTH-1:0] expected; // Tham số 1: Giá trị kỳ vọng đúng
        input [127:0] test_name;          // Tham số 2: Tên của bài test để dễ theo dõi
        begin
            // So sánh nghiêm ngặt (===) giá trị phần cứng tính toán được (imm16) 
            // với giá trị mà mình tính toán trước (expected).
            if (imm16 === expected) begin
                $display("[PASS] %s: imm6=6'b%b, sign_ext=%b -> imm16=16'h%04h", test_name, imm6, sign_ext, imm16);
                pass_count = pass_count + 1;
            end else begin
                // Nếu sai thì in ra giá trị thực tế (Got) và giá trị đáng nhẽ phải có (Expected)
                $display("[FAIL] %s: imm6=6'b%b, sign_ext=%b -> Got: 16'h%04h, Expected: 16'h%04h", test_name, imm6, sign_ext, imm16, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // =========================================================================
    // 4. KỊCH BẢN KIỂM THỬ (TEST SCENARIOS)
    // =========================================================================
    initial begin
        $display("=== BAT DAU TEST: IMMEDIATE GENERATOR ===");

        // ---------------------------------------------------------------------
        // KIỂM TRA TÍNH NĂNG ZERO-EXTENSION (MỞ RỘNG KHÔNG DẤU)
        // Ứng dụng thực tế: Thường dùng cho các phép toán Logic (ANDI, ORI) 
        // hoặc các lệnh cần nhét bù thêm toàn số 0 ở phía trước.
        // ---------------------------------------------------------------------
        sign_ext = 1'b0;

        // [Test 1] Nhập vào một số có MSB (bit dấu của 6 bit) là 0.
        imm6 = 6'b01_0101; // Giá trị: 21 (Decimal)
        #10;               // Đợi 10 nanosecond để tín hiệu điện truyền qua mạch logic
        check_result(16'h0015, "Zero Ext - So duong"); // Kỳ vọng: 0000 0000 0001 0101 (Hex: 0015)

        // [Test 2] Nhập vào một số có MSB là 1. Mặc dù MSB là 1, nhưng vì là chế độ 
        // Zero-Extend nên 10 bit bù vào vẫn PHẢI là số 0.
        imm6 = 6'b11_1111; // 63 (Unsigned)
        #10;
        check_result(16'h003F, "Zero Ext - MSB la 1"); // Kỳ vọng: 0000 0000 0011 1111 (Hex: 003F)


        // ---------------------------------------------------------------------
        // KIỂM TRA TÍNH NĂNG SIGN-EXTENSION (MỞ RỘNG CÓ DẤU)
        // Ứng dụng thực tế: Lệnh ADDI (cộng số âm/dương), LW/SW (tính offset địa chỉ)
        // ---------------------------------------------------------------------
        sign_ext = 1'b1;

        // [Test 3] Số dương: MSB = 0.
        // Quy tắc bù dấu: Vì MSB = 0, nó sẽ tự động chèn 10 số 0 vào phía trước.
        imm6 = 6'b01_1010; // +26 (Decimal)
        #10;
        check_result(16'h001A, "Sign Ext - So duong"); // Kỳ vọng: 0000 0000 0001 1010 (Hex: 001A)

        // [Test 4] Số âm thông thường (Bù 2): MSB = 1.
        // Quy tắc bù dấu: Vì MSB = 1, mạch điện phải copy số 1 này thành 10 bit phía trước 
        // để bảo toàn đúng giá trị âm trong hệ bù 2 (Two's Complement).
        imm6 = 6'b11_1111; // -1 (Decimal)
        #10;
        check_result(16'hFFFF, "Sign Ext - So -1"); // Kỳ vọng: 1111 1111 1111 1111 (Hex: FFFF)

        // [Test 5] Số âm nhỏ nhất có thể biểu diễn bằng 6-bit (Edge case)
        imm6 = 6'b10_0000; // -32 (Decimal)
        #10;
        check_result(16'hFFE0, "Sign Ext - So -32"); // Kỳ vọng: 1111 1111 1110 0000 (Hex: FFE0)

        // =========================================================================
        // 5. IN RA TỔNG KẾT VÀ KẾT THÚC MÔ PHỎNG
        // =========================================================================
        $display("========================================");
        if (fail_count == 0)
            $display("-> TAT CA %0d TEST DEU PASS!", pass_count);
        else
            $display("-> PHAT HIEN %0d LỖI TRÊN TỔNG %0d TEST!", fail_count, pass_count + fail_count);
        
        // $finish là lệnh đặc biệt của trình mô phỏng (như ModelSim/Icarus) 
        // để báo rằng đã chạy xong và có thể tắt chương trình.
        $finish;
    end

endmodule
