`include "../CORE_CONSTANTS.vh"

module control(
    //-------------------------- Inputs
    input [6:0] opcode,
    input       imm_I_10,
    input [2:0] funct3,
    input [6:0] funct7,
    
    //-------------------------- Control signals generated

    //ID
    output       reg regfile_we,
    output reg [2:0] imm_type,

    //EX
    output reg [1:0] sel_opb,
    output reg  [4:0] sel_op,
    output reg sel_exec_result,
    output reg jump,
    output reg branch,

    //MEM
    output  reg mem_wr_en,
    output  reg [2:0] val_wr_type,
    output  reg [2:0] val_rd_type,

    //WB
    output reg [2:0] sel_writeback
);
always@(opcode or imm_I_10 or funct3 or funct7)begin //combinational circuit
    //Default values - disable everything
    jump = `DISABLE;
    branch  = `DISABLE;
    regfile_we = `DISABLE;
    imm_type = `IMM_NOT_USED;
    sel_exec_result = `exec_result_ALU;
    sel_opb = `OPB_IMM;
    sel_op = `ALU_ADD;
    mem_wr_en = `DISABLE;
    val_wr_type = `MEM_NOT_USED;
    val_rd_type = `MEM_NOT_USED;
    sel_writeback = `WBACK_NONE;
    case(opcode)
        //Instructions with shared opcode

        `INT_REG_REG:begin
            jump = `DISABLE;
            branch  = `DISABLE;
            regfile_we = `ENABLE;
            imm_type = `IMM_NOT_USED;
            sel_exec_result = `exec_result_ALU;
            sel_opb = `OPB_RS2;
            mem_wr_en = `DISABLE;
            val_wr_type = `MEM_NOT_USED;
            val_rd_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_EXEC_RESULT;
            case(funct3)
                `AND:         sel_op = `ALU_AND;
                `OR:          sel_op = `ALU_OR;
                `XOR:         sel_op = `ALU_XOR;
                `SLTU:        sel_op = `ALU_SLTU;
                `SLT:         sel_op = `ALU_SLT;
                `SLL:         sel_op = `ALU_SLL;
                `SHIFT:begin
                    case(funct7)
                        `SRA: sel_op = `ALU_SRA;
                        `SRL: sel_op = `ALU_SRL;
                    endcase
                end
                `ARITHMETIC:begin
                    case(funct7)
                        `ADD: sel_op = `ALU_ADD;
                        `SUB: sel_op = `ALU_SUB;
                    endcase
                end
            endcase
        end

        `INT_REG_IMM:begin
            jump = `DISABLE;
            branch  = `DISABLE;
            regfile_we = `ENABLE;
            imm_type = `I_IMMEDIATE;
            sel_exec_result = `exec_result_ALU;
            sel_opb = `OPB_IMM;
            mem_wr_en = `DISABLE;
            val_wr_type = `MEM_NOT_USED;
            val_rd_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_EXEC_RESULT;
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

        `LOAD:begin
            jump = `DISABLE;
            branch  = `DISABLE;
            regfile_we = `ENABLE;
            imm_type = `I_IMMEDIATE;
            sel_exec_result = `exec_result_ALU;
            sel_opb = `OPB_IMM;
            sel_op = `ALU_ADD;
            mem_wr_en = `DISABLE;
            val_wr_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_EMDB;
            case(funct3)
                `LW:  val_rd_type = `FORWARD_INPUT;
                `LH:  val_rd_type = `SIGN_EXTEND_16;
                `LHU: val_rd_type = `ZERO_EXTEND_16;
                `LB:  val_rd_type = `SIGN_EXTEND_8;
                `LBU: val_rd_type = `ZERO_EXTEND_8;
            endcase
        end
        
        `STORE:begin
            jump = `DISABLE;
            branch  = `DISABLE;
            regfile_we =  `DISABLE;
            imm_type = `S_IMMEDIATE;
            sel_exec_result = `exec_result_ALU;
            sel_opb = `OPB_IMM;
            sel_op = `ALU_ADD;
            mem_wr_en = `ENABLE;
            val_rd_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_NONE;
            case(funct3)
                `SW: val_wr_type = `FORWARD_INPUT;
                `SH: val_wr_type = `SIGN_EXTEND_16;
                `SB: val_wr_type = `SIGN_EXTEND_8;
            endcase
        end
        
        `BRANCH:begin
            jump = `DISABLE;
            branch  = `ENABLE;
            regfile_we = `DISABLE;
            imm_type = `B_IMMEDIATE;
            sel_exec_result = `exec_result_PC_plus_imm;
            sel_opb = `OPB_RS2;
            mem_wr_en = `DISABLE;
            val_wr_type = `MEM_NOT_USED;
            val_rd_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_NONE;
            case (funct3)
                `BEQ:  sel_op = `ALU_EQ;
                `BNE:  sel_op = `ALU_NE;
                `BLT:  sel_op = `ALU_LT;
                `BGE:  sel_op = `ALU_GE;
                `BLTU: sel_op = `ALU_LTU;
                `BGEU: sel_op = `ALU_GEU;
            endcase
        end

        //Instructions without shared opcode

        `LUI: begin
            jump = `DISABLE;
            branch  = `DISABLE;
            regfile_we = `ENABLE;
            imm_type = `U_IMMEDIATE;
            sel_exec_result = `exec_result_ALU;
            sel_opb = `OPB_IMM;
            sel_op = `ALU_FORWARD_B;
            mem_wr_en = `DISABLE;
            val_wr_type = `MEM_NOT_USED;
            val_rd_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_EXEC_RESULT;  
        end
        
        `AUIPC:begin
            jump = `DISABLE;
            branch  = `DISABLE;
            regfile_we = `ENABLE;
            imm_type = `U_IMMEDIATE;
            sel_exec_result = `exec_result_PC_plus_imm;
            sel_opb = `OPB_IMM;
            sel_op =  `ALU_ADD;
            mem_wr_en = `DISABLE;
            val_wr_type = `MEM_NOT_USED;
            val_rd_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_EXEC_RESULT;  
        end

        `JAL:begin
            jump = `ENABLE;
            branch  = `DISABLE;
            regfile_we = `ENABLE;
            imm_type = `J_IMMEDIATE;
            sel_exec_result = `exec_result_PC_plus_imm;
            sel_opb = `OPB_IMM;
            sel_op = `ALU_ADD;
            mem_wr_en = `DISABLE;
            val_wr_type = `MEM_NOT_USED;
            val_rd_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_PC_4;
        end

        `JALR:begin
            jump = `ENABLE;
            branch  = `DISABLE;
            regfile_we = `ENABLE;
            imm_type = `I_IMMEDIATE;
            sel_exec_result = `exec_result_ALU;
            sel_opb = `OPB_IMM;
            sel_op = `ALU_ADD;
            mem_wr_en = `DISABLE;
            val_wr_type = `MEM_NOT_USED;
            val_rd_type = `MEM_NOT_USED;
            sel_writeback = `WBACK_PC_4;
        end
    endcase
end
endmodule