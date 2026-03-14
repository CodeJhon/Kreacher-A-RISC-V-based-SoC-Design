    // Execution Unit constants
    `ifndef CORE_CONSTANTS_VH
    `define CORE_CONSTANTS_VH

    // PC constants
    `define PC_IRQ0    64'h00000000_00000000
    `define PC_IRQ1    64'h00000000_00000004
    `define PC_RESET   64'h00000000_00000008
    `define PC_ILLEGAL 64'h00000000_0000000C

    //---------- Instruction Fetch (IF) stage constants ---------
    //sel_PC_step
    `define PC_STEP_4 1'b0
    `define PC_STEP_2 1'b1
    //instr_type
    `define RVI_INSTR 1'b0
    `define C_INSTR   1'b1

    // ---- PRIVILEGED INSTRUCTIONS | ENCODINGS -----
    `define MRET    32'h30200073
    `define WFI     32'h10500073

    // ---- OPCODE CONSTANTS ----
        //Instructions with shared opcode
    `define INT_REG_REG   7'b0110011
    `define INT_REG_REG_W 7'b0111011
    `define INT_REG_IMM   7'b0010011 
    `define INT_REG_IMM_W 7'b0011011
    `define LOAD          7'b0000011
    `define STORE         7'b0100011
    `define BRANCH        7'b1100011
    `define ZICSR         7'b1110011
        //Instructions without shared opcode
    `define LUI           7'b0110111
    `define AUIPC         7'b0010111
    `define JAL           7'b1101111
    `define JALR          7'b1100111

    // ---- func3 ---- INT_REG_REG
    `define ADD_SUB_MUL       3'b000
    `define SLL_MULH          3'b001
    `define SLT_MULHSU        3'b010
    `define SLTU_MULHU        3'b011
    `define XOR_DIV           3'b100
    `define SHIFT_RIGHT_DIVU  3'b101
    `define OR_REM            3'b110
    `define AND_REMU          3'b111

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

    // ---- func3 ---- ZICSR
    `define CSRRW  3'b001
    `define CSRRS  3'b010
    `define CSRRC  3'b011
    `define CSRRWI 3'b101
    `define CSRRSI 3'b110
    `define CSRRCI 3'b111

    // ---- ALU CONSTANTS ----
    `define ALU_ADD         6'b000000
    `define ALU_ADDW        6'b000001
    `define ALU_SUB         6'b000010
    `define ALU_SUBW        6'b000011
    `define ALU_SLT         6'b000100
    `define ALU_SLTU        6'b000101
    `define ALU_AND         6'b000110
    `define ALU_OR          6'b000111
    `define ALU_XOR         6'b001000

    `define ALU_SLL         6'b001001
    `define ALU_SLLW        6'b001010
    `define ALU_SRL         6'b001011
    `define ALU_SRLW        6'b001100
    `define ALU_SRA         6'b001101
    `define ALU_SRAW        6'b001110

    `define ALU_FORWARD_A   6'b001111
    `define ALU_FORWARD_B   6'b010000
    `define ALU_EQ          6'b010001
    `define ALU_NE          6'b010010
    `define ALU_LT          6'b010011
    `define ALU_GE          6'b010100
    `define ALU_LTU         6'b010101
    `define ALU_GEU         6'b100000

    `define ALU_CSRRC       6'b100001

    `define ALU_MUL         6'b100010
    `define ALU_MULH        6'b100011
    `define ALU_MULHSU      6'b100100
    `define ALU_MULHU       6'b100101
    `define ALU_DIV         6'b100110
    `define ALU_DIVU        6'b100111
    `define ALU_REM         6'b101000
    `define ALU_REMU        6'b101001

    `define ALU_MULW        6'b101010
    `define ALU_DIVW        6'b101011
    `define ALU_DIVUW       6'b101100
    `define ALU_REMW        6'b101101
    `define ALU_REMUW       6'b101110

    // --- CONTROL CONSTANTS ----
    //Global (for 1 bit signals)
    `define ENABLE 1'b1
    `define DISABLE 1'b0

    //sel_exec_result
    `define exec_result_ALU             1'b0
    `define exec_result_PC_plus_imm     1'b1
    
    //sel_opa
    `define OPA_RS1     2'b00
    `define OPA_CSR     2'b01

    //sel_opb
    `define OPB_IMM     2'b00
    `define OPB_RS2     2'b01
    `define OPB_RS1     2'b10

    //sel_writeback
    `define WBACK_EXEC_RESULT    3'b000
    `define WBACK_PC_step        3'b001
    `define WBACK_EMDB           3'b010
    `define WBACK_CSR            3'b011
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
    `define I_IMMEDIATE     3'b000
    `define S_IMMEDIATE     3'b001
    `define B_IMMEDIATE     3'b010
    `define U_IMMEDIATE     3'b011
    `define J_IMMEDIATE     3'b100
    `define ZICSR_IMMEDIATE 3'b101
    `define IMM_NOT_USED    3'b110

    //result_type
    `define RESULT_64   1'b0
    `define RESULT_32   1'b1

    
    //radix_n divider states
    `define S_IDLE 2'b00
    `define S_LOAD 2'b01
    `define S_ITERATE 2'b10
    `define S_DONE 2'b11

    // CSR constants
    
    `define MSTATUS_ADDR 12'h300
    `define MISA_ADDR    12'h301
    `define MTVEC_ADDR   12'h305

    `define MEPC_ADDR    12'h341
    `define MCAUSE_ADDR  12'h342

    // mcause allowed in Kreacher
    `define MCAUSE_IRQ0    64'd0
    `define MCAUSE_IRQ1    64'd1
    `define MCAUSE_ILLEGAL 64'd3

    //------------------    HCU signals
    
    //HCU_sel_RS1 and HCU_sel_RS2
    `define HCU_NO_BYPASS          2'b00
    `define HCU_BYPASS_MEM         2'b01
    `define HCU_BYPASS_WB          2'b10
    

    `endif
