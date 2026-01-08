`timescale 1ns/1ps
`include "MEMORY_CONSTANT.vh"

module tb_Memory_controller;

    // -------------------------
    // Parameters
    // -------------------------
    localparam ADDR_BYTE_W = 17;
    localparam XLEN       = 64; // Full data width
    localparam IXLEN      = 32; // Instruction width

    // -------------------------
    // Inputs
    // -------------------------
    reg [2:0] state;
    reg burst_dim;
    reg PRAM_in;
    reg PRAM_addr_type;
    reg SPI_rdata_type;
    reg ROM_addr_type;
    reg [ADDR_BYTE_W-1:0] INITIALIZATION_addr;
    reg mem_init;

    // Core interface
    reg EMCB;
    reg [ADDR_BYTE_W-1:0] EMAB;
    reg [XLEN-1:0] EMDB_write;
    reg [ADDR_BYTE_W-1:0] EIAB;

    // SPI interface
    reg rvalid;
    reg [XLEN-1:0] rdata;
    reg busy_done_SPI;

    // Memory interface
    reg [XLEN-1:0] data_read;
    reg [IXLEN-1:0] instruction_read;
    reg init_done;
    reg addr_data_valid_c;
    reg addr_inst_valid_c;

    // -------------------------
    // Outputs
    // -------------------------
    wire enable;
    wire mem_init_done;

    wire [XLEN-1:0] EMDB_read;
    wire pause_core;
    wire [IXLEN-1:0] EIB;

    wire start;
    wire is_write_SPI;
    wire [ADDR_BYTE_W-1:0] byte_addr;
    wire [ADDR_BYTE_W-1:0] burst_len;
    wire [XLEN-1:0] wdata;

    wire [XLEN-1:0] inst_data_write;
    wire [ADDR_BYTE_W-1:0] data_read_write_adr;
    wire [ADDR_BYTE_W-1:0] inst_fetch_adr;
    wire is_write_PRAM;
    
    wire addr_data_valid;
    wire addr_inst_valid;

    // -------------------------
    // DUT instantiation
    // -------------------------
    Memory_controller #(
        .ADDR_BYTE_W(ADDR_BYTE_W),
        .XLEN(XLEN),
        .IXLEN(IXLEN)
    ) dut (
        .state(state),
        .burst_dim(burst_dim),
        .PRAM_in(PRAM_in),
        .PRAM_addr_type(PRAM_addr_type),
        .SPI_rdata_type(SPI_rdata_type),
        .ROM_addr_type(ROM_addr_type),
        .INITIALIZATION_addr(INITIALIZATION_addr),
        .mem_init(mem_init),
        .enable(enable),
        .mem_init_done(mem_init_done),
        .EMCB(EMCB),
        .EMAB(EMAB),
        .EMDB_write(EMDB_write),
        .EMDB_read(EMDB_read),
        .pause_core(pause_core),
        .EIAB(EIAB),
        .EIB(EIB),
        .rvalid(rvalid),
        .rdata(rdata),
        .busy_done_SPI(busy_done_SPI),
        .start(start),
        .is_write_SPI(is_write_SPI),
        .byte_addr(byte_addr),
        .burst_len(burst_len),
        .wdata(wdata),
        .data_read(data_read),
        .instruction_read(instruction_read),
        .init_done(init_done),
        .inst_data_write(inst_data_write),
        .data_read_write_adr(data_read_write_adr),
        .inst_fetch_adr(inst_fetch_adr),
        .is_write_PRAM(is_write_PRAM),
        .addr_inst_valid(addr_inst_valid),
        .addr_inst_valid_c(addr_inst_valid_c),
        .addr_data_valid(addr_data_valid),
        .addr_data_valid_c(addr_data_valid_c)
    );

    // -------------------------
    // Clock generation (optional)
    // -------------------------
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz clock

    // -------------------------
    // Test sequence
    // -------------------------
    initial begin
        // Initialize inputs
        state               = 3'd1;
        burst_dim           = 1'b0;
        PRAM_in             = 1'b0;
        PRAM_addr_type      = 1'b0;
        SPI_rdata_type      = 1'b0;
        ROM_addr_type       = 1'b0;
        mem_init            = 1'b1;
        INITIALIZATION_addr = 0;

        EMCB       = 1'b0;
        EMAB       = 0;
        EMDB_write = 0;
        EIAB       = 0;

        rvalid        = 1'b0;
        busy_done_SPI = 1'b0;

        data_read        = 0;
        instruction_read = 0;
        init_done        = 1'b0;

        addr_data_valid_c = 0;
        addr_inst_valid_c = 0;

        #10;
        rdata = 64'hDEADBEEFCAFEBABE;
        busy_done_SPI = 1'b1;

        #20;
        init_done = 1'b1;

        // -------------------------
        // Test 1: Read from external memory
        // -------------------------
        #20;
        state               = 3'd1;
        burst_dim           = 1'b1;
        PRAM_in             = 1'b1;
        PRAM_addr_type      = 1'b1;
        SPI_rdata_type      = 1'b1;
        ROM_addr_type       = 1'b1;
        mem_init            = 1'b0;
        INITIALIZATION_addr = 0;
        EMAB                = 17'h8000;
        EMDB_write          = 64'd3;

        #20;
        rvalid        = 1'b1;
        busy_done_SPI = 1'b0;
        #10;
        $display("External memory read: EMDB_read=%h, rvalid=%b, pause_core=%b", EMDB_read, rvalid, pause_core);

        // -------------------------
        // Test 2: External write
        // -------------------------
        EMDB_write = 64'h11223344_55667788;
        EMCB       = 1'b1;
        rvalid     = 1'b0;
        busy_done_SPI = 1'b1;
        #10;
        $display("External write: wdata=%h, start=%b, byte_addr=%h", wdata, start, byte_addr);

        // -------------------------
        // Test 3: Internal write
        // -------------------------
        #20;
        EMAB       = 17'h0008;
        rvalid     = 1'b0;
        busy_done_SPI = 1'b0;
        #10;
        $display("Internal write: addr=%h, is_write_PRAM=%b", data_read_write_adr, is_write_PRAM);

        // -------------------------
        // Test 4: Internal read
        // -------------------------
        #20;
        EMCB       = 1'b0;
        data_read  = 64'd4;
        #10;
        $display("Internal read: EMDB_read=%h", EMDB_read);

        // -------------------------
        // Test 5: Instruction fetch
        // -------------------------
        #10;
        EIAB               = 16'd6;
        addr_inst_valid_c  = 1'b1;
        instruction_read   = 32'd15;
        #10;
        $display("Instruction fetch: inst_fetch_adr=%h, valid=%b, EIB=%h", inst_fetch_adr, addr_inst_valid, EIB);

        // -------------------------
        // Test 6: Instantiation test
        // -------------------------
        #10;
        state = 3'd1;
        #10;
        $display("Start signal=%b", start);

        // -------------------------
        // Test 7: PRAM writing during initialization
        // -------------------------
        #10;
        state               = 3'd2;
        burst_dim           = 1'b0;
        PRAM_in             = 1'b0;
        PRAM_addr_type      = 1'b0;
        SPI_rdata_type      = 1'b0;
        ROM_addr_type       = 1'b0;
        mem_init            = 1'b1;
        INITIALIZATION_addr = 16'd5;
        rvalid              = 1'b0;
        busy_done_SPI       = 1'b1;
        #20;
        rvalid              = 1'b1;
        busy_done_SPI       = 1'b0;
        INITIALIZATION_addr = 16'd10;
        #10;
        $display("PRAM write during initialization: is_write_PRAM=%b, int_data_write=%h, addr=%h", is_write_PRAM, inst_data_write, data_read_write_adr);

        #10;
        $finish;
    end

endmodule
