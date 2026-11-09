#!/usr/bin/env python3

import sys

def binary_to_word_hex(input_file, output_file):
    with open(input_file, "rb") as f:
        data = f.read()

    with open(output_file, "w") as f:
        # Step through the binary data 4 bytes at a time
        for i in range(0, len(data), 4):
            chunk = data[i:i+4]
            # Zero-pad if the last chunk is less than 4 bytes
            if len(chunk) < 4:
                chunk = chunk.ljust(4, b'\x00')
            
            # Format as a 32-bit word (Little-Endian: Byte 3, Byte 2, Byte 1, Byte 0)
            word = "{:02x}{:02x}{:02x}{:02x}\n".format(chunk[3], chunk[2], chunk[1], chunk[0])
            f.write(word)

    print("Input :", input_file)
    print("Output:", output_file)
    # Calculate how many 32-bit words were written
    words = len(data) // 4 + (1 if len(data) % 4 != 0 else 0)
    print("Words :", words)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: bin_to_dmem.py <input.bin> <output.mem>")
        sys.exit(1)

    binary_to_word_hex(sys.argv[1], sys.argv[2])
