`include "../../include/CORE_CONSTANTS.vh"

module IF_HK #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset,
    
    //Buses
    input  [31:0]     EIB,  //External Instruction Bus
    output [XLEN-1:0] EIAB, //External Instruction Address Bus 
    
    //----------------------------ID Stage
    //Data from/to ID stage
    input  [XLEN-1:0] ID_exec_result,

    output [XLEN-1:0] ID_PC_4,
    output [XLEN-1:0] ID_PC,
    output [31:0]     ID_EIB,

    //Control from/to ID stage
    input             ID_sel_next_PC
);

// ---------------------------------- Internal physical registers
reg [XLEN-1:0] PC;

// ---------------------------------- Implementation of modules

//PC+4
wire [XLEN-1:0] PC_4;
assign PC_4 = PC + 4;

//PC
reg [XLEN-1:0] next_PC;
always@(posedge clk)begin
    if(reset)   PC <= `PC_BASE_ADDRESS;
    else        PC <= next_PC;
end

//Mux
always@(ID_sel_next_PC, PC_4, ID_exec_result)begin
    case(ID_sel_next_PC)
        1'b0:         next_PC = PC_4;
        1'b1:         next_PC = ID_exec_result;
        default:      next_PC = 0;
    endcase
end

// ------------------------------------- Connection to adjacent stage(s)
//ID
assign ID_PC_4  = PC_4;
assign ID_PC    = PC;
assign ID_EIB   = EIB;


// -------------------------------------- Connection to buses (if any)
assign EIAB     = PC;

endmodule
