`include "../../include/CORE_CONSTANTS.vh"

module housekeeping #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset_n,
    input pause,

    //Interrupt Handler
    input acknowledge_irq0,
    input acknowledge_irq1,
    
    //Control
    input                 control_transfer_en,
    input                 illegal_trap,

    input                 concatenate_in_next_cycle,
    input                 pause_to_concatenate,

    input                 sel_PC_step,

    //addr coming from EX stage -> to jump at
    input [XLEN-1:0]      exec_result,

    //Outputs
    output [16:0]         EIAB,

    output reg [XLEN-1:0] PC,
    output reg [XLEN-1:0] PC_step,
    output reg [XLEN-1:0] next_program_PC,

    //---------------------------- HCU (Hazard Control Unit)
    input stall
);

//PC_step
always @( * ) begin
    case (sel_PC_step)
        `PC_STEP_4: PC_step = PC + 64'd4;
        `PC_STEP_2: PC_step = PC + 64'd2;
    endcase
end

//next PC (if only focused on the program, no external intervention)
always @( * ) begin
    if(illegal_trap)
        next_program_PC = `PC_ILLEGAL;
    else if(control_transfer_en)
        next_program_PC = exec_result;
    else
        next_program_PC = PC_step;
end

//next PC (considering external intervention)
reg [XLEN-1:0] next_PC;
always @( * ) begin
    if(pause || pause_to_concatenate || stall)
            next_PC = PC;
    else begin
        if(acknowledge_irq0)
            next_PC = `PC_IRQ0;
        else if(acknowledge_irq1)
            next_PC = `PC_IRQ1;
        else
            next_PC = next_program_PC;
    end
end

//PC
always@(posedge clk, negedge reset_n)begin
    if(!reset_n)                 PC <= `PC_RESET;
    else if(!pause && !stall)    PC <= next_PC;
end

//Output to EIAB
wire [XLEN-1:0] to_EIAB = concatenate_in_next_cycle ? (next_PC + {{(XLEN-2){1'b0}}, 2'd2}) : next_PC; // <- extra +2 needed to go to next row and concatenate

assign EIAB = to_EIAB[16:0];


endmodule