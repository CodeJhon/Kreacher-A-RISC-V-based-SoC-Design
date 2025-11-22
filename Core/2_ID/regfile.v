module regfile #(parameter XLEN = 32)(
    //global
    input clk,
    input reset,

    //Addresses
    input [4:0]           RS1_addr,
    input [4:0]           RS2_addr,
    input [4:0]           RD_addr,

    //Sources & Destinations
    input  [XLEN-1:0]     RD,
    output [XLEN-1:0]     RS1,
    output [XLEN-1:0]     RS2,

    //Control lines
    input                 regfile_we

);

// --------------------------------- Others
integer i;

// ---------------------------------- Internal physical registers
reg [XLEN-1:0] regfile [31:1];

// ---------------------------------- Implementation of modules

//Regfile (Written in 1st part of the cycle and Read on 2nd part) 
    //-> Allows Writing & Reading by/to 2 different stages in the same cycle

//Writing register on 1st part of cycle (negedge)
always@(negedge clk)begin
    if(reset)begin
        for(i=1;i<=31;i=i+1)begin
            regfile[i] <= 0;
        end
    end
    else if(regfile_we) regfile[RD_addr] <= RD;
end

// Reading register on 2nd part of cycle (asynchronously)
assign RS1 = (RS1_addr == 0) ? {XLEN{1'b0}} : regfile[RS1_addr];
assign RS2 = (RS2_addr == 0) ? {XLEN{1'b0}} : regfile[RS2_addr];        



endmodule