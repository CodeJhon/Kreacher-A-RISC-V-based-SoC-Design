`include "../../include/CORE_CONSTANTS.vh"

module housekeeping #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset_n,
    input pause,

    //Special pause signal
    input EX_pause_request,

    //Interrupt Handler
    input take_interrupt_0,
    input take_interrupt_1,
    
    //Control
    input                 control_transfer_en,
    input                 illegal_trap,

    input                 concatenate_in_next_cycle,
    input                 pause_to_concatenate,

    input                 sel_PC_step,

    //addr coming from EX stage -> to jump at
    input [XLEN-1:0]      exec_result,

    //Outputs
    output reg [16:0]     EIAB,

    output reg [XLEN-1:0] PC,
    output reg [XLEN-1:0] PC_step,
    output reg [XLEN-1:0] next_program_PC

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
    if(pause_to_concatenate || EX_pause_request)
            next_PC = PC;
    else begin
        if(take_interrupt_0)
            next_PC = `PC_IRQ0;
        else if(take_interrupt_1)
            next_PC = `PC_IRQ1;
        else
            next_PC = next_program_PC;
    end
end

//PC
always@(posedge clk, negedge reset_n)begin
    if(!reset_n)       PC <= `PC_RESET;
    else if (!pause)   PC <= next_PC;
end

//Output to EIAB
reg [XLEN-1:0] to_EIAB;
reg [XLEN-1:0] to_EIAB_old;

always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
        to_EIAB_old <= {XLEN{1'd0}};
    else if(!EX_pause_request)
        to_EIAB_old <= to_EIAB;
end

always @( * ) begin
    //Default
    to_EIAB = next_PC;

    if(concatenate_in_next_cycle)
        to_EIAB = next_PC + {{(XLEN-2){1'b0}}, 2'd2}; // <- extra +2 needed to go to next row and concatenate
end

always @( * ) begin
    //Default
    if(EX_pause_request)
        EIAB = to_EIAB_old[16:0];
    else
        EIAB = to_EIAB[16:0];
end


endmodule