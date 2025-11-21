`include "../../Core/CORE_CONSTANTS.vh"

`timescale 1ns/1ps

module kreacher_top_tb;

// Parameters
localparam XLEN = 32;
localparam RUN_NUMBER_OF_INSTRUCTIONS = 9;

// Signals
reg clk;
reg reset;

reg [1:0]  sel_next_PC;
reg [2:0]  imm_type;
reg        regfile_we;

reg [1:0]  sel_opa;
reg [1:0]  sel_opb;
reg [4:0]  sel_op;

reg        mem_wr_en;
reg [2:0]  val_rd_type;
reg [2:0]  val_wr_type;

reg [2:0]  sel_writeback;

// Instantiate DUT
kreacher_top #(.XLEN(XLEN)) DUT (
    .clk(clk),
    .reset(reset)
);

// Clock generation
initial clk = 0;
always #5 clk = ~clk;  // 100 MHz clock

// Reset logic
initial begin
    reset = 1;
    #16;
    reset = 0;
end


localparam CYCLES = 10*(RUN_NUMBER_OF_INSTRUCTIONS -1);

// Stimulus
initial begin
    
    //Wait for reset
    @(negedge reset);
    //First fetch
    #10;
    
    
    // Wait some cycles
    #CYCLES;

    //Wait latency cycles
    #30;

    // Wait final cycles
    #7;

    $display("Writing DMEM to file...");
    $writememh("DMEM_result.mem", DUT.memories_top_inst.DMEM.memory); 
    //File is found afterwards in Vivado_Kreacher\Vivado_Kreacher.sim\sim_1\behav\xsim
    $display("Memory dumped to DMEM_result.mem");

    // Finish simulation
    $stop;
end

endmodule
