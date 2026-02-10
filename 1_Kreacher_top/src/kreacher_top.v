module kreacher_top #(
    parameter ADDR_BYTE_W                 = 17,
    parameter ADDR_INIT_W                 = 16,
    parameter XLEN                        = 64,
    parameter IXLEN                       = 32,
    parameter [ADDR_BYTE_W-1:0] BASE_ADDR = 17'h00000,
    parameter [ADDR_BYTE_W-1:0] MEM_LIMIT = 17'h07FFF,
    parameter [ADDR_BYTE_W-1:0] INCR      = 17'd8,
    parameter BURST_LENGTH                = 16'd4096
)(
    input  I_CLK,
    input  I_A_RESET_L,

    output O_SS,
    output O_MOSI,
    input  O_MISO,
    input  [1:0] I_INTR_H,
    output [1:0] O_INTR_ACK
);

    // ---------------------------------------------------------------------
    // Space for pad instantiation
    // ---------------------------------------------------------------------
    wire clk;
    wire reset_n;
    
    wire spi_ss;
    wire spi_mosi;
    wire spi_miso;

    wire [1:0] intr_h;
    wire [1:0] intr_ack;

    //--Delete this when instantiating actual pads
    assign clk          = I_CLK;
    assign reset_n      = I_A_RESET_L;
    
    assign O_SS         = spi_ss;
    assign O_MOSI       = spi_mosi;
    assign spi_miso     = O_MISO;

    assign intr_h       = I_INTR_H;
    assign O_INTR_ACK   = intr_ack;

    //--Replace with:
    //pads pads_i (
    //    //From-To External
    //    .I_CLK        (I_CLK),
    //    .I_A_RESET_L  (I_A_RESET_L),
    //    
    //    .O_SS         (O_SS),
    //    .O_MOSI       (O_MOSI),
    //    .O_MISO       (O_MISO),
    //    
    //    .I_INTR_H     (I_INTR_H),
    //    .O_INTR_ACK   (O_INTR_ACK),
    //    
    //    //To-From Internal
    //    .clk          (clk),
    //    .reset_n      (reset_n),
    //    
    //    .ss           (spi_ss),
    //    .mosi         (spi_mosi),
    //    .miso         (spi_miso),
    //    
    //    .intr_h       (intr_h),
    //    .intr_ack     (intr_ack)        
    //);

    // ---------------------------------------------------------------------
    // Core signals
    // ---------------------------------------------------------------------
    wire EMCB;
    wire [XLEN-1:0] EMCB_mask;
    wire [XLEN-1:0] EMAB;
    wire [XLEN-1:0] EMDB_write;
    wire valid_data_read;
    wire valid_data_write;
    wire valid_instr_fetch;
    wire [ADDR_BYTE_W-1:0] EIAB;

    wire [XLEN-1:0] EMDB_read;
    wire pause_request_scheduler;
    wire pause_request_initialization;
    wire pause_request_load_store;
    wire pause_request_partial_store;
    wire [IXLEN-1:0] EIB;

    // ---------------------------------------------------------------------
    // Memory interface
    // ---------------------------------------------------------------------
    wire [XLEN-1:0]  data_read;
    wire [IXLEN-1:0] instruction_read;

    wire addr_data_valid;
    wire addr_inst_valid;
    wire [XLEN-1:0] inst_data_write;
    wire [ADDR_BYTE_W-1:0] data_read_write_adr;
    wire [ADDR_BYTE_W-1:0] inst_fetch_adr;
    wire is_write_PRAM;
    wire pause_to_schedule;
    wire [XLEN-1:0] init_internal_mask;

    // ---------------------------------------------------------------------
    // SPI interface
    // ---------------------------------------------------------------------
    wire rvalid;
    wire [XLEN-1:0] rdata;
    wire busy;
    wire done;
    wire start;
    wire is_write_SPI;
    wire [ADDR_BYTE_W-1:0] byte_addr;
    wire [ADDR_INIT_W-1:0] burst_len;
    wire [XLEN-1:0] wdata;
    wire init_abort;

    //---- Interrupt synchronization
    
    reg irq0_ff1, irq0_ff2;
    reg irq1_ff1, irq1_ff2;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            irq0_ff1 <= 1'b0;
            irq0_ff2 <= 1'b0;
            irq1_ff1 <= 1'b0;
            irq1_ff2 <= 1'b0;
        end else begin
            irq0_ff1 <= intr_h[0];//irq0
            irq0_ff2 <= irq0_ff1;
            irq1_ff1 <= intr_h[1];//irq1
            irq1_ff2 <= irq1_ff1;
        end
    end

    wire irq0_sync = irq0_ff2;
    wire irq1_sync = irq1_ff2;

    // ---------------------------------------------------------------------
    // Core
    // ---------------------------------------------------------------------
    core #(.XLEN(XLEN)) core_inst (
        .clk                (clk),
        .reset_n            (reset_n),
        .irq0_sync          (irq0_sync),
        .irq1_sync          (irq1_sync),
        .acknowledge_irq0   (intr_ack[0]),
        .acknowledge_irq1   (intr_ack[1]),
        .EMAB               (EMAB),
        .EMCB               (EMCB),
        .EMCB_mask          (EMCB_mask),
        .EMDB_out           (EMDB_write),
        .valid_instr_fetch  (valid_instr_fetch),
        .valid_data_read    (valid_data_read),
        .valid_data_write   (valid_data_write),
        .EMDB_in            (EMDB_read),
        .pause_request_scheduler(pause_request_scheduler),
        .pause_request_initialization(pause_request_initialization),
        .pause_request_load_store(pause_request_load_store),
        .pause_request_partial_store(pause_request_partial_store),
        .EIAB               (EIAB),
        .EIB                (EIB)
    );
    
    // ---------------------------------------------------------------------
    // Memory + Init Controller (REPLACED)
    // ---------------------------------------------------------------------
    init_memory_controller #(
        .ADDR_BYTE_W (ADDR_BYTE_W),
        .XLEN        (XLEN),
        .IXLEN       (IXLEN),
        .BURST_LENGTH (BURST_LENGTH)
    ) init_memory_controller_inst (
        .clk                 (clk),
        .reset_n             (reset_n),
        .interrupt           (irq0_sync),

        // Core interface
        .EMCB                (EMCB),
        .EMAB                (EMAB),
        .EMCB_mask           (EMCB_mask),
        .EMDB_write          (EMDB_write),
        .valid_instr_fetch   (valid_instr_fetch),
        .valid_data_read     (valid_data_read),
        .valid_data_write    (valid_data_write),
        .EIAB                (EIAB),

        .EMDB_read           (EMDB_read),
        .EIB                 (EIB),
        .pause_request_scheduler(pause_request_scheduler),
        .pause_request_initialization(pause_request_initialization),
        .pause_request_load_store(pause_request_load_store),
        .pause_request_partial_store(pause_request_partial_store),

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

        // PMEM interface
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

    // ---------------------------------------------------------------------
    // SPI master
    // ---------------------------------------------------------------------
    spi_master_interface #(
        .ADDR_BYTE_W (ADDR_BYTE_W),
        .DATA_W      (XLEN)
    ) spi_master_interface_inst (
        .I_CLK       (clk),
        .I_RSTN      (reset_n),

        .start       (start),
        .abort       (init_abort),
        .is_write    (is_write_SPI),
        .byte_addr   (byte_addr),
        .burst_len   (burst_len),

        .wdata       (wdata),
        .rdata       (rdata),
        .rvalid      (rvalid),
        .busy        (busy),
        .done        (done),

        .O_SS        (spi_ss),
        .O_MOSI      (spi_mosi),
        .I_MISO      (spi_miso)
    );

    // ---------------------------------------------------------------------
    // PMEM interface
    // ---------------------------------------------------------------------
    PMEM_interface_top #(
        .ADDR_BYTE_W (ADDR_BYTE_W),
        .XLEN        (XLEN),
        .IXLEN       (IXLEN)
    ) PMEM_interface_top_inst (
        .inst_data_write     (inst_data_write),
        .data_read_write_adr (data_read_write_adr),
        .addr_data_valid     (addr_data_valid),
        .inst_fetch_adr      (inst_fetch_adr),
        .addr_inst_valid     (addr_inst_valid),
        .is_write_PRAM       (is_write_PRAM),
        .data_read           (data_read),
        .instruction_read    (instruction_read),
        .pause_to_schedule   (pause_to_schedule),
        .init_internal_mask   (init_internal_mask),

        .clk                 (clk),
        .reset_n             (reset_n)
    );

endmodule
