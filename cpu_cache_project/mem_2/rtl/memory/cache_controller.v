`include "cache_config.vh"

module cache_controller (
    input wire clk,
    input wire rst,
    input wire cpu_req,      
    input wire cpu_we,       
    output reg stall,        
    output reg cpu_ready,    
    output reg cache_we,     
    input wire cache_hit,    
    input wire mem_ready,    
    output reg mem_req,      
    output reg mem_we        
);

    reg [3:0] current_state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) current_state <= `STATE_IDLE;
        else     current_state <= next_state;
    end

    // MẠCH ĐIỀU HƯỚNG LOGIC (10 States)
    always @(*) begin
        next_state = current_state; 
        case (current_state)
            `STATE_IDLE: if (cpu_req) next_state = `STATE_LOOKUP;
            `STATE_LOOKUP: begin
                if (cache_hit) begin
                    if (cpu_we == 0) next_state = `STATE_HIT_READ;
                    else             next_state = `STATE_HIT_WRITE;
                end else begin
                    if (cpu_we == 0) next_state = `STATE_MISS_READ_REQ;
                    else             next_state = `STATE_MISS_WRITE_REQ;
                end
            end
            `STATE_HIT_READ:        next_state = `STATE_DONE; 
            `STATE_MISS_READ_REQ:   next_state = `STATE_MISS_READ_WAIT; 
            `STATE_MISS_READ_WAIT:  if (mem_ready) next_state = `STATE_REFILL;
            `STATE_REFILL:          next_state = `STATE_DONE; 
            `STATE_HIT_WRITE:       next_state = `STATE_MISS_WRITE_REQ; 
            `STATE_MISS_WRITE_REQ:  next_state = `STATE_MISS_WRITE_WAIT;
            `STATE_MISS_WRITE_WAIT: if (mem_ready) next_state = `STATE_DONE;
            `STATE_DONE:            next_state = `STATE_IDLE;
            default:                next_state = `STATE_IDLE;
        endcase
    end

    // MẠCH XUẤT TÍN HIỆU (Điều khiển Stall và RAM)
    always @(*) begin
        // Mặc định hạ tất cả tín hiệu
        stall = 0; cpu_ready = 0; cache_we = 0; mem_req = 0; mem_we = 0;
        
        case (current_state)
            `STATE_LOOKUP:         stall = 1; 
            `STATE_HIT_READ:       begin cpu_ready = 1; stall = 0; end
            `STATE_MISS_READ_REQ:  begin stall = 1; mem_req = 1; mem_we = 0; end
            
            // VÁ LỖI READ DEADLOCK: Bắt buộc phải giữ mem_req = 1
            `STATE_MISS_READ_WAIT: begin stall = 1; mem_req = 1; mem_we = 0; end 
            
            `STATE_REFILL:         begin stall = 1; cache_we = 1; end
            `STATE_HIT_WRITE:      begin stall = 1; cache_we = 1; end
            `STATE_MISS_WRITE_REQ: begin stall = 1; mem_req = 1; mem_we = 1; end
            
            // VÁ LỖI WRITE DEADLOCK: Bắt buộc phải giữ mem_req = 1 và mem_we = 1
            `STATE_MISS_WRITE_WAIT:begin stall = 1; mem_req = 1; mem_we = 1; end 
            
            `STATE_DONE:           begin cpu_ready = 1; stall = 0; end
        endcase
    end

endmodule