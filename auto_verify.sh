#!/bin/bash

set -e

LDS=linker.ld
LOG=spike.log
TEST=riscv_arithmetic_basic_test
TARGET=rv32i
SRC=${TEST}_refine.S
ELF=${TEST}_refine.elf
BIN=${TEST}_refine.bin
MEM=PMEM_content.mem

cd riscv-dv/riscv-dv

set +e
python3 run.py --test=${TEST} --target=${TARGET} -o=riscv_random_test \
--simulator=pyflow --iterations=1
set -e

mkdir -p ../../auto_test
cp riscv_random_test/asm_test/${TEST}_0.S ../../auto_test

cd ../../auto_test

python refine_instruction.py

echo "===> [1/6] compiling ELF..."
riscv32-unknown-elf-gcc \
  -march=rv32i \
  -mabi=ilp32 \
  -nostdlib \
  -nostartfiles \
  -ffreestanding \
  -fno-pie -no-pie\
  -Wl,-T,${LDS} \
  ${SRC} \
  -o ${ELF}

echo "===> [2/6] generateing BIN..."
riscv32-unknown-elf-objcopy \
  -O binary \
  ${ELF} \
  ${BIN}

echo "===> [3/6] generating MEM file and instruction text..."
xxd -p -c 4 ${BIN} | \
sed 's/\(..\)\(..\)\(..\)\(..\)/\4\3\2\1/' > temp.mem

sed 's/\(..\)/\1 /g; s/ $//' temp.mem > ${MEM}

riscv32-unknown-elf-objdump -D -b binary -m riscv ${BIN} > instructions.txt

echo "===> [4/6] Running Spike and saving to ${LOG}..."
spike --log-commits --instructions=10000 --isa=rv32i ${ELF} 2>&1 | tee ${LOG}

echo "===> [5/6] Running simulation in Vivado..."
TCL_FILE="/mnt/d/riscv/auto_test/simulate.tcl"
WIN_PATH=$(wslpath -w "$TCL_FILE")
cmd.exe /c "Vivado -mode batch -source $WIN_PATH"

echo "===> [6/6] Comparing results..."
python compare_trace.py

echo "Process finished"
