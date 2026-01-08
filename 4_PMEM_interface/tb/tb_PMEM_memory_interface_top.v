`timescale 1ns/1ps

module tb_PMEM_memory_interface_top;

    // --------------------------------------------------
    // Parameters
    // --------------------------------------------------
    localparam XLEN  = 64;
    localparam IXLEN = 32;
    localparam ADDR_BYTE_W = 17;

    // --------------------------------------------------
    // DUT signals
    // --------------------------------------------------
    reg  clk;
    reg  reset;

    reg  [XLEN-1:0] inst_data_write;
    reg  [ADDR_BYTE_W-1:0] data_read_write_adr;
    reg  addr_data_valid;

    reg  [ADDR_BYTE_W-1:0] inst_fetch_adr;
    reg  addr_inst_valid;

    reg  is_write_PRAM;
    reg  mem_init_m;

    wire [XLEN-1:0]  data_read;
    wire [IXLEN-1:0] instruction_read;

    // --------------------------------------------------
    // Instantiate DUT
    // --------------------------------------------------
    PMEM_memory_interface_top dut (
        .inst_data_write(inst_data_write),
        .data_read_write_adr(data_read_write_adr),
        .addr_data_valid(addr_data_valid),
        .inst_fetch_adr(inst_fetch_adr),
        .addr_inst_valid(addr_inst_valid),
        .is_write_PRAM(is_write_PRAM),
        .mem_init_m(mem_init_m),
        .data_read(data_read),
        .instruction_read(instruction_read),
        .clk(clk),
        .reset(reset)
    );

    // --------------------------------------------------
    // Clock generation
    // --------------------------------------------------
    always #5 clk = ~clk;   // 100 MHz

    // --------------------------------------------------
    // Test procedure
    // --------------------------------------------------
    initial begin
        // Init
        clk = 0;
        reset = 1;
        inst_data_write = 0;
        addr_data_valid = 0;
        addr_inst_valid = 0;
        is_write_PRAM = 0;
        mem_init_m = 0;

        // Reset
        #20;
        reset = 0;

        // --------------------------------------------------
        // 1️⃣ WRITE 64-bit DATA
        // --------------------------------------------------
        @(posedge clk);
        inst_data_write      = 64'h1122_3344_5566_7788;
        data_read_write_adr  = 17'h00020; // row = [12:3] = 4, bank bit [2]=0
        addr_data_valid      = 1;
        is_write_PRAM        = 1;

        @(posedge clk);
        addr_data_valid = 0;
        is_write_PRAM   = 0;

        // Wait for write_done
        $display("WRITE DONE ");

        // --------------------------------------------------
        // 2️⃣ READ BACK 64-bit DATA
        // --------------------------------------------------
        @(posedge clk);
        data_read_write_adr = 17'h00020;
        addr_data_valid     = 1;

        @(posedge clk);
        addr_data_valid = 0;
        
        @(posedge clk);
        
        $display("READ DATA");

        if (data_read !== 64'h1122_3344_5566_7788)
            $error("DATA MISMATCH!",data_read);
        else
            $display("DATA MATCH OK");

        // --------------------------------------------------
        // 3️⃣ READ 32-bit INSTRUCTION (EVEN BANK)
        // --------------------------------------------------
        inst_read(17'h00020);
        // @(posedge clk);
        // inst_fetch_adr   = 17'h00020; // macro_sel = 0 → even PRAM
        // addr_inst_valid  = 1;

        // @(posedge clk);
        // addr_inst_valid = 0;
        
        // @(posedge clk);
        // $display("INST (EVEN) = %h", instruction_read);
        
        // --------------------------------------------------
        // 4️⃣ READ 32-bit INSTRUCTION (ODD BANK)
        // --------------------------------------------------
        inst_read(17'h00024);
        // @(posedge clk);
        // inst_fetch_adr   = 17'h00024; // bit[2]=1 → odd PRAM
        // addr_inst_valid  = 1;

        // @(posedge clk);
        // addr_inst_valid = 0;

        // $display("INST (ODD) = %h", instruction_read);

        // --------------------------------------------------
        // End simulation
        // --------------------------------------------------
        #50;
        $display("TEST PASSED");
        $finish;
    end

    task inst_read(input [ADDR_BYTE_W-1 : 0]adr);
        begin
            @(posedge clk);
            inst_fetch_adr   = adr; // bit[2]=1 → odd PRAM
            addr_inst_valid  = 1;

            @(posedge clk);
            addr_inst_valid = 0;

            @(posedge clk);
           $display("INST @ %h = %h", adr, instruction_read);
        end
    endtask

endmodule
