`include "../CORE_CONSTANTS.vh"

module control(
    //-------------------------- Inputs
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    
    //-------------------------- Control signals generated
    //IF
    output [1:0] sel_next_pc,

    //ID
    output       regfile_we,
    output [2:0] imm_type,

    //EX
    output [1:0] sel_opa,
    output [1:0] sel_opb,
    output [4:0] sel_op,

    //MEM
    output       mem_wr_en,
    output [2:0] val_wr_type,
    output [2:0] val_rd_type,

    //WB
    output [2:0] sel_writeback
);
always@(opcode or funct3 or funct7)begin //combinational circuit
    case(opcode)
        SHIFT_ARITHMETIC:begin
            case(func3)
                ADDI:begin
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
                SLTI:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = //check
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
                SLTIU: begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op =//check
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
                ANDI:begin
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
                XORI:begin
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
                ORI:begin
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
                SLLI:begin//check
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
                SRLI_SRAI:begin
                    sel_next_pc = `NEXT_PC_4;
                    regfile_we = `ENABLE;
                    imm_type = `I_IMMEDIATE;
                    sel_opa = `OPA_RS1;
                    sel_opb = `OPB_IMM;
                    sel_op = ;//check                                                             
                    mem_wr_en = `DISABLE;
                    val_wr_type = `MEM_NOT_USED;
                    val_rd_type = `MEM_NOT_USED;
                    sel_writeback = `WBACK_ALU_OUT;
                end
            endcase
        end

        LUI: begin
            sel_next_pc = ;
            regfile_we = ;
            imm_type = `U_IMMEDIATE;
            sel_opa = ;
            sel_opb = ;
            sel_op = ;
            mem_wr_en = ;
            val_wr_type = ;
            val_rd_type = ;
            sel_writeback = ;        
        end

        ADD:begin
            sel_next_pc = ;
            regfile_we = ;
            imm_type = ;
            sel_opa = ;
            sel_opb = ;
            sel_op = ;
            mem_wr_en = ;
            val_wr_type = ;
            val_rd_type = ;
            sel_writeback = ;
        end

    endcase
end
endmodule