#!/usr/bin/env python3
# tick: đã xong
"""Skeleton assembler for the locked 16-bit CPU ISA.

Usage:
    python tools/assembler.py asm/program_01_arithmetic.asm mem/program_01_arithmetic.mem

This file intentionally starts small. It already contains the locked opcode
and funct dictionaries, register parsing, and a two-pass shape. TODO items
mark the places that need stronger error handling and full syntax coverage.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


OPCODES = {
    "R": 0x0,
    "ADDI": 0x1,
    "LW": 0x2,
    "SW": 0x3,
    "BEQ": 0x4,
    "BNE": 0x5,
    "J": 0x6,
    "HALT": 0xF,
}

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


def strip_comment(line: str) -> str:
    return line.split("#", 1)[0].strip()


def parse_int(token: str) -> int:
    return int(token, 0)


def parse_register(token: str) -> int:
    token = token.strip().upper()
    if not re.fullmatch(r"R[0-7]", token):
        raise ValueError(f"Invalid register {token!r}; expected R0..R7")
    return int(token[1])


def tokenize_instruction(line: str) -> list[str]:
    line = line.replace(",", " ")
    line = line.replace("(", " ")
    line = line.replace(")", " ")
    return [part for part in line.split() if part]


def normalize_lines(source: str) -> list[str]:
    lines = []
    for raw in source.splitlines():
        line = strip_comment(raw)
        if line:
            lines.append(line)
    return lines


def pass1_collect_labels(lines: list[str]) -> tuple[dict[str, int], list[tuple[int, str]]]:
    labels: dict[str, int] = {}
    items: list[tuple[int, str]] = []
    pc = 0

    for line in lines:
        if ":" in line:
            label, rest = line.split(":", 1)
            labels[label.strip()] = pc
            line = rest.strip()
            if not line:
                continue

        lower = line.lower()
        if lower.startswith(".org"):
            pc = parse_int(line.split()[1])
            continue
        if lower in {".text", ".data"}:
            continue

        items.append((pc, line))
        pc += 1

    return labels, items


def encode_imm6(value: int) -> int:
    if value < -32 or value > 31:
        raise ValueError(f"imm6 value out of range: {value}")
    return value & 0x3F


def encode_word(line: str, pc: int, labels: dict[str, int]) -> int:
    tokens = tokenize_instruction(line)
    if not tokens:
        return 0

    mnemonic = tokens[0].upper()

    if mnemonic == ".WORD":
        return parse_int(tokens[1]) & 0xFFFF

    if mnemonic == "NOP":
        return 0x0000

    if mnemonic == "HALT":
        return OPCODES["HALT"] << 12

    if mnemonic in R_TYPE:
        # Assembly syntax: ADD rd, rs, rt
        # Encoding: opcode, rs, rt, rd, funct
        rd = parse_register(tokens[1])
        rs = parse_register(tokens[2])
        rt = parse_register(tokens[3])
        return (OPCODES["R"] << 12) | (rs << 9) | (rt << 6) | (rd << 3) | FUNCTS[mnemonic]

    if mnemonic == "ADDI":
        # Assembly syntax: ADDI rt, rs, imm6
        rt = parse_register(tokens[1])
        rs = parse_register(tokens[2])
        imm6 = encode_imm6(parse_int(tokens[3]))
        return (OPCODES[mnemonic] << 12) | (rs << 9) | (rt << 6) | imm6

    if mnemonic in {"LW", "SW"}:
        # Assembly syntax: LW rt, imm6(rs)
        rt = parse_register(tokens[1])
        imm6 = encode_imm6(parse_int(tokens[2]))
        rs = parse_register(tokens[3])
        return (OPCODES[mnemonic] << 12) | (rs << 9) | (rt << 6) | imm6

    if mnemonic in {"BEQ", "BNE"}:
        # Assembly syntax: BEQ rs, rt, label
        rs = parse_register(tokens[1])
        rt = parse_register(tokens[2])
        target = labels.get(tokens[3], parse_int(tokens[3]) if re.match(r"^-?0", tokens[3]) else None)
        if target is None:
            raise ValueError(f"Unknown branch label: {tokens[3]}")
        offset = target - (pc + 1)
        return (OPCODES[mnemonic] << 12) | (rs << 9) | (rt << 6) | encode_imm6(offset)

    if mnemonic == "J":
        target = labels.get(tokens[1], parse_int(tokens[1]) if re.match(r"^(0x|[0-9])", tokens[1]) else None)
        if target is None:
            raise ValueError(f"Unknown jump label: {tokens[1]}")
        if target < 0 or target > 0x0FFF:
            raise ValueError(f"Jump target out of range: {target}")
        return (OPCODES["J"] << 12) | (target & 0x0FFF)

    # TODO: replace with a richer diagnostic that includes source line number.
    raise ValueError(f"Unsupported instruction/directive: {line}")


def write_mem(items: list[tuple[int, int]], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="ascii") as f:
        last_addr = None
        for addr, word in items:
            if last_addr is None or addr != last_addr + 1:
                f.write(f"@{addr:04X}\n")
            f.write(f"{word & 0xFFFF:04X}\n")
            last_addr = addr


def assemble(input_path: Path, output_path: Path) -> None:
    lines = normalize_lines(input_path.read_text(encoding="ascii"))
    labels, parsed_items = pass1_collect_labels(lines)

    encoded_items = []
    for pc, line in parsed_items:
        encoded_items.append((pc, encode_word(line, pc, labels)))

    write_mem(encoded_items, output_path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Assemble locked 16-bit CPU .asm to .mem")
    parser.add_argument("input", type=Path, help="Input .asm file")
    parser.add_argument("output", type=Path, help="Output .mem file")
    args = parser.parse_args()

    assemble(args.input, args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
