`timescale 1ns/1ps
`include "cache_config.vh"

module cache_subsystem (
    input wire clk,
    input wire rst,

    // ========================================================================
    // 1. INTERFACE VỚI MEMORY ARBITER
    // ========================================================================
    input wire                      cpu_req,    
    input wire                      cpu_we,     
    input wire [`ADDR_WIDTH-1:0]    cpu_addr,   
    input wire [`DATA_WIDTH-1:0]    cpu_wdata,  
    output wire                     cpu_ready,  
    output wire [`DATA_WIDTH-1:0]   cache_rdata,
    output wire                     stall,      
    output wire                     cache_miss, // BẢN VÁ: Mở cổng xuất tín hiệu Miss ra ngoài

    // ========================================================================
    // 2. INTERFACE VỚI MAIN MEMORY
    // ========================================================================
    output wire                     mem_req,    
    output wire                     mem_we,     
    output wire [`ADDR_WIDTH-1:0]   mem_addr,   
    output wire [`DATA_WIDTH-1:0]   mem_wdata,  
    input wire [`DATA_WIDTH-1:0]    mem_rdata,  
    input wire                      mem_ready   
);

    // ========================================================================
    // MẠCH ĐI DÂY NỘI BỘ (INTERNAL WIRES)
    // ========================================================================
    wire cache_hit;       
    wire cache_we_ctrl;   

    // Định tuyến Bypass
    assign mem_addr  = cpu_addr;
    assign mem_wdata = cpu_wdata;

    // BẢN VÁ: Mạch Logic bắt Miss ngay tại lớp Wrapper
    // Chỉ Miss khi CPU thực sự có yêu cầu VÀ Cache báo trượt
    assign cache_miss = cpu_req && !cache_hit;

    // ========================================================================
    // LẮP RÁP 2 KHỐI LÕI
    // ========================================================================

    cache_controller u_cache_controller (
        // ... (Giữ nguyên các kết nối)
        .clk(clk),
        .rst(rst),
        .cpu_req(cpu_req),
        .cpu_we(cpu_we),
        .stall(stall),
        .cpu_ready(cpu_ready),
        .cache_we(cache_we_ctrl),
        .cache_hit(cache_hit),
        .mem_ready(mem_ready),
        .mem_req(mem_req),
        .mem_we(mem_we)
    );

    direct_mapped_cache u_cache_array (
        // ... (Giữ nguyên các kết nối)
        .clk(clk),
        .rst(rst),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .mem_rdata(mem_rdata), 
        .cpu_we(cpu_we),       
        .cache_we(cache_we_ctrl),
        .cache_rdata(cache_rdata),
        .cache_hit(cache_hit)
    );

endmodule