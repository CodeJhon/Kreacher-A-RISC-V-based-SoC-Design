    // Execution Unit constants
    `ifndef CORE_CONSTANTS_VH
    `define CORE_CONSTANTS_VH
    // PC STARTING POINT
    `define PC_BASE_ADDRESS 32'h80000000
    
    // ---- OPCODE CONSTANTS ----
        //Instructions with shared opcode
    `define INT_REG_REG   7'b0110011
    `define INT_REG_REG_W 7'b0111011
    `define INT_REG_IMM   7'b0010011 
    `define INT_REG_IMM_W 7'b0011011
    `define LOAD          7'b0000011
    `define STORE         7'b0100011
    `define BRANCH        7'b1100011
        //Instructions without shared opcode
    `define LUI           7'b0110111
    `define AUIPC         7'b0010111
    `define JAL           7'b1101111
    `define JALR          7'b1100111

    // ---- func3 ---- INT_REG_REG
    `define ARITHMETIC 3'b000
    `define SLL 3'b001
    `define SLT 3'b010
    `define SLTU 3'b011
    `define XOR  3'b100
    `define SHIFT 3'b101
    `define OR 3'b110
    `define AND 3'b111

    // ---- func3 ----LOAD
    `define LB  3'b000
    `define LH  3'b001
    `define LW  3'b010
    `define LBU 3'b100
    `define LHU 3'b101
    
    `define LWU 3'b110
    `define LD  3'b011

    // ---- func3 ----STORE
    `define SB 3'b000
    `define SH 3'b001
    `define SW 3'b010
    `define SD 3'b011

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
    `define ANDI 3'b111
    `define SRLI_SRAI 3'b101
    `define XORI 3'b100
    `define  ORI 3'b110 

    // ---- func3 ---- BRANCH
    `define BEQ  3'b000
    `define BNE  3'b001
    `define BLT  3'b100
    `define BGE  3'b101
    `define BLTU 3'b110
    `define BGEU 3'b111

    // ---- ALU CONSTANTS ----
    `define ALU_ADD         5'b00000
    `define ALU_SUB         5'b00001
    `define ALU_SLT         5'b00010
    `define ALU_SLTU        5'b00011
    `define ALU_AND         5'b00100
    `define ALU_OR          5'b00101
    `define ALU_XOR         5'b00110

    `define ALU_SLL         5'b00111
    `define ALU_SLLW        5'b01000
    `define ALU_SRL         5'b01001
    `define ALU_SRLW        5'b01010
    `define ALU_SRA         5'b01011
    `define ALU_SRAW        5'b01100

    `define ALU_FORWARD_B   5'b01101
    `define ALU_EQ          5'b01110
    `define ALU_NE          5'b01111
    `define ALU_LT          5'b10000
    `define ALU_GE          5'b10001
    `define ALU_LTU         5'b10010
    `define ALU_GEU         5'b10011

    // --- CONTROL CONSTANTS ----
    //Global (for 1 bit signals)
    `define ENABLE 1'b1
    `define DISABLE 1'b0

    //sel_exec_result
    `define exec_result_ALU             1'b0
    `define exec_result_PC_plus_imm     1'b1

    //sel_opb
    `define OPB_IMM     2'b00
    `define OPB_RS2     2'b01

    //sel_writeback
    `define WBACK_EXEC_RESULT    3'b000
    `define WBACK_PC_4           3'b001
    `define WBACK_EMDB           3'b010
    `define WBACK_NONE           3'b100

    //val_rd_type, val_wr_type (mem stage)
    `define FORWARD_INPUT   3'b000
    `define SIGN_EXTEND_32  3'b001
    `define SIGN_EXTEND_16  3'b010
    `define SIGN_EXTEND_8   3'b011
    
    `define ZERO_EXTEND_32  3'b100
    `define ZERO_EXTEND_16  3'b101
    `define ZERO_EXTEND_8   3'b110
    `define MEM_NOT_USED    3'b111

    //imm_type
    `define I_IMMEDIATE 3'b000
    `define S_IMMEDIATE 3'b001
    `define B_IMMEDIATE 3'b010
    `define U_IMMEDIATE 3'b011
    `define J_IMMEDIATE 3'b100
    `define IMM_NOT_USED 3'b101

    //result_type
    `define RESULT_64   1'b0
    `define RESULT_32   1'b1

    //------------------    HCU signals
    
    //HCU_sel_RS1 and HCU_sel_RS2
    `define HCU_NO_BYPASS          2'b00
    `define HCU_BYPASS_MEM         2'b01
    `define HCU_BYPASS_WB          2'b10


    `endif
