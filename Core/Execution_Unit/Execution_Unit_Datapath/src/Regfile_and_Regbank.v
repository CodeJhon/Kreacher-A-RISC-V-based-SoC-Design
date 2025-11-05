module Regfile_and_Regbank(
    input clk,
    input reset,
    input we,
    input sel_writer_bus,
    
    input       [31:0] A_write_T1,
    output      [31:0] A_read_T1,
    input       [31:0] B_write_T1,
    output      [31:0] B_read_T1,
    
    input       [31:0] A_write_PC,
    output      [31:0] A_read_PC,
    input       [31:0] B_write_PC,
    output      [31:0] B_read_PC,
    
    //Regfile - Coming from Bus A
    input        [4:0] A_sel_register,
    input       [31:0] A_write_regfile,
    output      [31:0] A_read_regfile,
    //Regfile - Coming from Bus B
    input        [4:0] B_sel_register,
    input       [31:0] B_write_regfile,
    output      [31:0] B_read_regfile
    );

`include "../EXEC_CONSTANTS.vh"
    
reg [31:0] regfile [30:0];//X0 not implemented here but in the assign statement
integer i;

reg [31:0] PC;

//Temporal registers
reg [31:0] T1;

assign A_read_regfile = (A_sel_register == 5'd0) ? 32'd0 : regfile[A_sel_register];//X0 = 0 always
assign B_read_regfile = (B_sel_register == 5'd0) ? 32'd0 : regfile[B_sel_register];//X0 = 0 always
assign A_read_T1 = T1;
assign B_read_T1 = T1;
assign A_read_PC = PC;
assign B_read_PC = PC;

always@(posedge clk)begin
    if(reset)begin//Clear all register on reset
        T1 <= 32'd0;
        PC <= 32'd0;
        for(i=0;i<31;i=i+1) regfile[i] <= 32'd0;
    end
    else begin
        if(we)begin
            case(sel_writer_bus)
                SEL_BUS_A: begin
                    T1 <= A_write_T1;
                    PC <= A_write_PC;
                    if(A_sel_register != 5'd0) regfile[A_sel_register] <= A_write_regfile;
                end
                SEL_BUS_B: begin
                    T1 <= B_write_T1;
                    PC <= B_write_PC;
                    if(B_sel_register != 5'd0) regfile[B_sel_register] <= B_write_regfile;
                end
            endcase
        end
    end
end

    
endmodule
