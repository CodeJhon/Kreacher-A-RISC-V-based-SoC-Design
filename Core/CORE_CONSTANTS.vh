    // Execution Unit constants
    `ifndef EXEC_CONSTANTS_VH
    `define EXEC_CONSTANTS_VH

    // ---- OPCODE CONSTANTS ----
    `define SHIFT_ARITHMETIC_I 7'b0010011 
    `define LUI 7'b0110111
    `define AUIPC 7'b0010111
    `define SHIFT_ARITHMETIC 7'b0110011

    `define JAL 7'b1101111
    `define JALR 7'b1100111

    `define LOAD  7'b0000011

    // ---- func3 ----SHIFT_ARITHMETIC
    `define ARITHMETIC 3'b000
    `define SLL 3'b001
    `define SLT 3'b010
    `define SLTU 3'b011
    `define XOR  3'b100
    `define SHIFT 3'b101
    `define OR 3'b110
    `define AND 3'b111

    // ---- func3 ----LOAD
    `define LB 3'h000
    `define LH 3'h001
    `define LW 3'h010
    `define LBU 3'h100
    `define LHU 3'h101

    // ---- func3 ----STORE
    `define SW 3'h010
    `define SH 3'h001
    `define SB 3'h000

    // ---- func7 ---- SHIFT_ARITHMETIC-SHIFT
    `define SRL 7'b0000000 
    `define SRA 7'b0100000

    // ---- func7 ---- SHIFT_ARITHMETIC - ARITHMETIC
    `define ADD 7'b0000000 
    `define SUB 7'b0100000

    // ---- func3 ----SHIFT_ARITHMETIC_I
    `define ADDI 3'b000
    `define SLLI 3'b001
    `define SLTI 3'b010
    `define SLTIU 3'b011
    `define ANDI 3'b100
    `define SRLI_SRAI 3'b101
    `define XORI 3'b110
    `define  ORI 3'b111 

    // ---- func7 ----


    // ---- ALU CONSTANTS ----
    `define ALU_ADD         5'b00000
    `define ALU_SUB         5'b00001
    `define ALU_SLT         5'b00010
    `define ALU_SLTU        5'b00011
    `define ALU_AND         5'b00100
    `define ALU_OR          5'b00101
    `define ALU_XOR         5'b00110
    `define ALU_SLL         5'b00111
    `define ALU_SRL         5'b01000
    `define ALU_SRA         5'b01001
    `define ALU_FORWARD_B   5'b01010

    // --- CONTROL CONSTANTS ----

    //sel_next_pc
    `define NEXT_PC_4         2'b00
    `define NEXT_PC_ALU_OUT   2'b01

    //sel_opa
    `define OPA_PC      2'b00
    `define OPA_RS1     2'b01

    //sel_opb
    `define OPB_IMM     2'b00
    `define OPB_RS2     2'b01

    //sel_writeback
    `define WBACK_ALU_OUT    3'b000
    `define WBACK_PC_4       3'b001
    `define WBACK_EMDB       3'b010
    `define WBACK_NONE       3'b100

    //val_rd_type, val_wr_type (mem stage)
    `define FORWARD_INPUT   3'b000
    `define SIGN_EXTEND_16  3'b001
    `define SIGN_EXTEND_8   3'b010
    `define ZERO_EXTEND_16  3'b011
    `define ZERO_EXTEND_8   3'b100
    `define MEM_NOT_USED    3'b101

    //imm_type
    `define I_IMMEDIATE 3'b000
    `define S_IMMEDIATE 3'b001
    `define B_IMMEDIATE 3'b010
    `define U_IMMEDIATE 3'b011
    `define J_IMMEDIATE 3'b100
    `define IMM_NOT_USED 3'b101

    `define ENABLE 1'b1
    `define DISABLE 1'b0

    //------------------    HCU signals
    
    //HCU_sel_RS1 and HCU_sel_RS2
    `define HCU_NO_BYPASS          2'b00
    `define HCU_BYPASS_MEM         2'b01
    `define HCU_BYPASS_WB          2'b10


    `endif
