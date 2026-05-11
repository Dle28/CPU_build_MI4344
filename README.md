# CPU Cache Project

University-level Verilog project for a compact 16-bit pipelined CPU with a
unified direct-mapped cache and delayed main memory.

## Final Architecture Decision

- 16-bit CPU
- Fixed 16-bit instruction width
- 8 registers: `R0` to `R7`
- `R0` is hardwired to zero
- Word-addressed memory
- 5-stage pipeline: IF -> ID -> EX -> MEM -> WB
- Von Neumann architecture
- Unified direct-mapped cache
- Cache size: 16 lines
- Cache line size: 1 word
- Cache write policy: write-through
- Cache write miss policy: no-write-allocate
- Main memory has artificial access delay
- Branch resolved in EX
- Global stall on cache miss
- Load-use hazard handled with stall + bubble
- Data hazards handled with forwarding
- Branch/jump handled with flush
- `.asm` programs assembled to `.mem` by `tools/assembler.py`

## Folder Structure

```text
rtl/cpu/      CPU core and pipeline support modules
rtl/memory/   arbiter, cache, cache controller, delayed RAM
rtl/top/      top-level integration
tb/           Verilog testbenches
asm/          assembly test programs
mem/          generated or placeholder memory images
tools/        Python assembler
sim/          simulator scripts
docs/         architecture, ISA, interfaces, cache FSM, test plan, report
```

## Future Simulation

Example Icarus Verilog flow after implementation grows:

```bat
sim\run.bat
```

Example assembler usage:

```bat
python tools\assembler.py asm\program_01_arithmetic.asm mem\program_01_arithmetic.mem
```

## Implementation Roadmap

1. `alu.v`
2. `register_file.v`
3. `immediate_generator.v`
4. `instruction_decoder.v`
5. `control_unit.v`
6. `pc_unit.v`
7. `pipeline_regs.v`
8. `main_memory.v`
9. `direct_mapped_cache.v`
10. `memory_arbiter.v`
11. `hazard_detection_unit.v`
12. `forwarding_unit.v`
13. `cpu_core.v`
14. `cpu_cache_top.v`
15. testbenches
16. `assembler.py`

## Minimum Viable Product

The MVP is complete when:

- arithmetic program reaches HALT with correct register results
- load/store program reads back stored data
- cache hit/miss is visible in waveform
- load-use stall is visible in waveform
- taken branch flushes wrong-path instruction
- full demo program reaches HALT

## Locked Non-Goals

Do not add:

- byte addressing
- `LI`
- cache line offset
- write-back cache
- branch prediction
- superscalar or out-of-order execution
- non-blocking cache
- multiple outstanding memory requests
