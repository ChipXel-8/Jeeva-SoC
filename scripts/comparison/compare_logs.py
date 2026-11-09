#!/usr/bin/env python3

import sys
import re


# ============================================================
# Helper Functions
# ============================================================

def u32(x):
    return x & 0xFFFFFFFF


def hex32(x):
    return "0x{:08x}".format(u32(x))


def values_equivalent(rtl_value, spike_value):
    return u32(rtl_value) == u32(spike_value)


# ============================================================
# Instruction Helpers
# ============================================================

def opcode(instr):
    return u32(instr) & 0x7F


def rs1_of(instr):
    return (u32(instr) >> 15) & 0x1F


def rs2_of(instr):
    return (u32(instr) >> 20) & 0x1F


def rd_of(instr):
    return (u32(instr) >> 7) & 0x1F


def csr_addr_of(instr):
    return (u32(instr) >> 20) & 0xFFF


def is_timing_csr(instr):
    """
    CSRs whose value depends on simulation/execution timing.
    """

    return csr_addr_of(instr) in {
        0xC00,       # CYCLE
        0xC80,       # CYCLEH
        0xB00,       # MCYCLE
        0xB80,       # MCYCLEH
        0xC02,       # INSTRET
        0xC82,       # INSTRETH
        0xB02,       # MINSTRET
        0xB82,       # MINSTRETH
    }


def is_load(instr):
    """s
    RV32I LOAD opcode.
    """

    return opcode(instr) == 0x03


def is_store(instr):
    """
    RV32I STORE opcode.
    """

    return opcode(instr) == 0x23


def source_is_timing_dependent(instr, timing_regs):
    """
    Returns True if the instruction gets its result from a
    register which contains a timing-dependent value.
    """

    op = opcode(instr)
    rs1 = rs1_of(instr)
    rs2 = rs2_of(instr)

    # R-type ALU instructions
    #
    # ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
    #
    if op == 0x33:
        return (
            rs1 in timing_regs or
            rs2 in timing_regs
        )

    # I-type ALU instructions
    #
    # ADDI, SLTI, SLTIU, XORI, ORI, ANDI,
    # SLLI, SRLI, SRAI
    #
    if op == 0x13:
        return rs1 in timing_regs

    # JALR
    if op == 0x67:
        return rs1 in timing_regs

    # LOAD is handled separately using timing_memory.
    if op == 0x03:
        return False

    # LUI / AUIPC
    if op == 0x37 or op == 0x17:
        return False

    # JAL
    if op == 0x6F:
        return False

    return False


# ============================================================
# RTL Parser
# ============================================================

def parse_rtl(filename):

    commits = []

    # Registers which currently contain timing-dependent data
    timing_regs = set()

    # Memory addresses which contain timing-dependent data
    timing_memory = set()

    reg_pattern = re.compile(
        r'^core\s+0:\s+'
        r'0x([0-9a-fA-F]+)\s+'
        r'\(0x([0-9a-fA-F]+)\)\s+'
        r'x([0-9]|[12][0-9]|3[01])\s+'
        r'0x([0-9a-fA-F]+)\s*$'
    )

    mem_pattern = re.compile(
        r'^core\s+0:\s+'
        r'0x([0-9a-fA-F]+)\s+'
        r'\(0x([0-9a-fA-F]+)\)\s+'
        r'MEM\[(?:0x)?([0-9a-fA-F]+)\]'
        r'\s*=\s*'
        r'(?:0x)?([0-9a-fA-F]+)\s*$',
        re.IGNORECASE
    )

    mem_pattern_alt = re.compile(
        r'^core\s+0:\s+'
        r'0x([0-9a-fA-F]+)\s+'
        r'\(0x([0-9a-fA-F]+)\)\s+'
        r'mem\s+'
        r'0x([0-9a-fA-F]+)\s+'
        r'0x([0-9a-fA-F]+)\s*$',
        re.IGNORECASE
    )

    with open(filename, "r") as f:

        for line_number, line in enumerate(f, 1):

            line = line.strip()

            if not line:
                continue

            # ------------------------------------------------
            # Memory Store
            # ------------------------------------------------

            m = mem_pattern.match(line)

            if not m:
                m = mem_pattern_alt.match(line)

            if m:

                pc = u32(int(m.group(1), 16))
                instr = u32(int(m.group(2), 16))
                addr = u32(int(m.group(3), 16))
                value = u32(int(m.group(4), 16))

                timing_dependent = (
                    rs2_of(instr) in timing_regs
                )

                commits.append({
                    "type": "mem",
                    "pc": pc,
                    "instr": instr,
                    "addr": addr,
                    "value": value,
                    "timing_dependent": timing_dependent,
                    "raw": line,
                    "line": line_number
                })

                # Remember that this memory location contains
                # timing-dependent data.
                if timing_dependent:
                    timing_memory.add(addr)
                else:
                    timing_memory.discard(addr)

                continue

            # ------------------------------------------------
            # Register Write
            # ------------------------------------------------

            m = reg_pattern.match(line)

            if m:

                pc = u32(int(m.group(1), 16))
                instr = u32(int(m.group(2), 16))
                rd = int(m.group(3))
                value = u32(int(m.group(4), 16))

                timing_dependent = False

                # Direct CYCLE / MCYCLE read
                if is_timing_csr(instr):
                    timing_dependent = True

                # ALU/JALR result derived from timing register
                elif source_is_timing_dependent(
                    instr,
                    timing_regs
                ):
                    timing_dependent = True

                commits.append({
                    "type": "reg",
                    "pc": pc,
                    "instr": instr,
                    "rd": rd,
                    "value": value,
                    "timing_dependent": timing_dependent,
                    "raw": line,
                    "line": line_number
                })

                # Update timing dependency of destination register
                if rd != 0:

                    if timing_dependent:
                        timing_regs.add(rd)
                    else:
                        timing_regs.discard(rd)

                continue

    return commits


# ============================================================
# Spike Parser
# ============================================================

def parse_spike(filename):

    commits = []

    # Registers containing timing-dependent values
    timing_regs = set()

    # Memory locations containing timing-dependent values
    timing_memory = set()

    commit_pattern = re.compile(
        r'^core\s+0:\s+'
        r'3\s+'
        r'0x([0-9a-fA-F]+)\s+'
        r'\(0x([0-9a-fA-F]+)\)'
        r'(.*)$'
    )

    reg_pattern = re.compile(
        r'(?:^|\s)'
        r'x([0-9]|[12][0-9]|3[01])\s+'
        r'0x([0-9a-fA-F]+)'
        r'(?=\s|$)'
    )

    mem_pattern = re.compile(
        r'(?:^|\s)'
        r'mem\s+'
        r'0x([0-9a-fA-F]+)'
        r'(?:\s+0x([0-9a-fA-F]+))?'
        r'(?=\s|$)',
        re.IGNORECASE
    )

    with open(filename, "r") as f:

        for line_number, line in enumerate(f, 1):

            line = line.strip()

            if not line:
                continue

            m = commit_pattern.match(line)

            if not m:
                continue

            pc = u32(int(m.group(1), 16))
            instr = u32(int(m.group(2), 16))
            rest = m.group(3).strip()

            # ------------------------------------------------
            # Memory information
            # ------------------------------------------------

            mem_info = mem_pattern.search(rest)

            # ------------------------------------------------
            # Store
            # ------------------------------------------------

            if mem_info and is_store(instr):

                addr = u32(int(mem_info.group(1), 16))

                if mem_info.group(2) is not None:
                    value = u32(
                        int(mem_info.group(2), 16)
                    )
                else:
                    value = 0

                timing_dependent = (
                    rs2_of(instr) in timing_regs
                )

                commits.append({
                    "type": "mem",
                    "pc": pc,
                    "instr": instr,
                    "addr": addr,
                    "value": value,
                    "timing_dependent": timing_dependent,
                    "raw": line,
                    "line": line_number
                })

                if timing_dependent:
                    timing_memory.add(addr)
                else:
                    timing_memory.discard(addr)

                # End marker used by your regression
                if (
                    addr == 0x80008000
                    and value == 1
                ):
                    break

                continue

            # ------------------------------------------------
            # Register Write
            # ------------------------------------------------

            reg = reg_pattern.search(rest)

            if reg:

                rd = int(reg.group(1))
                value = u32(
                    int(reg.group(2), 16)
                )

                timing_dependent = False

                # Direct timing CSR
                if is_timing_csr(instr):

                    timing_dependent = True

                # ALU/JALR result derived from timing register
                elif source_is_timing_dependent(
                    instr,
                    timing_regs
                ):

                    timing_dependent = True

                # LOAD from timing-dependent memory
                if is_load(instr) and mem_info:

                    load_addr = u32(
                        int(mem_info.group(1), 16)
                    )

                    if load_addr in timing_memory:
                        timing_dependent = True

                commits.append({
                    "type": "reg",
                    "pc": pc,
                    "instr": instr,
                    "rd": rd,
                    "value": value,
                    "timing_dependent": timing_dependent,
                    "raw": line,
                    "line": line_number
                })

                # Update destination register
                if rd != 0:

                    if timing_dependent:
                        timing_regs.add(rd)
                    else:
                        timing_regs.discard(rd)

                continue

    return commits


# ============================================================
# Commit Description
# ============================================================

def describe(commit):

    if commit["type"] == "reg":

        return (
            "PC={} INSTR={} x{}={}".format(
                hex32(commit["pc"]),
                hex32(commit["instr"]),
                commit["rd"],
                hex32(commit["value"])
            )
        )

    return (
        "PC={} INSTR={} MEM[{}]={}".format(
            hex32(commit["pc"]),
            hex32(commit["instr"]),
            hex32(commit["addr"]),
            hex32(commit["value"])
        )
    )


# ============================================================
# Compare One Architectural Commit
# ============================================================

def commits_equal(rtl, spike):

    # --------------------------------------------------------
    # PC
    # --------------------------------------------------------

    if rtl["pc"] != spike["pc"]:
        return False

    # --------------------------------------------------------
    # Instruction
    # --------------------------------------------------------

    if rtl["instr"] != spike["instr"]:
        return False

    # --------------------------------------------------------
    # Commit Type
    # --------------------------------------------------------

    if rtl["type"] != spike["type"]:
        return False

    # --------------------------------------------------------
    # Register Commit
    # --------------------------------------------------------

    if rtl["type"] == "reg":

        if rtl["rd"] != spike["rd"]:
            return False

        # Timing-dependent value:
        # numerical RTL/Spike values are allowed to differ.
        if (
            rtl.get("timing_dependent", False)
            or spike.get("timing_dependent", False)
        ):
            return True

        if not values_equivalent(
            rtl["value"],
            spike["value"]
        ):
            return False

    # --------------------------------------------------------
    # Memory Store
    # --------------------------------------------------------

    elif rtl["type"] == "mem":

        if rtl["addr"] != spike["addr"]:
            return False

        # Timing-dependent store value is allowed to differ.
        if (
            rtl.get("timing_dependent", False)
            or spike.get("timing_dependent", False)
        ):
            return True

        if not values_equivalent(
            rtl["value"],
            spike["value"]
        ):
            return False

    return True


# ============================================================
# Print Mismatch
# ============================================================

def print_mismatch(index, rtl, spike):

    print()
    print("========================================================")
    print(
        "MISMATCH at architectural commit {}".format(index)
    )
    print("========================================================")
    print()

    print("RTL   : {}".format(describe(rtl)))
    print("SPIKE : {}".format(describe(spike)))
    print()

    print("Field comparison")
    print()

    # --------------------------------------------------------
    # PC
    # --------------------------------------------------------

    print(
        "PC      : RTL={}  SPIKE={} {}".format(
            hex32(rtl["pc"]),
            hex32(spike["pc"]),
            "MATCH"
            if rtl["pc"] == spike["pc"]
            else "MISMATCH"
        )
    )

    # --------------------------------------------------------
    # Instruction
    # --------------------------------------------------------

    print(
        "INSTR   : RTL={}  SPIKE={} {}".format(
            hex32(rtl["instr"]),
            hex32(spike["instr"]),
            "MATCH"
            if rtl["instr"] == spike["instr"]
            else "MISMATCH"
        )
    )

    # --------------------------------------------------------
    # Type
    # --------------------------------------------------------

    print(
        "TYPE    : RTL={}  SPIKE={} {}".format(
            rtl["type"],
            spike["type"],
            "MATCH"
            if rtl["type"] == spike["type"]
            else "MISMATCH"
        )
    )

    # --------------------------------------------------------
    # Register
    # --------------------------------------------------------

    if rtl["type"] == "reg":

        print(
            "RD      : RTL=x{}  SPIKE=x{} {}".format(
                rtl["rd"],
                spike["rd"],
                "MATCH"
                if rtl["rd"] == spike["rd"]
                else "MISMATCH"
            )
        )

        timing = (
            rtl.get("timing_dependent", False)
            or spike.get("timing_dependent", False)
        )

        if timing:

            print(
                "VALUE   : RTL={}  SPIKE={} "
                "IGNORED (timing-dependent value)".format(
                    hex32(rtl["value"]),
                    hex32(spike["value"])
                )
            )

        else:

            print(
                "VALUE   : RTL={}  SPIKE={} {}".format(
                    hex32(rtl["value"]),
                    hex32(spike["value"]),
                    "MATCH"
                    if values_equivalent(
                        rtl["value"],
                        spike["value"]
                    )
                    else "MISMATCH"
                )
            )

    # --------------------------------------------------------
    # Memory
    # --------------------------------------------------------

    elif rtl["type"] == "mem":

        print(
            "ADDR    : RTL={}  SPIKE={} {}".format(
                hex32(rtl["addr"]),
                hex32(spike["addr"]),
                "MATCH"
                if rtl["addr"] == spike["addr"]
                else "MISMATCH"
            )
        )

        timing = (
            rtl.get("timing_dependent", False)
            or spike.get("timing_dependent", False)
        )

        if timing:

            print(
                "VALUE   : RTL={}  SPIKE={} "
                "IGNORED (timing-dependent value)".format(
                    hex32(rtl["value"]),
                    hex32(spike["value"])
                )
            )

        else:

            print(
                "VALUE   : RTL={}  SPIKE={} {}".format(
                    hex32(rtl["value"]),
                    hex32(spike["value"]),
                    "MATCH"
                    if values_equivalent(
                        rtl["value"],
                        spike["value"]
                    )
                    else "MISMATCH"
                )
            )

    print()
    print("RTL line {}:".format(rtl["line"]))
    print(rtl["raw"])

    print()
    print("SPIKE line {}:".format(spike["line"]))
    print(spike["raw"])


# ============================================================
# Compare Logs
# ============================================================

def compare_logs(rtl_file, spike_file):

    rtl = parse_rtl(rtl_file)
    spike = parse_spike(spike_file)

    print()
    print("========================================================")
    print("          PRAGYA RTL vs SPIKE COMPARISON")
    print("========================================================")
    print()

    print("RTL commits   : {}".format(len(rtl)))
    print("Spike commits : {}".format(len(spike)))
    print()

    # --------------------------------------------------------
    # Empty log checks
    # --------------------------------------------------------

    if len(rtl) == 0:

        print("ERROR: No RTL architectural commits found.")
        return 1

    if len(spike) == 0:

        print("ERROR: No Spike architectural commits found.")
        return 1

    # --------------------------------------------------------
    # Compare commits
    # --------------------------------------------------------

    common = min(
        len(rtl),
        len(spike)
    )

    for index in range(common):

        rtl_commit = rtl[index]
        spike_commit = spike[index]

        if not commits_equal(
            rtl_commit,
            spike_commit
        ):

            print_mismatch(
                index,
                rtl_commit,
                spike_commit
            )

            print()
            print("========================================================")
            print("                    TEST FAILED")
            print("========================================================")
            print()

            print(
                "{} architectural commits matched "
                "before failure.".format(index)
            )

            return 1

    # --------------------------------------------------------
    # Commit Count Mismatch
    # --------------------------------------------------------

    if len(rtl) != len(spike):

        print()
        print("========================================================")
        print("              COMMIT COUNT MISMATCH")
        print("========================================================")
        print()

        print(
            "RTL commits   : {}".format(len(rtl))
        )

        print(
            "Spike commits : {}".format(len(spike))
        )

        print()

        if len(rtl) > len(spike):

            extra = rtl[len(spike)]

            print("First extra RTL commit:")
            print(describe(extra))
            print()
            print(extra["raw"])

        else:

            extra = spike[len(rtl)]

            print("First extra Spike commit:")
            print(describe(extra))
            print()
            print(extra["raw"])

            print()
            print(
                "Spike line {}:".format(extra["line"])
            )

            print(extra["raw"])

        print()
        print("========================================================")
        print("                    TEST FAILED")
        print("========================================================")
        print()

        return 1

    # --------------------------------------------------------
    # PASS
    # --------------------------------------------------------

    print()
    print("========================================================")
    print("                    TEST PASSED")
    print("========================================================")
    print()

    print(
        "All {} architectural commits match.".format(
            len(rtl)
        )
    )

    return 0


# ============================================================
# Main
# ============================================================

def main():

    if len(sys.argv) != 3:

        print()
        print(
            "Usage: python3 {} <rtl_log> <spike_log>".format(
                sys.argv[0]
            )
        )

        return 2

    rtl_file = sys.argv[1]
    spike_file = sys.argv[2]

    try:

        return compare_logs(
            rtl_file,
            spike_file
        )

    except FileNotFoundError as e:

        print()
        print("ERROR: File not found")
        print(e)

        return 2

    except Exception as e:

        print()
        print("ERROR while comparing logs:")
        print(e)

        return 2


if __name__ == "__main__":
    sys.exit(main())
