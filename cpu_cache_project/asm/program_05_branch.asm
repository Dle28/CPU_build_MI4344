# program_05_branch.asm
# Purpose: taken BEQ should flush wrong-path instruction.

.text
.org 0x0000

main:
    ADDI R1, R0, 5
    ADDI R2, R0, 5
    BEQ  R1, R2, taken
    ADDI R3, R0, 31     # wrong path, must be flushed
taken:
    ADDI R4, R0, 9
    HALT
