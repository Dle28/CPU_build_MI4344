# Giao diện Module

Quy ước đặt tên tín hiệu:

```text
clk, rst, req, we, addr, wdata, rdata, ready, stall, flush, valid, hit, miss
```

## Đường đi Top-Level

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

| Cổng | Hướng | Mô tả |
|---|---|---|
| `clk` | input | clock hệ thống |
| `rst` | input | reset đồng bộ |
| `halted` | output | CPU đã gặp HALT |
| `debug_pc` | output | PC hiện tại (debug) |

## `cpu_core`

IF logical port:

| Cổng | Hướng | Mô tả |
|---|---|---|
| `if_req` | output | yêu cầu nạp lệnh |
| `if_addr` | output | địa chỉ word |
| `if_rdata` | input | word lệnh đọc về |
| `if_ready` | input | hoàn tất nạp lệnh |

MEM logical port:

| Cổng | Hướng | Mô tả |
|---|---|---|
| `mem_req` | output | yêu cầu load/store |
| `mem_we` | output | 1: store, 0: load |
| `mem_addr` | output | địa chỉ word |
| `mem_wdata` | output | dữ liệu store |
| `mem_rdata` | input | dữ liệu load |
| `mem_ready` | input | hoàn tất thao tác bộ nhớ |

Debug/control:

| Cổng | Hướng | Mô tả |
|---|---|---|
| `halted` | output | đã gặp HALT |
| `debug_pc` | output | quan sát PC |

## Các module con CPU

| Module | Cổng chính | Vai trò |
|---|---|---|
| `instruction_decoder` | `instr` → `opcode/rs/rt/rd/funct/imm6/address` | tách trường lệnh |
| `control_unit` | `opcode/funct` → control | sinh tín hiệu điều khiển |
| `register_file` | `rs/rt` read async, `rd` write sync | regfile 8 x 16 với luật R0 |
| `immediate_generator` | `imm6`, `sign_ext` → `imm16` | sign/zero extension |
| `alu` | `a`, `b`, `alu_op[3:0]` | ALU 16-bit theo `cpu_defines.vh` |
| `mux2to1` | `d0/d1/sel` | MUX 2-1 dùng cho ALUSrc, MemToReg |
| `mux3to1` | `d0/d1/d2/sel[1:0]` | MUX 3-1 dùng cho forwarding |
| `pipeline_regs` | `if_id_reg`, `id_ex_reg`, ... | thanh ghi pipeline (mục tiêu) |
| `forwarding_unit` | selector forward | chống data hazard (mục tiêu) |
| `hazard_detection_unit` | stall/flush | chống hazard (mục tiêu) |

Lưu ý chuẩn hoá:

- `alu_op` là 4-bit và khớp bảng mã trong `include/cpu_defines.vh`.

## `memory_arbiter`

Arbiter nhận IF + MEM logical ports từ `cpu_core` và lái 1 cổng cache vật lý.

Ưu tiên:

```text
MEM request > IF request
```

Cổng phía cache:

| Cổng | Hướng | Mô tả |
|---|---|---|
| `cache_req` | output | unified cache request |
| `cache_we` | output | write enable |
| `cache_addr` | output | địa chỉ word |
| `cache_wdata` | output | dữ liệu ghi |
| `cache_rdata` | input | dữ liệu đọc |
| `cache_ready` | input | hoàn tất thao tác cache |

## `direct_mapped_cache`

Cổng phía CPU/arbiter:

| Cổng | Hướng | Mô tả |
|---|---|---|
| `req` | input | yêu cầu truy cập cache |
| `we` | input | write enable |
| `addr` | input | địa chỉ word 16-bit |
| `wdata` | input | dữ liệu ghi |
| `rdata` | output | dữ liệu đọc |
| `ready` | output | hoàn tất |
| `hit` | output | hit |
| `miss` | output | miss |

Cổng phía main memory:

| Cổng | Hướng | Mô tả |
|---|---|---|
| `mem_req` | output | yêu cầu RAM |
| `mem_we` | output | write enable RAM |
| `mem_addr` | output | địa chỉ RAM |
| `mem_wdata` | output | dữ liệu ghi RAM |
| `mem_rdata` | input | dữ liệu đọc RAM |
| `mem_ready` | input | hoàn tất RAM (có delay) |

Lưu ý: bản hiện tại của `direct_mapped_cache` vẫn đang pass-through (chưa có tag compare + refill + write policy hoàn chỉnh).

## `main_memory`

| Cổng | Hướng | Mô tả |
|---|---|---|
| `req` | input | yêu cầu truy cập |
| `we` | input | write enable |
| `addr` | input | địa chỉ word |
| `wdata` | input | dữ liệu ghi |
| `rdata` | output | dữ liệu đọc |
| `ready` | output | xung hoàn tất (sau delay) |

Chỉ hỗ trợ tối đa 1 yêu cầu outstanding.
