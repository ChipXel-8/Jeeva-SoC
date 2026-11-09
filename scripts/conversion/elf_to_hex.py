#!/usr/bin/env python3

import sys
import os

def binary_to_word_hex(input_file, output_file):
    with open(input_file, "rb") as f:
        data = f.read()

    # Pad to a complete 32-bit word if necessary
    while len(data) % 4 != 0:
        data += b"\x00"

    with open(output_file, "w") as f:
        for i in range(0, len(data), 4):
            b0 = data[i]
            b1 = data[i + 1]
            b2 = data[i + 2]
            b3 = data[i + 3]

            # RISC-V is little endian.
            # memory[] in pragya_imem is 32-bit word organized.
            word = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)

            f.write("{:08x}\n".format(word))

    print("Input :", input_file)
    print("Output:", output_file)
    print("Bytes :", len(data))
    print("Words :", len(data) // 4)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: elf_to_hex.py <input.bin> <output.mem>")
        sys.exit(1)

    binary_to_word_hex(sys.argv[1], sys.argv[2])
