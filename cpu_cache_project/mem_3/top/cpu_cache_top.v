`include "cpu_defines.vh"

// ============================================================================
// FIX SPEC#4: Thêm parameter INIT_FILE để Testbench có thể override
// mà không cần sửa source code.
// Cách dùng trong testbench:
//   cpu_cache_top #(.INIT_FILE("my_test.mem")) u_dut (...);
// ============================================================================
module cpu_cache_top #(
    parameter INIT_FILE = "program.mem"
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    output wire        halted,

    // Tín hiệu Debug phục vụ Testbench
    output wire [15:0] debug_pc,
    output wire [15:0] debug_instr,
    output wire        debug_reg_write,
    output wire [2:0]  debug_wb_reg,
    output wire [15:0] debug_wb_data
);

    // ========================================================================
    // QUY HOẠCH CÁP NỐI (WIRE DECLARATIONS)
    // ========================================================================

    // 1. Cáp nối CPU Core <-> Arbiter (Tầng Fetch Lệnh - IF)
    wire        cpu_if_req;
    wire [15:0] cpu_if_addr;
    wire [15:0] arb_if_instr;
    wire        arb_if_ready;

    // 2. Cáp nối CPU Core <-> Arbiter (Tầng Truy xuất Dữ liệu - MEM)
    wire        cpu_mem_req;
    wire        cpu_mem_we;
    wire [15:0] cpu_mem_addr;
    wire [15:0] cpu_mem_wdata;
    wire [15:0] arb_mem_rdata;
    wire        arb_mem_ready;
    wire        cpu_stall_out;

    // 3. Cáp nối Arbiter <-> Cache Subsystem
    wire        arb_cache_req;
    wire        arb_cache_we;
    wire [15:0] arb_cache_addr;
    wire [15:0] arb_cache_wdata;
    wire [15:0] cache_arb_rdata;
    wire        cache_arb_ready;
    wire        cache_stall_out;
    wire        cache_miss_out;

    // 4. Cáp nối Cache Subsystem <-> Main Memory
    wire        cache_ram_req;
    wire        cache_ram_we;
    wire [15:0] cache_ram_addr;
    wire [15:0] cache_ram_wdata;
    wire [15:0] ram_cache_rdata;
    wire        ram_cache_ready;

    // ========================================================================
    // LẮP RÁP HỆ THỐNG (COMPONENT INSTANTIATION)
    // ========================================================================

    // [1] LÕI VI XỬ LÝ
    cpu_core u_cpu_core (
        .clk(clk),
        .rst(rst),
        .start(start),

        .if_req(cpu_if_req),
        .if_addr(cpu_if_addr),
        .if_instr_in(arb_if_instr),
        .if_ready(arb_if_ready),

        .mem_req(cpu_mem_req),
        .mem_we(cpu_mem_we),
        .mem_addr(cpu_mem_addr),
        .mem_wdata(cpu_mem_wdata),
        .mem_rdata(arb_mem_rdata),
        .mem_ready(arb_mem_ready),

        .halted(halted),
        .stall_out(cpu_stall_out)
    );

    // [2] BỘ ĐỊNH TUYẾN BỘ NHỚ
    // Không có clk/rst vì là mạch tổ hợp thuần túy
    memory_arbiter u_arbiter (
        .if_req(cpu_if_req),
        .if_addr(cpu_if_addr),
        .if_ready(arb_if_ready),
        .if_instr(arb_if_instr),

        .mem_req(cpu_mem_req),
        .mem_we(cpu_mem_we),
        .mem_addr(cpu_mem_addr),
        .mem_wdata(cpu_mem_wdata),
        .mem_ready(arb_mem_ready),
        .mem_rdata(arb_mem_rdata),

        .cache_req(arb_cache_req),
        .cache_we(arb_cache_we),
        .cache_addr(arb_cache_addr),
        .cache_wdata(arb_cache_wdata),
        .cache_ready(cache_arb_ready),
        .cache_rdata(cache_arb_rdata)
    );

    // [3] PHÂN HỆ CACHE L1
    cache_subsystem u_cache (
        .clk(clk),
        .rst(rst),

        .cpu_req(arb_cache_req),
        .cpu_we(arb_cache_we),
        .cpu_addr(arb_cache_addr),
        .cpu_wdata(arb_cache_wdata),
        .cpu_ready(cache_arb_ready),
        .cache_rdata(cache_arb_rdata),
        .stall(cache_stall_out),
        .cache_miss(cache_miss_out),

        .mem_req(cache_ram_req),
        .mem_we(cache_ram_we),
        .mem_addr(cache_ram_addr),
        .mem_wdata(cache_ram_wdata),
        .mem_rdata(ram_cache_rdata),
        .mem_ready(ram_cache_ready)
    );

    // [4] BỘ NHỚ VẬT LÝ — nhận INIT_FILE từ parameter trên
    main_memory #(
        .INIT_FILE(INIT_FILE)
    ) u_ram (
        .clk(clk),
        .rst(rst),
        .mem_req(cache_ram_req),
        .mem_we(cache_ram_we),
        .mem_addr(cache_ram_addr),
        .mem_wdata(cache_ram_wdata),
        .mem_rdata(ram_cache_rdata),
        .mem_ready(ram_cache_ready)
    );

    // ========================================================================
    // XUẤT TÍN HIỆU DEBUG (HIERARCHICAL REFERENCE)
    // ========================================================================
    assign debug_pc        = u_cpu_core.if_pc;
    assign debug_instr     = u_cpu_core.id_instr;
    assign debug_reg_write = u_cpu_core.wb_reg_write;
    assign debug_wb_reg    = u_cpu_core.wb_write_reg;
    assign debug_wb_data   = u_cpu_core.wb_write_data;

endmodule