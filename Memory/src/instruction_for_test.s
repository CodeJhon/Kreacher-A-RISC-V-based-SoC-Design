
    .globl _start
_start:
    ########################################
    #auipc, lui, ADDI/SLTI/SLTIU/ANDI/ORI/XORI
    ########################################
    lui     x1, 0x5          # LUI
    addi    x12, x0, 0x200      # base address
    sw      x1, 0(x12)

    auipc   x2, 0x10             # AUIPC
    sw      x2, 4(x12)

    addi    x3, x1, 10           # ADDI
    sw      x3, 8(x12)

    andi    x4, x3, 0xF          # ANDI
    sw      x4, 12(x12)

    slti    x5, x4, -20           # SLTI
    sw      x5, 16(x12)

    sltiu   x6, x4, -20           # SLTIU
    sw      x6, 20(x12)

    ori     x7, x3, 0xF0         # ORI
    sw      x7, 24(x12)

    xori    x8, x3, 0xFF         # XORI
    sw      x8, 28(x12)

    ########################################
    # SLLI/SRLI/SRAI
    ########################################
    slli    x9,  x3, 2           # SLLI
    sw      x9, 32(x12)

    srli    x10, x3, 1           # SRLI
    sw      x10, 36(x12)
    
    srai    x11, x3, 1           # SRAI
    sw      x11, 40(x12)

    ########################################
    # 
    ########################################
    

    ########################################
    # SH/SB
    ########################################
    sh      x9,  22(x12)          # SH
    sb      x10, 21(x12)          # SB

    ########################################
    # LW/LH/LHU/LB/LBU
    ########################################
    lw      x13, 20(x12)          # LW
    sw      x13, 44(x12)

    lh      x14, 20(x12)          # LH
    sw      x14, 48(x12)

    lhu     x15, 20(x12)          # LHU
    sw      x15, 52(x12)

    lb      x16, 20(x12)          # LB
    sw      x16, 56(x12)

    lbu     x17, 20(x12)          # LBU
    sw      x17, 60(x12)

    ########################################
    # jal / jalr
    ########################################
    jal     x18, label_jal       # JAL

after_jal:
    sw      x21, 112(x12)

    addi    x19, x0, 99          # indicator (not required instruction)
    sw      x19, 116(x12)

label_jal:
    sw      x18, 64(x12)

    addi    x20, x0, after_jal   # prepare indirect jump target
    sw      x20, 68(x12)
    

    ########################################
    # ADD/SUB/SLT/SLTU/AND/XOR/OR
    ########################################
    add     x22, x3, x9          # ADD
    sw      x22, 72(x12)

    sub     x23, x3, x9          # SUB
    sw      x23, 76(x12)

    slt     x24, x3, x9          # SLT
    sw      x24, 80(x12)

    sltu    x25, x3, x9          # SLTU
    sw      x25, 84(x12)

    and     x26, x3, x9          # AND
    sw      x26, 88(x12)

    xor     x27, x3, x9          # XOR
    sw      x27, 92(x12)

    or      x28, x3, x9          # OR
    sw      x28, 96(x12)

    ########################################
    # SLL/SRL/SRA
    ########################################
    sll     x29, x3, x4          # SLL
    sw      x29, 100(x12)

    srl     x30, x3, x4          # SRL
    sw      x30, 104(x12)

    sra     x31, x3, x4          # SRA
    sw      x31, 108(x12)


    jalr    x21, x20, 0          # JALR
    ########################################
    # 
    ########################################
end:
    jal x0, end
