# ModelSim/Questa placeholder compile/run script.
# TODO: update library setup and selected testbench as implementation grows.

vlib work
vlog ../rtl/cpu/*.v
vlog ../rtl/memory/*.v
vlog ../rtl/top/*.v
vlog ../tb/cpu_cache_tb.v
vsim work.cpu_cache_tb
do wave.do
run -all
