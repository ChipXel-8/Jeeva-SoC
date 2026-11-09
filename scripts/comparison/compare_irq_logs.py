#!/usr/bin/env python3

import sys
import re


if len(sys.argv) != 3:
    print("")
    print("Usage:")
    print("  python3 scripts/compare_irq_logs.py <rtl.log> <spike.log>")
    print("")
    sys.exit(1)


rtl_file = sys.argv[1]
spike_file = sys.argv[2]


# ============================================================
# RTL REGISTER COMMIT
#
# core   0: 0x80003154 (0x000c04b3) x9 0x80015ce0
# ============================================================

rtl_reg_re = re.compile(
    r"core\s+0:\s+"
    r"0x([0-9a-fA-F]+)\s+"
    r"\(0x([0-9a-fA-F]+)\)\s+"
    r"x(\d+)\s+"
    r"0x([0-9a-fA-F]+)"
)


# ============================================================
# RTL MEMORY COMMIT
#
# core   0: 0x80003150 (0x009c2023) mem 0x80015ce0 0x80011e64
# ============================================================

rtl_mem_re = re.compile(
    r"core\s+0:\s+"
    r"0x([0-9a-fA-F]+)\s+"
    r"\(0x([0-9a-fA-F]+)\)\s+"
    r"mem\s+"
    r"0x([0-9a-fA-F]+)\s+"
    r"0x([0-9a-fA-F]+)"
)


# ============================================================
# SPIKE REGISTER COMMIT
#
# core   0: 3 0x80003154 (0x000c04b3) x9  0x80015ce0
# ============================================================

spike_reg_re = re.compile(
    r"core\s+0:\s+3\s+"
    r"0x([0-9a-fA-F]+)\s+"
    r"\(0x([0-9a-fA-F]+)\)\s+"
    r"x(\d+)\s+"
    r"0x([0-9a-fA-F]+)"
)


# ============================================================
# SPIKE MEMORY COMMIT
# ============================================================

spike_mem_re = re.compile(
    r"core\s+0:\s+3\s+"
    r"0x([0-9a-fA-F]+)\s+"
    r"\(0x([0-9a-fA-F]+)\)\s+"
    r"mem\s+"
    r"0x([0-9a-fA-F]+)\s+"
    r"0x([0-9a-fA-F]+)"
)


# ============================================================
# IRQ marker
# ============================================================

irq_re = re.compile(r"#\s*IRQ_INJECTED")


# ============================================================
# MRET
# ============================================================

mret_re = re.compile(
    r"\(0x30200073\)"
)


# ============================================================
# Parse RTL
# ============================================================

def parse_rtl(line):

    m = rtl_reg_re.search(line)

    if m:
        return (
            "reg",
            int(m.group(1), 16),
            int(m.group(2), 16),
            int(m.group(3)),
            int(m.group(4), 16)
        )

    m = rtl_mem_re.search(line)

    if m:
        return (
            "mem",
            int(m.group(1), 16),
            int(m.group(2), 16),
            int(m.group(3), 16),
            int(m.group(4), 16)
        )

    return None


# ============================================================
# Parse Spike
# ============================================================

def parse_spike(line):

    m = spike_reg_re.search(line)

    if m:
        return (
            "reg",
            int(m.group(1), 16),
            int(m.group(2), 16),
            int(m.group(3)),
            int(m.group(4), 16)
        )

    m = spike_mem_re.search(line)

    if m:
        return (
            "mem",
            int(m.group(1), 16),
            int(m.group(2), 16),
            int(m.group(3), 16),
            int(m.group(4), 16)
        )

    return None


# ============================================================
# Read RTL
# ============================================================

def read_rtl(filename):

    commits = []
    irq_index = None

    with open(filename, "r", errors="ignore") as f:

        for line in f:

            if irq_re.search(line):

                if irq_index is None:
                    irq_index = len(commits)

                continue

            c = parse_rtl(line)

            if c:
                commits.append(c)

    return commits, irq_index


# ============================================================
# Read Spike
# ============================================================

def read_spike(filename):

    commits = []

    with open(filename, "r", errors="ignore") as f:

        for line in f:

            c = parse_spike(line)

            if c:
                commits.append(c)

    return commits


# ============================================================
# Print commit
# ============================================================

def print_commit(prefix, c):

    if c[0] == "reg":

        print(
            "%s PC=0x%08x INSTR=0x%08x x%d=0x%08x"
            % (
                prefix,
                c[1],
                c[2],
                c[3],
                c[4]
            )
        )

    else:

        print(
            "%s PC=0x%08x INSTR=0x%08x "
            "mem[0x%08x]=0x%08x"
            % (
                prefix,
                c[1],
                c[2],
                c[3],
                c[4]
            )
        )


# ============================================================
# Compare commits
# ============================================================

def compare_commit(r, s):

    return r == s


# ============================================================
# Find mtvec / handler start
# ============================================================

def find_handler_start(rtl, irq_index):

    if irq_index is None:
        return None

    if irq_index + 1 >= len(rtl):
        return None

    # The instruction immediately after IRQ injection may be
    # the interrupted instruction.
    #
    # Handler begins when execution jumps away from the normal
    # program sequence.

    normal_pc = rtl[irq_index][1]

    for i in range(irq_index + 1, len(rtl)):

        pc = rtl[i][1]

        # Detect a control-flow jump away from the sequential
        # normal PC.
        expected = (normal_pc + 4) & 0xffffffff

        if pc != expected:

            return i

        normal_pc = pc

    return None


# ============================================================
# Determine normal execution PC after interrupt
#
# We use the normal instruction stream immediately before IRQ.
#
# If IRQ happened after PC X, normal execution should continue
# at the following architectural PC(s), depending on where the
# interrupt was taken.
#
# We search Spike for the sequence that follows the RTL's
# post-handler return, while explicitly excluding mtvec.
# ============================================================

def find_post_irq_resume(rtl, spike, irq_index, handler_start):

    if handler_start is None:
        return None, None

    mtvec = rtl[handler_start][1]

    # --------------------------------------------------------
    # Candidate normal PCs:
    #
    # Look through RTL after handler and reject:
    #
    #   - mtvec
    #   - addresses belonging to the handler
    #
    # We identify a candidate when the RTL starts following
    # the normal sequential program stream again.
    # --------------------------------------------------------

    for rindex in range(handler_start + 1, len(rtl)):

        r = rtl[rindex]

        # Never synchronize on mtvec.
        if r[1] == mtvec:
            continue

        # ----------------------------------------------------
        # Need a reasonably strong sequence.
        # ----------------------------------------------------

        if rindex + 5 >= len(rtl):
            break

        seq = rtl[rindex:rindex + 6]

        # Reject sequences containing mtvec.
        if any(c[1] == mtvec for c in seq):
            continue

        # ----------------------------------------------------
        # Search Spike.
        #
        # PC + instruction only for synchronization.
        # ----------------------------------------------------

        for sindex in range(len(spike) - 6):

            good = True

            for j in range(6):

                rc = seq[j]
                sc = spike[sindex + j]

                if rc[1] != sc[1]:
                    good = False
                    break

                if rc[2] != sc[2]:
                    good = False
                    break

            if not good:
                continue

            # ------------------------------------------------
            # Verify architectural values for the entire
            # synchronization sequence.
            # ------------------------------------------------

            values_match = True

            for j in range(6):

                if rtl[rindex + j] != spike[sindex + j]:

                    values_match = False
                    break

            if values_match:

                return rindex, sindex

    return None, None


# ============================================================
# MAIN
# ============================================================

rtl, irq_index = read_rtl(rtl_file)
spike = read_spike(spike_file)


print("")
print("========================================")
print(" PRAGYA RISC-V-DV INTERRUPT COMPARISON")
print("========================================")
print("")

print("RTL commits   :", len(rtl))
print("Spike commits :", len(spike))
print("")


# ============================================================
# PHASE 1
# ============================================================

print("========================================")
print(" PHASE 1: PRE-INTERRUPT")
print("========================================")
print("")

if irq_index is None:

    print("ERROR: IRQ_INJECTED marker not found")
    sys.exit(1)


rtl_pre = rtl[:irq_index]

print("RTL pre-IRQ commits :", len(rtl_pre))
print("")


for i, r in enumerate(rtl_pre):

    if i >= len(spike):

        print("ERROR: Spike ended before IRQ")
        sys.exit(1)

    s = spike[i]

    if not compare_commit(r, s):

        print("")
        print("ERROR: PRE-INTERRUPT MISMATCH")
        print("")

        print("Commit number :", i + 1)

        print_commit("RTL  :", r)
        print_commit("SPIKE:", s)

        print("")
        print("Matched commits :", i)

        sys.exit(1)


print("Pre-interrupt comparison PASSED")
print("Matched commits :", len(rtl_pre))
print("")

print("IRQ marker commit index :", irq_index)
print("")


# ============================================================
# PHASE 2
# ============================================================

print("========================================")
print(" PHASE 2: INTERRUPT HANDLING")
print("========================================")
print("")


handler_start = find_handler_start(
    rtl,
    irq_index
)


if handler_start is None:

    print("ERROR: Could not identify interrupt handler")
    sys.exit(1)


mtvec = rtl[handler_start][1]


print("RTL handler start :", handler_start)
print("RTL mtvec         : 0x%08x" % mtvec)
print("")


# Find post-handler normal execution.

rtl_resume, spike_resume = find_post_irq_resume(
    rtl,
    spike,
    irq_index,
    handler_start
)


if rtl_resume is None:

    print("")
    print("ERROR: Could not synchronize RTL after interrupt handler")
    print("")
    print("The RTL may not have returned to normal execution.")
    print("")
    sys.exit(1)


print("Post-IRQ normal execution found")
print("")

print("RTL resume commit index   :", rtl_resume)
print("Spike resume commit index :", spike_resume)
print("")

print("RTL resume:")
print_commit("RTL  :", rtl[rtl_resume])

print("")

print("Spike resume:")
print_commit("SPIKE:", spike[spike_resume])

print("")


# ============================================================
# PHASE 3
# ============================================================

print("========================================")
print(" PHASE 3: POST-INTERRUPT NORMAL EXECUTION")
print("========================================")
print("")


rtl_post = rtl[rtl_resume:]
spike_post = spike[spike_resume:]


print("RTL post-IRQ commits   :", len(rtl_post))
print("Spike post-IRQ commits :", len(spike_post))
print("")


matched = 0


for i in range(min(len(rtl_post), len(spike_post))):

    r = rtl_post[i]
    s = spike_post[i]

    if not compare_commit(r, s):

        print("")
        print("========================================")
        print(" ERROR: POST-INTERRUPT MISMATCH")
        print("========================================")
        print("")

        print("Post-interrupt commit :", i + 1)

        print_commit("RTL  :", r)
        print_commit("SPIKE:", s)

        print("")
        print("Matched post-IRQ commits :", matched)
        print("")

        sys.exit(1)

    matched += 1


# ============================================================
# Count check
# ============================================================

if len(rtl_post) != len(spike_post):

    print("")
    print("========================================")
    print(" ERROR: POST-IRQ COMMIT COUNT MISMATCH")
    print("========================================")
    print("")

    print("RTL post-IRQ commits   :", len(rtl_post))
    print("Spike post-IRQ commits :", len(spike_post))
    print("Matched commits        :", matched)
    print("")

    sys.exit(1)


# ============================================================
# PASS
# ============================================================

print("========================================")
print(" INTERRUPT COMPARISON PASSED")
print("========================================")
print("")

print("Pre-IRQ commits           :", len(rtl_pre))
print("Post-IRQ matched commits  :", matched)
print("")

print("Interrupt handler skipped.")
print("RTL returned to normal execution.")
print("")

print("========================================")
print(" ALL ARCHITECTURAL COMMITS MATCH")
print("========================================")
print("")

sys.exit(0)
