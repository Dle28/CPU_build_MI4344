`include "cpu_defines.vh"

// ============================================================================
// 1. THANH GHI IF/ID (INSTRUCTION FETCH -> DECODE)
// FIX WARN#1: stall phải nằm TRÊN flush trong if-else chain.
// Lý do: Khi pipeline bị đóng băng (cache miss), dù EX vừa resolve branch,
// ta KHÔNG được xóa IF/ID vì PC chưa tiến - lệnh trong đó vẫn cần thiết.
// Chỉ khi hết stall, branch flush mới được phép diễn ra ở chu kỳ kế tiếp.
// ============================================================================
module pipeline_reg_if_id (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,
    input  wire        flush,

    input  wire [15:0] pc_in,
    input  wire [15:0] instr_in,

    output reg  [15:0] pc_out,
    output reg  [15:0] instr_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out    <= 16'h0000;
            instr_out <= 16'h0000;
        end else if (stall) begin
            // Ưu tiên 2: Đóng băng - giữ nguyên, không làm gì cả
            pc_out    <= pc_out;
            instr_out <= instr_out;
        end else if (flush) begin
            // Ưu tiên 3: Flush - chèn NOP (chỉ khi KHÔNG bị stall)
            pc_out    <= 16'h0000;
            instr_out <= 16'h0000;
        end else begin
            // Ưu tiên 4: Bình thường - trôi tiếp
            pc_out    <= pc_in;
            instr_out <= instr_in;
        end
    end
endmodule

// ============================================================================
// 2. THANH GHI ID/EX (DECODE -> EXECUTE)
// FIX WARN#1: Tách rst khỏi flush. Thứ tự đúng: rst > stall > flush > normal.
// Trường hợp nguy hiểm: cache_stall=1 VÀ branch_taken=1 đồng thời.
//   - Phiên bản cũ: rst||flush=1 -> flush thắng -> ID/EX bị xóa SAI.
//   - Phiên bản mới: stall thắng -> ID/EX giữ nguyên ĐÚNG.
//     (Branch flush sẽ diễn ra ở chu kỳ tiếp theo khi stall được giải phóng.)
// Trường hợp load-use hazard: stall(cache_stall)=0, flush(load_use)=1
//   -> stall=0 nên đi xuống flush -> flush thắng -> chèn bubble ĐÚNG.
// ============================================================================
module pipeline_reg_id_ex (
    input  wire        clk, rst, stall, flush,

    // Data in
    input  wire [15:0] pc_in, rs_data_in, rt_data_in, imm16_in,
    input  wire [2:0]  rs_in, rt_in, rd_in,

    // Control in
    input  wire [3:0]  alu_op_in,
    input  wire        reg_write_in, mem_read_in, mem_write_in, mem_to_reg_in,
    input  wire        alu_src_in, reg_dst_in,
    input  wire        branch_in, branch_ne_in, jump_in, halt_in,

    // Data out
    output reg  [15:0] pc_out, rs_data_out, rt_data_out, imm16_out,
    output reg  [2:0]  rs_out, rt_out, rd_out,

    // Control out
    output reg  [3:0]  alu_op_out,
    output reg         reg_write_out, mem_read_out, mem_write_out, mem_to_reg_out,
    output reg         alu_src_out, reg_dst_out,
    output reg         branch_out, branch_ne_out, jump_out, halt_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Ưu tiên 1: Reset toàn hệ thống
            pc_out <= 0; rs_data_out <= 0; rt_data_out <= 0; imm16_out <= 0;
            rs_out <= 0; rt_out <= 0; rd_out <= 0;
            alu_op_out    <= `ALU_ADD;
            reg_write_out <= 0; mem_read_out <= 0; mem_write_out <= 0; mem_to_reg_out <= 0;
            alu_src_out   <= 0; reg_dst_out  <= 0;
            branch_out    <= 0; branch_ne_out <= 0; jump_out <= 0; halt_out <= 0;
        end else if (stall) begin
            // Ưu tiên 2: Đóng băng - giữ nguyên mọi giá trị
        end else if (flush) begin
            // Ưu tiên 3: Chèn NOP/bubble - dập tắt toàn bộ cờ điều khiển
            pc_out <= 0; rs_data_out <= 0; rt_data_out <= 0; imm16_out <= 0;
            rs_out <= 0; rt_out <= 0; rd_out <= 0;
            alu_op_out    <= `ALU_ADD;
            reg_write_out <= 0; mem_read_out <= 0; mem_write_out <= 0; mem_to_reg_out <= 0;
            alu_src_out   <= 0; reg_dst_out  <= 0;
            branch_out    <= 0; branch_ne_out <= 0; jump_out <= 0; halt_out <= 0;
        end else begin
            // Ưu tiên 4: Bình thường - trôi tiếp
            pc_out <= pc_in; rs_data_out <= rs_data_in; rt_data_out <= rt_data_in; imm16_out <= imm16_in;
            rs_out <= rs_in; rt_out <= rt_in; rd_out <= rd_in;
            alu_op_out    <= alu_op_in;
            reg_write_out <= reg_write_in; mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in; mem_to_reg_out <= mem_to_reg_in;
            alu_src_out   <= alu_src_in; reg_dst_out <= reg_dst_in;
            branch_out    <= branch_in; branch_ne_out <= branch_ne_in;
            jump_out      <= jump_in;   halt_out      <= halt_in;
        end
    end
endmodule

// ============================================================================
// 3. THANH GHI EX/MEM (EXECUTE -> MEMORY)
// Không bị ảnh hưởng bởi WARN#1 vì cpu_core.v truyền flush=1'b0 cố định.
// Giữ nguyên cấu trúc, chỉ chuẩn hóa để nhất quán với các thanh ghi trên.
// ============================================================================
module pipeline_reg_ex_mem (
    input  wire        clk, rst, stall, flush,

    // Data in
    input  wire [15:0] alu_result_in, rt_data_in, branch_target_in,
    input  wire [2:0]  write_reg_in,
    input  wire        zero_in,

    // Control in
    input  wire        reg_write_in, mem_read_in, mem_write_in, mem_to_reg_in,
    input  wire        branch_in, branch_ne_in, jump_in, halt_in,

    // Data out
    output reg  [15:0] alu_result_out, rt_data_out, branch_target_out,
    output reg  [2:0]  write_reg_out,
    output reg         zero_out,

    // Control out
    output reg         reg_write_out, mem_read_out, mem_write_out, mem_to_reg_out,
    output reg         branch_out, branch_ne_out, jump_out, halt_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result_out <= 0; rt_data_out <= 0; branch_target_out <= 0;
            write_reg_out  <= 0; zero_out <= 0;
            reg_write_out  <= 0; mem_read_out <= 0; mem_write_out <= 0; mem_to_reg_out <= 0;
            branch_out     <= 0; branch_ne_out <= 0; jump_out <= 0; halt_out <= 0;
        end else if (stall) begin
            // Đóng băng - giữ nguyên
        end else if (flush) begin
            alu_result_out <= 0; rt_data_out <= 0; branch_target_out <= 0;
            write_reg_out  <= 0; zero_out <= 0;
            reg_write_out  <= 0; mem_read_out <= 0; mem_write_out <= 0; mem_to_reg_out <= 0;
            branch_out     <= 0; branch_ne_out <= 0; jump_out <= 0; halt_out <= 0;
        end else begin
            alu_result_out <= alu_result_in; rt_data_out <= rt_data_in;
            branch_target_out <= branch_target_in;
            write_reg_out  <= write_reg_in; zero_out <= zero_in;
            reg_write_out  <= reg_write_in; mem_read_out <= mem_read_in;
            mem_write_out  <= mem_write_in; mem_to_reg_out <= mem_to_reg_in;
            branch_out     <= branch_in; branch_ne_out <= branch_ne_in;
            jump_out       <= jump_in;   halt_out       <= halt_in;
        end
    end
endmodule

// ============================================================================
// 4. THANH GHI MEM/WB (MEMORY -> WRITE BACK)
// Tương tự EX/MEM: flush=1'b0 trong cpu_core.v, nhưng chuẩn hóa cấu trúc.
// ============================================================================
module pipeline_reg_mem_wb (
    input  wire        clk, rst, stall, flush,

    // Data in
    input  wire [15:0] mem_data_in, alu_result_in,
    input  wire [2:0]  write_reg_in,

    // Control in
    input  wire        reg_write_in, mem_to_reg_in, halt_in,

    // Data out
    output reg  [15:0] mem_data_out, alu_result_out,
    output reg  [2:0]  write_reg_out,

    // Control out
    output reg         reg_write_out, mem_to_reg_out, halt_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_data_out   <= 0; alu_result_out <= 0; write_reg_out <= 0;
            reg_write_out  <= 0; mem_to_reg_out <= 0; halt_out <= 0;
        end else if (stall) begin
            // Đóng băng - giữ nguyên
        end else if (flush) begin
            mem_data_out   <= 0; alu_result_out <= 0; write_reg_out <= 0;
            reg_write_out  <= 0; mem_to_reg_out <= 0; halt_out <= 0;
        end else begin
            mem_data_out   <= mem_data_in; alu_result_out <= alu_result_in;
            write_reg_out  <= write_reg_in;
            reg_write_out  <= reg_write_in; mem_to_reg_out <= mem_to_reg_in;
            halt_out       <= halt_in;
        end
    end
endmodule