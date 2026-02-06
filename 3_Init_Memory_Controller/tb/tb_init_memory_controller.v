`timescale 1ns/1ps

module tb_init_memory_controller;

    // -----------------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------------
    localparam ADDR_BYTE_W = 17;
    localparam XLEN        = 64;
    localparam IXLEN       = 32;
    localparam BURST_LEN   = 16'd1024;

    // -----------------------------------------------------------------
    // Clock / Reset
    // -----------------------------------------------------------------
    reg clk;
    reg reset_n;

    always #5 clk = ~clk;   // 100 MHz clock

    // -----------------------------------------------------------------
    // Core interface
    // -----------------------------------------------------------------
    reg                  EMCB;
    reg  [ADDR_BYTE_W-1:0] EMAB;
    reg                  external_access;
    reg  [XLEN-1:0]       EMDB_write;
    reg                  valid_instr_fetch;
    reg                  valid_data_read;
    reg                  valid_data_write;
    reg  [ADDR_BYTE_W-1:0] EIAB;
    reg  [XLEN-1:0]       EMCB_mask;

    wire [XLEN-1:0]       EMDB_read;
    wire [IXLEN-1:0]      EIB;
    wire                  pause_request_scheduler;
    wire                  pause_request_initialization;
    wire                  pause_request_load_store;

    // -----------------------------------------------------------------
    // SPI interface
    // -----------------------------------------------------------------
    reg                  rvalid;
    reg  [XLEN-1:0]      rdata;
    reg                  busy;
    reg                  done;

    wire                 spi_start;
    wire                 is_write_SPI;
    wire [ADDR_BYTE_W-1:0] byte_addr;
    wire [ADDR_BYTE_W-1:0] burst_len;
    wire [XLEN-1:0]       wdata;

    // -----------------------------------------------------------------
    // PMEM / ROM interface
    // -----------------------------------------------------------------
    reg  [XLEN-1:0]       data_read;
    reg  [IXLEN-1:0]      instruction_read;
    reg                  pause_to_schedule;

    wire                 addr_data_valid;
    wire                 addr_inst_valid;
    wire [XLEN-1:0]       inst_data_write;
    wire [ADDR_BYTE_W-1:0] data_read_write_adr;
    wire [ADDR_BYTE_W-1:0] inst_fetch_adr;
    wire                 is_write_PRAM;

    // -----------------------------------------------------------------
    // DUT
    // -----------------------------------------------------------------
    init_memory_controller #(
        .ADDR_BYTE_W (ADDR_BYTE_W),
        .XLEN        (XLEN),
        .IXLEN       (IXLEN),
        .BURST_LEN   (BURST_LEN)
    ) dut (
        .clk                         (clk),
        .reset_n                     (reset_n),

        .EMCB                        (EMCB),
        .EMAB                        (EMAB),
        .external_access             (external_access),
        .EMDB_write                  (EMDB_write),
        .valid_instr_fetch           (valid_instr_fetch),
        .valid_data_read             (valid_data_read),
        .valid_data_write            (valid_data_write),
        .EIAB                        (EIAB),
        .EMCB_mask                   (EMCB_mask),
        .EMDB_read                   (EMDB_read),
        .EIB                         (EIB),
        .pause_request_scheduler     (pause_request_scheduler),
        .pause_request_initialization(pause_request_initialization),
        .pause_request_load_store    (pause_request_load_store),

        .rvalid                      (rvalid),
        .rdata                       (rdata),
        .busy                        (busy),
        .done                        (done),

        .spi_start                   (spi_start),
        .is_write_SPI                (is_write_SPI),
        .byte_addr                   (byte_addr),
        .burst_len                   (burst_len),
        .wdata                       (wdata),

        .data_read                   (data_read),
        .instruction_read            (instruction_read),
        .pause_to_schedule           (pause_to_schedule),

        .addr_data_valid             (addr_data_valid),
        .addr_inst_valid             (addr_inst_valid),
        .inst_data_write             (inst_data_write),
        .data_read_write_adr         (data_read_write_adr),
        .inst_fetch_adr              (inst_fetch_adr),
        .is_write_PRAM               (is_write_PRAM)
    );

    // -----------------------------------------------------------------
    // Stimulus
    // -----------------------------------------------------------------
    initial begin
        // -------------------------------
        // Initial values @ #0
        // -------------------------------
        clk                  = 0;
        reset_n              = 0;

        EMCB                 = 0;
        EMAB                 = 0;
        EMCB_mask            = 0;
        EMDB_write           = 0;
        external_access      = 0;
        valid_instr_fetch    = 0;
        valid_data_read      = 0;
        valid_data_write     = 0;
        EIAB                 = 0;

        rvalid               = 0;
        rdata                = 0;
        busy                 = 0;
        done                 = 0;

        data_read            = 0;
        instruction_read     = 0;
        pause_to_schedule    = 0;

        // -------------------------------
        // Release reset
        // -------------------------------
        #20;
        reset_n = 1;

        // -------------------------------
        // #50 : Data write request
        // -------------------------------
        #30;
        EMAB             = 64'd8;
        EMCB             = 1'b1;
        EMDB_write       = 64'hFFFF_FFFF_FFFF_FFFF;
        EMCB_mask        = 64'hF0F0_F0F0_F0F0_F0F0;
        valid_data_write = 1'b1;

        // -------------------------------
        // After one clock → SPI busy
        // -------------------------------
        @(posedge clk);
        busy = 1'b1;

        // -------------------------------
        // After N clocks → SPI fetch done
        // -------------------------------
        repeat (4) @(posedge clk);
        busy   = 1'b0;
        done   = 1'b1;
        rvalid = 1'b1;
        rdata  = 64'h8888_8888_8888_8888;

        @(posedge clk);
        done   = 1'b0;
        rvalid = 1'b0;

        // -------------------------------
        // Busy again (partial write stall)
        // -------------------------------
        repeat (3) @(posedge clk);
        busy = 1'b1;

        repeat (2) @(posedge clk);
        busy = 1'b0;

        // -------------------------------
        // End simulation
        // -------------------------------
        #50;
        $finish;
    end

endmodule
