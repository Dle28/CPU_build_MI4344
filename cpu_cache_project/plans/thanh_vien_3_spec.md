# Thành viên 3 — Control Unit & System Integrator
**Nguyễn Nhật Phong**

---

## Danh sách file phải nộp

```
rtl/cpu/instruction_decoder.v
rtl/cpu/control_unit.v
rtl/cpu/pc_unit.v
rtl/cpu/pipeline_regs.v
rtl/cpu/hazard_detection_unit.v
rtl/cpu/forwarding_unit.v
rtl/cpu/cpu_core.v
rtl/top/cpu_cache_top.v
```

---

## Header file

Mọi file `.v` đều phải có dòng đầu:

```verilog
`include "cpu_defines.vh"
```

Các macro cần dùng đã định nghĩa trong `cpu_defines.vh`:
- `DATA_WIDTH` = 16
- `REG_ADDR_WIDTH` = 3
- `ALU_ADD/SUB/AND/OR/XOR/SLT/SLL/SRL`
- `EXT_ZERO`, `EXT_SIGN`

---

## 1. instruction_decoder.v

### Interface cứng

```verilog
module instruction_decoder (
    input  wire [15:0] instr,
    output wire [3:0]  opcode,
    output wire [2:0]  rs,
    output wire [2:0]  rt,
    output wire [2:0]  rd,
    output wire [2:0]  funct,
    output wire [5:0]  imm6,
    output wire [11:0] jump_addr
);
```

### Quy tắc cứng — bit mapping

| Output | Bits |
|--------|------|
| `opcode` | `instr[15:12]` |
| `rs` | `instr[11:9]` |
| `rt` | `instr[8:6]` |
| `rd` | `instr[5:3]` |
| `funct` | `instr[2:0]` |
| `imm6` | `instr[5:0]` |
| `jump_addr` | `instr[11:0]` |

Toàn bộ là `assign` tổ hợp, không có sequential logic.

---

## 2. control_unit.v

### Interface cứng

```verilog
module control_unit (
    input  wire [3:0] opcode,
    input  wire [2:0] funct,
    output reg        reg_dst,
    output reg        alu_src,
    output reg        mem_to_reg,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        branch,
    output reg        branch_ne,
    output reg        jump,
    output reg [3:0]  alu_op,
    output reg        halt
);
```

### Bảng opcode/funct cứng (phải khớp với assembler.py)

| Lệnh | Opcode | Funct |
|------|-------:|------:|
| R-type | `0x0` | tùy funct |
| ADD | `0x0` | `0x0` |
| SUB | `0x0` | `0x1` |
| AND | `0x0` | `0x2` |
| OR  | `0x0` | `0x3` |
| SLT | `0x0` | `0x4` |
| ADDI | `0x1` | — |
| LW   | `0x2` | — |
| SW   | `0x3` | — |
| BEQ  | `0x4` | — |
| BNE  | `0x5` | — |
| J    | `0x6` | — |
| HALT | `0xF` | — |
| NOP  | `0x0` | `0x0` (= `16'h0000`) |

### Bảng control signal cứng

| Lệnh | `reg_write` | `mem_read` | `mem_write` | `alu_src` | `mem_to_reg` | `branch` | `branch_ne` | `jump` | `halt` |
|------|:-----------:|:----------:|:-----------:|:---------:|:------------:|:--------:|:-----------:|:------:|:------:|
| ADD/SUB/AND/OR/SLT | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| ADDI | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| LW   | 1 | 1 | 0 | 1 | 1 | 0 | 0 | 0 | 0 |
| SW   | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| BEQ  | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
| BNE  | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| J    | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| HALT | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| NOP  | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### ALU op mapping cho R-type (decode từ funct)

| funct | alu_op |
|------:|--------|
| `0x0` | `ALU_ADD` |
| `0x1` | `ALU_SUB` |
| `0x2` | `ALU_AND` |
| `0x3` | `ALU_OR`  |
| `0x4` | `ALU_SLT` |

Với ADDI, LW, SW: `alu_op = ALU_ADD` (tính địa chỉ).
Với BEQ, BNE: `alu_op = ALU_SUB` (so sánh bằng cờ zero).

---

## 3. pc_unit.v

### Interface cứng

```verilog
module pc_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,
    input  wire        branch_taken,
    input  wire        jump,
    input  wire [15:0] branch_target,
    input  wire [15:0] jump_target,
    output reg  [15:0] pc_out,
    output wire [15:0] pc_next
);
```

### Quy tắc ưu tiên cứng (theo thứ tự)

1. `rst` → `pc_out = 0`
2. `stall` → giữ nguyên `pc_out` (không tăng)
3. `jump` → `pc_out = jump_target`
4. `branch_taken` → `pc_out = branch_target`
5. mặc định → `pc_out = pc_out + 1`

> **Lưu ý:** PC tăng theo đơn vị **word** (+1), không phải +2, vì địa chỉ là word address 16-bit.

`pc_next` là wire tổ hợp, luôn bằng `pc_out + 1`, dùng để tính địa chỉ lệnh tiếp theo trước khi quyết định.

---

## 4. pipeline_regs.v

Có thể gom tất cả 4 register vào một file hoặc tách riêng.

### Quy tắc chung cho tất cả pipeline register

- Reset về **NOP** (`16'h0000`) và các control signal = 0.
- `stall = 1` → giữ nguyên giá trị hiện tại (không cập nhật).
- `flush = 1` → ghi NOP/0 vào (flush ưu tiên hơn stall nếu cả hai cùng lên).
- Ghi theo `posedge clk`.

### IF/ID Register

```verilog
module pipeline_reg_if_id (
    input  wire        clk, rst, stall, flush,
    input  wire [15:0] pc_in,
    input  wire [15:0] instr_in,
    output reg  [15:0] pc_out,
    output reg  [15:0] instr_out
);
```

Flush → `instr_out = 16'h0000` (NOP).

### ID/EX Register

Phải lưu tối thiểu các trường sau:

```
pc, rs_data, rt_data, imm16
rs [2:0], rt [2:0], rd [2:0]
alu_op [3:0]
reg_write, mem_read, mem_write, mem_to_reg
alu_src, reg_dst
branch, branch_ne, jump, halt
```

Flush → tất cả control signal = 0, data = 0.

### EX/MEM Register

Phải lưu tối thiểu:

```
alu_result [15:0], rt_data [15:0]
write_reg [2:0]
zero, branch_target [15:0]
reg_write, mem_read, mem_write, mem_to_reg
branch, branch_ne, jump, halt
```

### MEM/WB Register

Phải lưu tối thiểu:

```
mem_data [15:0], alu_result [15:0]
write_reg [2:0]
reg_write, mem_to_reg, halt
```

---

## 5. hazard_detection_unit.v

### Interface cứng

```verilog
module hazard_detection_unit (
    input  wire [2:0] id_rs,
    input  wire [2:0] id_rt,
    input  wire [2:0] ex_rt,
    input  wire       ex_mem_read,
    input  wire       cache_stall,
    input  wire       if_mem_conflict,
    input  wire       branch_taken,
    input  wire       jump,
    output wire       pc_stall,
    output wire       if_id_stall,
    output wire       id_ex_flush,
    output wire       if_id_flush
);
```

### Quy tắc phát hiện hazard cứng

**Load-use hazard:**
```
condition = ex_mem_read && ((ex_rt == id_rs) || (ex_rt == id_rt))
```
Khi phát hiện:
- `pc_stall = 1` (giữ PC)
- `if_id_stall = 1` (giữ IF/ID)
- `id_ex_flush = 1` (chèn bubble vào ID/EX)

**Cache miss stall:**
```
condition = cache_stall == 1
```
Khi phát hiện:
- `pc_stall = 1`
- `if_id_stall = 1`
- Không flush

**Structural hazard (IF/MEM conflict):**
```
condition = if_mem_conflict == 1
```
Khi phát hiện:
- `pc_stall = 1`
- `if_id_stall = 1`

**Branch/jump flush:**
```
condition = branch_taken || jump
```
Khi phát hiện:
- `if_id_flush = 1` (xóa lệnh đã fetch sai)
- `id_ex_flush = 1` (xóa lệnh đã decode sai)

**Quy tắc R0:** Không được forward vào R0, không detect hazard liên quan R0.

---

## 6. forwarding_unit.v

### Interface cứng

```verilog
module forwarding_unit (
    input  wire [2:0] id_ex_rs,
    input  wire [2:0] id_ex_rt,
    input  wire [2:0] ex_mem_rd,
    input  wire [2:0] mem_wb_rd,
    input  wire       ex_mem_reg_write,
    input  wire       mem_wb_reg_write,
    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);
```

### Bảng mã chọn cứng

| Giá trị | Nguồn dữ liệu |
|:-------:|---------------|
| `2'b00` | Dữ liệu từ Register File (ID/EX) — không forward |
| `2'b01` | Forward từ MEM/WB |
| `2'b10` | Forward từ EX/MEM |

### Logic ưu tiên cứng (EX/MEM ưu tiên hơn MEM/WB)

```
// Forward A
if (ex_mem_reg_write && ex_mem_rd != 0 && ex_mem_rd == id_ex_rs)
    forward_a = 2'b10   // EX/MEM ưu tiên cao hơn
else if (mem_wb_reg_write && mem_wb_rd != 0 && mem_wb_rd == id_ex_rs)
    forward_a = 2'b01
else
    forward_a = 2'b00

// Forward B — logic tương tự với id_ex_rt
```

**Quy tắc cứng:** Không bao giờ forward khi `rd == 3'b000` (R0 luôn = 0).

---

## 7. cpu_core.v

### Interface cứng

```verilog
module cpu_core (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    output wire        if_req,
    output wire [15:0] if_addr,
    input  wire [15:0] if_instr_in,
    input  wire        if_ready,
    output wire        mem_req,
    output wire        mem_we,
    output wire [15:0] mem_addr,
    output wire [15:0] mem_wdata,
    input  wire [15:0] mem_rdata,
    input  wire        mem_ready,
    output wire        halted,
    output wire        stall_out
);
```

### Quy tắc cứng cho từng tầng

**IF stage:**
- `if_req = 1` khi `start = 1` và chưa `halted`
- `if_addr = pc_out`
- Stall toàn bộ IF nếu `if_ready = 0`

**ID stage:**
- Đọc register file tổ hợp
- Tính `branch_target = pc_if_id + sign_extend(imm6)`
- Tính `jump_target = {pc_if_id[15:12], jump_addr}` (lấy 4 bit cao của PC hiện tại)
- Phát hiện load-use hazard tại đây

**EX stage:**
- Branch resolve tại đây (dùng cờ `zero` từ ALU)
- `branch_taken = branch && zero` (BEQ)
- `branch_taken = branch_ne && !zero` (BNE)
- ALU input A chọn qua `mux3to1` (forwarding)
- ALU input B chọn qua `mux3to1` (forwarding) rồi qua `mux2to1` (alu_src)

**MEM stage:**
- `mem_req = mem_read || mem_write`
- `mem_we = mem_write`
- `mem_addr = alu_result`
- `mem_wdata = rt_data` (đã forward nếu cần)
- Stall toàn bộ pipeline nếu `mem_ready = 0`

**WB stage:**
- `write_reg = reg_dst ? rd : rt` (chọn đích ghi)
- `write_data = mem_to_reg ? mem_data : alu_result`
- Ghi về register file

**HALT:**
- Khi `halt = 1` đến tầng WB: set `halted = 1`, dừng PC, dừng mọi request

### Xử lý conflict với arbiter

`if_mem_conflict = mem_req && if_req` — truyền vào `hazard_detection_unit`.

---

## 8. cpu_cache_top.v

### Interface cứng

```verilog
module cpu_cache_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    output wire        halted,
    output wire [15:0] debug_pc,
    output wire [15:0] debug_instr,
    output wire        debug_reg_write,
    output wire [2:0]  debug_wb_reg,
    output wire [15:0] debug_wb_data
);
```

### Kết nối nội bộ

```
cpu_core
    ↕ if_req/if_addr/if_instr_in/if_ready
    ↕ mem_req/mem_we/mem_addr/mem_wdata/mem_rdata/mem_ready
memory_arbiter
    ↕ cache_req/cache_we/cache_addr/cache_wdata/cache_rdata/cache_ready/stall
cache_subsystem
    ↕ mem_req/mem_we/mem_addr/mem_wdata/mem_rdata/mem_ready
main_memory
```

### Quy tắc cứng

- `cpu_cache_top` **không chứa bất kỳ logic pipeline** nào, chỉ instantiate và wire.
- `main_memory` phải được truyền `INIT_FILE` qua parameter khi instantiate.
- Tất cả tín hiệu `debug_*` lấy từ `cpu_core` (WB stage).

---

## Tóm tắt quy tắc xuyên suốt

| Quy tắc | Chi tiết |
|---------|---------|
| R0 = 0 | Không ghi, không forward vào R0 (`3'b000`) |
| Branch resolve | Tại EX stage, flush IF/ID và ID/EX ngay chu kỳ tiếp |
| Load-use | Stall 1 chu kỳ, chèn bubble vào ID/EX |
| Cache miss | Stall toàn pipeline, giữ nguyên PC và IF/ID |
| Flush > Stall | Nếu cả hai cùng lên, flush thắng |
| NOP = `16'h0000` | Opcode `0x0`, funct `0x0` — pipeline register reset về đây |
| PC đơn vị word | Tăng +1 mỗi chu kỳ, không phải +2 bytes |
| Không truy cập RAM trực tiếp | `cpu_core` chỉ phát request, không nối thẳng vào `main_memory` |
