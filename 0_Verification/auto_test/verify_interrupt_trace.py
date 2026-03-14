import csv

# ==============================
# configuration
# ==============================

illegal_instructions = {
    "0x0000000f",
    "0x0000100f",
    "0x0000603b",
    "0x0000703b",
    "0x0000601b",
    "0x0000701b",
    "0x00003003",
    "0x00007003",
    "0x00004023",
    "0x00007023",
    "0x00002063",
    "0x00003063",
    "0x00001067",
    "0x00002067",
    "0x00000073",
    "0x00100073",
    "0xc00020f3",
    "0xf14020f3",
    "0x30509073",
    "0x30109073"
}

INT0_ENTRY = 0x80000000
INT1_ENTRY = 0x80000004
ILL_ENTRY = 0x8000000c

INT0_EXIT = 0x80000018
INT1_EXIT = 0x80000020
ILL_EXIT = 0x80000030


NORMAL = "normal"
INT0 = "int0"
INT1 = "int1"
ILL = "illegal"


# =========================================================
# helper functions
# =========================================================

def classify_pc(pc):

    if pc == 0x80000008 or pc >= 0x80000034:
        return NORMAL

    if pc == 0x80000000 or (0x80000010 <= pc <= 0x80000018):
        return INT0

    if pc == 0x80000004 or (0x8000001c <= pc <= 0x80000020):
        return INT1

    if pc == 0x8000000c or (0x80000024 <= pc <= 0x80000030):
        return ILL

    raise Exception(f"Unknown PC: {hex(pc)}")


def is_illegal(inst):
    return inst in illegal_instructions


def find_first_pc_change(rows, i):

    pc = rows[i]["pc"]

    j = i + 1

    while j < len(rows):

        if rows[j]["pc"] != pc:
            return j

        j += 1

    return None


def error(rows, i, msg):

    print("\n========= ERROR =========")

    for k in range(max(0, i-5), min(len(rows), i+5)):
        print(k, rows[k])

    raise Exception(f"\nError at line {i}: {msg}")


# =========================================================
# load csv
# =========================================================

def load_trace(filename):

    rows = []

    with open(filename, encoding="utf-8-sig") as f:

        reader = csv.DictReader(f)

        for row in reader:

            rows.append({
                "time": int(row["time_ns"]),
                "pc": int(row["pc"], 16),
                "inst": row["inst"].lower(),
                "irq_0": int(row["irq_0"]),
                "irq_1": int(row["irq_1"]),
                "ack_0": int(row["ack_0"]),
                "ack_1": int(row["ack_1"]),
                "mie": int(row["mie"]),
                "mcause": int(row["mcause"]),
            })

    print("Loaded", len(rows), "trace entries")

    return rows


# =========================================================
# verification
# =========================================================

def verify_trace(rows):

    last_inst_before_int0 = None
    last_inst_before_int1 = None

    i = 0

    while i < len(rows) - 1:

        if i + 1 >= len(rows):
            break

        cur = rows[i]
        nxt = rows[i + 1]
        pc_type = classify_pc(cur["pc"])
        next_type = classify_pc(nxt["pc"])
        inst_illegal = is_illegal(cur["inst"])
        # =================================================
        # NORMAL PROGRAM
        # =================================================

        if pc_type == NORMAL:

            if cur["mie"] == 0:

                if inst_illegal:

                    if nxt["pc"] != ILL_ENTRY:
                        error(rows, i, "illegal instruction must jump to illegal handler")

                    if nxt["mcause"] != 3:
                        error(rows, i, "mcause must be 3")

                else:

                    if next_type != NORMAL:
                        error(rows, i, "must stay in normal program")

            else:

                # =========================
                # IRQ0
                # =========================

                if cur["irq_0"] == 1:

                    # 原逻辑：下一条直接进入 handler
                    if rows[i + 1]["pc"] == INT0_ENTRY:

                        if rows[i + 1]["ack_0"] != 1:
                            error(rows, i, "ack_0 must be 1")

                    else:

                        # 下一条 PC 是否变化
                        if rows[i + 1]["pc"] != cur["pc"]:

                            # 找第二次 PC 变化
                            j = i + 2

                            while j < len(rows):

                                if rows[j]["pc"] != rows[j - 1]["pc"]:

                                    if rows[j]["pc"] != INT0_ENTRY:
                                        error(rows, i, "must jump to interrupt0 handler")

                                    if rows[j]["ack_0"] != 1:
                                        error(rows, i, "ack_0 must be 1")

                                    break

                                j += 1

                        else:

                            # PC stall
                            j = find_first_pc_change(rows, i)

                            if j is None:
                                error(rows, i, "no PC change found")

                            if rows[j]["pc"] != INT0_ENTRY:
                                error(rows, i, "must jump to interrupt0 handler")

                            if rows[j]["ack_0"] != 1:
                                error(rows, i, "ack_0 must be 1")


                # =========================
                # IRQ1
                # =========================

                elif cur["irq_1"] == 1:

                    # 原逻辑：下一条直接进入 handler

                    if rows[i + 1]["pc"] == INT1_ENTRY:

                        if rows[i + 1]["ack_1"] != 1:
                            error(rows, i, "ack_1 must be 1")


                    else:

                        irq0_seen = False

                        # 下一条 PC 是否变化

                        if rows[i + 1]["pc"] != cur["pc"]:

                            j = i + 2

                            while j < len(rows):

                                if rows[j]["irq_0"] == 1:
                                    irq0_seen = True

                                if rows[j]["pc"] != rows[j - 1]["pc"]:

                                    if irq0_seen:

                                        if rows[j]["pc"] != INT0_ENTRY:
                                            error(rows, i, "must jump to interrupt0 handler")

                                        if rows[j]["ack_0"] != 1:
                                            error(rows, i, "ack_0 must be 1")


                                    else:

                                        if rows[j]["pc"] != INT1_ENTRY:
                                            error(rows, i, "must jump to interrupt1 handler")

                                        if rows[j]["ack_1"] != 1:
                                            error(rows, i, "ack_1 must be 1")

                                    break

                                j += 1


                        else:

                            j = i + 1

                            while j < len(rows):

                                if rows[j]["irq_0"] == 1:
                                    irq0_seen = True

                                if rows[j]["pc"] != cur["pc"]:

                                    if irq0_seen:

                                        if rows[j]["pc"] != INT0_ENTRY:
                                            error(rows, i, "must jump to interrupt0 handler")

                                        if rows[j]["ack_0"] != 1:
                                            error(rows, i, "ack_0 must be 1")


                                    else:

                                        if rows[j]["pc"] != INT1_ENTRY:
                                            error(rows, i, "must jump to interrupt1 handler")

                                        if rows[j]["ack_1"] != 1:
                                            error(rows, i, "ack_1 must be 1")

                                    break

                                j += 1


                # =========================
                # ILLEGAL INSTRUCTION
                # =========================

                elif inst_illegal:

                    if nxt["pc"] != ILL_ENTRY:
                        error(rows, i, "illegal instruction must jump to handler")

                    if nxt["mcause"] != 3:
                        error(rows, i, "mcause must be 3")


        # =================================================
        # ILLEGAL HANDLER
        # =================================================

        elif pc_type == ILL:

            if cur["pc"] != ILL_EXIT:

                if next_type != ILL:
                    error(rows, i, "must stay in illegal handler")


        # =================================================
        # INTERRUPT 0 HANDLER
        # =================================================

        elif pc_type == INT0:

            if cur["mie"] != 0:
                error(rows, i, "mie must be 0 in interrupt0 handler")

            if cur["pc"] == INT0_ENTRY:
                last_inst_before_int0 = rows[i-1]["inst"]

            if cur["pc"] != INT0_EXIT:

                if next_type != INT0:
                    error(rows, i, "must stay in interrupt0 handler")

            else:

                if is_illegal(last_inst_before_int0):

                    if next_type != ILL:
                        error(rows, i, "must return to illegal handler")

                else:

                    if next_type != NORMAL:
                        error(rows, i, "must return to normal program")


        # =================================================
        # INTERRUPT 1 HANDLER
        # =================================================

        elif pc_type == INT1:

            if cur["mie"] != 0:
                error(rows, i, "mie must be 0 in interrupt1 handler")

            if cur["pc"] == INT1_ENTRY:
                last_inst_before_int1 = rows[i-1]["inst"]

            if cur["pc"] != INT1_EXIT:

                if next_type != INT1:
                    error(rows, i, "must stay in interrupt1 handler")

            else:

                if is_illegal(last_inst_before_int1):

                    if next_type != ILL:
                        error(rows, i, "must return to illegal handler")

                else:

                    if next_type != NORMAL:
                        error(rows, i, "must return to normal program")

        i += 1

    print("\nTrace verification PASSED")


# =========================================================
# main
# =========================================================


if __name__ == "__main__":

    trace = load_trace("../../Vivado_Kreacher/Vivado_kreacher.sim/sim_1/behav/xsim/irq_trace.csv")

    verify_trace(trace)