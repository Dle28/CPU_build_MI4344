# ISA

## Quy tắc toàn cục

| Tính năng | Quyết định |
|---|---|
| Độ rộng lệnh | 16 bit |
| Độ rộng dữ liệu | 16 bit |
| Thanh ghi | 8 thanh ghi, `R0` đến `R7` |
| Luật `R0` | Đọc luôn trả `16'h0000`; ghi bị bỏ qua |
| Bộ nhớ | Word-addressed 16-bit |
| PC increment | `PC = PC + 1` |
| `NOP` | `16'h0000` — tương đương `ADD R0, R0, R0` (opcode=0, funct=0, tất cả field = 0) |

---

## Định dạng lệnh

R-type:

```text
[15:12] opcode (4 bit)
[11:9]  rs     (3 bit) — toán hạng nguồn 1
[8:6]   rt     (3 bit) — toán hạng nguồn 2
[5:3]   rd     (3 bit) — toán hạng đích
[2:0]   funct  (3 bit) — chọn phép tính ALU
```

I-type:

```text
[15:12] opcode (4 bit)
[11:9]  rs     (3 bit) — toán hạng nguồn (base cho LW/SW)
[8:6]   rt     (3 bit) — toán hạng đích (ADDI/LW) hoặc dữ liệu (SW/BEQ/BNE)
[5:0]   imm6   (6 bit) — hằng số tức thì (sign-extended trước khi vào ALU)
```

J-type:

```text
[15:12] opcode   (4 bit)
[11:0]  address  (12 bit) — địa chỉ nhảy tuyệt đối (word address)
```

---

## Bảng opcode

| Opcode | Mnemonic | Loại |
|---|---|---|
| `4'h0` | R-type | R |
| `4'h1` | `ADDI` | I |
| `4'h2` | `LW` | I |
| `4'h3` | `SW` | I |
| `4'h4` | `BEQ` | I |
| `4'h5` | `BNE` | I |
| `4'h6` | `J` | J |
| `4'hF` | `HALT` | J-like |

---

## Bảng funct (R-type) và chi tiết ALU

> **Lưu ý quan trọng:** Field `funct` trong lệnh rộng **3 bit** (`[2:0]`).
> Trước khi đưa vào ALU, Control Unit zero-extend thành **4 bit**:
> `alu_op = {1'b0, funct}` — tức là `funct[2:0]` → `4'b0_funct`.
> Vì vậy các mã ALU hợp lệ là `4'b0000` đến `4'b0111`.

Opcode R-type luôn là `4'h0`.

### ADD — funct `3'h0` → alu_op `4'b0000`

```
result = rs + rt                         (16-bit unsigned wrap)
overflow = 1  khi:
    (+) + (+) → (-)   tức ~rs[15] & ~rt[15] & result[15]
    (-) + (-) → (+)   tức  rs[15] &  rt[15] & ~result[15]
zero     = (result == 0)
negative = result[15]
```

Cú pháp: `ADD rd, rs, rt`

---

### SUB — funct `3'h1` → alu_op `4'b0001`

```
result = rs - rt                         (16-bit unsigned wrap)
overflow = 1  khi:
    (+) - (-) → (-)   tức ~rs[15] &  rt[15] &  result[15]
    (-) - (+) → (+)   tức  rs[15] & ~rt[15] & ~result[15]
zero     = (result == 0)
negative = result[15]
```

Cú pháp: `SUB rd, rs, rt`

---

### AND — funct `3'h2` → alu_op `4'b0010`

```
result = rs & rt                         (bitwise AND từng bit)
overflow = 0  (phép logic, không tràn)
zero     = (result == 0)
negative = result[15]
```

Cú pháp: `AND rd, rs, rt`

---

### OR — funct `3'h3` → alu_op `4'b0011`

```
result = rs | rt                         (bitwise OR từng bit)
overflow = 0
zero     = (result == 0)
negative = result[15]
```

Cú pháp: `OR rd, rs, rt`

---

### XOR — funct `3'h4` → alu_op `4'b0100`

```
result = rs ^ rt                         (bitwise XOR từng bit)
overflow = 0
zero     = (result == 0)
negative = result[15]
```

Cú pháp: `XOR rd, rs, rt`

---

### SLT — funct `3'h5` → alu_op `4'b0101`

```
result = ($signed(rs) < $signed(rt)) ? 16'h0001 : 16'h0000
         So sánh CÓ DẤU (two's complement)
overflow = 0
zero     = (result == 0)  — tức là rs >= rt
negative = 0              — result chỉ là 0 hoặc 1
```

Cú pháp: `SLT rd, rs, rt`
Ví dụ: `R3 = 0xFFFF (-1)`, `R2 = 0x0001 (+1)` → `SLT R1, R3, R2` → `R1 = 1`

---

### SLL — funct `3'h6` → alu_op `4'b0110`

```
result = rs << rt[3:0]                   (shift trái logic, chèn 0 bên phải)
Chỉ dùng 4 bit thấp của rt làm shift amount (0..15 lần)
overflow = 0
zero     = (result == 0)
negative = result[15]
```

Cú pháp: `SLL rd, rs, rt`
Ví dụ: `rs = 0x0001`, `rt = 0x0003` → `SLL` → `result = 0x0008`

---

### SRL — funct `3'h7` → alu_op `4'b0111`

```
result = rs >> rt[3:0]                   (shift phải logic, chèn 0 bên trái)
Chỉ dùng 4 bit thấp của rt làm shift amount (0..15 lần)
KHÔNG phải arithmetic shift (không giữ bit dấu)
overflow = 0
zero     = (result == 0)
negative = result[15]  — luôn = 0 vì chèn 0 vào MSB
```

Cú pháp: `SRL rd, rs, rt`
Ví dụ: `rs = 0x8000`, `rt = 0x0001` → `SRL` → `result = 0x4000`

---

## Quy ước toán hạng Assembly

Cú pháp khuyến nghị:

```asm
ADD  rd, rs, rt
SUB  rd, rs, rt
AND  rd, rs, rt
OR   rd, rs, rt
XOR  rd, rs, rt
SLT  rd, rs, rt
SLL  rd, rs, rt       ; rd = rs << rt[3:0]
SRL  rd, rs, rt       ; rd = rs >> rt[3:0]
ADDI rt, rs, imm6     ; rt = rs + sign_extend(imm6)
LW   rt, imm6(rs)     ; rt = MEM[rs + sign_extend(imm6)]
SW   rt, imm6(rs)     ; MEM[rs + sign_extend(imm6)] = rt
BEQ  rs, rt, label    ; if rs == rt: PC = PC+1 + sign_extend(imm6)
BNE  rs, rt, label    ; if rs != rt: PC = PC+1 + sign_extend(imm6)
J    label             ; PC = zero_extend(address[11:0])
HALT                   ; Dừng pipeline (halt = 1)
```

---

## Quy tắc địa chỉ nhánh (Branch)

Nhánh được resolve ở EX. Địa chỉ nhánh:

```text
branch_target = PC_plus_1 + sign_extend(imm6)
```

Assembler mã hoá nhãn nhánh theo:

```text
imm6 = label_address - (branch_pc + 1)
```

BEQ/BNE dùng ALU_SUB để kiểm tra: nếu `zero = 1` (kết quả = 0) thì hai thanh ghi bằng nhau.

---

## Quy tắc địa chỉ nhảy (Jump)

Jump dùng địa chỉ tuyệt đối 12-bit (word address):

```text
jump_target = zero_extend(address[11:0])
              Phạm vi nhảy: địa chỉ 0x000 đến 0xFFF
```

---

## Quy tắc HALT

```text
Khi opcode = 4'hF:
    halt = 1
    Pipeline dừng (không fetch lệnh mới)
    PC giữ nguyên
```

HALT được implement ở tầng ID, tín hiệu `halt` truyền qua pipeline register.

---

## Cờ trạng thái ALU (Flags)

| Cờ | Bit | Mô tả |
|---|---|---|
| `zero` | `wire` | `1` khi `result == 16'h0000` (dùng cho BEQ/BNE) |
| `negative` | `result[15]` | `1` khi kết quả là số âm (two's complement) |
| `overflow` | `reg` | `1` khi ADD/SUB tràn số có dấu; `0` với mọi phép logic/shift |

> **Lưu ý:** `zero` là `assign` (combinational), `negative` và `overflow` là `reg` trong `always @(*)`.
