# Module Interface

Signal naming convention:

```text
clk, rst, req, we, addr, wdata, rdata, ready, stall, flush, valid, hit, miss
```

## Top-Level Path

```text
cpu_core
  IF logical port
  MEM logical port
    |
memory_arbiter
    |
direct_mapped_cache
    |
main_memory
```

## `cpu_cache_top`

| Port | Direction | Description |
|---|---|---|
| `clk` | input | system clock |
| `rst` | input | synchronous reset |
| `halted` | output | CPU has reached HALT |
| `debug_pc` | output | current/debug PC |

## `cpu_core`

IF logical port:

| Port | Direction | Description |
|---|---|---|
| `if_req` | output | instruction fetch request |
| `if_addr` | output | word address |
| `if_rdata` | input | fetched instruction word |
| `if_ready` | input | fetch completed |

MEM logical port:

| Port | Direction | Description |
|---|---|---|
| `mem_req` | output | load/store request |
| `mem_we` | output | 1 for store, 0 for load |
| `mem_addr` | output | word address |
| `mem_wdata` | output | store data |
| `mem_rdata` | input | load data |
| `mem_ready` | input | memory operation completed |

Debug/control:

| Port | Direction | Description |
|---|---|---|
| `halted` | output | HALT reached |
| `debug_pc` | output | PC observation |

## CPU Submodules

| Module | Main Ports | Role |
|---|---|---|
| `pc_unit` | `stall`, `flush`, `target_pc`, `pc` | word-addressed PC update |
| `instruction_decoder` | `instr`, `opcode`, `rs`, `rt`, `rd`, `funct`, `imm6`, `address` | field extraction |
| `control_unit` | `opcode`, `funct`, control outputs | decode control generation |
| `register_file` | `we`, `waddr`, `wdata`, read addresses/data | 8 x 16 register file with R0 rule |
| `immediate_generator` | `imm6`, `address12`, expanded outputs | sign/zero extension |
| `alu` | `a`, `b`, `alu_op`, `result`, `zero` | 16-bit ALU |
| `forwarding_unit` | pipeline register destinations/sources | forwarding select generation |
| `hazard_detection_unit` | cache/load/control hazard inputs | stall and flush generation |
| `if_id_reg` | `stall`, `flush`, `valid`, `pc`, `instr` | IF/ID register |
| `id_ex_reg` | data/control fields | ID/EX register |
| `ex_mem_reg` | ALU/store/control fields | EX/MEM register |
| `mem_wb_reg` | load/ALU/writeback fields | MEM/WB register |
| `mux2`, `mux3` | data inputs/select/output | operand and forwarding muxes |

## `memory_arbiter`

The arbiter accepts IF and MEM logical ports from `cpu_core` and drives one
physical cache port.

Priority:

```text
MEM request > IF request
```

Cache-side ports:

| Port | Direction | Description |
|---|---|---|
| `cache_req` | output | unified cache request |
| `cache_we` | output | write enable |
| `cache_addr` | output | word address |
| `cache_wdata` | output | write data |
| `cache_rdata` | input | read data |
| `cache_ready` | input | cache operation complete |

## `direct_mapped_cache`

CPU/arbiter-side ports:

| Port | Direction | Description |
|---|---|---|
| `req` | input | cache access request |
| `we` | input | write enable |
| `addr` | input | 16-bit word address |
| `wdata` | input | write data |
| `rdata` | output | read data |
| `ready` | output | cache access complete |
| `hit` | output | lookup hit |
| `miss` | output | miss in progress |

Memory-side ports:

| Port | Direction | Description |
|---|---|---|
| `mem_req` | output | RAM request |
| `mem_we` | output | RAM write enable |
| `mem_addr` | output | RAM word address |
| `mem_wdata` | output | RAM write data |
| `mem_rdata` | input | RAM read data |
| `mem_ready` | input | delayed RAM complete |

## `cache_controller`

FSM control placeholder for:

- lookup
- hit read
- hit write with write-through
- read miss request/wait/refill
- write miss request/wait without allocation

## `main_memory`

| Port | Direction | Description |
|---|---|---|
| `req` | input | memory request |
| `we` | input | write enable |
| `addr` | input | word address |
| `wdata` | input | write data |
| `rdata` | output | read data |
| `ready` | output | delayed completion pulse |

Only one outstanding memory request is supported.
