#!/usr/bin/env python3
# tick: đã xong
"""Assembler hoàn chỉnh cho kiến trúc CPU 16-bit Von Neumann.

Chức năng:
    Chương trình này biên dịch mã nguồn Assembly (.asm) thành mã máy dạng Hex (.mem)
    để nạp vào bộ nhớ (main_memory) của mô phỏng Verilog.

Cách sử dụng:
    python tools/assembler.py asm/program_01_arithmetic.asm mem/program_01_arithmetic.mem

Quá trình biên dịch gồm 2 bước (Two-pass Assembler):
    - Pass 1: Quét qua toàn bộ mã nguồn, tính toán địa chỉ (PC) cho từng lệnh và
      thu thập địa chỉ của tất cả các nhãn (labels).
    - Pass 2: Quét lại mã nguồn, dựa vào bảng nhãn đã thu thập để mã hoá (encode)
      từng dòng lệnh Assembly thành mã máy 16-bit tương ứng.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


# Bảng mã OPCODES định nghĩa 4 bit cao nhất [15:12] của mỗi lệnh
OPCODES = {
    "R": 0x0,       # Tất cả các lệnh R-type (ADD, SUB, AND, OR, XOR, SLT, SLL, SRL) đều có opcode = 0
    "ADDI": 0x1,    # Lệnh cộng hằng số (I-type)
    "LW": 0x2,      # Lệnh Load Word (I-type)
    "SW": 0x3,      # Lệnh Store Word (I-type)
    "BEQ": 0x4,     # Lệnh Branch if Equal (I-type)
    "BNE": 0x5,     # Lệnh Branch if Not Equal (I-type)
    "J": 0x6,       # Lệnh Jump (J-type)
    "HALT": 0xF,    # Lệnh dừng chương trình
}

# Bảng mã FUNCTS định nghĩa 3 bit thấp nhất [2:0] để phân biệt các lệnh R-type
FUNCTS = {
    "ADD": 0x0,
    "SUB": 0x1,
    "AND": 0x2,
    "OR": 0x3,
    "XOR": 0x4,
    "SLT": 0x5,
    "SLL": 0x6,
    "SRL": 0x7,
}

R_TYPE = set(FUNCTS.keys())
I_TYPE = {"ADDI", "LW", "SW", "BEQ", "BNE"}


class AssemblerError(Exception):
    """Lớp Exception tuỳ chỉnh để báo lỗi biên dịch kèm theo số dòng (nếu có)."""
    pass


def strip_comment(line: str) -> str:
    """Loại bỏ phần chú thích (bắt đầu bằng ký tự #) khỏi một dòng lệnh."""
    return line.split("#", 1)[0].strip()


def parse_int(token: str) -> int:
    """Chuyển đổi chuỗi thành số nguyên (hỗ trợ cả hệ thập phân, thập lục phân 0x, v.v.)."""
    try:
        return int(token, 0)
    except ValueError:
        raise AssemblerError(f"Không thể phân tích giá trị số: {token!r}")


def parse_register(token: str) -> int:
    """Phân tích tên thanh ghi (ví dụ: 'R1', 'R7') và trả về số hiệu thanh ghi (0-7)."""
    token = token.strip().upper()
    if not re.fullmatch(r"R[0-7]", token):
        raise AssemblerError(f"Thanh ghi không hợp lệ {token!r}; mong đợi R0..R7")
    return int(token[1])


def tokenize_instruction(line: str) -> list[str]:
    """Tách dòng lệnh thành các từ khoá (tokens) bằng cách loại bỏ dấu phẩy và dấu ngoặc."""
    line = line.replace(",", " ")
    line = line.replace("(", " ")
    line = line.replace(")", " ")
    return [part for part in line.split() if part]


def pass1_collect_labels(raw_lines: list[str]) -> tuple[dict[str, int], list[tuple[int, int, str]]]:
    """
    PASS 1: Thu thập địa chỉ của các nhãn (labels).
    
    Quét qua mã nguồn:
    - Nếu gặp nhãn (ví dụ 'LOOP:'), lưu địa chỉ PC hiện tại vào từ điển 'labels'.
    - Nếu gặp lệnh thông thường, lưu lại lệnh kèm địa chỉ PC và số dòng để xử lý ở Pass 2,
      sau đó tăng PC lên 1.
    - Xử lý các directive như '.org' để thay đổi địa chỉ PC hiện tại.
    
    Trả về:
    - labels: Từ điển ánh xạ từ tên nhãn sang địa chỉ (PC).
    - items: Danh sách các lệnh cần biên dịch, mỗi phần tử là một tuple (số dòng gốc, PC, nội dung lệnh).
    """
    labels: dict[str, int] = {}
    items: list[tuple[int, int, str]] = []
    pc = 0

    for line_num, raw in enumerate(raw_lines, start=1):
        line = strip_comment(raw)
        if not line:
            continue

        # Nếu dòng có chứa dấu hai chấm, đây là một nhãn (label)
        if ":" in line:
            label, rest = line.split(":", 1)
            labels[label.strip()] = pc
            line = rest.strip()
            if not line:
                continue

        lower = line.lower()
        # Directive .org: Thiết lập lại địa chỉ PC
        if lower.startswith(".org"):
            parts = line.split()
            if len(parts) < 2:
                raise AssemblerError(f"Dòng {line_num}: Lệnh .org thiếu địa chỉ")
            pc = parse_int(parts[1])
            continue
            
        # Bỏ qua các directive vùng nhớ không dùng
        if lower in {".text", ".data"}:
            continue

        # Lưu lại lệnh hợp lệ để xử lý trong Pass 2
        items.append((line_num, pc, line))
        pc += 1

    return labels, items


def encode_imm6(value: int) -> int:
    """Mã hoá giá trị immediate 6-bit. Đảm bảo giá trị nằm trong khoảng -32 đến 31."""
    if value < -32 or value > 31:
        raise AssemblerError(f"Giá trị immediate 6-bit vượt quá giới hạn: {value}")
    # Sử dụng bitmask 0x3F để lấy 6 bit cuối cùng
    return value & 0x3F


def encode_word(line_num: int, line: str, pc: int, labels: dict[str, int]) -> int:
    """
    PASS 2: Mã hoá một dòng lệnh Assembly thành mã máy 16-bit.
    
    Phân tích từng loại lệnh (R-type, I-type, J-type) dựa vào format quy định trong ISA.
    """
    try:
        tokens = tokenize_instruction(line)
        if not tokens:
            return 0

        mnemonic = tokens[0].upper()

        # Xử lý directive gán dữ liệu trực tiếp
        if mnemonic == ".WORD":
            if len(tokens) < 2:
                raise AssemblerError("Lệnh .WORD thiếu giá trị")
            return parse_int(tokens[1]) & 0xFFFF

        # NOP tương đương với lệnh: ADD R0, R0, R0 -> mã máy: 0x0000
        if mnemonic == "NOP":
            return 0x0000

        # HALT là lệnh nhảy đặc biệt (Opcode = 0xF) dừng CPU
        if mnemonic == "HALT":
            return OPCODES["HALT"] << 12

        # --- Mã hoá nhóm lệnh R-type ---
        # Định dạng: opcode[15:12] | rs[11:9] | rt[8:6] | rd[5:3] | funct[2:0]
        # Cú pháp Assembly: Mnemonic rd, rs, rt
        if mnemonic in R_TYPE:
            if len(tokens) < 4:
                raise AssemblerError(f"Cú pháp R-type không hợp lệ (cần rd, rs, rt): {line}")
            rd = parse_register(tokens[1])
            rs = parse_register(tokens[2])
            rt = parse_register(tokens[3])
            return (OPCODES["R"] << 12) | (rs << 9) | (rt << 6) | (rd << 3) | FUNCTS[mnemonic]

        # --- Mã hoá nhóm lệnh I-type ---
        # Lệnh ADDI: rt, rs, imm6
        if mnemonic == "ADDI":
            if len(tokens) < 4:
                raise AssemblerError(f"Cú pháp ADDI không hợp lệ: {line}")
            rt = parse_register(tokens[1])
            rs = parse_register(tokens[2])
            imm6 = encode_imm6(parse_int(tokens[3]))
            return (OPCODES[mnemonic] << 12) | (rs << 9) | (rt << 6) | imm6

        # Lệnh LW, SW: rt, imm6(rs)
        if mnemonic in {"LW", "SW"}:
            if len(tokens) < 4:
                raise AssemblerError(f"Cú pháp LW/SW không hợp lệ: {line}")
            rt = parse_register(tokens[1])
            imm6 = encode_imm6(parse_int(tokens[2]))
            rs = parse_register(tokens[3])
            return (OPCODES[mnemonic] << 12) | (rs << 9) | (rt << 6) | imm6

        # Lệnh Rẽ nhánh (BEQ, BNE): rs, rt, label
        if mnemonic in {"BEQ", "BNE"}:
            if len(tokens) < 4:
                raise AssemblerError(f"Cú pháp {mnemonic} không hợp lệ: {line}")
            rs = parse_register(tokens[1])
            rt = parse_register(tokens[2])
            target_str = tokens[3]
            
            # Tính toán địa chỉ offset
            # Bắt buộc target offset phải là một số hoặc nhãn (label)
            target = labels.get(target_str)
            if target is None:
                try:
                    # Nếu không phải label, thử phân tích như một số trực tiếp
                    target = parse_int(target_str)
                except Exception:
                    raise AssemblerError(f"Không tìm thấy nhãn rẽ nhánh (branch label): {target_str}")
            
            # Offset được tính tương đối so với PC của lệnh tiếp theo (PC + 1)
            offset = target - (pc + 1)
            return (OPCODES[mnemonic] << 12) | (rs << 9) | (rt << 6) | encode_imm6(offset)

        # --- Mã hoá nhóm lệnh J-type ---
        # Lệnh Jump: J label
        # Định dạng: opcode[15:12] | address[11:0]
        if mnemonic == "J":
            if len(tokens) < 2:
                raise AssemblerError(f"Cú pháp lệnh J không hợp lệ: {line}")
            target_str = tokens[1]
            
            target = labels.get(target_str)
            if target is None:
                try:
                    target = parse_int(target_str)
                except Exception:
                    raise AssemblerError(f"Không tìm thấy nhãn nhảy (jump label): {target_str}")
            
            if target < 0 or target > 0x0FFF:
                raise AssemblerError(f"Địa chỉ nhảy vượt quá phạm vi 12-bit (0-0xFFF): {target}")
                
            return (OPCODES["J"] << 12) | (target & 0x0FFF)

        # Nếu lệnh không khớp với bất kỳ Mnemonic nào đã định nghĩa
        raise AssemblerError(f"Không hỗ trợ lệnh/chỉ thị (unsupported instruction): {mnemonic}")
        
    except AssemblerError as e:
        # Gắn thêm số dòng vào thông báo lỗi nếu có lỗi do AssemblerError sinh ra
        raise AssemblerError(f"Lỗi ở dòng {line_num}: {str(e)}")
    except Exception as e:
        raise AssemblerError(f"Lỗi cú pháp ở dòng {line_num} ({line}): {str(e)}")


def write_mem(items: list[tuple[int, int]], output_path: Path) -> None:
    """Ghi danh sách mã máy ra file định dạng bộ nhớ Hex (.mem) hỗ trợ bởi hàm $readmemh trong Verilog."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="ascii") as f:
        last_addr = None
        for addr, word in items:
            # Dùng directive @địa_chỉ nếu địa chỉ không liên tiếp
            if last_addr is None or addr != last_addr + 1:
                f.write(f"@{addr:04X}\n")
            # Ghi mã máy 16-bit dưới dạng Hex 4 ký tự
            f.write(f"{word & 0xFFFF:04X}\n")
            last_addr = addr


def assemble(input_path: Path, output_path: Path) -> None:
    """Hàm chạy chính điều khiển toàn bộ quá trình biên dịch Assembler."""
    raw_lines = input_path.read_text(encoding="utf-8").splitlines()
    
    try:
        # Bước 1: Thu thập địa chỉ nhãn
        labels, parsed_items = pass1_collect_labels(raw_lines)

        # Bước 2: Mã hoá từng dòng lệnh
        encoded_items = []
        for line_num, pc, line in parsed_items:
            machine_code = encode_word(line_num, line, pc, labels)
            encoded_items.append((pc, machine_code))

        # Bước 3: Ghi ra file .mem
        write_mem(encoded_items, output_path)
        print(f"Bien dich thanh cong: {input_path} -> {output_path}")
    except AssemblerError as e:
        print(f"LOI BIEN DICH: {e}", file=sys.stderr)
        sys.exit(1)


def main() -> int:
    parser = argparse.ArgumentParser(description="Biên dịch mã Assembly CPU 16-bit sang mã máy (.mem)")
    parser.add_argument("input", type=Path, help="File mã nguồn .asm đầu vào")
    parser.add_argument("output", type=Path, help="File mã máy .mem đầu ra")
    args = parser.parse_args()

    assemble(args.input, args.output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
