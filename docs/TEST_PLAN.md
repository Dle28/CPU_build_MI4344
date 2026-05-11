# Test Plan

## Module Tests

| Testbench | Purpose |
|---|---|
| `alu_tb.v` | Verify ADD, SUB, AND, OR, XOR, SLT, SLL, SRL |
| `register_file_tb.v` | Verify reads, writes, reset, ignored writes to R0 |
| `control_unit_tb.v` | Verify opcode/funct control signals |
| `main_memory_tb.v` | Verify artificial delay and one outstanding request |
| `cache_tb.v` | Verify hit, read miss/refill, write-through, no-write-allocate |
| `memory_arbiter_tb.v` | Verify MEM priority over IF |
| `cpu_core_tb.v` | Verify pipeline behavior without full memory stress |
| `cpu_cache_tb.v` | Verify full integration |

## Integration Tests

| Program | Expected Focus |
|---|---|
| `program_01_arithmetic.asm` | ALU and register writeback |
| `program_02_load_store.asm` | LW/SW through memory path |
| `program_03_cache_hit_miss.asm` | first access miss, repeated access hit |
| `program_04_hazard.asm` | load-use stall and bubble |
| `program_05_branch.asm` | BEQ taken and wrong-path flush |
| `program_06_full_demo.asm` | combined final demonstration |

## Waveform Signals To Inspect

- `debug_pc`
- IF/ID, ID/EX, EX/MEM, MEM/WB `valid`
- `stall`
- `flush`
- forwarding selectors
- `cache_req`
- `cache_ready`
- `hit`
- `miss`
- `mem_req`
- `mem_ready`
- register writeback address/data

## Minimum Pass Criteria

- `R0` always reads zero.
- PC increments by one word.
- Wrong-path instruction after taken branch does not commit.
- Load-use pair inserts exactly the required bubble.
- Cache miss globally stalls the pipeline.
- Direct-mapped conflict behavior is observable.
- Full demo reaches HALT.
