module core_and_mem #(parameter XLEN = 64)(    
    //Global
    input clk,
    input reset_n,

    // Interrupt pins
    input irq0,       
    input irq1,

    output acknowledge_irq0,
    output acknowledge_irq1

);

// ------------------------------------------------ Buses
//PMEM
wire [31:0]     EIB;  //External Instruction Bus
wire [16:0]     EIAB;  //External Instruction Address Bus
//DMEM
wire [XLEN-1:0] EMAB;            //External Memory Address Bus
wire            EMCB;            //External Memory Control Bus
wire [XLEN-1:0] EMDB_out;        //External Memory Data Bus, output for the core, input for the external memory
wire [XLEN-1:0] EMDB_in;         //External Memory Data Bus, input for the core, output for the external memory

// Synchronization of interrupt pins

reg irq0_ff1, irq0_ff2;
reg irq1_ff1, irq1_ff2;

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        irq0_ff1 <= 1'b0;
        irq0_ff2 <= 1'b0;
        irq1_ff1 <= 1'b0;
        irq1_ff2 <= 1'b0;
    end else begin
        irq0_ff1 <= irq0;
        irq0_ff2 <= irq0_ff1;
        irq1_ff1 <= irq1;
        irq1_ff2 <= irq1_ff1;
    end
end

assign irq0_sync = irq0_ff2;
assign irq1_sync = irq1_ff2;

wire valid_instr_fetch;

core #(.XLEN(XLEN)) core_inst (
    .clk(clk), 
    .reset_n(reset_n),
    
    //Control
    .pause_core(1'b0),

    // Interrupt pins (synchronous)
    .irq0_sync(irq0_sync),
    .irq1_sync(irq1_sync),

    .acknowledge_irq0(acknowledge_irq0),
    .acknowledge_irq1(acknowledge_irq1),

    //PMEM signals
    .EIB(EIB),
    .EIAB(EIAB),
    .valid_instr_fetch(valid_instr_fetch),

    //DMEM signals
    .EMAB(EMAB),
    .EMCB(EMCB),
    .EMDB_out(EMDB_out),
    .EMDB_in(EMDB_in)

);

RAM #( .ADDR_LINES(17),
        .WORDS(10240), 
        .FILE_LOAD(1),
        .ROW_WIDTH(32),
        .MEM_FILE("PMEM_content.mem")
) program_memory (
    
    .clk(clk),
    .we(1'b0),
    .cs(valid_instr_fetch),
    .data_in(),
    .addr({2'b00, EIAB[16:2]}),
    .data_out(EIB)
);

RAM #( .ADDR_LINES(14),
        .WORDS  (8192),
        .FILE_LOAD(1),
        .ROW_WIDTH(64),
        .MEM_FILE("DMEM_content.mem")
       ) external_memory (
    
    .clk(clk),
    .we(EMCB),
    .cs(1'b1),
    .data_in(EMDB_out),
    .addr(EMAB[16:0]),
    .data_out(EMDB_in)
);



endmodule