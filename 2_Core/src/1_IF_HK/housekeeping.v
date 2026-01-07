`include "../../include/CORE_CONSTANTS.vh"

module housekeeping #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset,
    input pause,
    
    //Control
    input sel_next_PC,
    input sel_concatenation,
    input sel_PC_step,

    //addr coming from EX stage -> to jump at
    input [XLEN-1:0] exec_result,

    //Outputs
    output [16:0] EIAB,

    output reg [XLEN-1:0] PC,
    output     [XLEN-1:0] PC_2,
    output     [XLEN-1:0] PC_4

);


reg  [XLEN-1:0] next_PC;

//PC+4 & PC+2
wire [XLEN-1:0] PC_2, PC_4;
assign PC_2 = PC + 2;
assign PC_4 = PC + 4;

//next_PC
always @(sel_next_PC, sel_PC_step, exec_result, PC_2, PC_4, pause) begin
    if(pause)
                                next_PC = PC;
    else begin
        if      (sel_next_PC)   next_PC = exec_result;  // Jump / Branch
        else if (sel_PC_step)   next_PC = PC_2;         //  | 1_RVI |  RVC  | 
                                                        //  |  RVC  |  RVC  | 
        else                    next_PC = PC_4;         //  |  RVC  | 2_RVI |    
                                                        //  |      RVI      |     
    end
end

//PC
always@(posedge clk)begin
    if(reset)               PC <= `PC_BASE_ADDRESS;
    else if (!pause)        PC <= next_PC;
end

//Output to EIAB
wire [XLEN-1:0] to_EIAB = sel_concatenation ? (next_PC + 2) : next_PC; // <- extra +2 needed when reading "1_RVI" in | 1_RVI |  RVC  |

assign EIAB = {2'b00, to_EIAB[16:2]};


endmodule