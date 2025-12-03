import re
import csv
# Lists to store results
pc = []
instruction = []
wb_reg = []
wb_val = []

# Regex pattern (write-back part is optional)
pattern = re.compile(
    r'0x([0-9a-fA-F]+)\s+\(0x([0-9a-fA-F]+)\)'      # PC and instruction
    r'(?:\s+x(\d+)\s+0x([0-9a-fA-F]+))?'           # Optional wb_reg and wb_val
)

# Read the input file (assuming filename is data.txt)
with open("spike.log", "r", encoding="utf-8") as f:
    for idx, line in enumerate(f):
        if idx < 5:
            continue
        line = line.strip()
        match = pattern.search(line)

        if match:
            pc_hex = match.group(1)
            inst_hex = match.group(2)
            reg_str = match.group(3)
            val_hex = match.group(4)

            # Convert hex to decimal
            pc.append(int(pc_hex, 16))
            instruction.append(int(inst_hex, 16))

            # Handle optional write-back information
            if reg_str is not None and val_hex is not None:
                wb_reg.append(int(reg_str))
                wb_val.append(int(val_hex, 16))
            else:
                wb_reg.append(0)
                wb_val.append(0)

# Print results for verification
# print("PC =", PC)
# print("instruction =", instruction)
# print("wb_reg =", wb_reg)
# print("wb_val =", wb_val)

# Lists to store simulation data
pc_sim = []
instruction_sim = []
wb_reg_sim = []
wb_val_sim = []

# Open the CSV file (replace 'sim_data.csv' with your filename)
with open("kreacher_sim_project/kreacher_sim.sim/sim_1/behav/xsim/kreacher_trace.csv", "r", encoding="utf-8") as f:
    reader = csv.reader(f, delimiter=',')  # Assuming tab-separated, change delimiter if needed
    next(reader)  # Skip the header line

    for row in reader:
        # row format: time_ns, pc, inst, rd, rd_value
        pc_hex = row[1].strip()
        inst_hex = row[2].strip()
        rd_str = row[3].strip()
        val_hex = row[4].strip()

        try:
            # Convert hex fields to decimal
            pc_val = int(pc_hex, 16)
            inst_val = int(inst_hex, 16)  # If this fails, the row is skipped
            rd_val = int(rd_str)
            wb_val_dec = int(val_hex, 16)
        except ValueError:
            # Skip this row if any conversion fails (especially illegal instruction)
            continue

        # Convert hex strings to decimal (int), rd is already a decimal string
        pc_sim.append(int(pc_hex, 16))
        instruction_sim.append(int(inst_hex, 16))
        wb_reg_sim.append(int(rd_str))
        wb_val_sim.append(int(val_hex, 16))

# Print results for verification
# print("pc_sim =", pc_sim)
# print("instruction_sim =", instruction_sim)
# print("wb_reg_sim =", wb_reg_sim)
# print("wb_val_sim =", wb_val_sim)
# List to store instruction strings
instruction_text = []

# Open the input file
with open("instructions.txt", "r", encoding="utf-8") as f:
    for idx, line in enumerate(f):
        # Skip the first 7 lines (start from line 8)
        if idx < 7:
            continue

        line = line.strip()

        # Skip empty lines
        if not line:
            continue

        # Split the line by whitespace and tabs
        parts = line.split()

        # Safety check: ensure there are enough fields
        if len(parts) < 3:
            continue

        # Reconstruct the instruction part (everything after the hex instruction)
        instruction_part = " ".join(parts[2:])

        instruction_text.append(instruction_part)

    # First check whether the lengths are equal
if len(pc) != len(pc_sim):
    print(len(pc), len(pc_sim))
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
    if pc[i] != pc_sim[i]+2147483648:
        pc_diff_indices.append(i)
    if instruction[i] != instruction_sim[i]:
        instruction_diff_indices.append(i)
    if wb_reg[i] == 0 and wb_reg_sim[i] == 0:
        continue
    if wb_reg[i] != wb_reg_sim[i]:
        wb_reg_diff_indices.append(i)
    if wb_val[i] != wb_val_sim[i]:
        wb_val_diff_indices.append(i)

# if (not pc_diff_indices):
#     print("PC matched.")
#     if (not instruction_diff_indices):
#         print("Instructions matched.")
#         if (not wb_reg_diff_indices):
#             print("Write back registers matched.")
#             if (not wb_val_diff_indices):
#                 print("Write back values matched.")
#             else:
#                 print("Write back values mismatched")
#                 for i in wb_val_diff_indices:
#                     print(f"Reference trace: PC:{pc[i]:#018x}, Instrcution:{instruction[i]:#010x}, write back register:x{wb_reg[i]}, write back value:{wb_val[i]:#018x}")
#                     print(f"Simulated trace: PC:{pc_sim[i]:#018x}, Instrcution:{instruction_sim[i]:#010x}, write back register:x{wb_reg_sim[i]}, write back value:{wb_val_sim[i]:#018x}")
#                     print(f"Assembly code:{instruction_text[i]}")
#                     print("========================================================================================")
#         else:
#             print("Write back registers mismatched")
#             for i in wb_reg_diff_indices:
#                 print(f"Reference trace: PC:{pc[i]:#018x}, Instrcution:{instruction[i]:#010x}, write back register:x{wb_reg[i]}, write back value:{wb_val[i]:#018x}")
#                 print(f"Simulated trace: PC:{pc_sim[i]:#018x}, Instrcution:{instruction_sim[i]:#010x}, write back register:x{wb_reg_sim[i]}, write back value:{wb_val_sim[i]:#018x}")
#                 print(f"Assembly code:{instruction_text[i]}")
#                 print("========================================================================================")
#     else:
#         print("Instructions mismatched")
#         for i in instruction_diff_indices:
#             print(f"Reference trace: PC:{pc[i]:#018x}, Instrcution:{instruction[i]:#010x}, write back register:x{wb_reg[i]}, write back value:{wb_val[i]:#018x}")
#             print(f"Simulated trace: PC:{pc_sim[i]:#018x}, Instrcution:{instruction_sim[i]:#010x}, write back register:x{wb_reg_sim[i]}, write back value:{wb_val_sim[i]:#018x}")
#             print(f"Assembly code:{instruction_text[i]}")
#             print("========================================================================================")
# else:
#     print("PC mismatched")
#     for i in pc_diff_indices:
#         print(f"Reference trace: PC:{pc[i]:#018x}, Instrcution:{instruction[i]:#010x}, write back register:x{wb_reg[i]}, write back value:{wb_val[i]:#018x}")
#         print(f"Simulated trace: PC:{pc_sim[i]:#018x}, Instrcution:{instruction_sim[i]:#010x}, write back register:x{wb_reg_sim[i]}, write back value:{wb_val_sim[i]:#018x}")
#         print(f"Assembly code:{instruction_text[i]}")
#         print("========================================================================================")
# Open output file
output_file = open("compare_output.txt", "w", encoding="utf-8")

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

# Close the output file
output_file.close()
