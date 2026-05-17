`timescale 1ns/1ps
`include "cpu_defines.vh"

module control_unit (
    input  wire [3:0] opcode,
    input  wire [2:0] funct,
    output reg        reg_dst,
    output reg        alu_src,
    output reg        mem_to_reg,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        branch,
    output reg        branch_ne,
    output reg        jump,
    output reg [3:0]  alu_op,
    output reg        halt
);

    always @(*) begin
        // ====================================================================
        // 1. THIẾT LẬP TRẠNG THÁI MẶC ĐỊNH (CHỐNG LATCH)
        // Tất cả các cờ đều tắt (0). Chỉ bật lên khi đúng lệnh yêu cầu.
        // ====================================================================
        reg_dst    = 0;
        alu_src    = 0;
        mem_to_reg = 0;
        reg_write  = 0;
        mem_read   = 0;
        mem_write  = 0;
        branch     = 0;
        branch_ne  = 0;
        jump       = 0;
        halt       = 0;
        alu_op     = `ALU_ADD; // Mặc định là phép cộng

        // ====================================================================
        // 2. MẠCH ĐỊNH TUYẾN LOGIC (DECODING TREE)
        // ====================================================================
        case (opcode)
            4'h0: begin // Các lệnh R-Type
                reg_dst   = 1; // Ghi vào thanh ghi rd
                reg_write = 1; // Cho phép ghi
                // Giải mã ALU op dựa trên funct
                case (funct)
                    3'h0: alu_op = `ALU_ADD;
                    3'h1: alu_op = `ALU_SUB;
                    3'h2: alu_op = `ALU_AND;
                    3'h3: alu_op = `ALU_OR;
                    3'h4: alu_op = `ALU_XOR;  // XOR (bị sai trong phiên bản cũ)
                    3'h5: alu_op = `ALU_SLT;
                    3'h6: alu_op = `ALU_SLL;
                    3'h7: alu_op = `ALU_SRL;
                    default: alu_op = `ALU_ADD;
                endcase
            end

            4'h1: begin // Lệnh ADDI (I-Type)
                alu_src   = 1; // Chọn hằng số imm16 làm toán hạng B
                reg_write = 1; // Cho phép ghi vào rt
                alu_op    = `ALU_ADD; 
            end

            4'h2: begin // Lệnh LW (I-Type)
                alu_src    = 1; // Chọn imm16 để cộng địa chỉ nền
                mem_to_reg = 1; // Lấy dữ liệu từ Memory thay vì ALU
                reg_write  = 1; // Cho phép ghi vào rt
                mem_read   = 1; // Đẩy cờ đọc xuống Cache
                alu_op     = `ALU_ADD; // Tính địa chỉ
            end

            4'h3: begin // Lệnh SW (I-Type)
                alu_src   = 1; // Chọn imm16
                mem_write = 1; // Đẩy cờ ghi xuống Cache
                alu_op    = `ALU_ADD; // Tính địa chỉ
            end

            4'h4: begin // Lệnh BEQ (I-Type)
                branch = 1; // Cờ báo rẽ nhánh bằng
                alu_op = `ALU_SUB; // Ép ALU trừ 2 toán hạng để xét cờ zero
            end

            4'h5: begin // Lệnh BNE (I-Type)
                branch_ne = 1; // Cờ báo rẽ nhánh khác
                alu_op    = `ALU_SUB; // Ép ALU trừ để xét cờ zero
            end

            4'h6: begin // Lệnh J (J-Type)
                jump = 1; // Cờ nhảy tuyệt đối
            end

            4'hF: begin // Lệnh HALT (J-Type đặc biệt)
                halt = 1; // Phát cờ khai tử Pipeline
            end

            default: begin
                // Nếu dính mã rác, giữ nguyên mọi thứ ở mức 0 (NOP an toàn)
            end
        endcase
    end

endmodule