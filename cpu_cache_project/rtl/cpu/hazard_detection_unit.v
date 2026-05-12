`timescale 1ns/1ps

// Hazard/stall/flush control for the simple 5-stage pipeline.
// Rules locked for the project:
//   cache miss      -> global stall
//   load-use hazard -> freeze PC and IF/ID, flush ID/EX bubble
//   branch/jump     -> flush IF/ID and ID/EX
module hazard_detection_unit (
    input        cache_ready,
    input  [2:0] if_id_rs,
    input  [2:0] if_id_rt,
    input  [2:0] id_ex_rt,
    input        id_ex_mem_read,
    input        branch_taken,
    input        jump_taken,
    output       global_stall,
    output       stall_pc,
    output       stall_if_id,
    output       flush_if_id,
    output       flush_id_ex
);

    wire load_use_stall;
    wire control_taken;

    assign global_stall  = ~cache_ready;
    assign load_use_stall = id_ex_mem_read &&
                            (id_ex_rt != 3'd0) &&
                            ((id_ex_rt == if_id_rs) || (id_ex_rt == if_id_rt));
    assign control_taken = branch_taken | jump_taken;

    assign stall_pc    = global_stall | load_use_stall;
    assign stall_if_id = global_stall | load_use_stall;
    assign flush_if_id = control_taken;
    assign flush_id_ex = control_taken | load_use_stall;

endmodule
