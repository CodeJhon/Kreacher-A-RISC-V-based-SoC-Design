`include "../../include/CORE_CONSTANTS.vh"

module control #(parameter XLEN = 64)(
    //Global
    input pause,

    //-------------------------- Inputs
    input [31:0]     canonical_instruction,
    
    //-------------------------- Control signals generated
    //Flags
    output reg       valid_data_read,
    output reg       valid_data_write,

    //Illegal Instruction
    output            illegal_instr,

    //ID
    output reg [2:0]  imm_type,
    output reg        csr_re,
    output reg        read_mepc,

    //EX
    output reg        jump,
    output reg        branch,
    output reg        restore_mstatus,

    output reg [1:0]  sel_opa,
    output reg [1:0]  sel_opb,
    output reg [5:0]  sel_op,
    output       reg  regfile_we,

    output reg        sel_exec_result,

    output reg        csr_we,

    //MEM
    output  reg       mem_wr_en,
    output  reg [2:0] val_wr_type,
    output  reg [2:0] val_rd_type,
    output  reg       result_type,
    output  reg       sleep,

    //WB
    output reg [2:0] sel_writeback
);

//Internal signals
wire [6:0] opcode        = canonical_instruction[6:0];
wire       imm_I_10      = canonical_instruction[30];
wire [2:0] funct3        = canonical_instruction[14:12];
wire [6:0] funct7        = canonical_instruction[31:25];
wire [4:0] RD_addr       = canonical_instruction[11:7];
wire [4:0] uimm_RS1_addr = canonical_instruction[19:15];

wire [11:0] csr_addr     = canonical_instruction[31:20];

//Internal control
reg is_privileged;

//Internal reasons of an Illegal instr
reg invalid_opcode;
reg invalid_alu_op;
reg invalid_mem_op;
reg invalid_branch_op;
reg invalid_csr_op;
reg invalid_csr_read;
reg invalid_csr_write;

assign illegal_instr =  ~pause & (
                        invalid_opcode    | 
                        invalid_alu_op    |
                        invalid_mem_op    |
                        invalid_branch_op |
                        invalid_csr_op    |
                        invalid_csr_read  | 
                        invalid_csr_write);


always@( * )begin
    is_privileged      = 1'b0;

    // Default internal reasons of Illegal instr
    invalid_opcode     = 1'b0;
    invalid_alu_op     = 1'b0;
    invalid_mem_op     = 1'b0;
    invalid_branch_op  = 1'b0;
    invalid_csr_op     = 1'b0;
    invalid_csr_read   = 1'b0;
    invalid_csr_write  = 1'b0;

    //Default control - disable everything
    jump = `DISABLE;
    branch  = `DISABLE;
    regfile_we = `DISABLE;
    imm_type = `IMM_NOT_USED;
    sel_exec_result = `exec_result_ALU;
    sel_opb = `OPB_IMM;
    sel_opa = `OPA_RS1;
    sel_op = `ALU_ADD;
    mem_wr_en = `DISABLE;
    val_wr_type = `MEM_NOT_USED;
    val_rd_type = `MEM_NOT_USED;
    sel_writeback = `WBACK_NONE;
    result_type = `RESULT_64;
    
    valid_data_read = `DISABLE;
    valid_data_write = `DISABLE;
    
    csr_we = `DISABLE;
    csr_re = `DISABLE;

    restore_mstatus = `DISABLE;
    read_mepc       = `DISABLE;

    sleep           = `DISABLE;

    //--------------------Privileged instructions-----------------
    case (canonical_instruction)
        `MRET:begin
            is_privileged = 1'b1;

            read_mepc       = `ENABLE;
            sel_opa         = `OPA_CSR;
            sel_op          = `ALU_FORWARD_A;

            restore_mstatus = `ENABLE;
            jump            = `ENABLE;
        end
        `WFI:begin
            is_privileged = 1'b1;

            sleep           = `ENABLE;
        end
    endcase

    //--------------------Unprivileged instructions------------------
    if(!is_privileged)begin
        case(opcode)
            //Instructions with shared opcode

            `INT_REG_REG:begin
                jump = `DISABLE;
                branch  = `DISABLE;
                regfile_we = `ENABLE;
                imm_type = `IMM_NOT_USED;
                sel_exec_result = `exec_result_ALU;
                sel_opa = `OPA_RS1;
                sel_opb = `OPB_RS2;
                mem_wr_en = `DISABLE;
                val_wr_type = `MEM_NOT_USED;
                val_rd_type = `MEM_NOT_USED;
                sel_writeback = `WBACK_EXEC_RESULT;
                result_type = `RESULT_64;
                
                //Multiply/Div Instructions
                if(funct7[0])begin
                    case (funct3)
                        `AND_REMU:           sel_op = `ALU_REMU;
                        `OR_REM:             sel_op = `ALU_REM;
                        `XOR_DIV:            sel_op = `ALU_DIV;
                        `SLTU_MULHU:         sel_op = `ALU_MULHU;
                        `SLT_MULHSU:         sel_op = `ALU_MULHSU;
                        `SLL_MULH:           sel_op = `ALU_MULH;
                        `SHIFT_RIGHT_DIVU:   sel_op = `ALU_DIVU;
                        `ADD_SUB_MUL:        sel_op = `ALU_MUL;
                    endcase
                end
                
                //Arithmetic Instructions
                else begin
                    case (funct3)
                        `AND_REMU:            sel_op = `ALU_AND;
                        `OR_REM:              sel_op = `ALU_OR;
                        `XOR_DIV:             sel_op = `ALU_XOR;
                        `SLTU_MULHU:          sel_op = `ALU_SLTU;
                        `SLT_MULHSU:          sel_op = `ALU_SLT;
                        `SLL_MULH:            sel_op = `ALU_SLL;
                        `SHIFT_RIGHT_DIVU:begin
                            if(funct7[5])
                                              sel_op = `ALU_SRA;
                            else
                                              sel_op = `ALU_SRL;
                        end
                        `ADD_SUB_MUL:begin
                            if(funct7[5])
                                              sel_op = `ALU_SUB;
                            else
                                              sel_op = `ALU_ADD;
                        end
                    endcase
                end
            end

            `INT_REG_REG_W:begin
                jump = `DISABLE;
                branch  = `DISABLE;
                regfile_we = `ENABLE;
                imm_type = `IMM_NOT_USED;
                sel_exec_result = `exec_result_ALU;
                sel_opa = `OPA_RS1;
                sel_opb = `OPB_RS2;
                mem_wr_en = `DISABLE;
                val_wr_type = `MEM_NOT_USED;
                val_rd_type = `MEM_NOT_USED;
                sel_writeback = `WBACK_EXEC_RESULT;
                result_type = `RESULT_32;

                //Multiply/Div Instructions
                if(funct7[0])begin
                    case (funct3)
                        `SHIFT_RIGHT_DIVU:      sel_op = `ALU_DIVUW;
                        `ADD_SUB_MUL:           sel_op = `ALU_MULW;
                        `XOR_DIV:               sel_op = `ALU_DIVW;
                        `OR_REM:                sel_op = `ALU_REMW;
                        `AND_REMU:              sel_op = `ALU_REMUW;
                        default:
                            invalid_alu_op = 1'b1;
                    endcase
                end

                //Arithmetic Instructions
                else begin
                    case (funct3)
                        `SLL_MULH:          sel_op = `ALU_SLLW;
                        `SHIFT_RIGHT_DIVU:begin
                            if(funct7[5])
                                            sel_op = `ALU_SRAW;
                            else
                                            sel_op = `ALU_SRLW;
                        end
                        `ADD_SUB_MUL:begin
                            if(funct7[5])
                                            sel_op = `ALU_SUB;
                            else
                                            sel_op = `ALU_ADD;
                        end
                        default:
                            invalid_alu_op = 1'b1;
                    endcase
                end
                
            end

            `INT_REG_IMM:begin
                jump = `DISABLE;
                branch  = `DISABLE;
                regfile_we = `ENABLE;
                imm_type = `I_IMMEDIATE;
                sel_exec_result = `exec_result_ALU;
                sel_opa = `OPA_RS1;
                sel_opb = `OPB_IMM;
                mem_wr_en = `DISABLE;
                val_wr_type = `MEM_NOT_USED;
                val_rd_type = `MEM_NOT_USED;
                sel_writeback = `WBACK_EXEC_RESULT;
                result_type = `RESULT_64;
                case(funct3)
                    `ADDI:      sel_op = `ALU_ADD;
                    `SLTI:      sel_op = `ALU_SLT;
                    `SLTIU:     sel_op = `ALU_SLTU;
                    `ANDI:      sel_op = `ALU_AND;
                    `XORI:      sel_op = `ALU_XOR;
                    `ORI:       sel_op = `ALU_OR;
                    `SLLI:      sel_op = `ALU_SLL;
                    `SRLI_SRAI: sel_op = imm_I_10 ? `ALU_SRA : `ALU_SRL;
                endcase
            end

            `INT_REG_IMM_W:begin
                jump = `DISABLE;
                branch  = `DISABLE;
                regfile_we = `ENABLE;
                imm_type = `I_IMMEDIATE;
                sel_exec_result = `exec_result_ALU;
                sel_opa = `OPA_RS1;
                sel_opb = `OPB_IMM;
                mem_wr_en = `DISABLE;
                val_wr_type = `MEM_NOT_USED;
                val_rd_type = `MEM_NOT_USED;
                sel_writeback = `WBACK_EXEC_RESULT;
                result_type = `RESULT_32;
                case(funct3)
                    `ADDI:      sel_op = `ALU_ADD;
                    `SLLI:      sel_op = `ALU_SLLW;
                    `SRLI_SRAI: sel_op = imm_I_10 ? `ALU_SRAW : `ALU_SRLW;
                    default:
                        invalid_alu_op = 1'b1;
                endcase
            end

            `LOAD:begin
                jump = `DISABLE;
                branch  = `DISABLE;
                regfile_we = `ENABLE;
                imm_type = `I_IMMEDIATE;
                sel_exec_result = `exec_result_ALU;
                sel_opa = `OPA_RS1;
                sel_opb = `OPB_IMM;
                sel_op = `ALU_ADD;
                mem_wr_en = `DISABLE;
                val_wr_type = `MEM_NOT_USED;
                sel_writeback = `WBACK_EMDB;
                result_type = `RESULT_64;
                valid_data_read = `ENABLE;
                case(funct3)
                    `LD:  val_rd_type = `FORWARD_INPUT;
                    `LW:  val_rd_type = `SIGN_EXTEND_32;
                    `LWU: val_rd_type = `ZERO_EXTEND_32;
                    `LH:  val_rd_type = `SIGN_EXTEND_16;
                    `LHU: val_rd_type = `ZERO_EXTEND_16;
                    `LB:  val_rd_type = `SIGN_EXTEND_8;
                    `LBU: val_rd_type = `ZERO_EXTEND_8;
                    default:
                        invalid_mem_op = 1'b1;
                endcase
            end
            
            `STORE:begin
                jump = `DISABLE;
                branch  = `DISABLE;
                regfile_we =  `DISABLE;
                imm_type = `S_IMMEDIATE;
                sel_exec_result = `exec_result_ALU;
                sel_opa = `OPA_RS1;
                sel_opb = `OPB_IMM;
                sel_op = `ALU_ADD;
                mem_wr_en = `ENABLE;
                val_rd_type = `MEM_NOT_USED;
                sel_writeback = `WBACK_NONE;
                result_type = `RESULT_64;
                valid_data_write = `ENABLE;
                case(funct3)
                    `SD: val_wr_type = `FORWARD_INPUT;
                    `SW: val_wr_type = `ZERO_EXTEND_32;
                    `SH: val_wr_type = `ZERO_EXTEND_16;
                    `SB: val_wr_type = `ZERO_EXTEND_8;
                    default:
                        invalid_mem_op = 1'b1;
                endcase
            end
            
            `BRANCH:begin
                jump = `DISABLE;
                branch  = `ENABLE;
                regfile_we = `DISABLE;
                imm_type = `B_IMMEDIATE;
                sel_exec_result = `exec_result_PC_plus_imm;
                sel_opa = `OPA_RS1;
                sel_opb = `OPB_RS2;
                mem_wr_en = `DISABLE;
                val_wr_type = `MEM_NOT_USED;
                val_rd_type = `MEM_NOT_USED;
                sel_writeback = `WBACK_NONE;
                result_type = `RESULT_64;
                case (funct3)
                    `BEQ:  sel_op = `ALU_EQ;
                    `BNE:  sel_op = `ALU_NE;
                    `BLT:  sel_op = `ALU_LT;
                    `BGE:  sel_op = `ALU_GE;
                    `BLTU: sel_op = `ALU_LTU;
                    `BGEU: sel_op = `ALU_GEU;
                    default:
                        invalid_mem_op = 1'b1;
                endcase
            end

            `ZICSR:begin
                jump = `DISABLE;
                branch  = `DISABLE;
                imm_type = `ZICSR_IMMEDIATE;
                sel_exec_result = `exec_result_ALU;
                sel_opa = `OPA_CSR;
                mem_wr_en = `DISABLE;
                val_wr_type = `MEM_NOT_USED;
                val_rd_type = `MEM_NOT_USED;
                sel_writeback = `WBACK_CSR;
                result_type = `RESULT_64;

                //CSR Read-enable / Write-Enable logic
                case (funct3)
                    `CSRRW: begin
                        sel_opb = `OPB_RS1;
                        sel_op = `ALU_FORWARD_B;
                        
                        //-----------------Writing/Reading
                        //CSR write
                        csr_we = `ENABLE;

                        //CSR read -> Regfile write
                        if(RD_addr != 5'd0)begin
                            csr_re     = `ENABLE;
                            regfile_we = `ENABLE;
                        end 
                        else begin
                            csr_re     = `DISABLE;
                            regfile_we = `DISABLE;
                        end
                    end
                    `CSRRS: begin
                        sel_opb = `OPB_RS1;
                        sel_op = `ALU_OR;
                        
                        //-----------------Writing/Reading
                        //CSR write
                        if(uimm_RS1_addr != 5'd0) csr_we = `ENABLE;
                        else              csr_we = `DISABLE;
                        
                        //CSR read -> Regfile write
                        csr_re     = `ENABLE;
                        regfile_we = `ENABLE;
                    end
                    `CSRRC: begin
                        sel_opb = `OPB_RS1;
                        sel_op = `ALU_CSRRC;
                        
                        //-----------------Writing/Reading
                        //CSR write
                        if(uimm_RS1_addr != 5'd0) csr_we = `ENABLE;
                        else              csr_we = `DISABLE;
                        
                        //CSR read -> Regfile write
                        csr_re     = `ENABLE;
                        regfile_we = `ENABLE;
                    end

                    `CSRRWI: begin
                        sel_opb = `OPB_IMM;
                        sel_op = `ALU_FORWARD_B;
                        
                        //-----------------Writing/Reading
                        //CSR write
                        csr_we = `ENABLE;

                        //CSR read -> Regfile write
                        if(RD_addr != 5'd0)begin
                            csr_re     = `ENABLE;
                            regfile_we = `ENABLE;
                        end 
                        else begin
                            csr_re     = `DISABLE;
                            regfile_we = `DISABLE;
                        end
                    end
                    `CSRRSI: begin
                        sel_opb = `OPB_IMM;
                        sel_op = `ALU_OR;
                        
                        //-----------------Writing/Reading
                        //CSR write
                        if(uimm_RS1_addr != 5'd0) csr_we = `ENABLE;
                        else              csr_we = `DISABLE;
                        
                        //CSR read -> Regfile write
                        csr_re     = `ENABLE;
                        regfile_we = `ENABLE;
                    end
                    `CSRRCI: begin
                        sel_opb = `OPB_IMM;
                        sel_op = `ALU_CSRRC;
                        
                        //-----------------Writing/Reading
                        //CSR write
                        if(uimm_RS1_addr != 5'd0) csr_we = `ENABLE;
                        else              csr_we = `DISABLE;
                        
                        //CSR read -> Regfile write
                        csr_re     = `ENABLE;
                        regfile_we = `ENABLE;
                    end
                    default:
                        invalid_csr_op = 1'b1;
                endcase

                //Checking for legal reads (Only supported CSRs)
                if(csr_re)begin
                    case (csr_addr)
                        //Legal
                        `MSTATUS_ADDR, `MISA_ADDR, `MTVEC_ADDR, `MEPC_ADDR, `MCAUSE_ADDR:
                            invalid_csr_read = 1'b0;
                        //Illegal
                        default: 
                            invalid_csr_read = 1'b1;
                    endcase
                end

                //Checking for legal writes (Only Read/Write CSRs, not Read-Only)
                if(csr_we)begin
                    case (csr_addr)
                        //Legal
                        `MSTATUS_ADDR, `MEPC_ADDR, `MCAUSE_ADDR:
                            invalid_csr_read = 1'b0;
                        //Illegal
                        default: 
                            invalid_csr_write = 1'b1;
                    endcase
                end
            end

            //Instructions without shared opcode

            `LUI: begin
                jump = `DISABLE;
                branch  = `DISABLE;
                regfile_we = `ENABLE;
                imm_type = `U_IMMEDIATE;
                sel_exec_result = `exec_result_ALU;
                sel_opa = `OPA_RS1;
                sel_opb = `OPB_IMM;
                sel_op = `ALU_FORWARD_B;
                mem_wr_en = `DISABLE;
                val_wr_type = `MEM_NOT_USED;
                val_rd_type = `MEM_NOT_USED;
                sel_writeback = `WBACK_EXEC_RESULT;
                result_type = `RESULT_64;  
            end
            
            `AUIPC:begin
                jump = `DISABLE;
                branch  = `DISABLE;
                regfile_we = `ENABLE;
                imm_type = `U_IMMEDIATE;
                sel_exec_result = `exec_result_PC_plus_imm;
                sel_opa = `OPA_RS1;
                sel_opb = `OPB_IMM;
                sel_op =  `ALU_ADD;
                mem_wr_en = `DISABLE;
                val_wr_type = `MEM_NOT_USED;
                val_rd_type = `MEM_NOT_USED;
                sel_writeback = `WBACK_EXEC_RESULT;
                result_type = `RESULT_64;  
            end

            `JAL:begin
                jump = `ENABLE;
                branch  = `DISABLE;
                regfile_we = `ENABLE;
                imm_type = `J_IMMEDIATE;
                sel_exec_result = `exec_result_PC_plus_imm;
                sel_opa = `OPA_RS1;
                sel_opb = `OPB_IMM;
                sel_op = `ALU_ADD;
                mem_wr_en = `DISABLE;
                val_wr_type = `MEM_NOT_USED;
                val_rd_type = `MEM_NOT_USED;
                sel_writeback = `WBACK_PC_step;
                result_type = `RESULT_64;
            end

            `JALR:begin
                if(funct3 == 3'b000)begin
                    jump = `ENABLE;
                    branch  = `DISABLE;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_exec_result = `exec_result_ALU;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_PC_step;
                    result_type = `RESULT_64;
                end
                else
                    invalid_branch_op = 1'b1;
            end
        
            //Invalid Opcode
            default:
                invalid_opcode = 1'b1;

        endcase
    end
end
endmodule