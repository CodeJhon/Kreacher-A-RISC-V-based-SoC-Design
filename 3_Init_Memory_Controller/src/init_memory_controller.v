`timescale 1ns/1ps
`include "INIT_MEM_CONSTANTS.vh"

module init_memory_controller #(
    parameter ADDR_BYTE_W = 17,
    parameter ADDR_INIT_W = 16,
    parameter XLEN        = 64,
    parameter IXLEN       = 32,
    parameter BURST_LENGTH   = 16'd4096
)(
    // -----------------------------------------------------------------
    // Global
    // -----------------------------------------------------------------
    input  wire                 clk,
    input  wire                 reset_n,
    input  wire                 interrupt,

    // -----------------------------------------------------------------
    // Core interface  (EXACT mirror of Memory_controller)
    // -----------------------------------------------------------------
    input  wire                 EMCB,
    input  wire [XLEN-1:0]      EMAB,
    input  wire [XLEN-1:0]      EMDB_write,
    input  wire                 valid_instr_fetch,
    input  wire                 valid_data_read,
    input  wire                 valid_data_write,
    input  wire [ADDR_BYTE_W-1:0] EIAB,

    input  wire [XLEN-1:0]       EMCB_mask,
    output wire [XLEN-1:0]       EMDB_read,
    output wire [IXLEN-1:0]      EIB,
    output wire                  pause_request_scheduler,
    output wire                  pause_request_initialization,
    output wire                  pause_request_load_store,
    output wire                  pause_request_partial_store,

    // -----------------------------------------------------------------
    // SPI interface
    // -----------------------------------------------------------------
    input  wire                 rvalid,
    input  wire [XLEN-1:0]      rdata,
    input  wire                 busy,
    input  wire                 done,

    output wire                 start,
    output wire                 is_write_SPI,
    output wire [ADDR_BYTE_W-1:0] byte_addr,
    output wire [ADDR_INIT_W-1:0] burst_len,
    output wire [XLEN-1:0]       wdata,
    output wire                  init_abort,
    
    // -----------------------------------------------------------------
    // PMEM / ROM memory interface
    // -----------------------------------------------------------------
    input  wire [XLEN-1:0]        data_read,
    input  wire [IXLEN-1:0]       instruction_read,
    input  wire                   pause_to_schedule,

    output wire                   addr_data_valid,
    output wire                   addr_inst_valid,
    output wire [XLEN-1:0]        inst_data_write,
    output wire [ADDR_BYTE_W-1:0] data_read_write_adr,
    output wire [ADDR_BYTE_W-1:0] inst_fetch_adr,
    output wire                   is_write_PRAM,
    output wire [XLEN-1:0]        init_internal_mask
);

    // =========================================================================
    // Internal wires between init_ctrl and Memory_controller
    // =========================================================================
    wire [3:0] state;
    wire burst_dim;
    wire PRAM_in;
    wire PRAM_addr_type;
    wire [1:0] SPI_rdata_type;
    wire ROM_addr_type;
    wire [ADDR_BYTE_W-1:0] INITIALIZATION_addr;
    wire mem_init;
    wire pre_fetch;
    wire enable;
    wire partial_read_done;
    wire partial_write_done;
    wire write_state;
    wire [1:0]write_enable_state;
    wire masking_enabled;
    wire zero;

    assign zero = 1'b0;

    // =========================================================================
    // Init controller (internal only)
    // =========================================================================
    init_ctrl #(
        .ADDR_W (ADDR_BYTE_W)
    ) u_init_ctrl (
        .clk                 (clk),
        .reset_n             (reset_n),

        .interrupt           (interrupt),    
        .enable              (enable),
        .masking_enabled     (masking_enabled),
        .partial_read_done   (partial_read_done),
        .partial_write_done  (partial_write_done),

        .state               (state),

        .SPI_rdata_type      (SPI_rdata_type),
        .PRAM_addr_type      (PRAM_addr_type),
        .PRAM_in             (PRAM_in),
        .burst_dim           (burst_dim),
        .ROM_addr_type       (ROM_addr_type),
        .mem_init            (mem_init),
        .pre_fetch           (pre_fetch),
        .write_enable_state  (write_enable_state),
        .write_state         (write_state),

        .INITIALIZATION_addr (INITIALIZATION_addr)
    );

    // =========================================================================
    // Memory Controller (main datapath)
    // =========================================================================
    Memory_controller #(
        .ADDR_BYTE_W    (ADDR_BYTE_W),
        .ADDR_INIT_W    (ADDR_INIT_W),
        .XLEN           (XLEN),
        .IXLEN          (IXLEN),
        .BURST_LENGTH   (BURST_LENGTH)
    ) u_mem_ctrl (
        .clk                 (clk),
        .reset_n             (reset_n),
        // Init controller interface
        .interrupt           (interrupt), 
        .state               (state),
        .burst_dim           (burst_dim),
        .PRAM_in             (PRAM_in),
        .PRAM_addr_type      (PRAM_addr_type),
        .SPI_rdata_type      (SPI_rdata_type),
        .ROM_addr_type       (ROM_addr_type),
        .INITIALIZATION_addr (INITIALIZATION_addr),
        .mem_init            (mem_init),
        .pre_fetch           (pre_fetch),
        .enable              (enable),
        .masking_enabled     (masking_enabled),
        .partial_read_done   (partial_read_done),
        .partial_write_done  (partial_write_done),
        .write_enable_state  (write_enable_state),
        .write_state         (write_state),

        // Core interface
        .EMCB                (EMCB),
        .EMAB                (EMAB),
        .EMCB_mask           (EMCB_mask),
        .EMDB_write          (EMDB_write),
        .valid_instr_fetch   (valid_instr_fetch),
        .valid_data_read     (valid_data_read),
        .valid_data_write    (valid_data_write),
        .EMDB_read           (EMDB_read),
        .pause_request_scheduler(pause_request_scheduler),
        .pause_request_initialization(pause_request_initialization),
        .pause_request_load_store(pause_request_load_store),
        .pause_request_partial_store(pause_request_partial_store),

        // Instruction interface
        .EIAB                (EIAB),
        .EIB                 (EIB),

        // SPI interface
        .rvalid              (rvalid),
        .rdata               (rdata),
        .busy                (busy),
        .done                (done),
        .start               (start),
        .is_write_SPI        (is_write_SPI),
        .byte_addr           (byte_addr),
        .burst_len           (burst_len),
        .wdata               (wdata),
        .init_abort          (init_abort),

        // PMEM / ROM interface
        .data_read           (data_read),
        .instruction_read    (instruction_read),
        .addr_data_valid     (addr_data_valid),
        .addr_inst_valid     (addr_inst_valid),
        .inst_data_write     (inst_data_write),
        .data_read_write_adr (data_read_write_adr),
        .inst_fetch_adr      (inst_fetch_adr),
        .is_write_PRAM       (is_write_PRAM),
        .pause_to_schedule   (pause_to_schedule),
        .init_internal_mask  (init_internal_mask)
    );

endmodule
