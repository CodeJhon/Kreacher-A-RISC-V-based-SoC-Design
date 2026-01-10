#!/bin/bash

set -e

LDS=linker.ld
LOG=spike.log
TEST=riscv_rand_instr_test_jump
TARGET=rv32i
SRC=${TEST}_refine.S
ELF=${TEST}_refine.elf
BIN=${TEST}_refine.bin
MEM=PMEM_content.mem
TEMP_DIR="./Vivado_Kreacher_temp"
ROOT_DIR="$(pwd)"
if command -v python >/dev/null 2>&1; then
    PYTHON_CMD=python
elif command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD=python3
else
    echo "Error: Python is not installed."
    exit 1
fi

ARGS=$(getopt -o i:vc --long isa:,vivado,create -n "$0" -- "$@")
if [ $? != 0 ]; then
  echo "Wrong input of arguments"
  exit 1
fi

eval set -- "$ARGS"

while true; do
  case "$1" in
    -i|--isa)
      isa="$2"
      shift 2
      ;;
    -v|--vivado)
      create=true
      shift
      ;;
    -c|--create)
      create=true
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "unknown parameter $1"
      exit 1
      ;;
  esac
done

mkdir -p ./temp
mkdir -p ./run_logs



if [ "$create" ]
then
  cd ../../../riscv-dv/riscv-dv
  set +e
  $PYTHON_CMD run.py --test=${TEST} --target=${TARGET} -o=riscv_random_test \
  --simulator=pyflow --iterations=1
  set -e

  cp riscv_random_test/asm_test/${TEST}_0.S ../../vlsi_processor_design_project/3_Verification/auto_test/temp

  if [ -f ../../vlsi_processor_design_project/Memories/src/PMEM_content.mem ]
  then
    mv ../../vlsi_processor_design_project/Memories/src/PMEM_content.mem ../../vlsi_processor_design_project/Memories/src/PMEM_content_old.mem
  fi

  cd ../../vlsi_processor_design_project/3_Verification/auto_test

  $PYTHON_CMD refine_instruction.py

  cp linker.ld ./temp
  cd ./temp

  echo "===> [1/6] compiling ELF..."
  riscv64-unknown-elf-gcc \
    -mbig-endian \
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
  riscv64-unknown-elf-objcopy \
    -O binary \
    ${ELF} \
    ${BIN}

  echo "===> [3/6] generating MEM file and instruction text..."
  xxd -p -c 4 ${BIN} | \
  sed 's/\(..\)\(..\)\(..\)\(..\)/\4\3\2\1/' > temp.mem

  sed 's/\(..\)/\1 /g; s/ $//' temp.mem > ${MEM}
  cp ${MEM}  ../../../Memories/src/
  cp ${MEM}  ../run_logs/

  riscv64-unknown-elf-objdump -D -b binary -m riscv ${BIN} > instructions.txt
  cp instructions.txt ../PMEM_instructions.txt

  echo "===> [4/6] Running Spike and saving to ${LOG}..."
  spike --log-commits --instructions=10000 --isa=rv64i --big-endian ${ELF} 2>&1 | tee ${LOG}
  cp ${LOG} ../run_logs/
else 
  echo "Skipping the first 4 steps of generating random instructions. Now at step 5."
  cd ./temp
fi

if [ -d "$TEMP_DIR" ]; then
  echo "Old temporary project dectected, starting cleaning"
  rm -r "$TEMP_DIR"
  if [ $? -eq 0 ]; then
    echo "Deleted"
  else
    echo "Failed"
  fi
fi

if [ "$vivado" ]
then
  cp -r ../../../Vivado_Kreacher ./Vivado_Kreacher_temp
  cp ../simulate.tcl ./

  echo "===> [5/6] Running simulation in Vivado..."
  TCL_FILE="$ROOT_DIR/temp/simulate.tcl"
  WIN_PATH=$(wslpath -w "$TCL_FILE")
  cmd.exe /c "Vivado -mode batch -source $WIN_PATH"
else
  echo "Skipping Vivado simulation. Now at step 6."
  cp -r ../../../Vivado_Kreacher/ ./Vivado_kreacher_temp
fi

cd ..
set +e
echo "===> [6/6] Comparing results..."
if [ "$create" ]
then
$PYTHON_CMD compare_trace.py --create
else
$PYTHON_CMD compare_trace.py
fi
set -e

if [ "$create" ]
then
  while true; do
    read -p "Do you want to replace the old PMEM file with the new one(y/n): " choice
    case "$choice" in
      (y|yes|YES|Yes)
        rm ../../Memories/src/PMEM_content_old.mem
        cp ./run_logs/spike.log ./simulation_reference.log
        echo "Old PMEM is replaced with the new one"
        break
        ;;
      (n|no|NO|No)
        rm ../../Memories/src/PMEM_content.mem
        mv ../../Memories/src/PMEM_content_old.mem ../../Memories/src/PMEM_content.mem
        echo "Old PMEM kept. New PMEM discarded"
        break
        ;;
      *)
        echo "Invalid input"
        ;;
    esac
  done
fi

cp temp/Vivado_Kreacher_temp/Vivado_Kreacher.sim/sim_1/behav/xsim/kreacher_trace.csv run_logs/kreacher_trace.csv
rm -r temp/Vivado_Kreacher_temp

echo "Process finished"