`timescale 1ns / 1ps

module tb_memory_subsystem;

    // Tín hiệu hệ thống
    reg clk;
    reg rst_n;

    // Tín hiệu tầng IF
    reg  [15:0] if_addr;
    reg         if_read;
    wire [15:0] if_rdata;
    wire        if_stall;

    // Tín hiệu tầng MEM
    reg  [15:0] mem_addr;
    reg  [15:0] mem_wdata;
    reg         mem_read;
    reg         mem_write;
    wire [15:0] mem_rdata;
    wire        mem_stall;

    // Dây nối giữa Arbiter và Cache Controller
    wire [15:0] cache_addr, cache_wdata, cache_rdata;
    wire        cache_read, cache_write, cache_stall;
    
    // Dây nối giữa Cache Controller và Main Memory
    wire [15:0] main_addr, main_wdata, main_rdata;
    wire        main_read, main_write, main_ready;

    // ========================================================================
    // CÁC DÂY NỐI NỘI BỘ MỚI: Kết nối Cache Controller và Mảng Lưu Trữ Cache
    // ========================================================================
    wire [3:0]  c_index;
    wire [11:0] c_tag;
    wire        c_we;
    wire [15:0] c_wdata;
    wire        c_hit;
    wire [15:0] c_rdata;

    // Instantiate Arbiter
    memory_arbiter arbiter_inst (
        .if_addr(if_addr), .if_read(if_read), .if_rdata(if_rdata), .if_stall(if_stall),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_read(mem_read), .mem_write(mem_write), .mem_rdata(mem_rdata), .mem_stall(mem_stall),
        .cache_addr(cache_addr), .cache_wdata(cache_wdata), .cache_read(cache_read), .cache_write(cache_write), .cache_rdata(cache_rdata), .cache_stall(cache_stall)
    );

    // ========================================================================
    // THAY THẾ KHỐI CACHE CŨ BẰNG 2 KHỐI MỚI TÁCH RỜI
    // ========================================================================
    
    // 1. Khối Điều Khiển Bộ Đệm (Cache Controller)
    cache_controller controller_inst (
        .clk(clk), .rst_n(rst_n),
        // Giao tiếp với Arbiter
        .cpu_addr(cache_addr), .cpu_wdata(cache_wdata), .cpu_read(cache_read), .cpu_write(cache_write), .cpu_rdata(cache_rdata), .cpu_stall(cache_stall),
        // Giao tiếp sang mảng lưu trữ Cache bên dưới
        .cache_index(c_index), .cache_tag(c_tag), .cache_we(c_we), .cache_wdata(c_wdata), .cache_hit(c_hit), .cache_rdata(c_rdata),
        // Giao tiếp với Main Memory
        .mem_addr(main_addr), .mem_wdata(main_wdata), .mem_read(main_read), .mem_write(main_write), .mem_rdata(main_rdata), .mem_ready(main_ready)
    );

    // 2. Khối Mảng Lưu Trữ (Direct Mapped Cache Storage)
    direct_mapped_cache storage_inst (
        .clk(clk), .rst_n(rst_n),
        .index(c_index), .tag(c_tag), .we(c_we), .wdata(c_wdata), .hit(c_hit), .rdata(c_rdata)
    );

    // ========================================================================

    // Instantiate Main Memory
    main_memory mem_inst (
        .clk(clk), .rst_n(rst_n),
        .addr(main_addr), .wdata(main_wdata), .mem_read(main_read), .mem_write(main_write), .rdata(main_rdata), .mem_ready(main_ready)
    );

    // Tạo xung nhịp
    always #5 clk = ~clk;

    initial begin
        // Khởi tạo file dump để xem waveform (dành cho Icarus Verilog + GTKWave)
        $dumpfile("memory_tb.vcd");
        $dumpvars(0, tb_memory_subsystem);

        // Khởi tạo tín hiệu
        clk = 0; rst_n = 0;
        if_addr = 0; if_read = 0;
        mem_addr = 0; mem_wdata = 0; mem_read = 0; mem_write = 0;

        // Reset hệ thống
        #15 rst_n = 1;

        // KỊCH BẢN 1: IF Read Miss
        $display("--- Kich ban 1: IF Read Miss (Doc dia chi 10) ---");
        @(posedge clk);
        if_addr = 16'd10; if_read = 1'b1;
        // Đợi cho đến khi hết stall
        wait(!if_stall);
        @(posedge clk);
        if_read = 1'b0;

        // KỊCH BẢN 2: IF Read Hit
        $display("--- Kich ban 2: IF Read Hit (Doc lai dia chi 10) ---");
        @(posedge clk);
        if_addr = 16'd10; if_read = 1'b1;
        @(posedge clk);
        if_read = 1'b0; // Không bị stall, lấy data luôn trong 1 cycle

        // KỊCH BẢN 3: Xung đột IF và MEM (Structural Hazard)
        $display("--- Kich ban 3: MEM ghi data, IF doc lenh (Arbiter phan xu) ---");
        @(posedge clk);
        // IF xin đọc địa chỉ 10, MEM xin ghi vào địa chỉ 30
        if_addr = 16'd10; if_read = 1'b1; 
        mem_addr = 16'd30; mem_wdata = 16'hFFFF; mem_write = 1'b1;
        
        wait(!mem_stall); // Đợi MEM ghi xong
        @(posedge clk);
        mem_write = 1'b0; if_read = 1'b0;

        #20 $finish;
    end
endmodule