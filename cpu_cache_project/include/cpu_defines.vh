// ============================================================================
// FILE: cpu_defines.vh
// CHỨC NĂNG: Bộ siêu tham số và định nghĩa mã điều khiển toàn hệ thống
// LƯU Ý: Mọi module (.v) cần dùng hằng số phải gọi: `include "cpu_defines.vh"
// ============================================================================

// Header Guard: Ngăn chặn lỗi biên dịch do include file nhiều lần
`ifndef CPU_DEFINES_VH
`define CPU_DEFINES_VH

// ----------------------------------------------------------------------------
// 1. SIÊU THAM SỐ TOÀN CỤC (GLOBAL PARAMETERS)
// ----------------------------------------------------------------------------
`define DATA_WIDTH      16      // Độ rộng chuẩn của bus dữ liệu
`define REG_ADDR_WIDTH  3       // Độ rộng địa chỉ thanh ghi (8 thanh ghi)

// ----------------------------------------------------------------------------
// 2. MÃ ĐIỀU KHIỂN ALU (ALU CONTROL CODES - 4 BIT)
// Ánh xạ từ Bảng 2.2 của DATAPATH_INTERFACE.md
// ----------------------------------------------------------------------------
`define ALU_ADD         4'b0000 // Phép cộng (a + b)
`define ALU_SUB         4'b0001 // Phép trừ (a - b)
`define ALU_AND         4'b0010 // AND Bitwise (a & b)
`define ALU_OR          4'b0011 // OR Bitwise (a | b)
`define ALU_XOR         4'b0100 // XOR Bitwise (a ^ b)
`define ALU_SLT         4'b0101 // So sánh nhỏ hơn có dấu (Set on Less Than)
`define ALU_SLL         4'b0110 // Dịch trái logic (Shift Left Logical)
`define ALU_SRL         4'b0111 // Dịch phải logic (Shift Right Logical)

// ----------------------------------------------------------------------------
// 3. MÃ ĐIỀU KHIỂN BỘ MỞ RỘNG (IMMEDIATE GENERATOR - 1 BIT)
// Ánh xạ từ Mục 4.1 của DATAPATH_INTERFACE.md
// ----------------------------------------------------------------------------
`define EXT_ZERO        1'b0    // Mở rộng không dấu (Zero Extend) chèn 0
`define EXT_SIGN        1'b1    // Mở rộng có dấu (Sign Extend) giữ nguyên bit MSB

`endif // CPU_DEFINES_VH