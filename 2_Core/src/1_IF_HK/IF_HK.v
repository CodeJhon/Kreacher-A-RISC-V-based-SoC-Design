`include "../../include/CORE_CONSTANTS.vh"

module IF_HK #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset_n,
    input pause,
    
    //Special pause signal
    input EX_pause_request,

    //Interrupt Handler
    input acknowledge_irq0,
    input acknowledge_irq1,
    
    output [XLEN-1:0]      next_program_PC,
    output wire [XLEN-1:0] PC_step,
    
    //Buses
    input  [31:0]     EIB,  //External Instruction Bus
    output [16:0]     EIAB, //External Instruction Address Bus 

    //Control
    output            IF_pause_request,
    
    //----------------------------ID Stage
    //Data from/to ID stage
    input  [XLEN-1:0] ID_exec_result,

    output [XLEN-1:0] ID_PC,
    output [XLEN-1:0] ID_PC_step,
    output [31:0]     ID_canonical_instruction,

    //Control from/to ID stage
    input             ID_control_transfer_en,
    input             ID_illegal_trap
);

//--------------Internal to out
wire [XLEN-1:0] PC;

wire [31:0]     canonical_instruction;

// -> Internal core pause requested by IF_HK stage
wire            pause_to_concatenate; 

//------------Control 
wire pointer =  PC[1];
wire concatenate_in_next_cycle;
wire concatenate_flag;
wire instr_type;
wire sel_PC_step;

wire core_jump = ID_control_transfer_en | acknowledge_irq0 | acknowledge_irq1;

mini_controller u_mini_controller (
    // Global
    .clk                       (clk),
    .reset_n                   (reset_n),
    .pause                     (pause),

    // Quadrants of upper and lower halves of EIB
    .EIB_1_quad                (EIB[1:0]),
    .EIB_2_quad                (EIB[17:16]),

    .pointer                   (pointer),
    .core_jump                 (core_jump),

    // Control
    .concatenate_in_next_cycle (concatenate_in_next_cycle),
    .concatenate_flag          (concatenate_flag),
    .pause_to_concatenate      (pause_to_concatenate),

    .instr_type                (instr_type),
    .sel_PC_step               (sel_PC_step)
    
);

fetch u_fetch (
    // Global
    .clk                       (clk),
    .reset_n                   (reset_n),
    .pause                     (pause),

    .EIB                       (EIB),

    .pointer                   (pointer),

    // Control
    .concatenate_in_next_cycle (concatenate_in_next_cycle),
    .concatenate_flag          (concatenate_flag),
    
    .instr_type                (instr_type),

    // Output
    .canonical_instruction     (canonical_instruction)
);

housekeeping #(.XLEN(XLEN)) u_housekeeping (
    // Global
    .clk                (clk),
    .reset_n            (reset_n),
    .pause              (pause),

    //Special pause signal
    .EX_pause_request   (EX_pause_request),

    //Interrupt Handler
    .acknowledge_irq0(acknowledge_irq0),
    .acknowledge_irq1(acknowledge_irq1),

    // Control
    .control_transfer_en       (ID_control_transfer_en),
    .illegal_trap             (ID_illegal_trap),

    .concatenate_in_next_cycle (concatenate_in_next_cycle),
    .pause_to_concatenate      (pause_to_concatenate),

    .sel_PC_step               (sel_PC_step),

    // Addr coming from EX stage -> to jump at
    .exec_result               (ID_exec_result),

    // Outputs
    .EIAB                      (EIAB),                                     // ------> Connection to bus

    .PC                        (PC),
    .PC_step                   (PC_step),
    .next_program_PC           (next_program_PC)
);

// ------------------------------------- Connection to adjacent stage(s)
//ID
assign ID_PC                      = PC;
assign ID_PC_step                    = PC_step;
assign ID_canonical_instruction   = canonical_instruction;


// -------------------------------------- Other connections


//Control
assign IF_pause_request = pause_to_concatenate;

endmodule
