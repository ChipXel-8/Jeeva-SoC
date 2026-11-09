#!/usr/bin/env python3

import sys

if len(sys.argv) != 4:
    print("Usage: python3 bin_to_word_hex.py input.bin output.hex num_words")
    sys.exit(1)

input_file  = sys.argv[1]
output_file = sys.argv[2]
num_words   = int(sys.argv[3])

with open(input_file, "rb") as f:
    data = f.read()

max_bytes = num_words * 4

if len(data) > max_bytes:
    print("ERROR: binary is larger than target memory")
    print("Binary bytes :", len(data))
    print("Memory bytes :", max_bytes)
    sys.exit(1)

# Pad complete memory with zeros
data += bytes(max_bytes - len(data))

with open(output_file, "w") as f:
    for i in range(0, len(data), 4):
        word = int.from_bytes(data[i:i+4], byteorder="little")
        f.write("{:08x}\n".format(word))

print("Created:", output_file)
print("Words  :", num_words)
print("Bytes  :", num_words * 4)
