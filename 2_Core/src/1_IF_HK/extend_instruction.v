`include "../../include/INSTR_EXTENSION.vh"
`include "../../include/CORE_CONSTANTS.vh"

module extend_instruction (
    input      [15:0] compressed_instruction,

    output reg [31:0] extended_instruction
);

wire [2:0] quadrant;
assign quadrant = compressed_instruction[1:0];

//-----------------------------------------------------Operands

//Full 32 registers
wire [4:0] rs2      = compressed_instruction[6:2];
wire [4:0] rd_rs1   = compressed_instruction[11:7];

//Popular registers (prime) -> x8 to x15
wire [4:0] rd_rs2_p = { 2'b01 , compressed_instruction[4:2]};
wire [4:0] rd_rs1_p = { 2'b01 , compressed_instruction[9:7]};

//-------------------------------------------------Functions

wire [1:0] funct2   = compressed_instruction[6:5];
wire [1:0] funct2_p = compressed_instruction[11:10];

wire [2:0] funct3   = compressed_instruction[15:13];

wire [3:0] funct4   = compressed_instruction[15:12];

wire [5:0] funct6   = compressed_instruction[15:10];

//-------------------------------------------------Internal control
wire sel_sign_extension = !(
    // Quadrant 1: C.SRLI, C.SRAI
    (quadrant == `QUADRANT_1 && funct3   == 3'd4 && (funct2_p == 2'd0 || funct2_p == 2'd1))
    ||
    // Quadrant 2: C.SLLI
    (quadrant == `QUADRANT_2 && funct3   == 3'd0)
     );

//INFO: 
//      1. This case statement is organized as in the instruction set listing
//      2. Where immediates are sign-extended, the sign-extension is always from bit 12 (compressed_instruction[12])

//----------------------------------------------------------------------------------------Immediates

// ALU immediates
wire [11:0] imm_c_alu = {
                            //---- imm[11:6] ----------
    (sel_sign_extension ? {6{compressed_instruction[12]}} : 6'd0), 
                            //---- imm[5:0] ----------
                            compressed_instruction[12], 
                            compressed_instruction[6:2]};

wire [11:0] imm_c_addi16sp = {
                            //----- imm[11:10] ---------
                            {2{compressed_instruction[12]}},                    //Sign extension
                            //----- imm[9:4] ---------
                            compressed_instruction[12], 
                            compressed_instruction[4:3],
                            compressed_instruction[5],
                            compressed_instruction[2],
                            compressed_instruction[6],
                            //----- imm[3:0] ---------
                            4'd0};

wire [11:0] imm_c_addi4spn = {
                            //----- imm[11:0] ---------
                            2'd0,                             //imm[11:10]
                            compressed_instruction[10:7],     //imm[9:6]
                            compressed_instruction[12:11],    //imm[5:4]
                            compressed_instruction[5],        //imm[3]
                            compressed_instruction[6],        //imm[2]
                            2'd0 };                           //imm[1:0]

wire [19:0] imm_c_lui = {
                            // -----imm[31:18]------
                            {14{compressed_instruction[12]}},       //sign-extension
                            // -----imm[17:12]------
                            compressed_instruction[12], 
                            compressed_instruction[6:2]} ;

// Control-flow immediates
wire [11:0] imm_c_branch = {
                            //----- imm[12] ---------
                            compressed_instruction[12],                          //Sign extension   
                            //----- imm[10:5] ---------
                            {2{compressed_instruction[12]}},//imm[10:9]          //Sign extension
                            compressed_instruction[12],     //imm[8]
                            compressed_instruction[6:5],    //imm[7:6]
                            compressed_instruction[2],      //imm[5]
                            //----- imm[4:1] ---------
                            compressed_instruction[11],     //imm[4]
                            compressed_instruction[10],     //imm[3]
                            compressed_instruction[4:3],    //imm[2:1]
                            
                            //----- imm[11] ---------
                            compressed_instruction[12] };                         //Sign extension   

wire [19:0] imm_c_jal = {                        
                            //---------imm[20]----------------
                            compressed_instruction[12],             //sign-extension
                            //-----------imm[10:1]------------
                            compressed_instruction[8],//imm[10]
                            compressed_instruction[10],//imm[9]
                            compressed_instruction[9],//imm[8]
                            compressed_instruction[6],//imm[7]
                            compressed_instruction[7],//imm[6]
                            compressed_instruction[2],//imm[5]
                            compressed_instruction[11],//imm[4]
                            compressed_instruction[5],//imm[3]
                            compressed_instruction[4],//imm[2]
                            compressed_instruction[3],//imm[1]
                            //------------imm[11]---------------
                            compressed_instruction[12],
                            //------------imm[19:12]-------------
                            {8{compressed_instruction[12]}} };        //sign-extension

// Memory immediates
wire [11:0] imm_c_lw_sw = {
                            //----- imm[11:0] ---------
                            5'd0,                             //imm[11:7]
                            compressed_instruction[5],        //imm[6]
                            compressed_instruction[12:10],    //imm[5:3]
                            compressed_instruction[6],        //imm[2]
                            2'd0 };                           //imm[1:0]

wire [11:0] imm_c_ld_sd = {
                            //----- imm[11:0] ---------
                            4'd0,                             //imm[11:8]
                            compressed_instruction[6:5],      //imm[7:6]
                            compressed_instruction[12:10],    //imm[5:3]
                            3'd0 };                           //imm[2:0]

wire [11:0] imm_c_lwsp = {
                            //----- imm[11:0] ---------
                            4'd0,                            //imm[11:8]
                            compressed_instruction[3:2],     //imm[7:6]
                            compressed_instruction[12],      //imm[5]
                            compressed_instruction[6:4],     //imm[4:2]
                            2'd0 };                          //imm[1:0]

wire [11:0] imm_c_ldsp = {
                            //----- imm[11:0] ---------
                            3'd0,                            //imm[11:9]
                            compressed_instruction[4:2],     //imm[8:6]
                            compressed_instruction[12],      //imm[5]
                            compressed_instruction[6:5],     //imm[4:3]
                            3'd0 };                          //imm[2:0]
                            
wire [11:0] imm_c_swsp_sdsp = {
                            //----- imm[11:0] ---------
                            4'd0,                            //imm[11:8]
                            compressed_instruction[8:7],     //imm[7:6]
                            compressed_instruction[12:9],    //imm[5:2]
                            2'd0 };                          //imm[1:0]


always @(quadrant, funct2, funct2_p, funct3, funct4, funct6, 
        rd_rs1, rd_rs1_p, rd_rs2_p, rs2, 
        imm_c_addi16sp, imm_c_alu, imm_c_lui, imm_c_jal, imm_c_addi4spn, 
        imm_c_lw_sw, imm_c_ld_sd, imm_c_branch, imm_c_swsp_sdsp, imm_c_lwsp, imm_c_ldsp) begin
    //Default reconstruction -> NOP (addi x0, x0, 0)
    extended_instruction = 32'h00000013;
    
    //Reconstruction RVC -> RVI:
    case (quadrant)

        `QUADRANT_0: begin
            case (funct3)
                3'd0://                                              C.ADDI4SPN -> addi rd', x2, nzuimm
                    if(imm_c_addi4spn != 0)                                extended_instruction = {imm_c_addi4spn, `X_2, `ADDI, rd_rs1_p, `INT_REG_IMM}; 
                3'd2://                                              C.LW       -> lw rd', uimm(rs1')
                                                                     extended_instruction = {imm_c_lw_sw, rd_rs1_p, `LW, rd_rs2_p, `LOAD}; 
                3'd3://                                              C.LD       -> ld rd', uimm(rs1')
                                                                     extended_instruction = {imm_c_ld_sd, rd_rs1_p, `LD, rd_rs2_p, `LOAD};
                3'd6://                                              C.SW       -> sw rs2', uimm(rs1')
                                                                     extended_instruction = {imm_c_lw_sw[11:5], rd_rs2_p, rd_rs1_p, `SW, imm_c_lw_sw[4:0], `STORE}; 
                3'd7://                                              C.SD       -> sd rs2', uimm(rs1')
                                                                     extended_instruction = {imm_c_ld_sd[11:5], rd_rs2_p, rd_rs1_p, `SD, imm_c_ld_sd[4:0], `STORE}; 
            endcase
        end

        `QUADRANT_1: begin
            case (funct3)
                3'd0://                                              C.ADDI     -> addi  rd, rd, nzimm
                    if((rd_rs1 != 0) && (imm_c_alu != 0))             extended_instruction = {imm_c_alu, rd_rs1, `ADDI, rd_rs1, `INT_REG_IMM};
                3'd1://                                              C.ADDIW    -> addiw rd, rd, nzimm
                    if(rd_rs1 != 0)                                  extended_instruction = {imm_c_alu, rd_rs1, `ADDI, rd_rs1, `INT_REG_IMM_W};
                3'd2://                                              C.LI       -> addi rd, x0, imm
                    if(rd_rs1 != 0)                                  extended_instruction = {imm_c_alu,  `X_0 , `ADDI, rd_rs1, `INT_REG_IMM};
                3'd3:begin
                    //                                               C.ADDI16SP -> addi x2, rd, nzimm
                    if      (rd_rs1 == 2)                            extended_instruction = {imm_c_addi16sp,  `X_2 , `ADDI, rd_rs1, `INT_REG_IMM};
                    //                                               C.LUI      -> lui rd, nzimm
                    else if (rd_rs1 != 0)                            extended_instruction = {imm_c_lui,  rd_rs1, `LUI};
                end
                3'd4:begin
                    case (funct2_p)
                        2'd0://                                      C.SRLI      -> srli rd', rd', nzuimm[5:0]
                            if(imm_c_alu != 0)                        extended_instruction = {`FUNCT6_SHIFT_LOGICAL, imm_c_alu[5:0], rd_rs1_p, `SRLI_SRAI, rd_rs1_p, `INT_REG_IMM};
                        2'd1://                                      C.SRAI      -> srai rd', rd', nzuimm[5:0]
                            if(imm_c_alu != 0)                        extended_instruction = {`FUNCT6_SHIFT_ARITHMETIC, imm_c_alu[5:0], rd_rs1_p, `SRLI_SRAI, rd_rs1_p, `INT_REG_IMM};
                        2'd2://                                      C.ANDI      -> andi rd', rd', imm
                                                                     extended_instruction = {imm_c_alu, rd_rs1_p, `ANDI, rd_rs1_p, `INT_REG_IMM};
                    endcase
                end
                3'd5://                                              C.J       -> jal x0, imm
                                                                     extended_instruction = {imm_c_jal, `X_0, `JAL};
                3'd6://                                              C.BEQZ    -> beq rs1',x0, imm
                                                                     extended_instruction = {imm_c_branch[11:5], `X_0, rd_rs1_p, `BEQ, imm_c_branch[4:0], `BRANCH};
                3'd7://                                              C.BNEZ    -> bne rs1',x0, imm
                                                                     extended_instruction = {imm_c_branch[11:5], `X_0, rd_rs1_p, `BNE, imm_c_branch[4:0], `BRANCH};
            endcase

            case (funct6)
                `FUNCT_6_OP:begin
                    case (funct2)
                        2'd0://                                      C.SUB      -> sub rd', rd', rs2'
                                                                     extended_instruction = {`FUNCT7_ALU_SUB, rd_rs2_p, rd_rs1_p, `ADD_SUB, rd_rs1_p, `INT_REG_REG};
                        2'd1://                                      C.XOR      -> xor rd', rd', rs2'
                                                                     extended_instruction = {`FUNCT7_ALU_ADD, rd_rs2_p, rd_rs1_p, `XOR, rd_rs1_p, `INT_REG_REG};
                        2'd2://                                      C.OR       -> or rd', rd', rs2'
                                                                     extended_instruction = {`FUNCT7_ALU_ADD, rd_rs2_p, rd_rs1_p, `OR, rd_rs1_p, `INT_REG_REG};
                        2'd3://                                      C.AND      -> and rd', rd', rs2'
                                                                     extended_instruction = {`FUNCT7_ALU_ADD, rd_rs2_p, rd_rs1_p, `AND, rd_rs1_p, `INT_REG_REG};
                    endcase
                end
                `FUNCT_6_OPW:begin
                    case (funct2)
                        2'd0://                                      C.SUBW      -> subw rd', rd', rs2'
                                                                     extended_instruction = {`FUNCT7_ALU_SUB, rd_rs2_p, rd_rs1_p, `ADD_SUB, rd_rs1_p, `INT_REG_REG_W};
                        2'd1://                                      C.ADDW      -> addw rd', rd', rs2'
                                                                     extended_instruction = {`FUNCT7_ALU_ADD, rd_rs2_p, rd_rs1_p, `ADD_SUB, rd_rs1_p, `INT_REG_REG_W};
                    endcase
                end
            endcase 
        end

        `QUADRANT_2: begin
            case (funct3)
                3'd0://                                              C.SLLI      -> slli rd, rd, nzuimm[5:0]
                    if((imm_c_alu != 0) && (rd_rs1 != 0))              extended_instruction = {`FUNCT6_SHIFT_LOGICAL, imm_c_alu[5:0], rd_rs1, `SLLI, rd_rs1, `INT_REG_IMM};
                3'd2://                                              C.LWSP     -> lw rd, uimm(x2)
                    if(rd_rs1 != 0)                                  extended_instruction = {imm_c_lwsp, `X_2, `LW, rd_rs1, `LOAD};
                3'd3://                                              C.LDSP     -> ld rd, uimm(x2)
                    if(rd_rs1 != 0)                                  extended_instruction = {imm_c_ldsp, `X_2, `LD, rd_rs1, `LOAD};
                3'd6://                                              C.SWSP     -> sw rs2, uimm(x2)
                                                                     extended_instruction = {imm_c_swsp_sdsp[11:5], rs2, `X_2, `SW, imm_c_swsp_sdsp[4:0], `STORE};
                3'd7://                                              C.SDSP     -> sd rs2, uimm(x2)
                                                                     extended_instruction = {imm_c_swsp_sdsp[11:5], rs2, `X_2, `SD, imm_c_swsp_sdsp[4:0], `STORE};
            endcase

            case (funct4)
                `C_FUNCT4_JR_MV: begin
                    if(rd_rs1 != 0) begin
                        //                                           C.JR       -> jalr x0, 0(rs1)
                        if(rs2 == 0)                                 extended_instruction = {12'd0, rd_rs1, 3'd0, `X_0, `JALR};
                        //                                           C.MV       -> add  rd, x0, rs2
                        else                                         extended_instruction = {`FUNCT7_ALU_ADD, rs2, `X_0, `ADD_SUB, rd_rs1, `INT_REG_REG};
                    end
                end
                `C_FUNCT4_JALR_ADD :begin
                    if(rd_rs1 != 0) begin
                        //                                           C.JALR     -> jalr x1, 0(rs1)
                        if(rs2 == 0)                                 extended_instruction = {12'd0, rd_rs1, 3'd0, `X_1, `JALR};
                        //                                           C.ADD      -> add  rd, rd, rs2
                        else                                         extended_instruction = {`FUNCT7_ALU_ADD, rs2, rd_rs1, `ADD_SUB, rd_rs1, `INT_REG_REG};
                    end
                end
            endcase
        end
    
    endcase    
end



    
endmodule