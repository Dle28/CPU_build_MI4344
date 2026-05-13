`timescale 1ns/1ps

// tick: đã xong

module register_file_tb;

    reg         clk;
    reg         rst;
    reg  [2:0]  rs_addr;
    reg  [2:0]  rt_addr;
    reg  [2:0]  rd_addr;
    reg  [15:0] rd_wdata;
    reg         reg_write;
    wire [15:0] rs_data;
    wire [15:0] rt_data;

    register_file u_register_file (
        .clk(clk),
        .rst(rst),
        .rs_addr(rs_addr),
        .rt_addr(rt_addr),
        .rd_addr(rd_addr),
        .rd_wdata(rd_wdata),
        .reg_write(reg_write),
        .rs_data(rs_data),
        .rt_data(rt_data)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("register_file_tb: start");
        rst = 1'b1;
        rs_addr = 3'd0;
        rt_addr = 3'd1;
        rd_addr = 3'd0;
        rd_wdata = 16'h0000;
        reg_write = 1'b0;
        #20;

        // Release reset; R0 must be 0
        rst = 1'b0;
        #1;
        if (rs_data !== 16'h0000) begin
            $display("register_file_tb: FAIL reset/R0 read got %h", rs_data);
            $fatal(1);
        end

        // Write R1 = 0x00AA
        reg_write = 1'b1;
        rd_addr   = 3'd1;
        rd_wdata  = 16'h00AA;
        @(posedge clk);
        #1;
        reg_write = 1'b0;

        // Async readback
        rs_addr = 3'd1;
        #1;
        if (rs_data !== 16'h00AA) begin
            $display("register_file_tb: FAIL R1 read got %h exp 00AA", rs_data);
            $fatal(1);
        end

        // Attempt write to R0 (must be ignored)
        reg_write = 1'b1;
        rd_addr   = 3'd0;
        rd_wdata  = 16'hFFFF;
        @(posedge clk);
        #1;
        reg_write = 1'b0;

        rs_addr = 3'd0;
        #1;
        if (rs_data !== 16'h0000) begin
            $display("register_file_tb: FAIL R0 overwrite got %h exp 0000", rs_data);
            $fatal(1);
        end

        // Write R7 and read both ports
        reg_write = 1'b1;
        rd_addr   = 3'd7;
        rd_wdata  = 16'hBEEF;
        @(posedge clk);
        #1;
        reg_write = 1'b0;

        rs_addr = 3'd7;
        rt_addr = 3'd1;
        #1;
        if (rs_data !== 16'hBEEF || rt_data !== 16'h00AA) begin
            $display("register_file_tb: FAIL dual read got rs=%h rt=%h", rs_data, rt_data);
            $fatal(1);
        end

        $display("register_file_tb: PASS");
        $finish;
    end

endmodule
