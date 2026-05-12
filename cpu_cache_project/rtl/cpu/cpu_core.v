`timescale 1ns/1ps

// 16-bit 5-stage CPU core placeholder.
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

    reg [ADDR_WIDTH-1:0] pc_q;
    reg                  halted_q;

    // TODO: replace this fetch-only placeholder with IF/ID/EX/MEM/WB pipeline logic.
    // TODO: integrate hazard_detection_unit, forwarding_unit, and pipeline_regs.
    // TODO: generate real MEM-stage load/store requests from decoded instructions.
    assign if_req    = ~halted_q;
    assign if_addr   = pc_q;
    assign mem_req   = 1'b0;
    assign mem_we    = 1'b0;
    assign mem_addr  = {ADDR_WIDTH{1'b0}};
    assign mem_wdata = {DATA_WIDTH{1'b0}};
    assign halted    = halted_q;
    assign debug_pc  = pc_q;

    always @(posedge clk) begin
        if (rst) begin
            pc_q     <= {ADDR_WIDTH{1'b0}};
            halted_q <= 1'b0;
        end else begin
            // Placeholder behavior: advance PC only when instruction fetch completes.
            if (if_ready && ~halted_q) begin
                pc_q <= pc_q + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
            end

            // TODO: HALT must come from decoded opcode 4'hF in the real pipeline.
            if (if_ready && if_rdata[15:12] == 4'hF) begin
                halted_q <= 1'b1;
            end
        end
    end

    // Keep unused inputs visible to lint until real pipeline integration.
    wire [DATA_WIDTH-1:0] unused_mem_rdata = mem_rdata;
    wire                  unused_mem_ready = mem_ready;

endmodule
