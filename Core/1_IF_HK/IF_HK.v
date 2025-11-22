`include "../CORE_CONSTANTS.vh"

module IF_HK #(parameter XLEN = 32)(
    //Global
    input clk,
    input reset,
    
    //Buses
    input [XLEN-1:0]  EIB,  //External Instruction Bus
    output [XLEN-1:0] EIAB, //External Instruction Address Bus 
    
    //----------------------------ID Stage
    //Data from/to ID stage
    input      [XLEN-1:0] ID_ALU_out,

    output reg [XLEN-1:0] ID_PC_4,
    output reg [XLEN-1:0] ID_PC,
    output reg [XLEN-1:0] ID_EIB,

    //Control from/to ID stage
    input      [1:0]      ID_sel_next_PC,

    //---------------------------- HCU (Hazard Control Unit)
    input                 IF_stall,
    input                 IF_stall_PC

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
    if(reset)               PC <= 0;
    else if(!IF_stall_PC)   PC <= next_PC;
end

//Mux
always@(ID_sel_next_PC, PC_4, ID_ALU_out)begin
    case(ID_sel_next_PC)
        `NEXT_PC_4:         next_PC = PC_4;
        `NEXT_PC_ALU_OUT:   next_PC = ID_ALU_out;
        default:            next_PC = 0;
    endcase
end

// ------------------------------------- Connection to adjacent stage(s)
//ID
always @(posedge clk) begin
    if(reset)begin
        ID_PC_4  <= 0;
        ID_PC    <= 0;
        ID_EIB   <= 0;
    end
    else if(!IF_stall) begin
        ID_PC_4  <= PC_4;
        ID_PC    <= PC;
        ID_EIB   <= EIB;
    end
end


// -------------------------------------- Connection to buses (if any)
assign EIAB     = PC;

endmodule
