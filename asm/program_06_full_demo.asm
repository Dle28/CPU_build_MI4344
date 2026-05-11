# program_06_full_demo.asm
# Purpose: integrated arithmetic, memory, cache, hazard, and branch demo.

.text
.org 0x0000

main:
    ADDI R1, R0, 16     # data base
    ADDI R2, R0, 4
    ADDI R3, R0, 6
    ADD  R4, R2, R3     # forwarding candidate
    SW   R4, 0(R1)      # write-through path
    LW   R5, 0(R1)      # miss then refill
    LW   R6, 0(R1)      # expected hit
    ADD  R7, R5, R6     # load-use/forwarding area
    BEQ  R5, R6, done
    ADDI R7, R0, 31     # wrong path if branch taken
done:
    HALT

.data
.org 0x0010
demo_data:
    .word 0x0000
