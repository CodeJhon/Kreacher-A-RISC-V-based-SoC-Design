`include "../../include/CORE_CONSTANTS.vh"

module IF_HK #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset_n,
    input pause,

    //Flags
    output            valid_instr_fetch,
    
    //Buses
    input  [31:0]     EIB,  //External Instruction Bus
    output [16:0]     EIAB, //External Instruction Address Bus 

    //Control
    output            IF_pause_request,
    
    //----------------------------ID Stage
    //Data from/to ID stage
    input  [XLEN-1:0]     ID_exec_result,

    output reg [XLEN-1:0] ID_PC,
    output reg [XLEN-1:0] ID_PC_4,
    output reg [31:0]     ID_canonical_instruction,

    //Control from/to ID stage
    input                 ID_sel_next_PC,

    //---------------------------- HCU (Hazard Control Unit)
    input                 IF_stall,
    input                 IF_stall_PC,
    input                 IF_flush

);

//--------------Internal to out
wire [XLEN-1:0] PC;
wire [XLEN-1:0] PC_step;
wire [31:0]     canonical_instruction;

// -> Internal core pause requested by IF_HK stage
wire            pause_to_concatenate; 

//------------Control 
wire pointer =  PC[1];
wire concatenate_in_next_cycle;
wire concatenate_flag;
wire instr_type;
wire sel_PC_step;


mini_controller u_mini_controller (
    // Global
    .clk                       (clk),
    .reset_n                   (reset_n),
    .pause                     (pause),

    // Quadrants of upper and lower halves of EIB
    .EIB_1_quad                (EIB[1:0]),
    .EIB_2_quad                (EIB[17:16]),

    .pointer                   (pointer),
    .sel_next_PC               (ID_sel_next_PC),

    // Control
    .concatenate_in_next_cycle (concatenate_in_next_cycle),
    .concatenate_flag          (concatenate_flag),
    .pause_to_concatenate      (pause_to_concatenate),

    .instr_type                (instr_type),
    .sel_PC_step               (sel_PC_step),
    
    //---------------------------- HCU (Hazard Control Unit)
    .stall(IF_stall),
    .flush(IF_flush)
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
    .canonical_instruction     (canonical_instruction),

    //---------------------------- HCU (Hazard Control Unit)
    .stall(IF_stall),
    .flush(IF_flush)
);

housekeeping #(.XLEN(XLEN)) u_housekeeping (
    // Global
    .clk                (clk),
    .reset_n            (reset_n),
    .pause              (pause),

    // Control
    .sel_next_PC               (ID_sel_next_PC),

    .concatenate_in_next_cycle (concatenate_in_next_cycle),
    .pause_to_concatenate      (pause_to_concatenate),

    .sel_PC_step               (sel_PC_step),

    // Addr coming from EX stage -> to jump at
    .exec_result               (ID_exec_result),

    // Outputs
    .EIAB                      (EIAB),                                     // ------> Connection to bus
    .PC                        (PC),
    .PC_step                   (PC_step),

    //---------------------------- HCU (Hazard Control Unit)
    .stall(IF_stall_PC)
);

// ------------------------------------- Connection to adjacent stage(s)
//ID
always @(posedge clk, negedge reset_n) begin
    if(!reset_n || IF_flush) begin
        ID_PC                      <= 0;
        ID_PC_4                    <= 0;
        ID_canonical_instruction   <= 0;
    end
    else if(!pause && !IF_stall && !pause_to_concatenate) begin
        ID_PC                      <= PC;
        ID_PC_4                    <= PC_step;
        ID_canonical_instruction   <= canonical_instruction;
    end
end



// -------------------------------------- Other connections

//Flags
assign valid_instr_fetch = ~pause;

//Control
assign IF_pause_request = pause_to_concatenate;

endmodule
