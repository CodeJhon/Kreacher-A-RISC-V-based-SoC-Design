`timescale 1ns/1ps

module tb_PRAM;

    // -------------------------
    // Parameters
    // -------------------------
    localparam IXLEN = 32;   // Data width
    localparam DEPTH = 1024; // Number of words

    // -------------------------
    // DUT signals
    // -------------------------
    reg clk;
    reg reset;
    reg we;
    reg cs;
    reg [IXLEN-1:0] data_in;
    reg [9:0] addr;

    wire [IXLEN-1:0] data_out;
    wire read_done;
    wire write_done;

    // -------------------------
    // DUT instantiation
    // -------------------------
    PRAM #(
        .IXLEN(IXLEN),
        .WORDS(DEPTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .we(we),
        .cs(cs),
        .data_in(data_in),
        .addr(addr),
        .data_out(data_out),
        .read_done(read_done),
        .write_done(write_done)
    );

    // -------------------------
    // Clock generation
    // -------------------------
    initial clk = 0;
    always #5 clk = ~clk;   // 100 MHz

    // -------------------------
    // Test sequence
    // -------------------------
    initial begin
        // Initialize
        reset = 1;
        we = 0;
        cs = 0;
        data_in = 0;
        addr = 0;

        // Hold reset
        #20;
        reset = 0;

        // -------------------------
        // TEST 1: Write data
        // -------------------------
        @(negedge clk);
        cs = 1;
        we = 1;
        addr = 10'd10;
        data_in = 32'hDEADBEEF;

        @(posedge clk);
        #1;
        $display("TEST1 WRITE_DONE=%b (expect 1)", write_done);

        // -------------------------
        // TEST 2: Read data back
        // -------------------------
        @(negedge clk);
        we = 0;
        cs = 1;
        addr = 10'd10;

        @(posedge clk);
        #1;
        $display("TEST2 READ_DONE=%b DATA_OUT=%h (expect DEADBEEF)", read_done, data_out);

        // -------------------------
        // TEST 3: CS low (no access)
        // -------------------------
        @(negedge clk);
        cs = 0;
        we = 0;
        addr = 10'd10;

        @(posedge clk);
        #1;
        $display("TEST3 CS_LOW READ_DONE=%b WRITE_DONE=%b (expect 0)", read_done, write_done);

        // -------------------------
        // TEST 4: Boundary check
        // -------------------------
        @(negedge clk);
        cs = 1;
        we = 1;
        addr = DEPTH - 3;   // Should be ignored
        data_in = 32'hAAAAAAAA;

        @(posedge clk);
        #1;
        $display("TEST4 BOUNDARY WRITE_DONE=%b (expect 0)", write_done);

        // -------------------------
        // TEST 5: Reset clears memory
        // -------------------------
        reset = 1;
        #10;
        reset = 0;

        @(negedge clk);
        cs = 1;
        we = 0;
        addr = 10'd10;

        @(posedge clk);
        #1;
        $display("TEST5 AFTER RESET READ DATA=%h (expect 0)", data_out);

        // -------------------------
        // END OF TEST
        // -------------------------
        #20;
        $display("PRAM TESTBENCH COMPLETED");
        $finish;
    end

endmodule
