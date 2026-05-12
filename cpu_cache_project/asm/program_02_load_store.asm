# program_02_load_store.asm
# Purpose: basic store then load.

.text
.org 0x0000

main:
    ADDI R1, R0, 16     # base address = 0x0010
    ADDI R2, R0, 25     # data = 25
    SW   R2, 0(R1)      # memory[0x0010] = 25
    LW   R3, 0(R1)      # R3 = memory[0x0010]
    HALT

.data
.org 0x0010
data_word:
    .word 0x0000
