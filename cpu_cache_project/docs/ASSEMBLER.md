# Tài liệu Trình Biên dịch Hợp ngữ (Assembler)

`assembler.py` là trình biên dịch mã nguồn Assembly (.asm) sang dạng mã máy thập lục phân (.mem). Tệp `.mem` đầu ra được thiết kế theo đúng chuẩn để nạp vào bộ nhớ RAM của mô phỏng Verilog thông qua lệnh `$readmemh`.

## 1. Cú pháp chạy lệnh (Usage)

Để chạy Assembler, sử dụng command line (Terminal/CMD) tại thư mục gốc của project:

```bash
python tools/assembler.py <đường_dẫn_file_asm_đầu_vào> <đường_dẫn_file_mem_đầu_ra>
```

**Ví dụ:**
```bash
python tools/assembler.py asm/program_01_arithmetic.asm mem/program_01_arithmetic.mem
```

---

## 2. Kiến trúc Trình Biên dịch (Two-Pass Assembler)

Vì hợp ngữ cho phép sử dụng các **Nhãn nhảy (Jump/Branch Labels)** được định nghĩa ở *sau* lời gọi lệnh, Assembler bắt buộc phải đọc mã nguồn làm 2 vòng (2 passes) để giải quyết các tham chiếu chéo (Forward References):

### Pass 1: Quét nhãn và phân giải không gian (Label Collection)
- Đọc từng dòng lệnh để loại bỏ chú thích (các chữ sau ký tự `#`).
- Gán một con trỏ địa chỉ `PC` (Program Counter) nội bộ bắt đầu từ `0`.
- Nếu phát hiện **Nhãn** (ví dụ `LOOP:`), nó lưu địa chỉ `PC` hiện tại vào bảng Băm (Dictionary/Symbol Table).
- Bỏ qua các directive `.text` và `.data` (chỉ có tính trang trí), nhưng can thiệp trực tiếp vào giá trị `PC` nếu gặp directive `.org <địa_chỉ>`.
- Lưu lại các dòng lệnh hợp lệ cùng với dòng (line number) gốc để chuyển qua Pass 2.

### Pass 2: Mã hóa lệnh (Instruction Encoding)
- Quét lại danh sách các lệnh đã được làm sạch từ Pass 1.
- Dựa vào ký hiệu lệnh (Mnemonic) để phân loại thành `R-type`, `I-type` hoặc `J-type`.
- Tra bảng `OPCODES` và `FUNCTS` nội bộ để lấy mã bit tương ứng.
- Phân tích cú pháp thanh ghi (từ `R0` đến `R7`).
- **Phân giải nhãn:** Tính toán offset rẽ nhánh `PC_offset = target_PC - (current_PC + 1)` cho các lệnh `BEQ/BNE` và thay thế tên nhãn bằng số nguyên 12-bit cho lệnh `J`.
- Cảnh báo lỗi lập tức nếu sai cú pháp (Kèm số dòng nhờ dữ liệu của Pass 1).

---

## 3. Cú pháp hỗ trợ (Supported Syntax)

### Lệnh cơ bản
Mọi lệnh được quy định trong `ISA.md` đều được hỗ trợ đầy đủ. Có thể phân tách tham số bằng dấu phẩy, dấu cách hoặc dấu ngoặc.
- **R-type**: `ADD R1, R2, R3`
- **I-type**: `ADDI R1, R2, -5` hoặc `LW R1, 4(R2)`
- **J-type**: `J TARGET_LABEL`

### Chỉ thị (Directives)
Trình biên dịch cung cấp các macro và directive hỗ trợ viết code linh hoạt:
- **`#`** : Bắt đầu một dòng chú thích.
- **`Nhãn:`** : Đánh dấu một mốc địa chỉ bộ nhớ (VD: `START:`).
- **`.org <địa_chỉ>`** : Ép trình biên dịch dịch các lệnh tiếp theo bắt đầu từ địa chỉ `<địa_chỉ>` (hữu ích cho việc cách ly bộ nhớ Data và bộ nhớ Instruction).
- **`.WORD <giá_trị>`** : Ghi trực tiếp một số thập phân hoặc hex 16-bit vào bộ nhớ tại dòng hiện tại (Dùng để khởi tạo hằng số trong RAM).
- **`NOP`** : Mã giả (Pseudo-instruction), tương đương `ADD R0, R0, R0` (Mã máy: `0x0000`).
- **`HALT`** : Lệnh hệ thống, mã hoá thành Opcode `0xF000` nhằm báo cho CPU ngừng hoạt động.
- **`.text` / `.data`** : Các directive trang trí vùng nhớ, bị bỏ qua khi biên dịch (không tốn tài nguyên bộ nhớ).

---

## 4. Cơ chế xử lý lỗi (Error Handling)

Thay vì "văng" các Exception chung chung khó đọc của Python, Assembler sử dụng Custom Exception `AssemblerError`. Lỗi luôn luôn đính kèm:
1. **Số dòng gốc (Line Number)** bị sai trong file `.asm`.
2. Lỗi chi tiết (VD: Thanh ghi nằm ngoài R0-R7, offset vượt quá độ dài bit, hoặc gõ sai Mnemonic).

Ví dụ màn hình in ra:
```text
LOI BIEN DICH: Lỗi ở dòng 15: Cú pháp ADDI không hợp lệ: ADDI R1, R2
```

## 5. Cấu trúc đầu ra (Output Format)

File `.mem` sinh ra là file dạng text thuần túy (ASCII) với cú pháp được thiết kế tối ưu cho Verilog (`$readmemh`):
- Mỗi dòng chứa một Word mã máy 16-bit dưới dạng số Hex (4 ký tự).
- Nếu lệnh `.org` làm địa chỉ nhảy vọt (không liên tiếp), công cụ tự động thêm token chỉ định địa chỉ bằng dấu `@`. Ví dụ: `@002A` báo hiệu các dòng hex tiếp theo bắt đầu từ vùng nhớ số `0x2A`.
