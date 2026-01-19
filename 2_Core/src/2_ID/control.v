`include "../../include/CORE_CONSTANTS.vh"

module control #(parameter XLEN = 64)(
    //-------------------------- Inputs
    input [31:0]     canonical_instruction,
    
    //-------------------------- Control signals generated
    //Flags
    output reg       valid_data_read,
    output reg       valid_data_write,

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
    output reg [4:0]  sel_op,
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

//Internal control
reg is_privileged;

always@(*)begin
    is_privileged = 1'b0;

    //Default values - disable everything
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
                case(funct3)
                    `AND:         sel_op = `ALU_AND;
                    `OR:          sel_op = `ALU_OR;
                    `XOR:         sel_op = `ALU_XOR;
                    `SLTU:        sel_op = `ALU_SLTU;
                    `SLT:         sel_op = `ALU_SLT;
                    `SLL:         sel_op = `ALU_SLL;
                    `SHIFT_RIGHT:begin
                        case(funct7)
                            `SRA: sel_op = `ALU_SRA;
                            `SRL: sel_op = `ALU_SRL;
                        endcase
                    end
                    `ADD_SUB:begin
                        case(funct7)
                            `ADD: sel_op = `ALU_ADD;
                            `SUB: sel_op = `ALU_SUB;
                        endcase
                    end
                endcase
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
                case(funct3)
                    `SLL:         sel_op = `ALU_SLLW;
                    `SHIFT_RIGHT:begin
                        case(funct7)
                            `SRA: sel_op = `ALU_SRAW;
                            `SRL: sel_op = `ALU_SRLW;
                        endcase
                    end
                    `ADD_SUB:begin
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
                case (funct3)
                    `CSRRW: begin
                        sel_opb = `OPB_RS1;
                        sel_op = `ALU_FORWARD_B;
                        
                        //-----------------Writing/Reading
                        //CSR write
                        csr_we = `ENABLE;

                        //CSR read -> Regfile write
                        if(RD_addr != 0) {csr_re, regfile_we} = {2{`ENABLE}};
                        else             {csr_re, regfile_we} = {2{`DISABLE}};
                    end
                    `CSRRS: begin
                        sel_opb = `OPB_RS1;
                        sel_op = `ALU_OR;
                        
                        //-----------------Writing/Reading
                        //CSR write
                        if(uimm_RS1_addr != 0) csr_we = `ENABLE;
                        else              csr_we = `DISABLE;
                        
                        //CSR read -> Regfile write
                        {csr_re, regfile_we} = {2{`ENABLE}};
                    end
                    `CSRRC: begin
                        sel_opb = `OPB_RS1;
                        sel_op = `ALU_CSRRC;
                        
                        //-----------------Writing/Reading
                        //CSR write
                        if(uimm_RS1_addr != 0) csr_we = `ENABLE;
                        else              csr_we = `DISABLE;
                        
                        //CSR read -> Regfile write
                        {csr_re, regfile_we} = {2{`ENABLE}};
                    end

                    `CSRRWI: begin
                        sel_opb = `OPB_IMM;
                        sel_op = `ALU_FORWARD_B;
                        
                        //-----------------Writing/Reading
                        //CSR write
                        csr_we = `ENABLE;

                        //CSR read -> Regfile write
                        if(RD_addr != 0) {csr_re, regfile_we} = {2{`ENABLE}};
                        else             {csr_re, regfile_we} = {2{`DISABLE}};
                    end
                    `CSRRSI: begin
                        sel_opb = `OPB_IMM;
                        sel_op = `ALU_OR;
                        
                        //-----------------Writing/Reading
                        //CSR write
                        if(uimm_RS1_addr != 0) csr_we = `ENABLE;
                        else              csr_we = `DISABLE;
                        
                        //CSR read -> Regfile write
                        {csr_re, regfile_we} = {2{`ENABLE}};
                    end
                    `CSRRCI: begin
                        sel_opb = `OPB_IMM;
                        sel_op = `ALU_CSRRC;
                        
                        //-----------------Writing/Reading
                        //CSR write
                        if(uimm_RS1_addr != 0) csr_we = `ENABLE;
                        else              csr_we = `DISABLE;
                        
                        //CSR read -> Regfile write
                        {csr_re, regfile_we} = {2{`ENABLE}};
                    end
                endcase
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
        endcase
    end
end
endmodule