# Ke hoach project CPU Von Neumann pipeline 5 tang + unified cache

## 1. Muc tieu

Thiet ke va mo phong mot CPU 16-bit theo kien truc Von Neumann:

```text
CPU Core 5-stage pipeline
IF -> ID -> EX -> MEM -> WB
        |
        | IF request + MEM request
        v
Memory Arbiter
        |
        v
Unified Direct-Mapped Cache
        |
        v
Main Memory co delay
```

Yeu cau chinh:

- CPU 16-bit, instruction width 16-bit, address width 16-bit.
- 8 thanh ghi tong quat: `R0` den `R7`, trong do `R0 = 0`.
- Pipeline 5 tang: IF, ID, EX, MEM, WB.
- Von Neumann memory: instruction va data dung chung cache/RAM.
- Unified direct-mapped cache.
- Main memory co delay mo phong 5-10 chu ky.
- Co stall khi cache miss, load-use hazard, structural hazard.
- Co forwarding co ban.
- Co flush khi branch/jump.
- Co Python assembler de sinh file `.mem`.
- Co testbench rieng tung module va testbench tich hop.

## 2. Cau hinh thiet ke

| Thanh phan | Gia tri de xuat |
|---|---|
| Data width | 16-bit |
| Address width | 16-bit |
| Instruction width | 16-bit |
| Register file | 8 x 16-bit |
| Register zero | `R0` luon bang 0 |
| Pipeline | 5 tang |
| Cache | Unified direct-mapped cache |
| Cache size ban dau | 16 lines |
| Cache line ban dau | 1 word |
| Write policy | Write-through |
| Write miss policy | No-write-allocate |
| Main memory | RAM mo phong delay |
| Branch resolve | EX stage |
| Program input | `.asm` -> assembler -> `.mem` |

## 3. ISA 16-bit

### 3.1. Format R-type

```text
[15:12] opcode
[11:9]  rs
[8:6]   rt
[5:3]   rd
[2:0]   funct
```

Vi du:

```asm
ADD R1, R2, R3
```

Nghia la:

```text
R1 = R2 + R3
```

### 3.2. Format I-type

```text
[15:12] opcode
[11:9]  rs
[8:6]   rt
[5:0]   imm6
```

Vi du:

```asm
ADDI R1, R2, 5
LW   R1, 4(R2)
SW   R1, 4(R2)
BEQ  R1, R2, label
```

### 3.3. Format J-type

```text
[15:12] opcode
[11:0]  address
```

### 3.4. Bang opcode de xuat

Bang nay can duoc chot som va dung thong nhat giua `control_unit.v` va `assembler.py`.

| Lenh | Format | Opcode | Funct | Y nghia |
|---|---:|---:|---:|---|
| R-type | R | `0x0` | tuy lenh | Nhom ALU register-register |
| ADD | R | `0x0` | `0x0` | `rd = rs + rt` |
| SUB | R | `0x0` | `0x1` | `rd = rs - rt` |
| AND | R | `0x0` | `0x2` | `rd = rs & rt` |
| OR | R | `0x0` | `0x3` | `rd = rs | rt` |
| SLT | R | `0x0` | `0x4` | `rd = rs < rt` |
| ADDI | I | `0x1` | - | `rt = rs + imm` |
| LW | I | `0x2` | - | `rt = Memory[rs + offset]` |
| SW | I | `0x3` | - | `Memory[rs + offset] = rt` |
| BEQ | I | `0x4` | - | Neu `rs == rt` thi branch |
| BNE | I | `0x5` | - | Neu `rs != rt` thi branch |
| J | J | `0x6` | - | Jump unconditional |
| NOP | R | `0x0` | `0x0` | Ma lenh `16'h0000` |
| HALT | J | `0xF` | - | Dung CPU |

### 3.5. ALU operation code

| `alu_op` | Phep toan |
|---:|---|
| `4'b0000` | ADD |
| `4'b0001` | SUB |
| `4'b0010` | AND |
| `4'b0011` | OR |
| `4'b0100` | XOR |
| `4'b0101` | SLT |
| `4'b0110` | SLL |
| `4'b0111` | SRL |

## 4. Kien truc module

```text
cpu_cache_top
|
+-- cpu_core
|   +-- pc_unit
|   +-- instruction_decoder
|   +-- control_unit
|   +-- register_file
|   +-- immediate_generator
|   +-- alu
|   +-- forwarding_unit
|   +-- hazard_detection_unit
|   +-- pipeline_reg_if_id
|   +-- pipeline_reg_id_ex
|   +-- pipeline_reg_ex_mem
|   +-- pipeline_reg_mem_wb
|
+-- memory_arbiter
|
+-- direct_mapped_cache
|   +-- cache_controller
|   +-- tag_array
|   +-- valid_array
|   +-- dirty_array
|   +-- data_array
|
+-- main_memory
|
+-- testbench
```

## 5. Interface module

### 5.1. `cpu_cache_top`

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

Vai tro:

- Noi `cpu_core`, `memory_arbiter`, `direct_mapped_cache`, `main_memory`.
- Dua cac tin hieu debug ra testbench/waveform.
- Khong nen chua logic xu ly pipeline phuc tap.

### 5.2. `cpu_core`

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

Vai tro:

- Thuc hien pipeline IF/ID/EX/MEM/WB.
- Khong truy cap RAM truc tiep.
- Chi phat request instruction/data den arbiter.
- Stall pipeline khi `if_ready = 0`, `mem_ready = 0`, cache miss, load-use hazard, hoac memory conflict.

### 5.3. `pc_unit`

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

Thu tu uu tien:

1. `rst`: `PC = 0`.
2. `stall`: giu nguyen PC.
3. `jump`: `PC = jump_target`.
4. `branch_taken`: `PC = branch_target`.
5. Mac dinh: `PC = PC + 1`.

### 5.4. `register_file`

```verilog
module register_file (
   input  wire        clk,
   input  wire        rst,
   input  wire [2:0]  rs_addr,
   input  wire [2:0]  rt_addr,
   input  wire [2:0]  rd_addr,
   input  wire [15:0] rd_wdata,
   input  wire        reg_write,

   output wire [15:0] rs_data,
   output wire [15:0] rt_data
);
```

Quy uoc:

- `R0` luon tra ve `16'h0000`.
- Khong ghi khi `rd_addr == 3'b000`.
- Read nen la combinational, write theo canh clock.

### 5.5. `alu`

```verilog
module alu (
   input  wire [15:0] a,
   input  wire [15:0] b,
   input  wire [3:0]  alu_op,

   output reg  [15:0] result,
   output wire        zero,
   output wire        negative,
   output reg         overflow
);
```

Yeu cau:

- Ho tro ADD, SUB, AND, OR, XOR, SLT, SLL, SRL.
- `zero = (result == 0)`.
- `negative = result[15]`.
- `overflow` dung cho ADD/SUB signed.

### 5.6. `control_unit`

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

Bang control toi thieu:

| Lenh | `reg_write` | `mem_read` | `mem_write` | `alu_src` | `mem_to_reg` | `branch` | `jump` |
|---|---:|---:|---:|---:|---:|---:|---:|
| ADD/SUB/AND/OR/SLT | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| ADDI | 1 | 0 | 0 | 1 | 0 | 0 | 0 |
| LW | 1 | 1 | 0 | 1 | 1 | 0 | 0 |
| SW | 0 | 0 | 1 | 1 | 0 | 0 | 0 |
| BEQ | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| BNE | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| J | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| HALT | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### 5.7. `instruction_decoder`

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

Mapping:

- `opcode = instr[15:12]`
- `rs = instr[11:9]`
- `rt = instr[8:6]`
- `rd = instr[5:3]`
- `funct = instr[2:0]`
- `imm6 = instr[5:0]`
- `jump_addr = instr[11:0]`

### 5.8. `immediate_generator`

```verilog
module immediate_generator (
   input  wire [5:0]  imm6,
   input  wire        sign_ext,

   output wire [15:0] imm16
);
```

Yeu cau:

- `sign_ext = 1`: mo rong dau.
- `sign_ext = 0`: mo rong zero.
- Branch offset nen dung sign-extend.

### 5.9. Pipeline registers

Tat ca pipeline registers can co reset ve NOP va ho tro stall/flush phu hop.

#### `pipeline_reg_if_id`

```verilog
module pipeline_reg_if_id (
   input  wire        clk,
   input  wire        rst,
   input  wire        stall,
   input  wire        flush,
   input  wire [15:0] pc_in,
   input  wire [15:0] instr_in,

   output reg  [15:0] pc_out,
   output reg  [15:0] instr_out
);
```

#### `pipeline_reg_id_ex`

Can luu toi thieu:

- `pc`
- `rs_data`, `rt_data`
- `imm`
- `rs`, `rt`, `rd`
- `alu_op`
- `reg_write`, `mem_read`, `mem_write`, `mem_to_reg`
- `alu_src`, `reg_dst`
- `branch`, `branch_ne`, `jump`, `halt`

#### `pipeline_reg_ex_mem`

Can luu toi thieu:

- `alu_result`
- `rt_data`
- `write_reg`
- `zero`
- `branch_target`
- `reg_write`, `mem_read`, `mem_write`, `mem_to_reg`
- `branch`, `branch_ne`, `jump`, `halt`

#### `pipeline_reg_mem_wb`

Can luu toi thieu:

- `mem_data`
- `alu_result`
- `write_reg`
- `reg_write`
- `mem_to_reg`
- `halt`

### 5.10. `hazard_detection_unit`

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

Xu ly toi thieu:

- Load-use hazard:
  `ex_mem_read && ((ex_rt == id_rs) || (ex_rt == id_rt))`
- Cache miss stall:
  `cache_stall = 1`
- Structural hazard:
  IF va MEM cung can truy cap unified cache.
- Branch/jump flush:
  Xoa instruction sai sau khi target duoc xac dinh.

### 5.11. `forwarding_unit`

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

Ma chon:

| Gia tri | Y nghia |
|---:|---|
| `2'b00` | Dung du lieu tu ID/EX |
| `2'b01` | Forward tu MEM/WB |
| `2'b10` | Forward tu EX/MEM |

### 5.12. `memory_arbiter`

```verilog
module memory_arbiter (
   input  wire        clk,
   input  wire        rst,

   input  wire        if_req,
   input  wire [15:0] if_addr,
   output reg         if_ready,
   output reg  [15:0] if_instr,

   input  wire        mem_req,
   input  wire        mem_we,
   input  wire [15:0] mem_addr,
   input  wire [15:0] mem_wdata,
   output reg         mem_ready,
   output reg  [15:0] mem_rdata,

   output reg         cache_req,
   output reg         cache_we,
   output reg  [15:0] cache_addr,
   output reg  [15:0] cache_wdata,
   input  wire        cache_ready,
   input  wire [15:0] cache_rdata
);
```

Quy tac uu tien:

1. Neu `mem_req = 1`, phuc vu MEM stage.
2. Neu khong, neu `if_req = 1`, phuc vu IF stage.
3. Khi MEM dang chiem cache, IF phai stall.

### 5.13. `direct_mapped_cache`

```verilog
module direct_mapped_cache #(
   parameter CACHE_LINES = 16
) (
   input  wire        clk,
   input  wire        rst,

   input  wire        cpu_req,
   input  wire        cpu_we,
   input  wire [15:0] cpu_addr,
   input  wire [15:0] cpu_wdata,
   output reg         cpu_ready,
   output reg  [15:0] cpu_rdata,
   output reg         cache_hit,
   output reg         cache_miss,

   output reg         mem_req,
   output reg         mem_we,
   output reg  [15:0] mem_addr,
   output reg  [15:0] mem_wdata,
   input  wire [15:0] mem_rdata,
   input  wire        mem_ready
);
```

Voi 16 lines, line size 1 word:

```text
Tag   = address[15:4]
Index = address[3:0]
```

Chinh sach:

- Read hit: tra data cache.
- Read miss: doc RAM, refill cache, tra data.
- Write hit: cap nhat cache va ghi RAM.
- Write miss: ghi thang RAM, khong allocate cache.

FSM de xuat:

```text
IDLE
LOOKUP
HIT_READ
HIT_WRITE
MISS_READ_REQ
MISS_READ_WAIT
REFILL
MISS_WRITE_REQ
MISS_WRITE_WAIT
DONE
```

### 5.14. `main_memory`

```verilog
module main_memory #(
   parameter MEM_SIZE  = 65536,
   parameter MEM_DELAY = 5,
   parameter INIT_FILE = ""
) (
   input  wire        clk,
   input  wire        rst,
   input  wire        mem_req,
   input  wire        mem_we,
   input  wire [15:0] mem_addr,
   input  wire [15:0] mem_wdata,

   output reg  [15:0] mem_rdata,
   output reg         mem_ready
);
```

Yeu cau:

- Ho tro `$readmemh(INIT_FILE, memory)` neu `INIT_FILE` khac rong.
- Moi request mat `MEM_DELAY` chu ky.
- `mem_ready` chi len 1 trong chu ky hoan thanh.

## 6. Xu ly hazard

### 6.1. Structural hazard Von Neumann

Nguyen nhan:

- IF can fetch instruction.
- MEM can load/store data.
- Ca hai dung chung cache.

Cach xu ly:

- Arbiter uu tien MEM.
- IF stall khi MEM dang request.
- PC va IF/ID giu nguyen trong chu ky conflict.

### 6.2. Load-use hazard

Vi du:

```asm
LW  R1, 0(R0)
ADD R2, R1, R1
```

Xu ly:

- Phat hien o ID stage.
- Stall PC va IF/ID 1 chu ky.
- Flush ID/EX de chen bubble.

### 6.3. Data hazard co forwarding

Vi du:

```asm
ADD R1, R2, R3
ADD R4, R1, R5
```

Xu ly:

- Forward EX/MEM -> EX neu ket qua vua tinh xong.
- Forward MEM/WB -> EX neu ket qua dang write-back.
- Khong forward vao `R0`.

### 6.4. Control hazard

Branch resolve o EX stage:

- Neu branch taken hoac jump, flush IF/ID va ID/EX.
- PC duoc nap branch/jump target.
- Khong cho lenh sai ghi register/memory.

## 7. Cac chuong trinh demo

### Demo 1: ALU

Test truc tiep `alu.v`:

- ADD dung.
- SUB dung.
- AND dung.
- OR dung.
- SLT dung.
- `zero`, `negative`, `overflow` dung.

### Demo 2: CPU arithmetic

```asm
ADDI R1, R0, 5
ADDI R2, R0, 10
ADD  R3, R1, R2
HALT
```

Ky vong:

- `R1 = 5`
- `R2 = 10`
- `R3 = 15`

### Demo 3: Load/store

```asm
ADDI R1, R0, 20
SW   R1, 0(R0)
LW   R2, 0(R0)
HALT
```

Ky vong:

- `Memory[0] = 20`
- `R2 = 20`

### Demo 4: Cache miss/hit

```asm
LW R1, 10(R0)
LW R2, 10(R0)
HALT
```

Ky vong:

- LW dau tien: cache miss.
- LW thu hai: cache hit.

### Demo 5: Hazard

```asm
LW  R1, 0(R0)
ADD R2, R1, R1
HALT
```

Ky vong:

- CPU stall hoac forward dung.
- `R2 = R1 + R1`.

### Demo 6: Branch

```asm
ADDI R1, R0, 5
ADDI R2, R0, 5
BEQ  R1, R2, TARGET
ADDI R3, R0, 1
TARGET:
ADDI R3, R0, 9
HALT
```

Ky vong:

- `R3 = 9`.
- Instruction sai sau branch bi flush.

## 8. Testbench can co

| Testbench | Muc tieu |
|---|---|
| `alu_tb.v` | Test ADD, SUB, AND, OR, SLT, flag |
| `register_file_tb.v` | Test read/write, reset, R0 |
| `control_unit_tb.v` | Test opcode/funct sinh control dung |
| `main_memory_tb.v` | Test delay va `mem_ready` |
| `cache_tb.v` | Test hit/miss, refill, write-through |
| `memory_arbiter_tb.v` | Test uu tien MEM hon IF |
| `cpu_core_tb.v` | Test pipeline core voi memory gia lap |
| `cpu_cache_tb.v` | Test tich hop CPU + arbiter + cache + RAM |

## 9. Tin hieu debug nen dua ra waveform

| Nhom | Tin hieu |
|---|---|
| Pipeline | `pc`, `if_id_instr`, `id_ex_opcode`, `ex_mem_alu_result`, `mem_wb_data` |
| Register | `reg_write`, `write_reg`, `write_data` |
| Hazard | `stall`, `flush`, `forward_a`, `forward_b` |
| Memory | `mem_req`, `mem_we`, `mem_addr`, `mem_rdata`, `mem_ready` |
| Cache | `cache_hit`, `cache_miss`, `cache_state`, `valid`, `tag`, `index` |
| RAM | `ram_req`, `ram_ready`, `delay_counter` |

## 10. Python assembler

### 10.1. Input

```asm
ADDI R1, R0, 5
ADDI R2, R0, 10
ADD  R3, R1, R2
SW   R3, 0(R0)
LW   R4, 0(R0)
HALT
```

### 10.2. Output

File `.mem`, moi dong la mot instruction 16-bit dang hex.

```text
1045
108A
0280
30C0
2100
F000
```

Luu y:

- Gia tri hex phai theo dung bang opcode/funct da chot trong tai lieu nay.
- `assembler.py` la nguon chuan de sinh `.mem`; khong nen nhap machine code bang tay.
- Ho tro label cho BEQ/BNE/J.
- Bao loi neu immediate vuot 6-bit signed range.

## 11. Phan chia nhiem vu nhom 4 nguoi

### 11.1. Thanh vien 1 - Datapath & ALU Designer

Nguoi phu trach: Vu Xuan Hai

File/module:

- `rtl/cpu/alu.v`
- `rtl/cpu/register_file.v`
- `rtl/cpu/immediate_generator.v`
- `rtl/cpu/mux.v`
- EX/WB datapath trong `cpu_core.v` hoac module rieng

Deliverable:

- ALU chay dung ADD, SUB, AND, OR, SLT.
- Register file doc/ghi dung, `R0` khong bi ghi de.
- Immediate generator sign-extend va zero-extend dung.
- MUX chon du lieu dung theo control signal.

Checklist:

- [ ] Co `alu_tb.v`.
- [ ] Co `register_file_tb.v`.
- [ ] ALU co `zero`, `negative`, `overflow`.
- [ ] `R0` luon bang 0.
- [ ] Co mo ta ro `alu_op`.

### 11.2. Thanh vien 2 - Memory & Cache Specialist

Nguoi phu trach: Nguyen Vu Hoang

File/module:

- `rtl/memory/direct_mapped_cache.v`
- `rtl/memory/cache_controller.v`
- `rtl/memory/main_memory.v`
- `rtl/memory/memory_arbiter.v`

Deliverable:

- Cache read hit tra data dung.
- Cache read miss request RAM, refill cache.
- Cache write hit cap nhat cache va RAM.
- Cache write miss ghi thang RAM.
- RAM co delay va `mem_ready`.
- Arbiter uu tien MEM hon IF.

Checklist:

- [ ] Cache co valid bit.
- [ ] Cache co tag array.
- [ ] Cache co data array.
- [ ] Co `cache_hit` va `cache_miss`.
- [ ] Miss lam CPU stall.
- [ ] RAM delay mo phong duoc.
- [ ] IF va MEM khong truy cap cache cung luc.

### 11.3. Thanh vien 3 - Control Unit & System Integrator

Nguoi phu trach: Nguyen Nhat Phong

File/module:

- `rtl/cpu/control_unit.v`
- `rtl/cpu/instruction_decoder.v`
- `rtl/cpu/pc_unit.v`
- `rtl/cpu/pipeline_regs.v`
- `rtl/cpu/hazard_detection_unit.v`
- `rtl/cpu/forwarding_unit.v`
- `rtl/cpu/cpu_core.v`
- `rtl/top/cpu_cache_top.v`

Deliverable:

- Fetch, decode, execute, memory, write-back dung.
- PC tang dung va branch/jump target dung.
- Stall dung khi cache miss va load-use hazard.
- Forwarding cho ALU.
- Flush dung khi branch/jump.
- CPU chay duoc chuong trinh nhieu lenh.

Checklist:

- [ ] Pipeline register hoat dong dung.
- [ ] Co stall khi cache miss.
- [ ] Co stall khi load-use hazard.
- [ ] Co forwarding cho ALU.
- [ ] Co flush khi branch/jump.
- [ ] CPU chay duoc chuong trinh tich hop.

### 11.4. Thanh vien 4 - Verification & Tooling Engineer

Nguoi phu trach: Le Hoang Dung

File/module:

- `tb/cpu_cache_tb.v`
- `tb/alu_tb.v`
- `tb/register_file_tb.v`
- `tb/cache_tb.v`
- `tools/assembler.py`
- `asm/*.asm`
- `mem/*.mem`
- `sim/run.do` hoac `Makefile`

Deliverable:

- Test rieng tung module chinh.
- Test tich hop CPU + cache + RAM.
- Assembler dich `.asm` sang `.mem`.
- Chuong trinh demo day du arithmetic, load/store, cache, hazard, branch.
- Waveform minh hoa pipeline/cache/stall/flush.
- Bang ket qua pass/fail.

Checklist:

- [ ] Co testbench cho tung module chinh.
- [ ] Co it nhat 5 chuong trinh assembly test.
- [ ] Co file `.mem` nap vao RAM.
- [ ] Co waveform chung minh cache hit/miss.
- [ ] Co waveform chung minh stall/flush.
- [ ] Co bang ket qua test pass/fail.

## 12. Ke hoach trien khai theo tuan

### Tuan 1 - Chot kien truc va interface

Muc tieu:

- Hoan thanh thiet ke tren giay truoc khi code.

Cong viec:

| Cong viec | Phu trach |
|---|---|
| Chot ISA 16-bit | Ca nhom |
| Chot opcode/funct | Thanh vien 3 + 4 |
| Chot interface module | Ca nhom |
| Ve so do CPU/cache | Thanh vien 3 |
| Tao repo Git | Thanh vien 4 |
| Tao skeleton file Verilog | Thanh vien 3 |
| Tao format test program | Thanh vien 4 |

Ket qua:

- [ ] Co bang ISA.
- [ ] Co so do datapath.
- [ ] Co so do cache FSM.
- [ ] Co danh sach module.
- [ ] Co interface input/output co dinh.
- [ ] Co Git repo.

### Tuan 2 - Code module don le

Muc tieu:

- Moi nguoi hoan thanh module rieng va test rieng.

Cong viec:

| Nguoi | Cong viec |
|---|---|
| Vu Xuan Hai | ALU, Register File, Immediate Generator |
| Nguyen Vu Hoang | RAM delay, Cache FSM ban don gian |
| Nguyen Nhat Phong | PC, Decoder, Control Unit, Pipeline Register |
| Le Hoang Dung | Testbench module, Python assembler ban dau |

Ket qua:

- [ ] ALU pass test.
- [ ] Register file pass test.
- [ ] Control unit pass test.
- [ ] RAM delay pass test.
- [ ] Cache read hit/miss pass test.
- [ ] Assembler dich duoc lenh co ban.

### Tuan 3 - Tich hop CPU pipeline

Muc tieu:

- CPU chay duoc chuong trinh don gian, chua can cache phuc tap.

Chuong trinh test:

```asm
ADDI R1, R0, 5
ADDI R2, R0, 10
ADD  R3, R1, R2
HALT
```

Cong viec:

| Cong viec | Phu trach |
|---|---|
| Ghep IF/ID/EX/MEM/WB | Thanh vien 3 |
| Kiem tra datapath | Thanh vien 1 + 3 |
| Gan cache voi CPU | Thanh vien 2 + 3 |
| Viet test program | Thanh vien 4 |
| Debug waveform | Ca nhom |

Ket qua:

- [ ] CPU fetch duoc instruction.
- [ ] Decode dung opcode.
- [ ] ALU chay dung trong pipeline.
- [ ] Register WB dung.
- [ ] Chay duoc chuong trinh ADD/ADDI.

### Tuan 4 - Them cache miss, stall, hazard

Muc tieu:

- CPU hoat dong dung khi co cache hit/miss va pipeline hazard.

Cong viec:

| Cong viec | Phu trach |
|---|---|
| Cache miss lam CPU stall | Thanh vien 2 + 3 |
| Load-use hazard | Thanh vien 3 |
| Forwarding | Thanh vien 3 |
| Test LW/SW | Thanh vien 4 |
| Kiem tra RAM/cache consistency | Thanh vien 2 + 4 |

Chuong trinh test cache:

```asm
ADDI R1, R0, 8
LW   R2, 0(R1)
LW   R3, 0(R1)
ADD  R4, R2, R3
HALT
```

Ky vong:

- LW dau tien: cache miss.
- LW thu hai: cache hit.
- Load-use hazard khong lam sai data.

Ket qua:

- [ ] Cache miss tao stall.
- [ ] Cache hit tra du lieu nhanh.
- [ ] Load-use hazard khong lam sai du lieu.
- [ ] Forwarding hoat dong.
- [ ] LW/SW chay dung.

### Tuan 5 - Branch, jump, hoan thien test

Muc tieu:

- Hoan thien CPU co dieu khien luong.

Cong viec:

| Cong viec | Phu trach |
|---|---|
| BEQ/BNE | Thanh vien 3 |
| JUMP | Thanh vien 3 |
| Flush pipeline | Thanh vien 3 |
| Test branch/jump | Thanh vien 4 |
| Toi uu cache FSM | Thanh vien 2 |
| Don code | Ca nhom |

Ket qua:

- [ ] BEQ dung.
- [ ] BNE dung.
- [ ] JUMP dung.
- [ ] Pipeline flush dung.
- [ ] Khong ghi nham register sau branch.

### Tuan 6 - Bao cao, demo, slide

Muc tieu:

- Chuan bi san pham cuoi.

Cong viec:

| Cong viec | Phu trach |
|---|---|
| Chup waveform | Thanh vien 4 |
| Ve so do kien truc | Thanh vien 3 |
| Viet phan datapath | Thanh vien 1 |
| Viet phan cache | Thanh vien 2 |
| Viet phan test | Thanh vien 4 |
| Tong hop bao cao | Ca nhom |

Ket qua:

- [ ] Source code hoan chinh.
- [ ] Testbench hoan chinh.
- [ ] File assembly test.
- [ ] File `.mem`.
- [ ] Waveform minh hoa.
- [ ] Bao cao.
- [ ] Slide thuyet trinh.

## 13. Thu tu code nen lam

1. `rtl/cpu/alu.v`
2. `rtl/cpu/register_file.v`
3. `rtl/cpu/immediate_generator.v`
4. `rtl/cpu/instruction_decoder.v`
5. `rtl/cpu/control_unit.v`
6. `rtl/cpu/pc_unit.v`
7. `rtl/cpu/pipeline_regs.v`
8. `rtl/memory/main_memory.v`
9. `rtl/memory/direct_mapped_cache.v`
10. `rtl/memory/memory_arbiter.v`
11. `rtl/cpu/hazard_detection_unit.v`
12. `rtl/cpu/forwarding_unit.v`
13. `rtl/cpu/cpu_core.v`
14. `rtl/top/cpu_cache_top.v`
15. `tb/cpu_cache_tb.v`
16. `tools/assembler.py`

## 14. Cau truc thu muc project

```text
cpu_cache_project/
|
+-- rtl/
|   +-- cpu/
|   |   +-- cpu_core.v
|   |   +-- pc_unit.v
|   |   +-- instruction_decoder.v
|   |   +-- control_unit.v
|   |   +-- register_file.v
|   |   +-- immediate_generator.v
|   |   +-- alu.v
|   |   +-- forwarding_unit.v
|   |   +-- hazard_detection_unit.v
|   |   +-- mux.v
|   |   +-- pipeline_regs.v
|   |
|   +-- memory/
|   |   +-- memory_arbiter.v
|   |   +-- direct_mapped_cache.v
|   |   +-- cache_controller.v
|   |   +-- main_memory.v
|   |
|   +-- top/
|       +-- cpu_cache_top.v
|
+-- tb/
|   +-- alu_tb.v
|   +-- register_file_tb.v
|   +-- control_unit_tb.v
|   +-- main_memory_tb.v
|   +-- cache_tb.v
|   +-- memory_arbiter_tb.v
|   +-- cpu_core_tb.v
|   +-- cpu_cache_tb.v
|
+-- asm/
|   +-- program_01_arithmetic.asm
|   +-- program_02_load_store.asm
|   +-- program_03_cache_hit_miss.asm
|   +-- program_04_branch.asm
|   +-- program_05_full.asm
|
+-- mem/
|   +-- program_01_arithmetic.mem
|   +-- program_02_load_store.mem
|   +-- program_03_cache_hit_miss.mem
|   +-- program_04_branch.mem
|   +-- program_05_full.mem
|
+-- tools/
|   +-- assembler.py
|
+-- sim/
|   +-- run.bat
|   +-- run.do
|   +-- wave.do
|
+-- docs/
|   +-- ISA.md
|   +-- MODULE_INTERFACE.md
|   +-- CACHE_FSM.md
|   +-- REPORT.md
|
+-- README.md
```

## 15. Cong cu can cai dat

### 15.1. Lua chon nhe cho Windows

- VS Code.
- Verilog HDL extension.
- Icarus Verilog.
- GTKWave.
- Python 3.
- Git.

### 15.2. Lua chon day du hon

- ModelSim hoac QuestaSim.
- Vivado neu can mo phong/tong hop FPGA.
- VS Code.
- Python 3.
- Git.

## 16. Lenh mo phong goi y voi Icarus Verilog

Vi du test ALU:

```bat
iverilog -o build/alu_tb.vvp rtl/cpu/alu.v tb/alu_tb.v
vvp build/alu_tb.vvp
gtkwave wave/alu_tb.vcd
```

Vi du test tich hop:

```bat
python tools/assembler.py asm/program_05_full.asm mem/program_05_full.mem
iverilog -o build/cpu_cache_tb.vvp ^
  rtl/cpu/*.v ^
  rtl/memory/*.v ^
  rtl/top/*.v ^
  tb/cpu_cache_tb.v
vvp build/cpu_cache_tb.vvp
gtkwave wave/cpu_cache_tb.vcd
```

## 17. Minimum Viable Product

Neu thoi gian gap, can hoan thanh toi thieu:

- [ ] CPU 16-bit.
- [ ] 8 registers, `R0 = 0`.
- [ ] 5-stage pipeline.
- [ ] Ho tro ADD, SUB, ADDI, LW, SW, BEQ, J, HALT.
- [ ] Unified direct-mapped cache.
- [ ] Cache hit/miss.
- [ ] RAM delay.
- [ ] Stall khi cache miss.
- [ ] Stall load-use hazard hoac xu ly tuong duong.
- [ ] Testbench tong.
- [ ] Waveform chung minh pipeline, cache hit/miss, stall.

Forwarding va branch nang cao co the lam sau, nhung khong duoc de CPU ghi sai du lieu.

## 18. Checklist nghiem thu cuoi cung

### 18.1. Datapath

- [ ] ALU dung cho ADD, SUB, AND, OR, SLT.
- [ ] Flag `zero`, `negative`, `overflow` dung.
- [ ] Register file doc/ghi dung.
- [ ] `R0` khong bi ghi de.
- [ ] Immediate sign-extend va zero-extend dung.

### 18.2. Control va pipeline

- [ ] Decoder tach dung opcode/rs/rt/rd/imm/funct.
- [ ] Control unit sinh dung tin hieu.
- [ ] PC tang dung.
- [ ] IF/ID, ID/EX, EX/MEM, MEM/WB hoat dong dung.
- [ ] WB ghi dung thanh ghi dich.
- [ ] HALT dung CPU dung thoi diem.

### 18.3. Hazard

- [ ] Cache miss stall pipeline.
- [ ] Structural hazard IF/MEM duoc arbiter xu ly.
- [ ] Load-use hazard duoc stall.
- [ ] Forwarding EX/MEM va MEM/WB hoat dong.
- [ ] Branch/jump flush instruction sai.

### 18.4. Cache va memory

- [ ] Cache co valid bit.
- [ ] Cache co tag array.
- [ ] Cache co data array.
- [ ] Read hit dung.
- [ ] Read miss dung va refill cache.
- [ ] Write hit dung voi write-through.
- [ ] Write miss dung voi no-write-allocate.
- [ ] RAM delay dung so chu ky.
- [ ] Cache/RAM consistency dung sau SW/LW.

### 18.5. Tooling va verification

- [ ] `assembler.py` dich duoc day du lenh yeu cau.
- [ ] Co it nhat 5 file `.asm`.
- [ ] Co `.mem` tuong ung.
- [ ] Co testbench rieng module chinh.
- [ ] Co testbench tich hop.
- [ ] Co waveform cho pipeline.
- [ ] Co waveform cho cache hit/miss.
- [ ] Co waveform cho stall/flush.
- [ ] Co bang ket qua pass/fail.

## 19. Quy uoc dat ten tin hieu

Dung thong nhat:

- `clk`
- `rst`
- `req`
- `we`
- `addr`
- `wdata`
- `rdata`
- `ready`
- `stall`
- `flush`
- `valid`
- `hit`
- `miss`

Khong nen tron nhieu kieu nhu `write_enable`, `wr_en`, `wen`, `memwrite` trong cung project.

## 20. Lo trinh uu tien

1. CPU khong pipeline, khong cache chay duoc ADD/ADDI.
2. Them pipeline 5 tang.
3. Them LW/SW voi RAM don gian.
4. Them direct-mapped cache.
5. Them stall khi cache miss.
6. Them hazard detection va forwarding.
7. Them branch/jump/flush.
8. Viet bao cao, chup waveform, lam slide demo.

Khong nen bat dau bang cache truoc khi CPU core toi thieu chay duoc, vi neu cache dung nhung CPU chua chay thi rat kho debug.

## 21. Ket luan thiet ke

Thiet ke duoc chot cho nhom:

- CPU 16-bit.
- 5-stage pipeline.
- Von Neumann unified memory.
- Direct-mapped unified cache.
- RAM co delay.
- Write-through + no-write-allocate.
- Stall khi cache miss.
- Forwarding co ban.
- Branch flush don gian.
- Python assembler ho tro nap chuong trinh.

Day la cau hinh vua du de the hien cac noi dung quan trong cua kien truc may tinh:

- Datapath.
- Control signal.
- Pipeline.
- Hazard.
- Cache hit/miss.
- Memory latency.
- Stall.
- Instruction execution.
- Verification.
