# HIỆP ƯỚC GIAO TIẾP PHẦN CỨNG (HARDWARE INTERFACE CONTRACT)
**Phân hệ:** Datapath & ALU (Thành viên 1: Vũ Xuân Hải)
**Kiến trúc:** 16-bit Von Neumann, 5-Stage Pipeline

---

## 1. QUY TẮC TOÀN CỤC (GLOBAL RULES)
*   **Độ rộng tín hiệu chuẩn:** Mọi dòng dữ liệu tính toán (Data Bus) đều là `16-bit`.
*   **Độ rộng địa chỉ thanh ghi:** `3-bit` (Dành cho 8 thanh ghi từ R0 đến R7).
*   **Nguyên tắc Đồng hồ (Clocking):** 
    *   Các khối tổ hợp thuần túy (ALU, Immediate Generator, MUX): **KHÔNG** sử dụng `clk`. Dữ liệu chảy tự do (Combinational Logic).
    *   Tập thanh ghi (Register File): Ghi đồng bộ theo sườn lên của xung nhịp (Positive Edge Clock), Đọc bất đồng bộ (Asynchronous Read) để tránh làm trễ Pipeline tầng ID.
*   **Luật R0:** Thanh ghi R0 bị "hardwired" (gắn cứng) với giá trị `16'h0000`. Mọi nỗ lực ghi tín hiệu vào R0 đều bị phần cứng bỏ qua.

---

## 2. ĐẶC TẢ MODULE 1: Khối tính toán trung tâm (ALU)
**File thực thi:** `src/alu.v`
**Vị trí trong Pipeline:** Tầng EX (Execute)

### 2.1. Giao diện Cổng (Port Interface)
| Hướng | Tên Tín Hiệu | Độ Rộng | Ý Nghĩa Kỹ Thuật & Tương Tác |
| :--- | :--- | :--- | :--- |
| **IN** | `a` | 16-bit | Toán hạng A (thường được MUX chọn từ ID/EX Register hoặc Forwarding). |
| **IN** | `b` | 16-bit | Toán hạng B (thường được MUX chọn từ ID/EX Register, Imm16 hoặc Forwarding). |
| **IN** | `alu_op` | 4-bit | Mã điều khiển từ Control Unit quyết định phép toán phần cứng. |
| **OUT**| `result` | 16-bit | Kết quả tính toán đưa vào thanh ghi EX/MEM. |
| **OUT**| `zero` | 1-bit | Cờ báo `result == 16'h0000`. Phục vụ lệnh BEQ (Branch if Equal). |
| **OUT**| `negative` | 1-bit | Cờ báo kết quả âm (Bit MSB `result[15] == 1`). |
| **OUT**| `overflow` | 1-bit | Cờ báo tràn số có dấu. Xảy ra khi cộng hai số cùng dấu ra khác dấu. |

### 2.2. Bảng chân lý Mã điều khiển (ALU Control Truth Table)
Khối Control Unit (Thành viên 3) bắt buộc phải xuất tín hiệu `alu_op` khớp với bảng mã này:
*   `0000`: Phép Cộng (ADD) -> `result = a + b`
*   `0001`: Phép Trừ (SUB) -> `result = a - b`
*   `0010`: AND Bitwise -> `result = a & b`
*   `0011`: OR Bitwise -> `result = a | b`
*   `0100`: XOR Bitwise -> `result = a ^ b`
*   `0101`: Set on Less Than (SLT) -> `result = (a < b) ? 1 : 0` (So sánh có dấu)
*   `0110`: Shift Left Logical (SLL) -> `result = a << b`
*   `0111`: Shift Right Logical (SRL) -> `result = a >> b`

---

## 3. ĐẶC TẢ MODULE 2: Tập thanh ghi (Register File)
**File thực thi:** `src/register_file.v`
**Vị trí trong Pipeline:** Đọc ở tầng ID (Decode), Ghi ở tầng WB (Write-Back)

### 3.1. Giao diện Cổng (Port Interface)
| Hướng | Tên Tín Hiệu | Độ Rộng | Ý Nghĩa Kỹ Thuật & Tương Tác |
| :--- | :--- | :--- | :--- |
| **IN** | `clk` | 1-bit | Xung nhịp hệ thống. |
| **IN** | `rst` | 1-bit | Đưa toàn bộ 8 thanh ghi về `16'h0000` (Tích cực mức cao: 1). |
| **IN** | `rs_addr` | 3-bit | Địa chỉ thanh ghi nguồn 1 (Trích xuất từ Instruction `[11:9]`). |
| **IN** | `rt_addr` | 3-bit | Địa chỉ thanh ghi nguồn 2 (Trích xuất từ Instruction `[8:6]`). |
| **IN** | `rd_addr` | 3-bit | Địa chỉ thanh ghi đích để ghi dữ liệu (Nhận từ tầng WB). |
| **IN** | `rd_wdata` | 16-bit | Dữ liệu cần ghi vào thanh ghi đích `rd_addr`. |
| **IN** | `reg_write`| 1-bit | Tín hiệu cho phép ghi từ Control Unit. `1` = Ghi tại sườn lên clock, `0` = Khóa ghi. |
| **OUT**| `rs_data` | 16-bit | Giá trị đọc từ thanh ghi `rs_addr` (Xuất ra ngay lập tức, không đợi clock). |
| **OUT**| `rt_data` | 16-bit | Giá trị đọc từ thanh ghi `rt_addr` (Xuất ra ngay lập tức, không đợi clock). |

---

## 4. ĐẶC TẢ MODULE 3: Bộ mở rộng hằng số (Immediate Generator)
**File thực thi:** `src/immediate_generator.v`
**Vị trí trong Pipeline:** Tầng ID (Decode)

### 4.1. Giao diện Cổng (Port Interface)
| Hướng | Tên Tín Hiệu | Độ Rộng | Ý Nghĩa Kỹ Thuật & Tương Tác |
| :--- | :--- | :--- | :--- |
| **IN** | `imm6` | 6-bit | Hằng số rút trích từ lệnh I-Type (Instruction `[5:0]`). |
| **IN** | `sign_ext` | 1-bit | Tín hiệu cấu hình: `1` = Mở rộng có dấu (Sign Extend) phục vụ ADDI/LW/SW. `0` = Mở rộng không dấu (Zero Extend). |
| **OUT**| `imm16` | 16-bit | Số 16-bit đã được mở rộng để đẩy vào ALU. |

---

## 5. ĐẶC TẢ MODULE 4: Các bộ định tuyến (Multiplexers)
**File thực thi:** `src/mux2to1.v`, `src/mux3to1.v`
**Bản chất:** Các công tắc số tử điều hướng dòng chảy dữ liệu. Sẽ được Thành viên 3 gọi (instantiate) nhiều lần ở các tầng khác nhau.

### 5.1. MUX 2-to-1 (Phục vụ ALUSrc, MemToReg)
| Hướng | Tên Tín Hiệu | Độ Rộng | Ý Nghĩa Kỹ Thuật & Tương Tác |
| :--- | :--- | :--- | :--- |
| **IN** | `d0` | 16-bit | Dữ liệu đầu vào số 0. |
| **IN** | `d1` | 16-bit | Dữ liệu đầu vào số 1. |
| **IN** | `sel` |  1-bit | Chốt chọn (Ví dụ: `sel = 0` thì ngõ ra là `d0`). |
| **OUT**| `y` | 16-bit | Dữ liệu được chọn. |

### 5.2. MUX 3-to-1 (Phục vụ Forwarding Unit)
| Hướng | Tên Tín Hiệu | Độ Rộng | Ý Nghĩa Kỹ Thuật & Tương Tác |
| :--- | :--- | :--- | :--- |
| **IN** | `d0` | 16-bit | Dữ liệu gốc (Chưa forward). |
| **IN** | `d1` | 16-bit | Dữ liệu forward từ tầng WB. |
| **IN** | `d2` | 16-bit | Dữ liệu forward từ tầng MEM. |
| **IN** | `sel` | 2-bit | Chốt chọn (Từ `00` đến `10`). |
| **OUT**| `y` | 16-bit | Dữ liệu được chọn đưa vào ALU. |

---
*Cảnh báo cho Thành viên 3 (Tích hợp): Mọi sự vi phạm về độ rộng bit, tên cổng hoặc thiết lập sai mã `alu_op` trong file `cpu_core.v` khi gọi các module này sẽ dẫn đến lỗi tổng hợp (Synthesis Error) hoặc tính toán sai rác.*