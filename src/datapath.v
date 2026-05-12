// ============================================================================
// FILE: src/datapath.v
// CHỨC NĂNG: Khối Tích hợp Lõi Datapath (Gắn kết RegFile, ImmGen, MUX và ALU)
// ============================================================================

`include "cpu_defines.vh"

module datapath (
    input wire clk,
    input wire rst,

    // --- CÁC TÍN HIỆU TỪ CONTROL UNIT (Đóng vai trò điều khiển ngã ba) ---
    input wire       reg_write,
    input wire       alu_src,    // 0: Chọn ngõ ra RegFile, 1: Chọn Imm16
    input wire       sign_ext,
    input wire [3:0] alu_op,
    input wire       mem_to_reg, // 0: Lấy từ ALU, 1: Lấy từ Memory (giả lập)

    // --- CÁC TRƯỜNG CỦA LỆNH (Instruction Fields) ---
    input wire [2:0] rs_addr,
    input wire [2:0] rt_addr,
    input wire [2:0] rd_addr,
    input wire [5:0] imm6,

    // --- DỮ LIỆU TỪ BỘ NHỚ (Giả lập tầng MEM dội về) ---
    input wire [15:0] mem_data_in,

    // --- CÁC CỔNG ĐO ĐẠC (Xuất ra để Testbench nhìn thấy) ---
    output wire [15:0] alu_result_out,
    output wire        alu_zero_out
);

    // ========================================================================
    // QUY HOẠCH CÁP ĐIỆN NỘI BỘ (Internal Wires)
    // ========================================================================
    wire [15:0] rs_data_wire;
    wire [15:0] rt_data_wire;
    wire [15:0] imm16_wire;
    wire [15:0] alu_b_wire;      // Dây cắm vào cổng B của ALU
    wire [15:0] alu_result_wire; // Dây từ ALU chạy ra
    wire [15:0] rd_wdata_wire;   // Dây cắm ngược lại vào cổng ghi của RegFile

    assign alu_result_out = alu_result_wire; // Nối ra ngoài để đo

    // ========================================================================
    // LẮP RÁP LINH KIỆN (Component Instantiation)
    // ========================================================================

    // 1. TẬP THANH GHI
    register_file u_regfile (
        .clk(clk),
        .rst(rst),
        .rs_addr(rs_addr),
        .rt_addr(rt_addr),
        .rd_addr(rd_addr),
        .rd_wdata(rd_wdata_wire), // Nhận dữ liệu từ trạm bẻ ghi MemToReg
        .reg_write(reg_write),
        .rs_data(rs_data_wire),
        .rt_data(rt_data_wire)
    );

    // 2. BỘ KÉO GIÃN HẰNG SỐ
    immediate_generator u_imm_gen (
        .imm6(imm6),
        .sign_ext(sign_ext),
        .imm16(imm16_wire)
    );

    // 3. TRẠM BẺ GHI SỐ 1: ALUSrc (Đứng trước cửa ALU)
    mux2to1 u_mux_alu_src (
        .d0(rt_data_wire), // Luồng 0: Dữ liệu từ thanh ghi Rt
        .d1(imm16_wire),   // Luồng 1: Dữ liệu hằng số
        .sel(alu_src),
        .y(alu_b_wire)     // Dội vào cổng B của ALU
    );

    // 4. MÁY ÉP TÍNH TOÁN: ALU
    alu u_alu (
        .a(rs_data_wire),
        .b(alu_b_wire),
        .alu_op(alu_op),
        .result(alu_result_wire),
        .zero(alu_zero_out),
        .negative(), // Tạm thời bỏ trống không cắm dây
        .overflow()  // Tạm thời bỏ trống không cắm dây
    );

    // 5. TRẠM BẺ GHI SỐ 2: MemToReg (Đứng trước cửa Write-Back)
    mux2to1 u_mux_mem_to_reg (
        .d0(alu_result_wire),
        .d1(mem_data_in),
        .sel(mem_to_reg),
        .y(rd_wdata_wire)  // Dội ngược về cổng rd_wdata của u_regfile
    );

endmodule