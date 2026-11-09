#!/usr/bin/env python3

regs = [
    "x0","x1","x2","x3","x4","x5","x6","x7",
    "x8","x9","x10","x11","x12","x13","x14","x15",
    "x16","x17","x18","x19","x20","x21","x22","x23",
    "x24","x25","x26","x27","x28","x29","x30","x31"
]

tests = [
    ("cross_branch_regs_001", "beq"),
    ("cross_branch_regs_002", "bne"),
    ("cross_branch_regs_003", "blt"),
    ("cross_branch_regs_004", "bge"),
    ("cross_branch_regs_005", "bltu"),
    ("cross_branch_regs_006", "bgeu"),
]


def generate(filename, branch):

    path = "sw/tests/c/" + filename + ".c"

    with open(path, "w") as f:

        f.write('#include "pragya_test.h"\n')
        f.write('#include <stdint.h>\n\n')

        f.write('/*\n')
        f.write(' * ============================================================\n')
        f.write(' * RV32I BRANCH REGISTER CROSS COVERAGE TEST\n')
        f.write(' * ============================================================\n')
        f.write(' *\n')
        f.write(' * Instruction : %s\n' % branch.upper())
        f.write(' *\n')
        f.write(' * 32 rs1 values x 32 rs2 values\n')
        f.write(' *\n')
        f.write(' * TOTAL LEGAL BINS = 1024\n')
        f.write(' *\n')
        f.write(' * RV32I ONLY\n')
        f.write(' * No RV32M\n')
        f.write(' * No SYSTEM\n')
        f.write(' * No CSR\n')
        f.write(' * No FENCE\n')
        f.write(' * ============================================================\n')
        f.write(' */\n\n')

        f.write('int main(void)\n')
        f.write('{\n\n')

        f.write('    /*==========================================================\n')
        f.write('      %s × rs1 × rs2\n' % branch.upper())
        f.write('      32 × 32 = 1024 bins\n')
        f.write('      ==========================================================*/\n\n')

        f.write('    asm volatile (\n\n')

        for i, rs1 in enumerate(regs):

            f.write('        /*----------------------------------------------*/\n')
            f.write('        /* rs1 = %s                                  */\n' % rs1)
            f.write('        /*----------------------------------------------*/\n')

            for j, rs2 in enumerate(regs):

                label = "%s_%d_%d" % (branch, i, j)

                f.write(
                    '        "%s %s,%s,%s\\n"\n'
                    % (branch, rs1, rs2, label)
                )

                f.write(
                    '        "%s:\\n"\n'
                    % label
                )

            f.write('\n')

        f.write('        :\n')
        f.write('        :\n')
        f.write('        : "memory"\n')
        f.write('    );\n\n')

        f.write('    test_pass();\n')
        f.write('    return 0;\n')
        f.write('}\n')

    return path


print()
print("==============================================")
print(" Branch Register Coverage Tests")
print("==============================================")

for filename, branch in tests:

    path = generate(filename, branch)

    print("%-25s : %-4s : 1024 bins" %
          (filename, branch.upper()))

print("----------------------------------------------")
print("TOTAL                    : 6144 bins")
print("==============================================")
