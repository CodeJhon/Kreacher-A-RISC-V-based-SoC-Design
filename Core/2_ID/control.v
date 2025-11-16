module control(
    //-------------------------- Inputs
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    
    //-------------------------- Control signals generated
    //IF
    output [1:0] sel_next_pc,

    //ID
    output regfile_we,
    //output [] imm_type,

    //EX
    output [1:0] sel_opa,
    output [1:0] sel_opb,
    output [4:0] sel_op,

    //MEM
    output mem_wr_en,
    //output [] val_wr_type,
    //output [] val_rd_type,

    //WB
    output [2:0] sel_writeback
);

endmodule