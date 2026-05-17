`timescale 1ns/1ps
`include "cpu_defines.vh"

module cpu_core (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    
    // Interface tới Memory Arbiter (Tầng IF)
    output wire        if_req,
    output wire [15:0] if_addr,
    input  wire [15:0] if_instr_in,
    input  wire        if_ready,
    
    // Interface tới Memory Arbiter (Tầng MEM)
    output wire        mem_req,
    output wire        mem_we,
    output wire [15:0] mem_addr,
    output wire [15:0] mem_wdata,
    input  wire [15:0] mem_rdata,
    input  wire        mem_ready,
    
    // Trạng thái hệ thống
    output wire        halted,
    output wire        stall_out
);

    // ========================================================================
    // KHAI BÁO CÁP ĐIỆN NỘI BỘ (INTERNAL WIRES)
    // ========================================================================
    
    // Tín hiệu toàn cục
    reg  halted_reg;
    wire cache_stall;
    wire if_mem_conflict;
    
    // --- WIRES TẦNG IF ---
    wire [15:0] if_pc, if_pc_next;
    
    // --- WIRES TẦNG ID ---
    wire [15:0] id_pc, id_instr;
    wire [3:0]  id_opcode;
    wire [2:0]  id_rs, id_rt, id_rd, id_funct;
    wire [5:0]  id_imm6;
    wire [11:0] id_jump_addr;
    wire [15:0] id_imm16;
    wire [15:0] id_rs_data, id_rt_data;
    wire [15:0] id_jump_target;
    // Tín hiệu điều khiển sinh ra từ ID
    wire id_reg_dst, id_alu_src, id_mem_to_reg, id_reg_write, id_mem_read;
    wire id_mem_write, id_branch, id_branch_ne, id_jump, id_halt;
    wire [3:0] id_alu_op;

    // --- WIRES TẦNG EX ---
    wire [15:0] ex_pc, ex_rs_data, ex_rt_data, ex_imm16;
    wire [2:0]  ex_rs, ex_rt, ex_rd;
    wire        ex_reg_dst, ex_alu_src, ex_mem_to_reg, ex_reg_write, ex_mem_read;
    wire        ex_mem_write, ex_branch, ex_branch_ne, ex_jump, ex_halt;
    wire [3:0]  ex_alu_op;
    
    wire [15:0] ex_alu_result;
    wire        ex_zero;
    wire [15:0] ex_branch_target;
    wire [2:0]  ex_write_reg;
    wire        ex_branch_taken;
    wire [15:0] alu_in_a, alu_in_b, forward_b_data;

    // --- WIRES TẦNG MEM ---
    wire [15:0] mem_alu_result_wire, mem_rt_data_wire, mem_branch_target;
    wire [2:0]  mem_write_reg_wire;
    wire        mem_zero;
    wire        mem_reg_write_wire, mem_mem_read_wire, mem_mem_write_wire;
    wire        mem_mem_to_reg_wire, mem_branch_wire, mem_branch_ne_wire;
    wire        mem_jump_wire, mem_halt_wire;

    // --- WIRES TẦNG WB ---
    wire [15:0] wb_mem_data, wb_alu_result;
    wire [2:0]  wb_write_reg;
    wire        wb_reg_write, wb_mem_to_reg, wb_halt;
    wire [15:0] wb_write_data;

    // --- WIRES ĐIỀU KHIỂN HAZARD & FORWARDING ---
    wire pc_stall, if_id_stall, id_ex_flush, if_id_flush;
    wire [1:0] forward_a, forward_b;

    // ========================================================================
    // LOGIC ĐIỀU KHIỂN TOÀN CỤC & TẠO XUNG STALL
    // ========================================================================
    
    assign halted = halted_reg;
    
    // Chốt trạng thái HALT khi cờ chạy xuống đến WB
    always @(posedge clk or posedge rst) begin
        if (rst) halted_reg <= 1'b0;
        else if (wb_halt) halted_reg <= 1'b1;
    end

    // Yêu cầu Fetch: Bật khi có lệnh Start, chưa chết (Halt), và rỗng Memory Stall
    // Nếu có Halt đang trôi trong ống, cũng tự động khóa IF để tránh nạp rác.
    wire pipe_has_halt = id_halt | ex_halt | mem_halt_wire | wb_halt;
    assign if_req = start && !halted_reg && !pipe_has_halt;
    assign if_addr = if_pc;

    // Định nghĩa Cache Stall & Conflict
    // Sửa lỗi Deadlock: Chỉ stall toàn Pipeline khi request ĐANG ĐƯỢC ƯU TIÊN bị miss.
    assign cache_stall = mem_req ? !mem_ready : (if_req ? !if_ready : 1'b0);
    assign if_mem_conflict = mem_req && if_req;
    assign stall_out = pc_stall | if_id_stall | cache_stall;

    // ========================================================================
    // TẦNG 1: INSTRUCTION FETCH (IF)
    // ========================================================================
    pc_unit u_pc (
        .clk(clk),
        .rst(rst),
        .enable(start),           // PC chỉ tăng khi CPU đã được kích hoạt
        .stall(pc_stall | cache_stall), 
        .branch_taken(ex_branch_taken),
        .jump(id_jump), // Jump chốt ngay tại ID để tiết kiệm chu kỳ
        .branch_target(ex_branch_target),
        .jump_target(id_jump_target),
        .pc_out(if_pc),
        .pc_next(if_pc_next)
    );

    pipeline_reg_if_id u_if_id (
        .clk(clk), .rst(rst), 
        .stall(if_id_stall | cache_stall), 
        .flush(if_id_flush | ex_branch_taken), 
        .pc_in(if_pc), .instr_in(if_instr_in),
        .pc_out(id_pc), .instr_out(id_instr)
    );

    // ========================================================================
    // TẦNG 2: INSTRUCTION DECODE (ID)
    // ========================================================================
    instruction_decoder u_decode (
        .instr(id_instr),
        .opcode(id_opcode), .rs(id_rs), .rt(id_rt), .rd(id_rd),
        .funct(id_funct), .imm6(id_imm6), .jump_addr(id_jump_addr)
    );

    control_unit u_control (
        .opcode(id_opcode), .funct(id_funct),
        .reg_dst(id_reg_dst), .alu_src(id_alu_src), .mem_to_reg(id_mem_to_reg),
        .reg_write(id_reg_write), .mem_read(id_mem_read), .mem_write(id_mem_write),
        .branch(id_branch), .branch_ne(id_branch_ne), .jump(id_jump),
        .alu_op(id_alu_op), .halt(id_halt)
    );

    register_file u_regfile (
        .clk(clk), .rst(rst),
        .rs_addr(id_rs), .rt_addr(id_rt), 
        .rd_addr(wb_write_reg), .rd_wdata(wb_write_data), .reg_write(wb_reg_write),
        .rs_data(id_rs_data), .rt_data(id_rt_data)
    );

    immediate_generator u_imm_gen (
        .imm6(id_imm6),
        .sign_ext(1'b1), // Đa số lệnh yêu cầu Sign Extend
        .imm16(id_imm16)
    );

    // Tính Jump Target trực tiếp tại ID
    assign id_jump_target = {id_pc[15:12], id_jump_addr};

    pipeline_reg_id_ex u_id_ex (
        .clk(clk), .rst(rst), .stall(cache_stall), .flush(id_ex_flush),
        .pc_in(id_pc), .rs_data_in(id_rs_data), .rt_data_in(id_rt_data), .imm16_in(id_imm16),
        .rs_in(id_rs), .rt_in(id_rt), .rd_in(id_rd),
        .alu_op_in(id_alu_op),
        .reg_write_in(id_reg_write), .mem_read_in(id_mem_read), .mem_write_in(id_mem_write), .mem_to_reg_in(id_mem_to_reg),
        .alu_src_in(id_alu_src), .reg_dst_in(id_reg_dst),
        .branch_in(id_branch), .branch_ne_in(id_branch_ne), .jump_in(id_jump), .halt_in(id_halt),
        
        .pc_out(ex_pc), .rs_data_out(ex_rs_data), .rt_data_out(ex_rt_data), .imm16_out(ex_imm16),
        .rs_out(ex_rs), .rt_out(ex_rt), .rd_out(ex_rd),
        .alu_op_out(ex_alu_op),
        .reg_write_out(ex_reg_write), .mem_read_out(ex_mem_read), .mem_write_out(ex_mem_write), .mem_to_reg_out(ex_mem_to_reg),
        .alu_src_out(ex_alu_src), .reg_dst_out(ex_reg_dst),
        .branch_out(ex_branch), .branch_ne_out(ex_branch_ne), .jump_out(ex_jump), .halt_out(ex_halt)
    );

    // ========================================================================
    // TẦNG 3: EXECUTE (EX)
    // ========================================================================
    
    // Mạch định tuyến chọn đích ghi
    assign ex_write_reg = ex_reg_dst ? ex_rd : ex_rt;
    
    // Mạch tính địa chỉ Branch (PC hiện tại + 1 + offset)
    assign ex_branch_target = ex_pc + 16'd1 + ex_imm16;

    // Mạch MUX Forwarding (Tích hợp cứng)
    assign alu_in_a = (forward_a == 2'b10) ? mem_alu_result_wire :
                      (forward_a == 2'b01) ? wb_write_data : ex_rs_data;
                      
    assign forward_b_data = (forward_b == 2'b10) ? mem_alu_result_wire :
                            (forward_b == 2'b01) ? wb_write_data : ex_rt_data;
                            
    assign alu_in_b = ex_alu_src ? ex_imm16 : forward_b_data;

    alu u_alu (
        .a(alu_in_a), .b(alu_in_b), .alu_op(ex_alu_op),
        .result(ex_alu_result), .zero(ex_zero), .negative(), .overflow()
    );

    // Còi báo Rẽ nhánh
    assign ex_branch_taken = (ex_branch && ex_zero) || (ex_branch_ne && !ex_zero);

    pipeline_reg_ex_mem u_ex_mem (
        .clk(clk), .rst(rst), .stall(cache_stall), .flush(1'b0),
        .alu_result_in(ex_alu_result), .rt_data_in(forward_b_data), .branch_target_in(ex_branch_target),
        .write_reg_in(ex_write_reg), .zero_in(ex_zero),
        .reg_write_in(ex_reg_write), .mem_read_in(ex_mem_read), .mem_write_in(ex_mem_write), .mem_to_reg_in(ex_mem_to_reg),
        .branch_in(ex_branch), .branch_ne_in(ex_branch_ne), .jump_in(ex_jump), .halt_in(ex_halt),
        
        .alu_result_out(mem_alu_result_wire), .rt_data_out(mem_rt_data_wire), .branch_target_out(mem_branch_target),
        .write_reg_out(mem_write_reg_wire), .zero_out(mem_zero),
        .reg_write_out(mem_reg_write_wire), .mem_read_out(mem_mem_read_wire), .mem_write_out(mem_mem_write_wire), .mem_to_reg_out(mem_mem_to_reg_wire),
        .branch_out(mem_branch_wire), .branch_ne_out(mem_branch_ne_wire), .jump_out(mem_jump_wire), .halt_out(mem_halt_wire)
    );

    // ========================================================================
    // TẦNG 4: MEMORY (MEM)
    // ========================================================================
    assign mem_req   = (mem_mem_read_wire || mem_mem_write_wire) && !halted_reg;
    assign mem_we    = mem_mem_write_wire;
    assign mem_addr  = mem_alu_result_wire;
    assign mem_wdata = mem_rt_data_wire;

    pipeline_reg_mem_wb u_mem_wb (
        .clk(clk), .rst(rst), .stall(cache_stall), .flush(1'b0),
        .mem_data_in(mem_rdata), .alu_result_in(mem_alu_result_wire), .write_reg_in(mem_write_reg_wire),
        .reg_write_in(mem_reg_write_wire), .mem_to_reg_in(mem_mem_to_reg_wire), .halt_in(mem_halt_wire),
        
        .mem_data_out(wb_mem_data), .alu_result_out(wb_alu_result), .write_reg_out(wb_write_reg),
        .reg_write_out(wb_reg_write), .mem_to_reg_out(wb_mem_to_reg), .halt_out(wb_halt)
    );

    // ========================================================================
    // TẦNG 5: WRITE BACK (WB)
    // ========================================================================
    assign wb_write_data = wb_mem_to_reg ? wb_mem_data : wb_alu_result;

    // ========================================================================
    // BỘ PHẬN ĐIỀU PHỐI (HAZARD & FORWARDING)
    // ========================================================================
    hazard_detection_unit u_hazard (
        .id_rs(id_rs), .id_rt(id_rt), .ex_rt(ex_rt),
        .ex_mem_read(ex_mem_read),
        .cache_stall(cache_stall),
        .if_mem_conflict(if_mem_conflict),
        .branch_taken(ex_branch_taken),
        .jump(id_jump),
        .pc_stall(pc_stall), .if_id_stall(if_id_stall),
        .id_ex_flush(id_ex_flush), .if_id_flush(if_id_flush)
    );

    forwarding_unit u_forward (
        .id_ex_rs(ex_rs), .id_ex_rt(ex_rt),
        .ex_mem_rd(mem_write_reg_wire), .mem_wb_rd(wb_write_reg),
        .ex_mem_reg_write(mem_reg_write_wire), .mem_wb_reg_write(wb_reg_write),
        .forward_a(forward_a), .forward_b(forward_b)
    );

endmodule