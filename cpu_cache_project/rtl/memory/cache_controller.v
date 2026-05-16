`timescale 1ns / 1ps

module cache_controller (
    input  wire        clk,
    input  wire        rst_n,
    
    // Giao tiếp với CPU (qua Arbiter)
    input  wire [15:0] cpu_addr,
    input  wire [15:0] cpu_wdata,
    input  wire        cpu_read,
    input  wire        cpu_write,
    output reg  [15:0] cpu_rdata,
    output reg         cpu_stall,
    
    // Giao tiếp với mảng lưu trữ Cache (gắn sang file direct_mapped_cache.v)
    output wire [3:0]  cache_index,
    output wire [11:0] cache_tag,
    output reg         cache_we,
    output reg  [15:0] cache_wdata,
    input  wire        cache_hit,
    input  wire [15:0] cache_rdata,
    
    // Giao tiếp với Main Memory
    output reg  [15:0] mem_addr,
    output reg  [15:0] mem_wdata,
    output reg         mem_read,
    output reg         mem_write,
    input  wire [15:0] mem_rdata,
    input  wire        mem_ready
);

    // Bẻ nhánh địa chỉ CPU sang cho mảng Cache phân tích
    assign cache_index = cpu_addr[3:0];
    assign cache_tag   = cpu_addr[15:4];

    // Khai báo FSM
    localparam IDLE     = 1'b0;
    localparam WAIT_MEM = 1'b1;
    reg state, next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    // Logic điều khiển trung tâm
    always @(*) begin
        next_state  = state;
        cpu_stall   = 1'b0;
        cache_we    = 1'b0;
        cache_wdata = 16'd0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        mem_addr    = cpu_addr;
        mem_wdata   = cpu_wdata;
        cpu_rdata   = 16'd0;

        case (state)
            IDLE: begin
                if (cpu_read) begin
                    if (cache_hit) begin
                        cpu_rdata  = cache_rdata; // Read Hit: Lấy dữ liệu luôn, ko stall
                    end else begin
                        cpu_stall  = 1'b1;         // Read Miss: Bắt đầu stall CPU
                        mem_read   = 1'b1;         // Gọi bộ nhớ chính
                        next_state = WAIT_MEM;
                    end
                end 
                else if (cpu_write) begin
                    cpu_stall  = 1'b1;             // Write-through: Luôn stall để ghi xuống Mem
                    mem_write  = 1'b1;
                    next_state = WAIT_MEM;
                end
            end

            WAIT_MEM: begin
                cpu_stall = 1'b1;                  // Giữ trạng thái stall CPU
                if (mem_ready) begin
                    next_state = IDLE;
                    if (cpu_read) begin
                        cpu_rdata = mem_rdata;
                        cache_we  = 1'b1;          // Read Miss xong -> nạp vào Cache
                        cache_wdata = mem_rdata;
                    end 
                    else if (cpu_write) begin
                        // Write-through + No-write-allocate:
                        // Chỉ cập nhật Cache nếu trước đó đã HIT. Nếu MISS thì bỏ qua.
                        if (cache_hit) begin
                            cache_we    = 1'b1;
                            cache_wdata = cpu_wdata;
                        end
                    end
                end else begin
                    mem_read  = cpu_read;
                    mem_write = cpu_write;
                end
            end
        endcase
    end

endmodule