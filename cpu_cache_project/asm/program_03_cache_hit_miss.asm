# program_03_cache_hit_miss.asm
# Purpose: repeated LW from same word address.
# Expected: first LW miss and refill, second LW hit after cache implementation.

.text
.org 0x0000

main:
    ADDI R1, R0, 16
    LW   R2, 0(R1)
    LW   R3, 0(R1)
    HALT

.data
.org 0x0010
cache_data:
    .word 0x002A
