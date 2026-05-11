# program_04_hazard.asm
# Purpose: load-use hazard.
# Expected: LW followed by dependent ADD causes stall + bubble.

.text
.org 0x0000

main:
    ADDI R1, R0, 16
    LW   R2, 0(R1)
    ADD  R3, R2, R2
    ADD  R4, R3, R2
    HALT

.data
.org 0x0010
hazard_data:
    .word 0x0007
