`timescale 1ns/1ps
`include "cache_config.vh"

module main_memory #(
    parameter MEM_SIZE  = 65536,          // Dung lượng RAM 64KB (chuẩn 16-bit address)
    parameter MEM_DELAY = `RAM_DELAY,     // Kế thừa độ trễ từ cấu hình lõi
    parameter INIT_FILE = ""              // Tên file mã máy sẽ được nạp
)(
    input wire clk,
    input wire rst,
    input wire mem_req,
    input wire mem_we,
    input wire [`ADDR_WIDTH-1:0] mem_addr,
    input wire [`DATA_WIDTH-1:0] mem_wdata,
    
    output reg [`DATA_WIDTH-1:0] mem_rdata,
    output reg mem_ready
);

    // Mảng lưu trữ vật lý 65536 x 16-bit
    reg [`DATA_WIDTH-1:0] ram_array [0:MEM_SIZE-1]; 
    
    // Bộ đếm chu kỳ trễ (Mở rộng lên 4-bit để an toàn nếu tăng MEM_DELAY)
    reg [3:0] delay_counter;
    
    // ========================================================================
    // CƠ CHẾ NẠP MÃ MÁY (BOOTSTRAP LOADER)
    // ========================================================================
    integer i;
    initial begin
        if (INIT_FILE != "") begin
            // Nạp mã máy từ file .mem nếu được truyền tham số
            $readmemh(INIT_FILE, ram_array);
        end else begin
            // Tráng sạch RAM bằng 0 nếu không có file nạp
            for (i = 0; i < MEM_SIZE; i = i + 1) begin
                ram_array[i] = 16'h0000;
            end
        end
    end

    // ========================================================================
    // BỘ MÁY ĐẾM TRỄ VÀ PHỤC VỤ ĐỌC/GHI (DELAY FSM)
    // ========================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            delay_counter <= 0;
            mem_ready <= 0;
            mem_rdata <= 16'h0000;
        end else begin
            if (mem_req && !mem_ready) begin
                if (delay_counter < MEM_DELAY - 1) begin
                    // Đang trễ: Khóa mem_ready, tăng đếm
                    delay_counter <= delay_counter + 1;
                    mem_ready <= 0;
                end else begin
                    // Đã trễ xong: Thực thi vật lý
                    if (mem_we) ram_array[mem_addr] <= mem_wdata;
                    else        mem_rdata <= ram_array[mem_addr];
                    
                    mem_ready <= 1;       // Báo tín hiệu hoàn thành
                    delay_counter <= 0;   // Đặt lại bộ đếm cho lệnh tiếp theo
                end
            end else if (!mem_req) begin
                // Reset trạng thái khi không có yêu cầu
                mem_ready <= 0;
                delay_counter <= 0;
            end
        end
    end
endmodule