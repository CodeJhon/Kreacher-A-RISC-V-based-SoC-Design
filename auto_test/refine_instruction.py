import re

# 输入输出文件
input_file = "riscv_arithmetic_basic_test_0.S"   # 原始汇编文件
output_file = "riscv_arithmetic_basic_test_refine.S"  # 生成的新汇编文件

# 读取原始汇编文件
with open(input_file, "r") as f:
    code = f.read()


def extract_section(label, code):
    """
    严格提取指定标签下的内容（label 为 'init' 或 'main'），
    从下一行开始读取，直到下一个标签行（形如 xxx:）或文件结束。
    不包括标签行本身。
    """
    pattern = rf"^{label}:\s*$\n(.*?)(?=\n\w+:\s*$|\Z)"
    match = re.search(pattern, code, re.MULTILINE | re.DOTALL)
    if match:
        section = match.group(1).rstrip()
        return section
    return ""


# 提取 init 和 main 的内容
init_content = extract_section("init", code)
main_content = extract_section("main", code)

# 合并为要插入的内容
insert_content = f"{init_content}\n{main_content}"

# 固定模板
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

# 用提取内容替换模板中的 xxx
patched_code = template.replace("xxx", insert_content)

# 删除包含 'user_stack_end' 或 'test_done' 的行，并去掉空行
filtered_lines = [
    line for line in patched_code.splitlines()
    if "user_stack_end" not in line and "test_done" not in line and line.strip() != ""
]
final_code = "\n".join(filtered_lines) + "\n"  # 最后加一个换行符保持文件结尾整洁

# 写入新文件
with open(output_file, "w") as f:
    f.write(final_code)

print(f"已生成新文件: {output_file}")
