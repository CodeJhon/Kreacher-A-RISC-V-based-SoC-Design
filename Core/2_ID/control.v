`include "../CORE_CONSTANTS.vh"

module control(
    //-------------------------- Inputs
    input [6:0] opcode,
    input       imm_I_10,
    input [2:0] funct3,
    input [6:0] funct7,
    
    //-------------------------- Control signals generated
    //IF
    output reg [1:0] sel_next_pc,

    //ID
    output       reg regfile_we,
    output reg [2:0] imm_type,

    //EX
    output reg [1:0] sel_opa,
    output reg [1:0] sel_opb,
    output reg  [4:0] sel_op,

    //MEM
    output  reg mem_wr_en,
    output  reg [2:0] val_wr_type,
    output  reg [2:0] val_rd_type,

    //WB
    output reg [2:0] sel_writeback
);
always@(opcode or imm_I_10 or funct3 or funct7)begin //combinational circuit
    sel_next_pc = `NEXT_PC_4;
    regfile_we = `ENABLE;
    imm_type = `IMM_NOT_USED;
    sel_opa = `OPA_RS1;
    sel_opb = `OPB_IMM;
    sel_op = `ALU_ADD;
    mem_wr_en = `DISABLE;
    val_wr_type = `MEM_NOT_USED;
    val_rd_type = `MEM_NOT_USED;
    sel_writeback = `WBACK_ALU_OUT;
    case(opcode)
        `SHIFT_ARITHMETIC_I:begin
            case(funct3)
                `ADDI:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
                `SLTI:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_SLT;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
                `SLTIU: begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op =`ALU_SLTU;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
                `ANDI:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_AND;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
                `XORI:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_XOR;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
                `ORI:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_OR;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
                `SLLI:begin//check
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_SLL;                                                               
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
                `SRLI_SRAI:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = imm_I_10? `ALU_SRA : `ALU_SRL;//check                                                             
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
                default:begin//can be same as NOP operation for now
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `IMM_NOT_USED;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
            endcase
        end

        `LUI: begin
            sel_next_pc = `NEXT_PC_4;
            regfile_we = `ENABLE;
            imm_type = `U_IMMEDIATE;
            sel_opa = `OPA_RS1;//check opa is not needed as we are using `ALU_FORWARD_B
            sel_opb = `OPB_IMM;
            sel_op = `ALU_FORWARD_B;
            mem_wr_en = `DISABLE;
            val_wr_type = `MEM_NOT_USED;
            val_rd_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_ALU_OUT;  
        end

        `AUIPC:begin
            sel_next_pc = `NEXT_PC_4;
            regfile_we = `ENABLE;
            imm_type = `U_IMMEDIATE;
            sel_opa = `OPA_PC;
            sel_opb = `OPB_IMM;
            sel_op =  `ALU_ADD;
            mem_wr_en = `DISABLE;
            val_wr_type = `MEM_NOT_USED;
            val_rd_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_ALU_OUT;  
        end

        `SHIFT_ARITHMETIC:begin
            case(funct3)
                `AND:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `IMM_NOT_USED;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_RS2;
                    sel_op = `ALU_AND;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;  
                end
                `OR:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `IMM_NOT_USED;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_RS2;
                    sel_op = `ALU_OR;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;  
                end
                `SHIFT:begin
                    case(funct7)
                        `SRA:begin
                            sel_next_pc = `NEXT_PC_4;
                            regfile_we = `ENABLE;
                            imm_type = `IMM_NOT_USED;
                            sel_opa = `OPA_RS1;
                            sel_opb = `OPB_RS2;
                            sel_op = `ALU_SRA;
                            mem_wr_en = `DISABLE;
                            val_wr_type = `MEM_NOT_USED;
                            val_rd_type = `MEM_NOT_USED;
                            sel_writeback = `WBACK_ALU_OUT;
                        end
                        `SRL:begin
                            sel_next_pc = `NEXT_PC_4;
                            regfile_we = `ENABLE;
                            imm_type = `IMM_NOT_USED;
                            sel_opa = `OPA_RS1;
                            sel_opb = `OPB_RS2;
                            sel_op = `ALU_SRL;
                            mem_wr_en = `DISABLE;
                            val_wr_type = `MEM_NOT_USED;
                            val_rd_type = `MEM_NOT_USED;
                            sel_writeback = `WBACK_ALU_OUT;
                        end
                        default:begin//can be same as NOP operation for now
                            sel_next_pc = `NEXT_PC_4;
                            regfile_we = `ENABLE;
                            imm_type = `IMM_NOT_USED;
                            sel_opa = `OPA_RS1;
                            sel_opb = `OPB_IMM;
                            sel_op = `ALU_ADD;
                            mem_wr_en = `DISABLE;
                            val_wr_type = `MEM_NOT_USED;
                            val_rd_type = `MEM_NOT_USED;
                            sel_writeback = `WBACK_ALU_OUT;
                        end
                    endcase
                end
                `XOR:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `IMM_NOT_USED;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_RS2;
                    sel_op = `ALU_XOR;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;  
                end
                `SLTU:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `IMM_NOT_USED;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_RS2;
                    sel_op = `ALU_SLTU;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;  
                end
                 `SLT:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `IMM_NOT_USED;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_RS2;
                    sel_op = `ALU_SLT;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;  
                end
                `SLL:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `IMM_NOT_USED;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_RS2;
                    sel_op = `ALU_SLL;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;  
                end
                `ARITHMETIC:begin
                    case(funct7)
                        `ADD:begin
                            sel_next_pc = `NEXT_PC_4;
                            regfile_we = `ENABLE;
                            imm_type = `IMM_NOT_USED;
                            sel_opa = `OPA_RS1;
                            sel_opb = `OPB_RS2;
                            sel_op = `ALU_ADD;
                            mem_wr_en = `DISABLE;
                            val_wr_type = `MEM_NOT_USED;
                            val_rd_type = `MEM_NOT_USED;
                            sel_writeback = `WBACK_ALU_OUT;  
                        end

                        `SUB:begin
                            sel_next_pc = `NEXT_PC_4;
                            regfile_we = `ENABLE;
                            imm_type = `IMM_NOT_USED;
                            sel_opa = `OPA_RS1;
                            sel_opb = `OPB_RS2;
                            sel_op = `ALU_SUB;
                            mem_wr_en = `DISABLE;
                            val_wr_type = `MEM_NOT_USED;
                            val_rd_type = `MEM_NOT_USED;
                            sel_writeback = `WBACK_ALU_OUT;  
                        end
                        default:begin//can be same as NOP operation for now
                            sel_next_pc = `NEXT_PC_4;
                            regfile_we = `ENABLE;
                            imm_type = `IMM_NOT_USED;
                            sel_opa = `OPA_RS1;
                            sel_opb = `OPB_IMM;
                            sel_op = `ALU_ADD;
                            mem_wr_en = `DISABLE;
                            val_wr_type = `MEM_NOT_USED;
                            val_rd_type = `MEM_NOT_USED;
                            sel_writeback = `WBACK_ALU_OUT;
                        end
                    endcase
                end
                default:begin//can be same as NOP operation for now
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `IMM_NOT_USED;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
            endcase
        end

        `JAL:begin
            sel_next_pc = `NEXT_PC_ALU_OUT;
            regfile_we = `ENABLE;
            imm_type = `J_IMMEDIATE;
            sel_opa = `OPA_PC;
            sel_opb = `OPB_IMM;
            sel_op = `ALU_ADD;
            mem_wr_en = `DISABLE;
            val_wr_type = `MEM_NOT_USED;
            val_rd_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_PC_4;
        end

        `JALR:begin
            sel_next_pc = `NEXT_PC_ALU_OUT;
            regfile_we = `ENABLE;
            imm_type = `I_IMMEDIATE;
            sel_opa = `OPA_RS1;
            sel_opb = `OPB_IMM;
            sel_op = `ALU_ADD;
            mem_wr_en = `DISABLE;
            val_wr_type = `MEM_NOT_USED;
            val_rd_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_PC_4;
        end
        `LOAD:begin
            case(funct3)
                `LW:begin
                    sel_next_pc =  `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `FORWARD_INPUT;
                    sel_writeback = `WBACK_EMDB;
                end

                `LH:begin
                    sel_next_pc =  `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `SIGN_EXTEND_16;
                    sel_writeback = `WBACK_EMDB;
                end

                `LHU:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type =  `ZERO_EXTEND_16;
                    sel_writeback = `WBACK_EMDB;
                end

                `LB:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `SIGN_EXTEND_8;
                    sel_writeback = `WBACK_EMDB;
                end

                `LBU:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `ZERO_EXTEND_8;
                    sel_writeback = `WBACK_EMDB;
                end
                default:begin//can be same as NOP operation for now
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `IMM_NOT_USED;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
            endcase
        end
        
        `STORE:begin
            case(funct3)
                `SW:begin
                    sel_next_pc =  `NEXT_PC_4;
                    regfile_we =  `DISABLE;
                    imm_type = `S_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `ENABLE;
                    val_wr_type = `FORWARD_INPUT;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_NONE;
                end

                `SH:begin
                    sel_next_pc =  `NEXT_PC_4;
                    regfile_we =  `DISABLE;
                    imm_type = `S_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `ENABLE;
                    val_wr_type =`SIGN_EXTEND_16;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_NONE;
                end

                `SB:begin
                    sel_next_pc =  `NEXT_PC_4;
                    regfile_we =  `DISABLE;
                    imm_type = `S_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `ENABLE;
                    val_wr_type = `SIGN_EXTEND_8;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_NONE;
                end
                default:begin//can be same as NOP operation for now
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `IMM_NOT_USED;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = `ALU_ADD;
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                end
            endcase
        end
        

        default:begin//can be same as NOP operation for now
            sel_next_pc = `NEXT_PC_4;
            regfile_we = `ENABLE;
            imm_type = `IMM_NOT_USED;
            sel_opa = `OPA_RS1;
            sel_opb = `OPB_IMM;
            sel_op = `ALU_ADD;
            mem_wr_en = `DISABLE;
            val_wr_type = `MEM_NOT_USED;
            val_rd_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_ALU_OUT;
        end
    endcase
end
endmodule