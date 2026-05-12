# ISA

## Global Rules

| Feature | Decision |
|---|---|
| Instruction width | 16 bits |
| Data width | 16 bits |
| Registers | 8 registers, `R0` to `R7` |
| `R0` rule | Reads return `16'h0000`; writes are ignored |
| Memory | 16-bit word-addressed |
| PC increment | `PC = PC + 1` |
| `NOP` | `16'h0000` |

## Instruction Formats

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

## Opcode Table

| Opcode | Mnemonic | Type |
|---|---|---|
| `4'h0` | R-type | R |
| `4'h1` | `ADDI` | I |
| `4'h2` | `LW` | I |
| `4'h3` | `SW` | I |
| `4'h4` | `BEQ` | I |
| `4'h5` | `BNE` | I |
| `4'h6` | `J` | J |
| `4'hF` | `HALT` | J-like |

## Funct Table

R-type opcode is always `4'h0`.

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

## Assembly Operand Convention

Recommended assembly syntax:

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

## Branch Target Rule

Branches are resolved in EX.

```text
branch_target = PC_plus_1 + sign_extend(imm6)
```

The assembler should encode label branches as:

```text
imm6 = label_address - (branch_pc + 1)
```

## Jump Target Rule

Jump uses the 12-bit absolute word address field.

```text
jump_target = zero_extend(address[11:0])
```

## Shift Rule

`SLL` and `SRL` use the low bits of the `rt` operand as the shift amount. No
separate shift-immediate instruction exists in the locked ISA.
