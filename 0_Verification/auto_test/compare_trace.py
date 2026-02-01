import re
import csv
# Lists to store results
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--create", action="store_true")
args = parser.parse_args()


def extend_inst(raw_instr):
    extend_instr_bin_str = "00000000000000000000000000010011"
    raw_instr_bin_str = format(int(raw_instr, 16), '016b')
    quadrant = raw_instr_bin_str[-2:]
    rs_2 = raw_instr_bin_str[-7:-2]
    rd_rs1 = raw_instr_bin_str[-12:-7]
    rd_rs2_p = "01" + raw_instr_bin_str[-5:-2]
    rd_rs1_p = "01" + raw_instr_bin_str[-10:-7]
    funct2 = raw_instr_bin_str[-7:-5]
    funct2_p = raw_instr_bin_str[-12:-10]
    funct3 = raw_instr_bin_str[-16:-13]
    funct4 = raw_instr_bin_str[-16:-12]
    funct6 = raw_instr_bin_str[-16:-10]

    sel_sign_extension = not ((quadrant == "01" and funct3 == "100" and (funct2_p == "00" or funct2_p == "01")) or (
                quadrant == "10" and funct3 == "000"))

    imm_c_alu = (raw_instr_bin_str[-13] * 6 if sel_sign_extension else "000000") + raw_instr_bin_str[
        -13] + raw_instr_bin_str[-7:-2]
    imm_c_addi16sp = raw_instr_bin_str[-13] * 3 + raw_instr_bin_str[-5:-3] + raw_instr_bin_str[-6] + raw_instr_bin_str[
        -3] + raw_instr_bin_str[-7] + "0000"
    imm_c_addi4spn = "00" + raw_instr_bin_str[-11:-7] + raw_instr_bin_str[-13:-11] + raw_instr_bin_str[-6] + \
                     raw_instr_bin_str[-7] + "00"
    imm_c_lui = raw_instr_bin_str[-13] * 14 + raw_instr_bin_str[-13] + raw_instr_bin_str[-7:-2]
    imm_c_branch = raw_instr_bin_str[-13] * 4 + raw_instr_bin_str[-7:-5] + raw_instr_bin_str[-3] + raw_instr_bin_str[
        -12] + raw_instr_bin_str[-11] + raw_instr_bin_str[-5:-3] + raw_instr_bin_str[-13]
    imm_c_jal = (raw_instr_bin_str[-13] + raw_instr_bin_str[-9] + raw_instr_bin_str[-11] + raw_instr_bin_str[-10] +
                 raw_instr_bin_str[-7] + raw_instr_bin_str[-8] + raw_instr_bin_str[-3]
                 + raw_instr_bin_str[-12] + raw_instr_bin_str[-6] + raw_instr_bin_str[-5] + raw_instr_bin_str[-4] +
                 raw_instr_bin_str[-13] * 9)
    imm_c_lw_sw = "00000" + raw_instr_bin_str[-6] + raw_instr_bin_str[-13:-10] + raw_instr_bin_str[-7] + "00"
    imm_c_ld_sd = "0000" + raw_instr_bin_str[-7:-5] + raw_instr_bin_str[-13:-10] + "000"
    imm_c_lwsp = "0000" + raw_instr_bin_str[-4:-2] + raw_instr_bin_str[-13] + raw_instr_bin_str[-7:-4] + "00"
    imm_c_ldsp = "000" + raw_instr_bin_str[-5:-2] + raw_instr_bin_str[-13] + raw_instr_bin_str[-7:-5] + "000"
    imm_c_swsp_sdsp = "000" + raw_instr_bin_str[-10:-7] + raw_instr_bin_str[-13:-10] + "000"

    if quadrant == "00":
        if funct3 == "000":
            extend_instr_bin_str = imm_c_addi4spn + "00010" + "000" + rd_rs2_p + "0010011"
        elif funct3 == "010":
            extend_instr_bin_str = imm_c_lw_sw + rd_rs1_p + "010" + rd_rs2_p + "0000011"
        elif funct3 == "011":
            extend_instr_bin_str = imm_c_ld_sd + rd_rs1_p + "011" + rd_rs2_p + "0000011"
        elif funct3 == "110":
            extend_instr_bin_str = imm_c_lw_sw[-12:-5] + rd_rs2_p + rd_rs1_p + "010" + imm_c_lw_sw[-5:] + "0100011"
        elif funct3 == "111":
            extend_instr_bin_str = imm_c_ld_sd[-12:-5] + rd_rs2_p + rd_rs1_p + "011" + imm_c_ld_sd[-5:] + "0100011"
    elif quadrant == "01":
        if funct3 == "000":
            if rd_rs1 != "00000" and imm_c_alu != "000000000000":
                extend_instr_bin_str = imm_c_alu + rd_rs1 + "000" + rd_rs1 + "0010011"
        elif funct3 == "001":
            if rd_rs1 != "00000":
                extend_instr_bin_str = imm_c_alu + rd_rs1 + "000" + rd_rs1 + "0011011"
        elif funct3 == "010":
            if rd_rs1 != "00000":
                extend_instr_bin_str = imm_c_alu + "00000" + "000" + rd_rs1 + "0010011"
        elif funct3 == "011":
            if rd_rs1 == "00010":
                extend_instr_bin_str = imm_c_addi16sp + "00010" + "000" + rd_rs1 + "0010011"
            elif rd_rs1 != "00000":
                extend_instr_bin_str = imm_c_lui + rd_rs1 + "0110111"
        elif funct3 == "100":
            if funct2_p == "00":  # C.SRLI
                if imm_c_alu != "000000000000":
                    extend_instr_bin_str = "000000" + imm_c_alu[-6:] + rd_rs1_p + "101" + rd_rs1_p + "0010011"
            elif funct2_p == "01":  # C.SRAI
                if imm_c_alu != "000000000000":
                    extend_instr_bin_str = "010000" + imm_c_alu[-6:] + rd_rs1_p + "101" + rd_rs1_p + "0010011"
            elif funct2_p == "10":  # C.ANDI
                extend_instr_bin_str = imm_c_alu + rd_rs1_p + "111" + rd_rs1_p + "0010011"
        elif funct3 == "101":
            extend_instr_bin_str = imm_c_jal + "00000" + "1101111"
        elif funct3 == "110":
            extend_instr_bin_str = imm_c_branch[-12:-5] + "00000" + rd_rs1_p + "000" + imm_c_branch[-5:] + "1100011"
        elif funct3 == "111":
            extend_instr_bin_str = imm_c_branch[-12:-5] + "00000" + rd_rs1_p + "001" + imm_c_branch[-5:] + "1100011"
        if funct6 == "100011":
            if funct2 == "00":  # C.SUB
                extend_instr_bin_str = "0100000" + rd_rs2_p + rd_rs1_p + "000" + rd_rs1_p + "0110011"
            elif funct2 == "01":  # C.XOR
                extend_instr_bin_str = "0000000" + rd_rs2_p + rd_rs1_p + "100" + rd_rs1_p + "0110011"
            elif funct2 == "10":  # C.OR
                extend_instr_bin_str = "0000000" + rd_rs2_p + rd_rs1_p + "110" + rd_rs1_p + "0110011"
            elif funct2 == "11":  # C.AND
                extend_instr_bin_str = "0000000" + rd_rs2_p + rd_rs1_p + "111" + rd_rs1_p + "0110011"
        elif funct6 == "100111":
            if funct2 == "00":  # C.SUBW
                extend_instr_bin_str = "0100000" + rd_rs2_p + rd_rs1_p + "000" + rd_rs1_p + "0111011"
            elif funct2 == "01":  # C.ADDW
                extend_instr_bin_str = "0000000" + rd_rs2_p + rd_rs1_p + "000" + rd_rs1_p + "0111011"
    elif quadrant == "10":
        if funct3 == "000":
            if imm_c_alu != "000000000000" and rd_rs1 != "00000":
                extend_instr_bin_str = "000000" + imm_c_alu[-6:] + rd_rs1 + "001" + rd_rs1 + "0010011"
        elif funct3 == "010":
            if rd_rs1 != "00000":
                extend_instr_bin_str = imm_c_lwsp + "00010" + "010" + rd_rs1 + "0000011"
        elif funct3 == "011":
            if rd_rs1 != "00000":
                extend_instr_bin_str = imm_c_ldsp + "00010" + "011" + rd_rs1 + "0000011"
        elif funct3 == "110":
            extend_instr_bin_str = imm_c_swsp_sdsp[-12:-5] + rs_2 + "00010" + "010" + imm_c_swsp_sdsp[-5:] + "0100011"
        elif funct3 == "111":
            extend_instr_bin_str = imm_c_swsp_sdsp[-12:-5] + rs_2 + "00010" + "011" + imm_c_swsp_sdsp[-5:] + "0100011"
        if funct4 == "1000":
            if rd_rs1 != "00000":
                if rs_2 == "00000":
                    extend_instr_bin_str = "0" * 12 + rd_rs1 + "000" + "00000" + "1100111"
                else:
                    extend_instr_bin_str = "0000000" + rs_2 + "00000" + "000" + rd_rs1 + "0110011"
        elif funct4 == "1001":
            if rd_rs1 != "00000":
                if rs_2 == "00000":
                    extend_instr_bin_str = "0" * 12 + rd_rs1 + "000" + "00001" + "1100111"
                else:
                    extend_instr_bin_str = "0000000" + rs_2 + rd_rs1 + "000" + rd_rs1 + "0110011"
    return extend_instr_bin_str


# extend_instruction_test = extend_inst("0x00fe")
# print(int(extend_instruction_test, 2))

pc = []
instruction = []
instruction_raw = []
wb_reg = []
wb_val = []
DMEM_addr = []
DMEM_data = []
DMEM_data_hex = []
# Regex patterns
# Pattern 1: Normal instruction with optional write-back (no mem)
pattern_normal = re.compile(
    r'0x([0-9a-fA-F]+)\s+\(0x([0-9a-fA-F]+)\)'  # PC and instruction
    r'(?:\s+x(\d+)\s+0x([0-9a-fA-F]+))?'  # Optional wb_reg and wb_val
    r'(?!\s+mem)'  # Negative lookahead: no "mem" following
)

# Pattern 2: Load instruction (with mem at the end)
pattern_load = re.compile(
    r'0x([0-9a-fA-F]+)\s+\(0x([0-9a-fA-F]+)\)'  # PC and instruction
    r'\s+x(\d+)\s+0x([0-9a-fA-F]+)'  # wb_reg and wb_val
    r'\s+mem\s+0x([0-9a-fA-F]+)'  # mem address
)

# Pattern 3: Store instruction (mem without preceding register write-back)
pattern_store = re.compile(
    r'0x([0-9a-fA-F]+)\s+\(0x([0-9a-fA-F]+)\)'  # PC and instruction
    r'\s+mem\s+0x([0-9a-fA-F]+)\s+0x([0-9a-fA-F]+)'  # mem address and data
)

spike_path = "run_logs/spike.log" if args.create else "simulation_reference.log"

# Read the input file
with open(spike_path, "r", encoding="utf-8") as f:
    for idx, line in enumerate(f):
        if idx < 5:
            continue
        line = line.strip()

        # Try to match store pattern first (most specific)
        match_store = pattern_store.search(line)
        if match_store:
            # Store instruction: record Memories address and data
            try:
                mem_addr = int(match_store.group(3), 16)
            except (ValueError, TypeError) as e:
                print(f"[WARN] Can't convert addreess to int: {match_store.group(3)}，error: {e}")
                mem_addr = None
            try:
                mem_data = int(match_store.group(4), 16)
            except (ValueError, TypeError) as e:
                print(f"[WARN] Can't convert data to int: {match_store.group(4)}，error: {e}")
                mem_data = None

            DMEM_addr.append(mem_addr)
            DMEM_data.append(mem_data)
            DMEM_data_hex.append(match_store.group(4))
            continue

        # Try to match load pattern
        match_load = pattern_load.search(line)
        if match_load:
            # Load instruction: record PC, instruction, register, and value
            pc_hex = match_load.group(1)
            inst_hex = match_load.group(2)
            reg_str = match_load.group(3)
            val_hex = match_load.group(4)
            # mem_addr = match_load.group(5)  # Optional: can also record load address
            if reg_str is not None and val_hex is not None:
                try:
                    wb_reg.append(int(reg_str))
                except (ValueError, TypeError) as e:
                    print(f"[WARN] Can't convert register addreess to int: {match_store.group(3)}，error: {e}")
                    wb_reg.append(None)
                try:
                    wb_val.append(int(val_hex, 16))
                except (ValueError, TypeError) as e:
                    print(f"[WARN] Can't convert write back value to hex: {match_store.group(4)}，error: {e}")
                    wb_val.append(None)
                try:
                    pc.append(int(pc_hex, 16))
                except (ValueError, TypeError) as e:
                    print(f"[WARN] Can't convert PC to hex: {match_store.group(1)}，error: {e}")
                    pc.append(None)
                try:
                    instruction_raw.append(int(inst_hex, 16))
                except (ValueError, TypeError) as e:
                    print(f"[WARN] Can't convert instruction to hex: {match_store.group(2)}，error: {e}")
                    instruction_raw.append(None)
                if (bin(int(inst_hex[-1], 16))[-2:] == "11"):
                    try:
                        instruction.append(int(inst_hex, 16))
                    except (ValueError, TypeError) as e:
                        print(f"[WARN] Can't convert instruction to hex: {match_store.group(2)}，error: {e}")
                        instruction.append(None)
                else:
                    try:
                        instruction.append(int(extend_inst(inst_hex), 2))
                    except (ValueError, TypeError) as e:
                        print(f"[WARN] Can't convert instruction to hex: {extend_inst(inst_hex)}，error: {e}")
                        instruction.append(None)
            continue

        # Try to match normal pattern (no mem keyword)
        match_normal = pattern_normal.search(line)
        if match_normal:
            pc_hex = match_normal.group(1)
            inst_hex = match_normal.group(2)
            reg_str = match_normal.group(3)
            val_hex = match_normal.group(4)

            # Handle optional write-back information
            if reg_str is not None and val_hex is not None:
                try:
                    wb_reg.append(int(reg_str))
                except (ValueError, TypeError) as e:
                    print(f"[WARN] Can't convert register addreess to int: {match_store.group(3)}，error: {e}")
                    wb_reg.append(None)
                try:
                    wb_val.append(int(val_hex, 16))
                except (ValueError, TypeError) as e:
                    print(f"[WARN] Can't convert write back value to hex: {match_store.group(4)}，error: {e}")
                    wb_val.append(None)
                try:
                    pc.append(int(pc_hex, 16))
                except (ValueError, TypeError) as e:
                    print(f"[WARN] Can't convert PC to hex: {match_store.group(1)}，error: {e}")
                    pc.append(None)
                try:
                    instruction_raw.append(int(inst_hex, 16))
                except (ValueError, TypeError) as e:
                    print(f"[WARN] Can't convert instruction to hex: {match_store.group(2)}，error: {e}")
                    instruction_raw.append(None)
                if (bin(int(inst_hex[-1], 16))[-2:] == "11"):
                    try:
                        instruction.append(int(inst_hex, 16))
                    except (ValueError, TypeError) as e:
                        print(f"[WARN] Can't convert instruction to hex: {match_store.group(2)}，error: {e}")
                        instruction.append(None)
                else:
                    try:
                        instruction.append(int(extend_inst(inst_hex), 2))
                    except (ValueError, TypeError) as e:
                        print(f"[WARN] Can't convert instruction to hex: {extend_inst(inst_hex)}，error: {e}")
                        instruction.append(None)

pc_sim = []
instruction_sim = []
wb_reg_sim = []
wb_val_sim = []

# Open the CSV file (replace 'sim_data.csv' with your filename)
with open("temp/Vivado_kreacher_temp/Vivado_kreacher.sim/sim_1/behav/xsim/kreacher_trace.csv", "r",
          encoding="utf-8") as f:
    reader = csv.reader(f, delimiter=',')  # Assuming tab-separated, change delimiter if needed
    next(reader)  # Skip the header line

    for row in reader:
        # row format: time_ns, pc, inst, rd, rd_value
        pc_hex = row[1].strip()
        inst_hex = row[2].strip()
        rd_str = row[3].strip() if len(row) > 3 else ""
        val_hex = row[4].strip() if len(row) > 4 else ""

        try:
            # Convert hex fields to decimal
            pc_val = int(pc_hex, 16)
            inst_val = int(inst_hex, 16)  # If this fails, the row is skipped
        except ValueError:
            # Skip this row if any conversion fails (especially illegal instruction)
            continue
        # rd_val = int(rd_str) if rd_str != "" else ""
        # wb_hex_val = int(val_hex, 16) if val_hex != "" else ""
        # Convert hex strings to decimal (int), rd is already a decimal string
        if (rd_str != '0'):
            pc_sim.append(int(pc_hex, 16))
            instruction_sim.append(int(inst_hex, 16))
            try:
                wb_reg_sim.append(int(rd_str))
            except (ValueError, TypeError) as e:
                print(f"[WARN] Can't convert simulated register address to int: {rd_str}，error: {e}")
                wb_reg_sim.append(None)
            try:
                wb_val_sim.append(int(val_hex, 16))
            except (ValueError, TypeError) as e:
                print(f"[WARN] Can't convert simulated write back value to hex: {val_hex}，error: {e}")
                wb_val_sim.append(None)

# Open the input file
instruction_file_path = "temp/instructions.txt" if args.create else "PMEM_instructions.txt"


def find_instruction_by_hex(target_hex):
    with open(instruction_file_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            parts = line.split()

            if len(parts) < 3:
                continue

            machine_code = parts[1]
            if machine_code.lower() == target_hex.lower():
                instruction = " ".join(parts[2:])
                return instruction

    return None


pc_i = 100000
ins_i = 100000
wb_reg_i = 100000
wb_val_i = 100000
for i in range(min(len(pc), len(pc_sim))):
    if pc[i] != pc_sim[i]:
        pc_i = i
        break
for i in range(min(len(instruction), len(instruction_sim))):
    if instruction[i] != instruction_sim[i]:
        ins_i = i
        break
for i in range(min(len(wb_reg), len(wb_reg_sim))):
    if wb_reg[i] != wb_reg_sim[i]:
        wb_reg_i = i
        break
for i in range(min(len(wb_val), len(wb_val_sim))):
    if wb_val[i] != wb_val_sim[i]:
        wb_val_i = i
        break

i_min = min(pc_i, ins_i, wb_reg_i, wb_val_i)
if i_min != 100000:
    print(f"First mismatch at item {i_min + 1}")
    print(f"Simulated PC:{hex(pc_sim[i_min])}")
    print(f"Reference PC:{hex(pc[i_min])}")
    print(f"Simulated instruction:{hex(instruction_sim[i_min])}")
    print(f"Reference instruction:{hex(instruction[i_min])}")
    if instruction_raw[i_min] != instruction[i_min]:
        instruction_str = format(instruction_raw[i_min], "04x")
        print(f"Original c instruction before extension:{hex(instruction_raw[i_min])}")
    else:
        instruction_str = str(hex(instruction_raw[i_min]))[2:]
    print(f"Simulated wb_reg:{wb_reg_sim[i_min]}")
    print(f"Reference wb_reg:{wb_reg[i_min]}")
    print(f"Simulated wb_val:{hex(wb_val_sim[i_min])}")
    print(f"Reference wb_val:{hex(wb_val[i_min])}")
    assembly_instr = find_instruction_by_hex(instruction_str)
    print(f"Assembly instruction: {assembly_instr}")
    raise ValueError("A mismatch has been found.")

    # First check whether the lengths are equal
if len(pc) != len(pc_sim):
    print("Length of reference PC list:", len(pc))
    print("Length of simulated PC list:", len(pc_sim))
    for i in range(min(len(pc), len(pc_sim))):
        if pc[i] != pc_sim[i]:
            print(f"First mismatch at item {i + 1}")
            print(f"Simulated PC:{hex(pc_sim[i])}")
            print(f"Reference PC:{hex(pc[i])}")
            break
    raise ValueError("The two PC lists have different lengths.")
if len(instruction) != len(instruction_sim):
    raise ValueError("The two instruction lists have different lengths.")
if len(wb_reg) != len(wb_reg_sim):
    raise ValueError("The two write back register lists have different lengths.")
if len(wb_val) != len(wb_val_sim):
    raise ValueError("The two write back value lists have different lengths.")
# Store all mismatched indices
pc_diff_indices = []
instruction_diff_indices = []
wb_reg_diff_indices = []
wb_val_diff_indices = []

# Compare values element by element
for i in range(len(pc)):
    if pc[i] != pc_sim[i]:
        pc_diff_indices.append(i)
    if instruction[i] != instruction_sim[i]:
        instruction_diff_indices.append(i)
    if (wb_reg[i] == 0 and wb_reg_sim[i] == 0) or (wb_reg[i] == "") or (wb_reg[i] == 0 and wb_reg_sim[i] == ""):
        continue
    if wb_reg[i] != wb_reg_sim[i]:
        wb_reg_diff_indices.append(i)
    if wb_val[i] != wb_val_sim[i]:
        wb_val_diff_indices.append(i)

output_file = open("run_logs/compare_output.txt", "w", encoding="utf-8")


def log(msg):
    """Print to console and write to file at the same time."""
    print(msg)
    output_file.write(msg + "\n")


if not pc_diff_indices:
    log("PC matched.")
    if not instruction_diff_indices:
        log("Instructions matched.")
        if not wb_reg_diff_indices:
            log("Write back registers matched.")
            if not wb_val_diff_indices:
                log("Write back values matched.")
            else:
                log("Write back values mismatched\n")
                for i in wb_val_diff_indices:
                    log(f"Reference trace: PC:{pc[i]:#018x}, Instrcution:{instruction[i]:#010x}, "
                        f"write back register:x{wb_reg[i]}, write back value:{wb_val[i]:#018x}")
                    log(f"Simulated trace: PC:{pc_sim[i]:#018x}, Instrcution:{instruction_sim[i]:#010x}, "
                        f"write back register:x{wb_reg_sim[i]}, write back value:{wb_val_sim[i]:#018x}")
                    log(f"Assembly code: {instruction_text[i]}")
                    log("=" * 80)
        else:
            log("Write back registers mismatched\n")
            for i in wb_reg_diff_indices:
                log(f"Reference trace: PC:{pc[i]:#018x}, Instrcution:{instruction[i]:#010x}, "
                    f"write back register:x{wb_reg[i]}, write back value:{wb_val[i]:#018x}")
                log(f"Simulated trace: PC:{pc_sim[i]:#018x}, Instrcution:{instruction_sim[i]:#010x}, "
                    f"write back register:x{wb_reg_sim[i]}, write back value:{wb_val_sim[i]:#018x}")
                log(f"Assembly code: {instruction_text[i]}")
                log("=" * 80)
    else:
        log("Instructions mismatched\n")
        for i in instruction_diff_indices:
            log(f"Reference trace: PC:{pc[i]:#018x}, Instrcution:{instruction[i]:#010x}, "
                f"write back register:x{wb_reg[i]}, write back value:{wb_val[i]:#018x}")
            log(f"Simulated trace: PC:{pc_sim[i]:#018x}, Instrcution:{instruction_sim[i]:#010x}, "
                f"write back register:x{wb_reg_sim[i]}, write back value:{wb_val_sim[i]:#018x}")
            log(f"Assembly code: {instruction_text[i]}")
            log("=" * 80)
else:
    log("PC mismatched\n")
    for i in pc_diff_indices:
        log(f"Reference trace: PC:{pc[i]:#018x}, Instrcution:{instruction[i]:#010x}, "
            f"write back register:x{wb_reg[i]}, write back value:{wb_val[i]:#018x}")
        log(f"Simulated trace: PC:{pc_sim[i]:#018x}, Instrcution:{instruction_sim[i]:#010x}, "
            f"write back register:x{wb_reg_sim[i]}, write back value:{wb_val_sim[i]:#018x}")
        log(f"Assembly code: {instruction_text[i]}")
        log("=" * 80)

DMEM_old_data = []
DMEM_simulate_data = []


def split_hex_to_bytes(value):
    bytes_str = [value[i:i + 2] for i in range(0, len(value), 2)]
    bytes_str.reverse()
    return bytes_str


def verify_dmem_content(DMEM_addr, DMEM_data):
    """
    Verify DMEM content matches expected values

    Args:
        DMEM_addr: List of DMEM addresses
        DMEM_data: List of DMEM data
    """
    mem_file_path = "../../Memories/src/DMEM_content.mem"
    with open(mem_file_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            chunks = [line[i:i + 8] for i in range(0, len(line), 8)]
            DMEM_old_data.extend(reversed(chunks))

    mem_file_path = "../../Vivado_Kreacher/Vivado_kreacher.sim/sim_1/behav/xsim/DMEM_result.mem"
    with open(mem_file_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            chunks = [line[i:i + 8] for i in range(0, len(line), 8)]
            DMEM_simulate_data.extend(reversed(chunks))
    DMEM_simulate_data[:] = [element for element in DMEM_simulate_data if element != 'xxxxxxxx']
    diff = []
    if DMEM_addr:
        for i in range(len(DMEM_addr)):
            addr = DMEM_addr[i]
            expected_data = DMEM_data[i]
            expected_data_hex = DMEM_data_hex[i]
            # Convert to hex and extract lower 17 bits
            addr_hex = addr & 0x1FFFF  # 0x1FFFF = 17-bit mask
            k = addr_hex  # Convert to decimal (already in decimal)
            # Check if line number is out of range
            if k / 4 >= len(DMEM_old_data):
                print(
                    f"Error: Address 0x{addr:08x} corresponds to line {k / 8}, which exceeds file size ({len(DMEM_old_data)} lines)")
                continue
            # TODO: This is for SD only, SW/SH/SB requires different logic
            # print(DMEM_old_data[int(k / 4)], DMEM_old_data[int(k / 4) + 1])
            DMEM_old_data[int(k / 4)] = expected_data_hex[-8:]
            DMEM_old_data[int(k / 4) + 1] = expected_data_hex[0:-8]
            # print(DMEM_old_data[int(k / 4)], DMEM_old_data[int(k / 4) + 1])
            if len(DMEM_old_data) != len(DMEM_simulate_data):
                raise ValueError(
                    f"Length mismatch: len(DMEM_ref_data)={len(DMEM_old_data)}, len(DMEM_simulate_data)={len(DMEM_simulate_data)}"
                )

        for i, (x, y) in enumerate(zip(DMEM_old_data, DMEM_simulate_data)):
            if x != y:
                diff.append(i)

    if not diff:
        print("Store word instructions checked. DMEM result matched.")
        print("Congratulations! You have survived the torture test!")
        print(" ")
        print("           ###                          ###            ")
        print("         ##   ##                      ##   ##         ")
        print("       ##       ##                  ##       ##   ")
        print("      ##          ##               ##          ## ")
        print("        ")
        print("                           ||   ")
        print("                           ||")
        print("                           ||   ")
        print("                           }}")
        print("                              ")
        print("                   ==            ==")
        print("                    ==          ==")
        print("                       ==    ==")
        print("                          ==")
    else:
        for i in diff:
            print(
                f"addr = 0x{(i * 4):08x}, DMEM_ref_data = {DMEM_old_data[i]}, DMEM_simulate_data = {DMEM_simulate_data[i]}")


# Usage example
verify_dmem_content(DMEM_addr, DMEM_data)
# Close the output file
output_file.close()

