`timescale 1ns/1ps
`include "cache_config.vh"

module direct_mapped_cache (
    input wire clk,
    input wire rst,
    input wire [`ADDR_WIDTH-1:0] cpu_addr,
    input wire [`DATA_WIDTH-1:0] cpu_wdata,
    
    // --- BẢN VÁ LỖI #1: Thêm cổng hứng dữ liệu từ RAM và cờ báo ---
    input wire [`DATA_WIDTH-1:0] mem_rdata, 
    input wire cpu_we,                      
    // ---------------------------------------------------------------
    
    input wire cache_we, 
    output wire [`DATA_WIDTH-1:0] cache_rdata,
    output wire cache_hit
);

    wire [`TAG_WIDTH-1:0] addr_tag   = cpu_addr[`TAG_MSB:`TAG_LSB];
    wire [`IDX_MSB:`IDX_LSB] addr_idx = cpu_addr[`IDX_MSB:`IDX_LSB];

    // --- BẢN VÁ LỖI #1: MUX CHỌN NGUỒN GHI DỮ LIỆU VÀO CACHE ---
    // Nếu cpu_we = 1 -> Chọn cpu_wdata (CPU ghi)
    // Nếu cpu_we = 0 -> Chọn mem_rdata (FSM đang REFILL từ RAM)
    wire [`DATA_WIDTH-1:0] write_data = cpu_we ? cpu_wdata : mem_rdata;
    // -----------------------------------------------------------

    reg valid_array [0:`CACHE_DEPTH-1];
    reg [`TAG_WIDTH-1:0] tag_array [0:`CACHE_DEPTH-1];
    reg [`DATA_WIDTH-1:0] data_array [0:`CACHE_DEPTH-1];

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < `CACHE_DEPTH; i = i + 1) begin
                valid_array[i] <= 1'b0;
                tag_array[i]   <= 0;
                data_array[i]  <= 0;
            end
        end else if (cache_we) begin
            valid_array[addr_idx] <= 1'b1;
            tag_array[addr_idx]   <= addr_tag;
            data_array[addr_idx]  <= write_data; // Nạp dữ liệu đã qua MUX
        end
    end

    assign cache_rdata = data_array[addr_idx];
    assign cache_hit = valid_array[addr_idx] && (tag_array[addr_idx] == addr_tag);

endmodule