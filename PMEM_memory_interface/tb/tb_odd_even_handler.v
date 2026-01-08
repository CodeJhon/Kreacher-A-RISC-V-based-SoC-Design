`timescale 1ns/1ps

module tb_odd_even_handler;

    // -------------------------
    // Parameters
    // -------------------------
    localparam IXLEN = 32;      // Instruction width
    localparam XLEN  = 64;      // Full data width
    localparam ADDR_BYTE_W = 17;

    // -------------------------
    // DUT inputs
    // -------------------------
    reg  [XLEN-1:0]        data_in;
    reg  [ADDR_BYTE_W-1:0] addr_handler;
    reg  addr_data_valid;
    reg  addr_inst_valid;
    reg  we0, we1;
    reg  cs0, cs1;

    reg  [IXLEN-1:0]       data_out_even;
    reg  [IXLEN-1:0]       data_out_odd;
    reg  write_done_even, write_done_odd;
    reg  read_done_even, read_done_odd;

    // -------------------------
    // DUT outputs
    // -------------------------
    wire [IXLEN-1:0]       inst_out;
    wire write_done;
    wire read_done;
    wire [XLEN-1:0]        data_out;

    wire [IXLEN-1:0]       data_in_even;
    wire [IXLEN-1:0]       data_in_odd;
    wire [9:0]             addr;
    wire cs_even, cs_odd;
    wire we_even, we_odd;

    // -------------------------
    // DUT instantiation
    // -------------------------
    odd_even_handler #(
        .IXLEN(IXLEN),
        .XLEN(XLEN),
        .ADDR_BYTE_W(ADDR_BYTE_W)
    ) dut (
        .data_in(data_in),
        .addr_handler(addr_handler),
        .addr_data_valid(addr_data_valid),
        .addr_inst_valid(addr_inst_valid),
        .inst_out(inst_out),
        .we0(we0),
        .we1(we1),
        .cs0(cs0),
        .cs1(cs1),
        .write_done(write_done),
        .read_done(read_done),
        .data_out(data_out),

        .data_out_even(data_out_even),
        .data_out_odd(data_out_odd),
        .write_done_odd(write_done_odd),
        .write_done_even(write_done_even),
        .read_done_odd(read_done_odd),
        .read_done_even(read_done_even),
        .data_in_even(data_in_even),
        .data_in_odd(data_in_odd),
        .addr(addr),
        .cs_even(cs_even),
        .cs_odd(cs_odd),
        .we_even(we_even),
        .we_odd(we_odd)
    );

    // -------------------------
    // Test sequence
    // -------------------------
    initial begin
        // Default signal values
        data_in        = 64'h0;
        addr_handler   = 0;
        addr_data_valid = 0;
        addr_inst_valid = 0;
        we0 = 0; we1 = 0;
        cs0 = 0; cs1 = 0;

        data_out_even = 32'hAAAA_AAAA;
        data_out_odd  = 32'hBBBB_BBBB;
        write_done_even = 0;
        write_done_odd  = 0;
        read_done_even  = 0;
        read_done_odd   = 0;

        #10;

        // -------------------------
        // TEST 1: Data write (both macros enabled)
        // -------------------------
        data_in        = 64'h11223344_55667788;
        addr_data_valid = 1;
        cs0 = 1; cs1 = 1;
        we0 = 1; we1 = 1;

        #10;
        $display("TEST1 DATA WRITE");
        $display(" data_in_even=%h data_in_odd=%h", data_in_even, data_in_odd);
        $display(" cs_even=%b cs_odd=%b we_even=%b we_odd=%b", cs_even, cs_odd, we_even, we_odd);

        addr_data_valid = 0;
        cs0 = 0; cs1 = 0;
        we0 = 0; we1 = 0;

        // -------------------------
        // TEST 2: Instruction read EVEN (addr[2]=0)
        // -------------------------
        addr_handler   = 17'b0;
        addr_inst_valid = 1;
        cs0 = 1;
        read_done_even = 1;

        #10;
        $display("TEST2 INST EVEN inst_out=%h read_done=%b", inst_out, read_done);

        addr_inst_valid = 0;
        cs0 = 0;
        read_done_even = 0;

        // -------------------------
        // TEST 3: Instruction read ODD (addr[2]=1)
        // -------------------------
        addr_handler    = 17'b00000000000000100; // bit[2]=1
        addr_inst_valid = 1;
        cs1 = 1;
        read_done_odd   = 1;

        #10;
        $display("TEST3 INST ODD inst_out=%h read_done=%b", inst_out, read_done);

        addr_inst_valid = 0;
        cs1 = 0;
        read_done_odd   = 0;

        // -------------------------
        // TEST 4: Data read (both macros)
        // -------------------------
        addr_data_valid = 1;
        read_done_even = 1;
        read_done_odd  = 1;

        #10;
        $display("TEST4 DATA READ data_out=%h read_done=%b", data_out, read_done);

        addr_data_valid = 0;
        read_done_even = 0;
        read_done_odd  = 0;

        // -------------------------
        // TEST 5: Write done aggregation
        // -------------------------
        write_done_even = 1;
        write_done_odd  = 1;

        #10;
        $display("TEST5 WRITE_DONE write_done=%b", write_done);

        write_done_even = 0;
        write_done_odd  = 0;

        #20;
        $display("ODD_EVEN_HANDLER TEST COMPLETED");
        $finish;
    end

endmodule
