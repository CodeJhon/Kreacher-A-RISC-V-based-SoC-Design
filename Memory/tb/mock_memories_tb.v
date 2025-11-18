`timescale 1ns / 1ps

module mock_memories_tb #(parameter XLEN = 32)();

// --- Testbench Signals ---
reg  clk;
reg  reset;
reg  we;
reg  PMEM_cs;
reg  [XLEN-1:0] EIAB; // Assuming XLEN=32 for instantiation
wire [XLEN-1:0] EIB;

// --- Test Parameters ---
localparam CLOCK_PERIOD = 10; // 10ns for a 100MHz clock

// --- Instantiate the DUT (Device Under Test) ---
memories_top #(.XLEN(XLEN)) DUT (
    .clk      ( clk ),
    .reset    ( reset ),
    .PMEM_cs  ( PMEM_cs ),
    .EIAB     ( EIAB ),
    .EIB      ( EIB )
);

// --- Clock Generation ---
initial begin
    clk = 0;
    forever #(CLOCK_PERIOD/2) clk = ~clk;
end

// --- Test Sequence (Main Stimulus) ---
initial begin
    // 1. Initial Reset and Setup
    reset   = 0;
    we      = 0;
    PMEM_cs = 1;
    EIAB    = 32'h0;
    $display("--- Starting Simulation ---");
    
    #10;
    EIAB    = 32'd4;
    #10;
    EIAB    = 32'd8;
    
    // 6. Finish Simulation
    @(posedge clk);
    PMEM_cs = 0; // Deselect
    $display("--- Simulation Complete ---");
    $finish;
end


endmodule