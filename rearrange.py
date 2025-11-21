# rearrange_hex.py

input_file = "./Vivado_Kreacher/Vivado_Kreacher.sim/sim_1/behav/xsim/DMEM_result.mem"
output_file = "DMEM_result_rearranged.mem"

hex_values = []

# Read all hex numbers from file (strip whitespace/newlines)
with open(input_file, "r") as f:
    for line in f:
        value = line.strip()
        if value:  # skip empty lines
            hex_values.append(value)

# Write 4-per-line into the output file
with open(output_file, "w") as f:
    for i in range(0, len(hex_values), 4):
        group = hex_values[i:i+4]
        f.write(" ".join(group) + "\n")

print("Done! Output written to", output_file)
