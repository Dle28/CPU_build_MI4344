# program_01_arithmetic.asm
# Purpose: ADDI, ADD, SUB smoke test.

.text
.org 0x0000

main:
    ADDI R1, R0, 5      # R1 = 5
    ADDI R2, R0, 3      # R2 = 3
    ADD  R3, R1, R2     # R3 = 8
    SUB  R4, R3, R1     # R4 = 3
    HALT
