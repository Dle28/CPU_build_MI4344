# FSM Cache

## Chính sách cache (Locked)

| Tính năng | Quyết định |
|---|---|
| Loại | Unified direct-mapped cache |
| Số line | 16 |
| Line size | 1 word |
| Độ rộng địa chỉ | word address 16-bit |
| Độ rộng dữ liệu | 16-bit |
| Write policy | Write-through |
| Write miss policy | No-write-allocate |
| Read miss policy | Read-allocate |

## Tách địa chỉ

Vì mỗi line chỉ chứa đúng 1 word nên không có offset bit.

```text
address[15:4] = tag
address[3:0]  = index
```

Các mảng cache:

```text
valid_array : 16 x 1
tag_array   : 16 x 12
data_array  : 16 x 16
```

## Hành vi đọc

Read hit:

```text
trả data_array[index]
ready = 1
hit = 1
```

Read miss:

```text
gửi yêu cầu xuống main memory
đợi mem_ready
refill valid/tag/data
trả dữ liệu vừa nạp
ready = 1
miss = 1 trong lúc xử lý miss
```

## Hành vi ghi

Write hit:

```text
cập nhật data_array[index]
ghi cùng word xuống main memory (write-through)
ready khi ghi RAM hoàn tất
```

Write miss:

```text
ghi thẳng xuống main memory
không allocate line trong cache
ready khi ghi RAM hoàn tất
```

## Các trạng thái FSM (mục tiêu)

| State | Mục đích |
|---|---|
| `IDLE` | chờ yêu cầu từ CPU/arbiter |
| `LOOKUP` | đọc valid/tag/data và so tag |
| `HIT_READ` | trả dữ liệu đọc trong cache |
| `HIT_WRITE` | update cache và bắt đầu write-through |
| `MISS_READ_REQ` | phát yêu cầu RAM read |
| `MISS_READ_WAIT` | đợi RAM trả dữ liệu |
| `REFILL` | nạp lại line cache |
| `MISS_WRITE_REQ` | phát yêu cầu RAM write (không allocate) |
| `MISS_WRITE_WAIT` | đợi RAM ghi xong |
| `DONE` | pulse `ready`, quay về `IDLE` |

## Ghi chú triển khai

- Chỉ cho phép 1 request outstanding.
- Khi FSM không ở `IDLE`, cần latch `addr/we/wdata` ổn định.
- `ready` phải là tín hiệu hoàn tất sạch cho arbiter.
- Không thêm dirty bit hay write-back.

## Trạng thái hiện tại

- Module cache hiện tại đang pass-through tới `main_memory` để bring-up đường dữ liệu.
- FSM đúng theo tài liệu này là mục tiêu cho giai đoạn tiếp theo.
