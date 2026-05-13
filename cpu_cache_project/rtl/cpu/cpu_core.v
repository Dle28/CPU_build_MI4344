`timescale 1ns/1ps

// 16-bit CPU core (bring-up): single-cycle style FSM.
// The core exposes separate logical IF and MEM request ports. The external
// memory_arbiter merges them into the unified cache path.
module cpu_core #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16
) (
    input                   clk,
    input                   rst,

    output                  if_req,
    output [ADDR_WIDTH-1:0] if_addr,
    input  [DATA_WIDTH-1:0] if_rdata,
    input                   if_ready,

    output                  mem_req,
    output                  mem_we,
    output [ADDR_WIDTH-1:0] mem_addr,
    output [DATA_WIDTH-1:0] mem_wdata,
    input  [DATA_WIDTH-1:0] mem_rdata,
    input                   mem_ready,

    output                  halted,
    output [ADDR_WIDTH-1:0] debug_pc
);

    `include "cpu_defines.vh"

    // ------------------------------------------------------------------------
    // FSM State
    // ------------------------------------------------------------------------
    localparam S_FETCH    = 3'd0;
    localparam S_DECODE   = 3'd1;
    localparam S_MEM_WAIT = 3'd2;
    localparam S_WB       = 3'd3;
    localparam S_HALT     = 3'd4;

    reg [2:0]            state_q;
    reg [ADDR_WIDTH-1:0] pc_q;
    reg [DATA_WIDTH-1:0] instr_q;
    reg [DATA_WIDTH-1:0] mem_data_q;
    reg [ADDR_WIDTH-1:0] next_pc_q;

    // ------------------------------------------------------------------------
    // Instruction fields
    // ------------------------------------------------------------------------
    wire [3:0] opcode;
    wire [2:0] rs;
    wire [2:0] rt;
    wire [2:0] rd;
    wire [2:0] funct;
    wire [5:0] imm6;
    wire [11:0] address;

    instruction_decoder u_instruction_decoder (
        .instr(instr_q),
        .opcode(opcode),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .funct(funct),
        .imm6(imm6),
        .address(address)
    );

    // ------------------------------------------------------------------------
    // Control
    // ------------------------------------------------------------------------
    wire       ctrl_reg_write;
    wire       ctrl_mem_read;
    wire       ctrl_mem_write;
    wire       ctrl_branch_eq;
    wire       ctrl_branch_ne;
    wire       ctrl_jump;
    wire       ctrl_alu_src_imm;
    wire       ctrl_sign_ext;
    wire       ctrl_mem_to_reg;
    wire       ctrl_halt;
    wire [3:0] ctrl_alu_op;

    control_unit u_control_unit (
        .opcode(opcode),
        .funct(funct),
        .reg_write(ctrl_reg_write),
        .mem_read(ctrl_mem_read),
        .mem_write(ctrl_mem_write),
        .branch_eq(ctrl_branch_eq),
        .branch_ne(ctrl_branch_ne),
        .jump(ctrl_jump),
        .alu_src_imm(ctrl_alu_src_imm),
        .sign_ext(ctrl_sign_ext),
        .mem_to_reg(ctrl_mem_to_reg),
        .halt(ctrl_halt),
        .alu_op(ctrl_alu_op)
    );

    // ------------------------------------------------------------------------
    // Datapath (RegFile + ImmGen + ALU + MUX)
    // ------------------------------------------------------------------------
    wire [2:0] dst_reg = (opcode == 4'h0) ? rd : rt; // R-type -> rd, I-type -> rt

    wire [15:0] dp_rs_data;
    wire [15:0] dp_rt_data;
    wire [15:0] dp_alu_result;
    wire        dp_alu_zero;

    // reg_write is only asserted in WB state to make timing explicit.
    wire dp_reg_write = (state_q == S_WB) ? ctrl_reg_write : 1'b0;

    // mem_to_reg is only relevant for LW writeback.
    wire dp_mem_to_reg = (state_q == S_WB) ? ctrl_mem_to_reg : 1'b0;

    datapath u_datapath (
        .clk(clk),
        .rst(rst),
        .reg_write(dp_reg_write),
        .alu_src(ctrl_alu_src_imm),
        .sign_ext(ctrl_sign_ext),
        .alu_op(ctrl_alu_op),
        .mem_to_reg(dp_mem_to_reg),
        .rs_addr(rs),
        .rt_addr(rt),
        .rd_addr(dst_reg),
        .imm6(imm6),
        .mem_data_in(mem_data_q),
        .rs_data_out(dp_rs_data),
        .rt_data_out(dp_rt_data),
        .alu_result_out(dp_alu_result),
        .alu_zero_out(dp_alu_zero)
    );

    // ------------------------------------------------------------------------
    // IF/MEM requests
    // ------------------------------------------------------------------------
    assign if_req  = (state_q == S_FETCH);
    assign if_addr = pc_q;

    assign mem_req   = (state_q == S_MEM_WAIT);
    assign mem_we    = ctrl_mem_write;
    assign mem_addr  = dp_alu_result;
    assign mem_wdata = dp_rt_data;

    assign halted   = (state_q == S_HALT);
    assign debug_pc = pc_q;

    // ------------------------------------------------------------------------
    // Next-PC computation (combinational from current decoded instruction)
    // ------------------------------------------------------------------------
    wire [ADDR_WIDTH-1:0] pc_plus_1 = pc_q + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
    wire [ADDR_WIDTH-1:0] branch_off = {{(ADDR_WIDTH-6){imm6[5]}}, imm6};
    wire [ADDR_WIDTH-1:0] branch_target = pc_plus_1 + branch_off;
    wire [ADDR_WIDTH-1:0] jump_target = {{(ADDR_WIDTH-12){1'b0}}, address};

    wire branch_taken = (ctrl_branch_eq & (dp_rs_data == dp_rt_data)) |
                        (ctrl_branch_ne & (dp_rs_data != dp_rt_data));

    always @(*) begin
        if (ctrl_jump) begin
            next_pc_q = jump_target;
        end else if (branch_taken) begin
            next_pc_q = branch_target;
        end else begin
            next_pc_q = pc_plus_1;
        end
    end

    // ------------------------------------------------------------------------
    // Sequential FSM
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state_q    <= S_FETCH;
            pc_q       <= {ADDR_WIDTH{1'b0}};
            instr_q    <= {DATA_WIDTH{1'b0}};
            mem_data_q <= {DATA_WIDTH{1'b0}};
        end else begin
            case (state_q)
                S_FETCH: begin
                    if (if_ready) begin
                        instr_q <= if_rdata;
                        state_q <= S_DECODE;
                    end
                end

                S_DECODE: begin
                    // HALT stops the core immediately (no further fetch).
                    if (ctrl_halt) begin
                        state_q <= S_HALT;
                    end else if (ctrl_mem_read || ctrl_mem_write) begin
                        // Start a load/store transaction.
                        state_q <= S_MEM_WAIT;
                    end else if (ctrl_reg_write) begin
                        // ALU/ADDI type: writeback next.
                        state_q <= S_WB;
                    end else begin
                        // Branch/jump/NOP: just advance PC.
                        pc_q    <= next_pc_q;
                        state_q <= S_FETCH;
                    end
                end

                S_MEM_WAIT: begin
                    if (mem_ready) begin
                        mem_data_q <= mem_rdata;
                        if (ctrl_mem_read) begin
                            state_q <= S_WB;
                        end else begin
                            // Store completes without WB.
                            pc_q    <= next_pc_q;
                            state_q <= S_FETCH;
                        end
                    end
                end

                S_WB: begin
                    // reg_write will be asserted into datapath on this cycle.
                    pc_q    <= next_pc_q;
                    state_q <= S_FETCH;
                end

                S_HALT: begin
                    // Stay halted.
                    state_q <= S_HALT;
                end

                default: begin
                    state_q <= S_FETCH;
                end
            endcase
        end
    end

endmodule
