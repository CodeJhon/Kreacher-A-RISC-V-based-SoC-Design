module regfile #(parameter XLEN = 64)(
    //global
    input clk,
    input reset_n,

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
reg [XLEN-1:0] regfile_bank [31:0];

// ---------------------------------- Implementation of modules

//Regfile 

// Writing register synchronously
always@(posedge clk, negedge reset_n)begin
    if(!reset_n)begin
        for(i=0;i<=31;i=i+1)begin
            regfile_bank[i] <= {XLEN{1'b0}};
        end
    end
    else if(regfile_we && RD_addr != 5'd0) 
        regfile_bank[RD_addr] <= RD;
end

// Reading register asynchronously
assign RS1 = (RS1_addr == 5'd0) ? {XLEN{1'b0}} : regfile_bank[RS1_addr];
assign RS2 = (RS2_addr == 5'd0) ? {XLEN{1'b0}} : regfile_bank[RS2_addr];        



endmodule