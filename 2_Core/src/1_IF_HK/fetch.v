`include "../../include/CORE_CONSTANTS.vh"

module fetch (
    //Global
    input clk,
    input reset_n,
    input pause,

    input [31:0]      EIB,

    input             pointer,

    //control
    input             concatenate_in_next_cycle,
    input             concatenate_flag,
    
    input             instr_type,

    //output
    output reg [31:0] canonical_instruction,

    //---------------------------- HCU (Hazard Control Unit)
    input stall,
    input flush
);

//----------------------------------------Definition of upper and lower parts of the instruction

    //EIB_1 
wire [15:0] EIB_1 = EIB[15:0];
    //EIB_2
wire [15:0] EIB_2 = EIB[31:16]; 

//EIB_2_temp -> Defined as temporal register
//         - stores the upper part of EIB; can be either RVC or 1_RVI
reg  [15:0] EIB_2_temp;
always @(posedge clk, negedge reset_n) begin    
    if(!reset_n || flush)               EIB_2_temp <= 16'd0;
    else if(!pause && !stall) begin
        //Stores in temporal register if the lower 16 bits are a C instruction, or if you need to concatenate your lower 16 bits
        if(concatenate_in_next_cycle)   EIB_2_temp <= EIB[31:16];
        else                            EIB_2_temp <= 16'd0;    
    end
end

//----------------------------------------Compressed Instruction & Extension (According to RISCV ISA )

wire [15:0] compressed_instruction;
wire [31:0] extended_instruction;

assign compressed_instruction = pointer ? EIB_2 : EIB_1;

extend_instruction u_extend_instr(
    .compressed_instruction(compressed_instruction),
    .extended_instruction(extended_instruction)
);

//--------------------------------------- Instruction to execute
always @( * ) begin
    if(concatenate_flag)
        canonical_instruction = {EIB_1, EIB_2_temp};
    else begin
        case (instr_type)
            `RVI_INSTR: canonical_instruction = EIB;
            `C_INSTR:   canonical_instruction = extended_instruction;
        endcase
    end
end


endmodule