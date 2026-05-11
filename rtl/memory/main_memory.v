`timescale 1ns/1ps

// Delayed 16-bit word-addressed main memory.
// One outstanding request is supported.
module main_memory #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16,
    parameter MEM_DEPTH = 65536,
    parameter DELAY_CYCLES = 5,
    parameter INIT_FILE = ""
) (
    input                   clk,
    input                   rst,
    input                   req,
    input                   we,
    input  [ADDR_WIDTH-1:0] addr,
    input  [DATA_WIDTH-1:0] wdata,
    output reg [DATA_WIDTH-1:0] rdata,
    output reg              ready
);

    reg [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];
    reg                  busy;
    reg                  latched_we;
    reg [ADDR_WIDTH-1:0] latched_addr;
    reg [DATA_WIDTH-1:0] latched_wdata;
    reg [15:0]           delay_count;

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, memory);
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            ready         <= 1'b0;
            rdata         <= {DATA_WIDTH{1'b0}};
            busy          <= 1'b0;
            latched_we    <= 1'b0;
            latched_addr  <= {ADDR_WIDTH{1'b0}};
            latched_wdata <= {DATA_WIDTH{1'b0}};
            delay_count   <= 16'd0;
        end else begin
            ready <= 1'b0;

            if (!busy && req) begin
                busy          <= 1'b1;
                latched_we    <= we;
                latched_addr  <= addr;
                latched_wdata <= wdata;
                delay_count   <= DELAY_CYCLES[15:0];
            end else if (busy) begin
                if (delay_count == 16'd0) begin
                    if (latched_we) begin
                        memory[latched_addr] <= latched_wdata;
                        rdata <= latched_wdata;
                    end else begin
                        rdata <= memory[latched_addr];
                    end
                    ready <= 1'b1;
                    busy  <= 1'b0;
                end else begin
                    delay_count <= delay_count - 16'd1;
                end
            end
        end
    end

endmodule
