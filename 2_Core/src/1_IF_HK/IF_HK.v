`include "../../include/CORE_CONSTANTS.vh"

module IF_HK #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset_n,
    
    //Buses
    input  [31:0]     EIB,  //External Instruction Bus
    output [16:0]     EIAB, //External Instruction Address Bus 
    
    //----------------------------ID Stage
    //Data from/to ID stage
    input  [XLEN-1:0] ID_exec_result,

    output [XLEN-1:0] ID_PC_4,
    output [XLEN-1:0] ID_PC,
    output [31:0]     ID_canonical_instruction,

    //Control from/to ID stage
    input             ID_sel_next_PC
);

//--------------Outputs
wire [XLEN-1:0] PC;
wire [XLEN-1:0] PC_4;
wire [31:0]     canonical_instruction;

//------------Control signals
    //Housekeeping
wire sel_PC_step;
    //Fetch
wire sel_EIB_2;
wire sel_comp_instr;
wire sel_instr_tpye;
wire sel_concatenation;

assign sel_comp_instr = PC[1];


mini_controller u_mini_controller (
    // Global
    .clk                (clk),
    .reset_n              (reset_n),

    // Quadrants of upper and lower halves of EIB
    .EIB_1_quad         (EIB[1:0]),
    .EIB_2_quad         (EIB[17:16]),

    .sel_next_PC        (ID_sel_next_PC),

    // Control
    .sel_concatenation  (sel_concatenation),

        // To housekeeping
    .sel_PC_step        (sel_PC_step),

        // To fetch
    .sel_EIB_2          (sel_EIB_2),
    .sel_instr_tpye     (sel_instr_tpye)
    
);

fetch u_fetch (
    // Global
    .clk                   (clk),
    .reset_n                 (reset_n),

    .EIB                   (EIB),

    // Control
    .sel_EIB_2             (sel_EIB_2),
    .sel_comp_instr        (sel_comp_instr),
    .sel_instr_tpye        (sel_instr_tpye),
    .sel_concatenation     (sel_concatenation),
    .sel_next_PC            (ID_sel_next_PC),

    // Output
    .canonical_instruction(canonical_instruction)
);

housekeeping #(.XLEN(XLEN)) u_housekeeping (
    // Global
    .clk                (clk),
    .reset_n              (reset_n),

    // Control
    .sel_next_PC        (ID_sel_next_PC),
    .sel_concatenation  (sel_concatenation),
    .sel_PC_step        (sel_PC_step),

    // Addr coming from EX stage -> to jump at
    .exec_result        (ID_exec_result),

    // Outputs
    .EIAB               (EIAB),                                     // ------> Connection to bus
    .PC                 (PC),
    .PC_2               (),
    .PC_4               (PC_4)
);

// ------------------------------------- Connection to adjacent stage(s)
//ID
assign ID_PC_4  = PC_4;
assign ID_PC    = PC;
assign ID_canonical_instruction   = canonical_instruction;


endmodule
