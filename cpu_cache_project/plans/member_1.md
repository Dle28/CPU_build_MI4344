# HIỆP ƯỚC GIAO TIẾP PHẦN CỨNG (HARDWARE INTERFACE CONTRACT)
**Phân hệ:** Datapath & ALU (Thành viên 1: Vũ Xuân Hải)
**Kiến trúc mục tiêu:** 16-bit Von Neumann, 5-Stage Pipeline

---

## 1. QUY TẮC TOÀN CỤC (GLOBAL RULES)

- **Độ rộng tín hiệu chuẩn:** mọi bus dữ liệu tính toán là `16-bit`.
- **Độ rộng địa chỉ thanh ghi:** `3-bit` (R0..R7).
- **Nguyên tắc clocking:**
  - ALU / Immediate Generator / MUX: logic tổ hợp, **không** dùng `clk`.
  - Register File: ghi đồng bộ sườn lên `clk`, đọc bất đồng bộ.
- **Luật R0:** R0 hardwired `16'h0000`; mọi ghi vào R0 bị bỏ qua.

---

## 2. MODULE 1: ALU

**File thực thi:** `rtl/cpu/alu.v`
**Vị trí (mục tiêu):** tầng EX

### 2.1. Giao diện cổng

| Hướng | Tên | Độ rộng | Ý nghĩa |
|---|---|---:|---|
| IN | `a` | 16 | toán hạng A |
| IN | `b` | 16 | toán hạng B |
| IN | `alu_op` | 4 | mã điều khiển ALU theo `include/cpu_defines.vh` |
| OUT | `result` | 16 | kết quả |
| OUT | `zero` | 1 | `result == 0`, phục vụ BEQ |
| OUT | `negative` | 1 | `result[15] == 1` |
| OUT | `overflow` | 1 | cờ tràn số có dấu |

### 2.2. Bảng mã điều khiển `alu_op` (4-bit)

Khối điều khiển bắt buộc xuất `alu_op` khớp các macro sau trong `include/cpu_defines.vh`:

- `ALU_ADD` = `4'b0000`
- `ALU_SUB` = `4'b0001`
- `ALU_AND` = `4'b0010`
- `ALU_OR`  = `4'b0011`
- `ALU_XOR` = `4'b0100`
- `ALU_SLT` = `4'b0101`
- `ALU_SLL` = `4'b0110`
- `ALU_SRL` = `4'b0111`

---

## 3. MODULE 2: REGISTER FILE

**File thực thi:** `rtl/cpu/register_file.v`
**Vị trí (mục tiêu):** đọc ở ID, ghi ở WB

### 3.1. Giao diện cổng

| Hướng | Tên | Độ rộng | Ý nghĩa |
|---|---|---:|---|
| IN | `clk` | 1 | clock |
| IN | `rst` | 1 | reset toàn bộ về 0 |
| IN | `rs_addr` | 3 | địa chỉ nguồn 1 |
| IN | `rt_addr` | 3 | địa chỉ nguồn 2 |
| IN | `rd_addr` | 3 | địa chỉ đích ghi |
| IN | `rd_wdata` | 16 | dữ liệu ghi |
| IN | `reg_write` | 1 | cho phép ghi |
| OUT | `rs_data` | 16 | dữ liệu đọc rs (async) |
| OUT | `rt_data` | 16 | dữ liệu đọc rt (async) |

---

## 4. MODULE 3: IMMEDIATE GENERATOR

**File thực thi:** `rtl/cpu/immediate_generator.v`
**Vị trí (mục tiêu):** ID

### 4.1. Giao diện cổng

| Hướng | Tên | Độ rộng | Ý nghĩa |
|---|---|---:|---|
| IN | `imm6` | 6 | hằng số từ I-type |
| IN | `sign_ext` | 1 | `EXT_SIGN` hoặc `EXT_ZERO` (trong `cpu_defines.vh`) |
| OUT | `imm16` | 16 | immediate đã mở rộng |

---

## 5. MODULE 4: MULTIPLEXERS (MUX)

**File thực thi:** `rtl/cpu/mux.v`

- `mux2to1`: dùng cho `ALUSrc`, `MemToReg`.
- `mux3to1`: dùng cho forwarding.

### 5.1. MUX 2-to-1

| Hướng | Tên | Độ rộng | Ý nghĩa |
|---|---|---:|---|
| IN | `d0` | 16 | input 0 |
| IN | `d1` | 16 | input 1 |
| IN | `sel` | 1 | chọn |
| OUT | `y` | 16 | output |

### 5.2. MUX 3-to-1

| Hướng | Tên | Độ rộng | Ý nghĩa |
|---|---|---:|---|
| IN | `d0` | 16 | dữ liệu gốc |
| IN | `d1` | 16 | forward từ WB |
| IN | `d2` | 16 | forward từ MEM |
| IN | `sel` | 2 | chọn |
| OUT | `y` | 16 | output |

---

*Cảnh báo tích hợp:* nếu sai độ rộng bit, sai tên cổng, hoặc sai mã `alu_op` khi gọi các module trên, sẽ dẫn đến lỗi compile/synthesis hoặc kết quả tính sai.
