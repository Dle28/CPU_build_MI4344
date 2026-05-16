// ============================================================================
// FILE: rtl/cpu/register_file.v
// CHỨC NĂNG: Tập thanh ghi 8x16-bit (Đọc bất đồng bộ, Ghi đồng bộ)
// ============================================================================

// tick: đã xong

`include "cpu_defines.vh"

module register_file (
    // -- INPUTS --
    input  wire                       clk,
    input  wire                       rst,
    input  wire [`REG_ADDR_WIDTH-1:0] rs_addr,
    input  wire [`REG_ADDR_WIDTH-1:0] rt_addr,
    input  wire [`REG_ADDR_WIDTH-1:0] rd_addr,
    input  wire [`DATA_WIDTH-1:0]     rd_wdata,
    input  wire                       reg_write,

    // -- OUTPUTS --
    output wire [`DATA_WIDTH-1:0]     rs_data,
    output wire [`DATA_WIDTH-1:0]     rt_data
);

    // ------------------------------------------------------------------------
    // 1. KHỞI TẠO MẢNG LƯU TRỮ VẬT LÝ (Memory Array)
    // Tạo ra 8 thanh ghi (ngăn kéo), mỗi thanh ghi rộng 16-bit
    // ------------------------------------------------------------------------
    reg [`DATA_WIDTH-1:0] registers [7:0];

    // ------------------------------------------------------------------------
    // 2. MẠCH ĐỌC BẤT ĐỒNG BỘ (Asynchronous Read)
    // Sử dụng 'assign' để dòng điện rẽ nhánh ra ngay lập tức không cần chờ clk.
    // Ép cứng luật R0: Nếu địa chỉ hỏi mua là 0, luôn trả về 16'h0000.
    // ------------------------------------------------------------------------
    assign rs_data = (rs_addr == 3'b000) ? 16'h0000 : registers[rs_addr];
    assign rt_data = (rt_addr == 3'b000) ? 16'h0000 : registers[rt_addr];

    // ------------------------------------------------------------------------
    // 3. MẠCH GHI ĐỒNG BỘ & RESET TOÀN CỤC (Synchronous Write)
    // Kích hoạt duy nhất tại sườn lên của xung nhịp (posedge clk)
    // ------------------------------------------------------------------------
    integer i; // Biến phụ trợ dùng cho vòng lặp reset phần cứng
    
    always @(posedge clk) begin
        if (rst) begin
            // Trạng thái Reset: Xả điện toàn bộ 8 thanh ghi về 0
            for (i = 0; i < 8; i = i + 1) begin
                registers[i] <= 16'h0000;
            end
        end
        else if (reg_write) begin
            // Trạng thái Ghi: Chỉ ghi khi được phép VÀ địa chỉ đích không phải là R0
            if (rd_addr != 3'b000) begin
                registers[rd_addr] <= rd_wdata;
            end
        end
    end

endmodule
