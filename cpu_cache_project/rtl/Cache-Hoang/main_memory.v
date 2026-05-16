`timescale 1ns / 1ps

module main_memory (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] addr,
    input  wire [15:0] wdata,
    input  wire        mem_read,
    input  wire        mem_write,
    output reg  [15:0] rdata,
    output reg         mem_ready
);

    reg [15:0] ram [0:1023]; // RAM 1024 words
    localparam DELAY_CYCLES = 3; 
    reg [2:0] delay_counter;
    reg active;

    // Khởi tạo một vài giá trị cho RAM để test
    initial begin
        ram[10] = 16'hAAAA; // Tại địa chỉ 10 có data 0xAAAA
        ram[20] = 16'hBBBB; // Tại địa chỉ 20 có data 0xBBBB
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_ready     <= 1'b0;
            delay_counter <= 3'd0;
            active        <= 1'b0;
            rdata         <= 16'd0;
        end else begin
            if ((mem_read || mem_write) && !active) begin
                active        <= 1'b1;
                delay_counter <= DELAY_CYCLES;
                mem_ready     <= 1'b0;
            end else if (active) begin
                if (delay_counter > 0) begin
                    delay_counter <= delay_counter - 1;
                end else begin
                    mem_ready <= 1'b1;
                    active    <= 1'b0;
                    if (mem_read)       rdata <= ram[addr[9:0]];
                    else if (mem_write) ram[addr[9:0]] <= wdata;
                end
            end else begin
                mem_ready <= 1'b0;
            end
        end
    end
endmodule