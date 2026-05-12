`timescale 1ns/1ps

// Cache controller FSM skeleton for the unified direct-mapped cache.
// The direct_mapped_cache module owns tag/data/valid arrays; this controller
// will eventually sequence lookup, refill, write-through, and no-write-allocate.
module cache_controller (
    input        clk,
    input        rst,
    input        req,
    input        we,
    input        hit,
    input        mem_ready,
    output reg   ready,
    output reg   mem_req,
    output reg   mem_we,
    output reg   refill,
    output reg   miss,
    output reg [3:0] state
);

    localparam IDLE            = 4'd0;
    localparam LOOKUP          = 4'd1;
    localparam HIT_READ        = 4'd2;
    localparam HIT_WRITE       = 4'd3;
    localparam MISS_READ_REQ   = 4'd4;
    localparam MISS_READ_WAIT  = 4'd5;
    localparam REFILL          = 4'd6;
    localparam MISS_WRITE_REQ  = 4'd7;
    localparam MISS_WRITE_WAIT = 4'd8;
    localparam DONE            = 4'd9;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (req) begin
                        state <= LOOKUP;
                    end
                end
                LOOKUP: begin
                    if (hit && !we) begin
                        state <= HIT_READ;
                    end else if (hit && we) begin
                        state <= HIT_WRITE;
                    end else if (!hit && !we) begin
                        state <= MISS_READ_REQ;
                    end else begin
                        state <= MISS_WRITE_REQ;
                    end
                end
                HIT_READ: begin
                    state <= DONE;
                end
                HIT_WRITE: begin
                    state <= MISS_WRITE_WAIT;
                end
                MISS_READ_REQ: begin
                    state <= MISS_READ_WAIT;
                end
                MISS_READ_WAIT: begin
                    if (mem_ready) begin
                        state <= REFILL;
                    end
                end
                REFILL: begin
                    state <= DONE;
                end
                MISS_WRITE_REQ: begin
                    state <= MISS_WRITE_WAIT;
                end
                MISS_WRITE_WAIT: begin
                    if (mem_ready) begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    always @(*) begin
        ready   = 1'b0;
        mem_req = 1'b0;
        mem_we  = 1'b0;
        refill  = 1'b0;
        miss    = 1'b0;

        case (state)
            HIT_READ: begin
                ready = 1'b1;
            end
            HIT_WRITE: begin
                mem_req = 1'b1;
                mem_we  = 1'b1;
            end
            MISS_READ_REQ,
            MISS_READ_WAIT: begin
                mem_req = 1'b1;
                mem_we  = 1'b0;
                miss    = 1'b1;
            end
            REFILL: begin
                refill = 1'b1;
            end
            MISS_WRITE_REQ,
            MISS_WRITE_WAIT: begin
                mem_req = 1'b1;
                mem_we  = 1'b1;
                miss    = 1'b1;
            end
            DONE: begin
                ready = 1'b1;
            end
            default: begin
            end
        endcase
    end

endmodule
