# GÓI THỰC THI PHẦN CỨNG: PHÂN HỆ BỘ NHỚ & CACHE
**Chỉ thị:** Copy toàn bộ mã nguồn dưới đây vào đúng tên file được chỉ định trong thư mục `rtl/memory/`. Không tự ý sửa đổi bất kỳ biến số nào.

---

## BƯỚC 1: TẠO FILE CẤU HÌNH GỐC (SINGLE SOURCE OF TRUTH)
**Tên file:** `cache_config.vh`
**Bản chất:** Nơi lưu trữ toàn bộ các hằng số mạng lưới. Các file khác sẽ gọi hằng số từ đây để tránh lệch bit.

```verilog
// ==============================================================================
// FILE: cache_config.vh
// ==============================================================================
`ifndef CACHE_CONFIG_VH
`define CACHE_CONFIG_VH

// 1. Kích thước Bus
`define ADDR_WIDTH 16
`define DATA_WIDTH 16

// 2. Cấu trúc Cache (Direct-Mapped 16 lines, 1 word/line)
`define TAG_MSB 15
`define TAG_LSB 4
`define IDX_MSB 3
`define IDX_LSB 0
`define CACHE_DEPTH 16
`define TAG_WIDTH 12

// 3. Máy trạng thái FSM (Kiến trúc 10 States bảo vệ Pipeline)
`define STATE_IDLE            4'b0000
`define STATE_LOOKUP          4'b0001
`define STATE_HIT_READ        4'b0010
`define STATE_HIT_WRITE       4'b0011
`define STATE_MISS_READ_REQ   4'b0100
`define STATE_MISS_READ_WAIT  4'b0101
`define STATE_REFILL          4'b0110
`define STATE_MISS_WRITE_REQ  4'b0111
`define STATE_MISS_WRITE_WAIT 4'b1000
`define STATE_DONE            4'b1001

// 4. Độ trễ phần cứng
`define RAM_DELAY 5

`endif // CACHE_CONFIG_VH