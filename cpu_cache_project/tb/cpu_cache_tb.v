
`timescale 1ns/1ps

module cpu_cache_tb;

	reg clk;
	reg rst;
	wire halted;
	wire [15:0] debug_pc;

	// Use a short memory delay for faster simulation.
	cpu_cache_top #(
		.MEMORY_DELAY(2),
		.MEM_INIT_FILE("mem/test_arithmetic.mem")
	) u_top (
		.clk(clk),
		.rst(rst),
		.halted(halted),
		.debug_pc(debug_pc)
	);

	// Clock
	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk;
	end

	// Reset
	initial begin
		rst = 1'b1;
		repeat (3) @(posedge clk);
		rst = 1'b0;
	end

	integer cycles;

	// Run + check
	initial begin
		cycles = 0;
		$display("cpu_cache_tb: start");

		// Wait for reset to complete and for state to settle.
		wait (rst == 1'b0);
		repeat (2) @(posedge clk);

		// Timeout safety.
		while (halted !== 1'b1 && cycles < 2000) begin
			@(posedge clk);
			cycles = cycles + 1;
		end

		if (halted !== 1'b1) begin
			$display("cpu_cache_tb: FAIL timeout (pc=%h)", debug_pc);
			$fatal(1);
		end

		// Hierarchical peek into register file (debug-only in TB).
		if (u_top.u_cpu_core.u_datapath.u_regfile.registers[1] !== 16'h0005) begin
			$display("cpu_cache_tb: FAIL R1 got=%h exp=0005", u_top.u_cpu_core.u_datapath.u_regfile.registers[1]);
			$fatal(1);
		end
		if (u_top.u_cpu_core.u_datapath.u_regfile.registers[2] !== 16'h0003) begin
			$display("cpu_cache_tb: FAIL R2 got=%h exp=0003", u_top.u_cpu_core.u_datapath.u_regfile.registers[2]);
			$fatal(1);
		end
		if (u_top.u_cpu_core.u_datapath.u_regfile.registers[3] !== 16'h0008) begin
			$display("cpu_cache_tb: FAIL R3 got=%h exp=0008", u_top.u_cpu_core.u_datapath.u_regfile.registers[3]);
			$fatal(1);
		end
		if (u_top.u_cpu_core.u_datapath.u_regfile.registers[4] !== 16'h0003) begin
			$display("cpu_cache_tb: FAIL R4 got=%h exp=0003", u_top.u_cpu_core.u_datapath.u_regfile.registers[4]);
			$fatal(1);
		end

		$display("cpu_cache_tb: PASS (cycles=%0d, pc=%h)", cycles, debug_pc);
		$finish;
	end

endmodule

