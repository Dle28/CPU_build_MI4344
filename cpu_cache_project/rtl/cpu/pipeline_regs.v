`timescale 1ns/1ps

// IF/ID pipeline register.
module if_id_reg #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16
) (
    input                   clk,
    input                   rst,
    input                   stall,
    input                   flush,
    input                   valid_in,
    input  [ADDR_WIDTH-1:0] pc_in,
    input  [DATA_WIDTH-1:0] instr_in,
    output reg              valid_out,
    output reg [ADDR_WIDTH-1:0] pc_out,
    output reg [DATA_WIDTH-1:0] instr_out
);

    always @(posedge clk) begin
        if (rst || flush) begin
            valid_out <= 1'b0;
            pc_out    <= {ADDR_WIDTH{1'b0}};
            instr_out <= {DATA_WIDTH{1'b0}};
        end else if (!stall) begin
            valid_out <= valid_in;
            pc_out    <= pc_in;
            instr_out <= instr_in;
        end
    end

endmodule

// ID/EX pipeline register. ctrl_* fields are intentionally explicit to make
// waveform debugging easier than with a packed opaque control bus.
module id_ex_reg #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16
) (
    input                   clk,
    input                   rst,
    input                   stall,
    input                   flush,
    input                   valid_in,
    input  [ADDR_WIDTH-1:0] pc_in,
    input  [DATA_WIDTH-1:0] rs_data_in,
    input  [DATA_WIDTH-1:0] rt_data_in,
    input  [DATA_WIDTH-1:0] imm_in,
    input  [2:0]            rs_in,
    input  [2:0]            rt_in,
    input  [2:0]            rd_in,
    input  [2:0]            alu_op_in,
    input                   reg_write_in,
    input                   mem_read_in,
    input                   mem_write_in,
    input                   branch_eq_in,
    input                   branch_ne_in,
    input                   jump_in,
    input                   alu_src_imm_in,
    input                   mem_to_reg_in,
    input                   halt_in,
    output reg              valid_out,
    output reg [ADDR_WIDTH-1:0] pc_out,
    output reg [DATA_WIDTH-1:0] rs_data_out,
    output reg [DATA_WIDTH-1:0] rt_data_out,
    output reg [DATA_WIDTH-1:0] imm_out,
    output reg [2:0]        rs_out,
    output reg [2:0]        rt_out,
    output reg [2:0]        rd_out,
    output reg [2:0]        alu_op_out,
    output reg              reg_write_out,
    output reg              mem_read_out,
    output reg              mem_write_out,
    output reg              branch_eq_out,
    output reg              branch_ne_out,
    output reg              jump_out,
    output reg              alu_src_imm_out,
    output reg              mem_to_reg_out,
    output reg              halt_out
);

    always @(posedge clk) begin
        if (rst || flush) begin
            valid_out       <= 1'b0;
            pc_out          <= {ADDR_WIDTH{1'b0}};
            rs_data_out     <= {DATA_WIDTH{1'b0}};
            rt_data_out     <= {DATA_WIDTH{1'b0}};
            imm_out         <= {DATA_WIDTH{1'b0}};
            rs_out          <= 3'd0;
            rt_out          <= 3'd0;
            rd_out          <= 3'd0;
            alu_op_out      <= 3'd0;
            reg_write_out   <= 1'b0;
            mem_read_out    <= 1'b0;
            mem_write_out   <= 1'b0;
            branch_eq_out   <= 1'b0;
            branch_ne_out   <= 1'b0;
            jump_out        <= 1'b0;
            alu_src_imm_out <= 1'b0;
            mem_to_reg_out  <= 1'b0;
            halt_out        <= 1'b0;
        end else if (!stall) begin
            valid_out       <= valid_in;
            pc_out          <= pc_in;
            rs_data_out     <= rs_data_in;
            rt_data_out     <= rt_data_in;
            imm_out         <= imm_in;
            rs_out          <= rs_in;
            rt_out          <= rt_in;
            rd_out          <= rd_in;
            alu_op_out      <= alu_op_in;
            reg_write_out   <= reg_write_in;
            mem_read_out    <= mem_read_in;
            mem_write_out   <= mem_write_in;
            branch_eq_out   <= branch_eq_in;
            branch_ne_out   <= branch_ne_in;
            jump_out        <= jump_in;
            alu_src_imm_out <= alu_src_imm_in;
            mem_to_reg_out  <= mem_to_reg_in;
            halt_out        <= halt_in;
        end
    end

endmodule

// EX/MEM pipeline register.
module ex_mem_reg #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16
) (
    input                   clk,
    input                   rst,
    input                   stall,
    input                   flush,
    input                   valid_in,
    input  [DATA_WIDTH-1:0] alu_result_in,
    input  [DATA_WIDTH-1:0] store_data_in,
    input  [ADDR_WIDTH-1:0] branch_target_in,
    input  [2:0]            rd_in,
    input                   branch_taken_in,
    input                   reg_write_in,
    input                   mem_read_in,
    input                   mem_write_in,
    input                   mem_to_reg_in,
    input                   halt_in,
    output reg              valid_out,
    output reg [DATA_WIDTH-1:0] alu_result_out,
    output reg [DATA_WIDTH-1:0] store_data_out,
    output reg [ADDR_WIDTH-1:0] branch_target_out,
    output reg [2:0]        rd_out,
    output reg              branch_taken_out,
    output reg              reg_write_out,
    output reg              mem_read_out,
    output reg              mem_write_out,
    output reg              mem_to_reg_out,
    output reg              halt_out
);

    always @(posedge clk) begin
        if (rst || flush) begin
            valid_out         <= 1'b0;
            alu_result_out    <= {DATA_WIDTH{1'b0}};
            store_data_out    <= {DATA_WIDTH{1'b0}};
            branch_target_out <= {ADDR_WIDTH{1'b0}};
            rd_out            <= 3'd0;
            branch_taken_out  <= 1'b0;
            reg_write_out     <= 1'b0;
            mem_read_out      <= 1'b0;
            mem_write_out     <= 1'b0;
            mem_to_reg_out    <= 1'b0;
            halt_out          <= 1'b0;
        end else if (!stall) begin
            valid_out         <= valid_in;
            alu_result_out    <= alu_result_in;
            store_data_out    <= store_data_in;
            branch_target_out <= branch_target_in;
            rd_out            <= rd_in;
            branch_taken_out  <= branch_taken_in;
            reg_write_out     <= reg_write_in;
            mem_read_out      <= mem_read_in;
            mem_write_out     <= mem_write_in;
            mem_to_reg_out    <= mem_to_reg_in;
            halt_out          <= halt_in;
        end
    end

endmodule

// MEM/WB pipeline register.
module mem_wb_reg #(
    parameter DATA_WIDTH = 16
) (
    input                   clk,
    input                   rst,
    input                   stall,
    input                   flush,
    input                   valid_in,
    input  [DATA_WIDTH-1:0] mem_rdata_in,
    input  [DATA_WIDTH-1:0] alu_result_in,
    input  [2:0]            rd_in,
    input                   reg_write_in,
    input                   mem_to_reg_in,
    input                   halt_in,
    output reg              valid_out,
    output reg [DATA_WIDTH-1:0] mem_rdata_out,
    output reg [DATA_WIDTH-1:0] alu_result_out,
    output reg [2:0]        rd_out,
    output reg              reg_write_out,
    output reg              mem_to_reg_out,
    output reg              halt_out
);

    always @(posedge clk) begin
        if (rst || flush) begin
            valid_out      <= 1'b0;
            mem_rdata_out  <= {DATA_WIDTH{1'b0}};
            alu_result_out <= {DATA_WIDTH{1'b0}};
            rd_out         <= 3'd0;
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            halt_out       <= 1'b0;
        end else if (!stall) begin
            valid_out      <= valid_in;
            mem_rdata_out  <= mem_rdata_in;
            alu_result_out <= alu_result_in;
            rd_out         <= rd_in;
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            halt_out       <= halt_in;
        end
    end

endmodule
