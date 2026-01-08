import re

# Input and output file paths
input_file = "temp/riscv_rand_instr_test_jump_0.S"   # Original assembly file
output_file = "temp/riscv_rand_instr_test_jump_refine.S"  # Generated refined assembly file

# Read the original assembly file
with open(input_file, "r") as f:
    code = f.read()


def extract_section(label, code):
    """
    Strictly extract the content under a specified label (label is 'init' or 'main').
    The extraction starts from the next line after the label,
    and stops at the next label line (format like xxx:) or the end of file.
    The label line itself is not included.
    """
    pattern = rf"^{label}:\s*$\n(.*?)(?=\n\w+:\s*$|\Z)"
    match = re.search(pattern, code, re.MULTILINE | re.DOTALL)
    if match:
        section = match.group(1).rstrip()
        lines = section.splitlines()
        if lines:
            lines = lines[:-1]  # 去掉最后一行
        return "\n".join(lines)
    return ""


# Extract the content of init and main sections
init_content = extract_section("init", code)
main_content = extract_section("main", code)

# Merge init and main content into one block to be inserted
insert_content = f"{init_content}\n{main_content}"

# Fixed assembly template
template = """.section .text
.globl _start
_start: 
 xxx 
.section .bss 
.align 4 
tohost: 
    .word 0 
fromhost: 
    .word 0 
"""

# Replace placeholder xxx in the template with extracted content
patched_code = template.replace("xxx", insert_content)

# Remove lines containing 'user_stack_end' or 'test_done', and remove empty lines
filtered_lines = [
    line for line in patched_code.splitlines()
    if "user_stack_end" not in line and "test_done" not in line and line.strip() != ""
]

# Recombine lines and add a final newline at the end of the file
final_code = "\n".join(filtered_lines) + "\n"

# Write the final result to the output file
with open(output_file, "w") as f:
    f.write(final_code)

# Print generation success message
print(f"New file generated: {output_file}")
