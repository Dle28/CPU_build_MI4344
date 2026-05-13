# Kế hoạch kiểm thử (Test Plan)

## 1. Test module

| Testbench | Mục đích | Trạng thái |
|---|---|---|
| `alu_tb.v` | Kiểm tra ADD/SUB/AND/OR/XOR/SLT/SLL/SRL + cờ `zero/negative/overflow` | Đã có |
| `register_file_tb.v` | Kiểm tra read/write/reset + bỏ ghi R0 | Đã có |
| `cpu_cache_tb.v` | Test tích hợp tối thiểu: chạy chương trình nhỏ và kiểm tra giá trị thanh ghi | Đã có |
| `control_unit_tb.v` | Kiểm tra các tín hiệu điều khiển theo opcode/funct | Placeholder |
| `main_memory_tb.v` | Kiểm tra delay và chỉ 1 outstanding request | Placeholder |
| `cache_tb.v` | Kiểm tra hit/miss/refill/write-through/no-write-allocate | Placeholder |
| `memory_arbiter_tb.v` | Kiểm tra ưu tiên MEM > IF | Placeholder |
| `cpu_core_tb.v` | Kiểm tra hành vi core (pipeline khi có) | Placeholder |

## 2. Test tích hợp theo chương trình

| Program | Mục tiêu kỳ vọng |
|---|---|
| `program_01_arithmetic.asm` | ALU và writeback |
| `program_02_load_store.asm` | LW/SW qua đường bộ nhớ |
| `program_03_cache_hit_miss.asm` | miss lần đầu, hit các lần sau |
| `program_04_hazard.asm` | load-use stall và bubble |
| `program_05_branch.asm` | BEQ taken và flush đường sai |
| `program_06_full_demo.asm` | demo tổng hợp cuối cùng |

Ghi chú: các file `.mem` trong `mem/` hiện có thể là placeholder nếu assembler chưa sinh đủ. Test tích hợp có thể dùng `.mem` hand-encode tạm thời để bring-up.

## 3. Tín hiệu waveform nên quan sát

- `debug_pc`
- `stall`, `flush` (khi có pipeline)
- `cache_req`, `cache_ready`
- `hit`, `miss`
- `mem_req`, `mem_ready`
- writeback address/data

## 4. Tiêu chí tối thiểu để xem là đạt

- `R0` luôn đọc ra 0.
- PC tăng đúng 1 word mỗi lệnh (trừ branch/jump).
- LW/SW hoạt động đúng trên đường bộ nhớ thống nhất.
- Cache (khi hoàn thiện) quan sát được hit/miss.
- Demo cuối chạy tới HALT.
