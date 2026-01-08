module fetch (
    //Global
    input clk,
    input reset_n,
    input pause,

    input [31:0]  EIB,

    //control
    input         sel_EIB_2,
    input         sel_comp_instr,
    input         sel_instr_tpye,
    input         sel_concatenation,
    input         sel_next_PC,

    //output
    output [31:0] canonical_instruction
);

//Control
reg old_sel_next_PC;
always @(posedge clk, negedge reset_n) begin
    if(!reset_n)       old_sel_next_PC <= 1'b0;
    else if(!pause)    old_sel_next_PC <= sel_next_PC;
end

//----------------------------------------Definition of upper and lower parts of the instruction
wire [15:0] EIB_1, EIB_2;
reg  [15:0] EIB_2_temp;

    //EIB_1 
assign EIB_1 = EIB[15:0];
    //EIB_2
assign EIB_2 = old_sel_next_PC ? EIB[31:16] : EIB_2_temp; //Added to cover the case when we arrive from a jump and want to execute something from the upper part
//EIB_2_temp -> Defined as temporal register
//         - stores the upper part of EIB; can be either RVC or 1_RVI
always @(posedge clk, negedge reset_n) begin    
    if(!reset_n)        EIB_2_temp <= 16'd0;
    else if(!pause) begin
        //Stores in temporal register if the lower 16 bits are a C instruction, or if you need to concatenate your lower 16 bits
        if(sel_EIB_2)   EIB_2_temp <= EIB[31:16];
        else            EIB_2_temp <= 16'd0;    
    end
end

//----------------------------------------Compressed Instruction & Extension (According to RISCV ISA )

wire [15:0] compressed_instruction;
wire [31:0] extended_instruction;

assign compressed_instruction = sel_comp_instr ? EIB_2 : EIB_1;

extend_instruction u_extend_instr(
    .compressed_instruction(compressed_instruction),
    .extended_instruction(extended_instruction)
);

//--------------------------------------- Instruction to execute
assign canonical_instruction = sel_concatenation ? {EIB_1, EIB_2} :
                                                    sel_instr_tpye ? extended_instruction : EIB;



endmodule