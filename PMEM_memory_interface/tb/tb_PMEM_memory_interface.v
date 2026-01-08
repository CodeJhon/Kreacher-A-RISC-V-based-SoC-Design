`timescale 1ns/1ps
`include "MEMORY_CONSTANT.vh"

module tb_PMEM_memory_interface;

    // -------------------------
    // Parameters
    // -------------------------
    localparam IXLEN = 32;      // Instruction width
    localparam XLEN  = 64;      // Full data width
    localparam ADDR_BYTE_W = 17;

    // -------------------------
    // DUT signals
    // -------------------------
    reg  [XLEN-1:0] inst_data_write;
    reg  [ADDR_BYTE_W-1:0] data_read_write_adr;
    reg  addr_data_valid;
    reg  [ADDR_BYTE_W-1:0] inst_fetch_adr;
    reg  addr_inst_valid;
    reg  is_write_PRAM;
    reg  mem_init_m;

    wire [XLEN-1:0] data_read;
    wire [IXLEN-1:0] instruction_read;
    wire init_done;

    reg  [XLEN-1:0] data_out1;
    reg  [IXLEN-1:0] inst_out1;
    reg  write_done;

    wire [XLEN-1:0] data_in;
    wire [ADDR_BYTE_W-1:0] addr_handler1;
    wire cs_0, cs_1;
    wire we_0, we_1;

    // -------------------------
    // DUT instantiation
    // -------------------------
    PMEM_memory_interface #(
        .XLEN(XLEN),
        .IXLEN(IXLEN),
        .ADDR_BYTE_W(ADDR_BYTE_W)
    ) dut (
        .inst_data_write(inst_data_write),
        .data_read_write_adr(data_read_write_adr),
        .addr_data_valid(addr_data_valid),
        .inst_fetch_adr(inst_fetch_adr),
        .addr_inst_valid(addr_inst_valid),
        .is_write_PRAM(is_write_PRAM),
        .mem_init_m(mem_init_m),
        .data_read(data_read),
        .instruction_read(instruction_read),
        .init_done(init_done),
        .data_out1(data_out1),
        .inst_out1(inst_out1),
        .write_done(write_done),
        .data_in(data_in),
        .addr_handler1(addr_handler1),
        .cs_0(cs_0),
        .cs_1(cs_1),
        .we_0(we_0),
        .we_1(we_1)
    );

    // -------------------------
    // Test sequence
    // -------------------------
    initial begin
        // Default signal values
        inst_data_write     = 0;
        data_read_write_adr = 0;
        inst_fetch_adr      = 0;
        addr_data_valid     = 0;
        addr_inst_valid     = 0;
        is_write_PRAM       = 0;
        mem_init_m          = 0;
        data_out1           = 64'hDEADBEEFCAFEBABE;
        inst_out1           = 32'h12345678;
        write_done          = 0;

        #10;

        // -------------------------
        // TEST 1: Instruction fetch only
        // -------------------------
        inst_fetch_adr  = 17'h1000;
        addr_inst_valid = 1;
        #10;
        $display("TEST1 INST_ONLY addr_handler1 = %h", addr_handler1);
        addr_inst_valid = 0;

        // -------------------------
        // TEST 2: Data access only
        // -------------------------
        data_read_write_adr = 17'h2004;
        addr_data_valid     = 1;
        #10;
        $display("TEST2 DATA_ONLY addr_handler1 = %h", addr_handler1);
        addr_data_valid = 0;

        // -------------------------
        // TEST 3: Both valid (DATA has priority)
        // -------------------------
        inst_fetch_adr      = 17'h3000;
        data_read_write_adr = 17'h4000;
        addr_inst_valid     = 1;
        addr_data_valid     = 1;
        #10;
        $display("TEST3 BOTH_VALID addr_handler1 = %h (should be DATA)", addr_handler1);
        addr_inst_valid = 0;
        addr_data_valid = 0;

        // -------------------------
        // TEST 4: Write enable + chip select
        // -------------------------
        data_read_write_adr = 17'h1FC0;
        addr_data_valid     = 1;
        is_write_PRAM       = 1;
        #10;
        $display("TEST4 cs_0=%b cs_1=%b we_0=%b we_1=%b", cs_0, cs_1, we_0, we_1);
        addr_data_valid = 0;
        is_write_PRAM   = 0;

        // -------------------------
        // TEST 5: init_done condition
        // -------------------------
        data_read_write_adr = 17'h02FF7;
        mem_init_m          = 1;
        write_done          = 1;
        #10;
        $display("TEST5 init_done = %b", init_done);

        // -------------------------
        // END OF TEST
        // -------------------------
        #20;
        $display("TESTBENCH COMPLETED");
        $finish;
    end

endmodule
