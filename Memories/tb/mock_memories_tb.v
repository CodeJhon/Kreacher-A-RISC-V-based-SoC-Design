`timescale 1ns / 1ps

module mock_memories_tb #(parameter XLEN = 64)();

// --- Testbench Signals ---
reg  clk;
reg  reset;
reg  DMEM_we;
reg  PMEM_cs;
reg  DMEM_cs;
reg  [XLEN-1:0] EIAB; // Assuming XLEN=32 for instantiation
wire [XLEN-1:0] EIB;
reg [XLEN-1:0] EMDB_out;
reg [XLEN-1:0] EMAB;
wire [XLEN-1:0] EMDB_in;

// --- Test Parameters ---
localparam CLOCK_PERIOD = 10; // 10ns for a 100MHz clock

// --- Instantiate the DUT (Device Under Test) ---
memories_top #(.XLEN(XLEN)) DUT (
    .clk      ( clk ),
    .reset    ( reset ),
    .DMEM_we       ( DMEM_we ),
    .PMEM_cs  ( PMEM_cs ),
    .DMEM_cs  ( DMEM_cs ),
    .EIAB     ( EIAB ),
    .EIB      ( EIB ),
    .EMDB_out  ( EMDB_out ),
    .EMAB     ( EMAB ),
    .EMDB_in ( EMDB_in )
    
);

// --- Clock Generation ---
initial begin
    clk = 0;
    forever #(CLOCK_PERIOD/2) clk = ~clk;
end

// --- Test Sequence (Main Stimulus) ---
initial begin
    // 1. Initial Reset and Setup
    #15;
    reset   = 0;
    DMEM_we      = 0;
    PMEM_cs = 1;
    DMEM_cs = 0;
    EIAB    = 32'h0;
    EMDB_out = 32'h0;
    EMAB    = 32'h0;
    $display("--- Starting Simulation ---");
    
    #10;
    EIAB    = 32'h00000004;
    
    #10;
    DMEM_we      = 0;
    PMEM_cs = 0;
    DMEM_cs = 1;
    EMDB_out = 32'hA700BB9F;
    EMAB    = 32'h0;
    
    #10;
    DMEM_we      = 1;
    
    #10;
    DMEM_we      = 0;
    PMEM_cs = 0;
    DMEM_cs = 1;
    EMDB_out = 32'h7D00AF8C;
    EMAB    = 32'h00000008;
    
    #10;
    DMEM_we      =1;
    
    #10;
    DMEM_we      = 0;
    PMEM_cs = 1;
    DMEM_cs = 1;
    EIAB    = 32'h00000008;
    EMAB    = 32'h00000008;
    
    #10;
    PMEM_cs = 0; // Deselect
    
    #100;
    $display("Writing DMEM to file...");
    $writememh("DMEM_result.mem", DUT.DMEM.memory); 
    //File is found afterwards in Vivado_Kreacher\Vivado_Kreacher.sim\sim_1\behav\xsim
    $display("Memory dumped to DMEM_result.mem");

    $display("--- Simulation Complete ---");
    $finish;
end


endmodule