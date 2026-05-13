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
| `NOP` | `16'h0000` |

## Định dạng lệnh

R-type:

```text
[15:12] opcode
[11:9]  rs
[8:6]   rt
[5:3]   rd
[2:0]   funct
```

I-type:

```text
[15:12] opcode
[11:9]  rs
[8:6]   rt
[5:0]   imm6
```

J-type:

```text
[15:12] opcode
[11:0]  address
```

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

## Bảng funct (R-type)

Opcode R-type luôn là `4'h0`.

| Funct | Mnemonic |
|---|---|
| `3'h0` | `ADD` |
| `3'h1` | `SUB` |
| `3'h2` | `AND` |
| `3'h3` | `OR` |
| `3'h4` | `XOR` |
| `3'h5` | `SLT` |
| `3'h6` | `SLL` |
| `3'h7` | `SRL` |

## Quy ước toán hạng Assembly

Cú pháp khuyến nghị:

```asm
ADD  rd, rs, rt
ADDI rt, rs, imm6
LW   rt, imm6(rs)
SW   rt, imm6(rs)
BEQ  rs, rt, label
BNE  rs, rt, label
J    label
HALT
```

## Quy tắc địa chỉ nhánh (Branch)

Nhánh được resolve ở EX (mục tiêu pipeline). Địa chỉ nhánh:

```text
branch_target = PC_plus_1 + sign_extend(imm6)
```

Assembler nên mã hoá nhãn nhánh theo:

```text
imm6 = label_address - (branch_pc + 1)
```

## Quy tắc địa chỉ nhảy (Jump)

Jump dùng địa chỉ tuyệt đối 12-bit (word address):

```text
jump_target = zero_extend(address[11:0])
```

## Quy tắc shift

`SLL` và `SRL` dùng các bit thấp của toán hạng `rt` làm số lần dịch. Không có lệnh shift-immediate riêng trong ISA locked.
