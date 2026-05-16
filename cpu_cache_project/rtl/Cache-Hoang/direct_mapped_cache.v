`timescale 1ns / 1ps

module direct_mapped_cache (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  index,
    input  wire [11:0] tag,
    input  wire        we,          // Write Enable từ Controller dội về
    input  wire [15:0] wdata,       // Dữ liệu muốn ghi vào Cache
    output wire        hit,         // Báo hiệu Hit (1) hoặc Miss (0)
    output wire [15:0] rdata        // Dữ liệu đọc ra từ Cache
);

    // Khởi tạo mảng lưu trữ vật lý
    reg         valid_array [0:15];
    reg [11:0]  tag_array   [0:15];
    reg [15:0]  data_array  [0:15];

    // Mạch tổ hợp kiểm tra Hit/Miss
    assign hit   = valid_array[index] && (tag_array[index] == tag);
    assign rdata = data_array[index];

    // Cập nhật mảng lưu trữ khi có tín hiệu cho phép ghi (we) từ Controller
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 16; i = i + 1) begin
                valid_array[i] <= 1'b0;
                tag_array[i]   <= 12'd0;
                data_array[i]  <= 16'd0;
            end
        end else if (we) begin
            valid_array[index] <= 1'b1;
            tag_array[index]   <= tag;
            data_array[index]  <= wdata;
        end
    end

endmodule