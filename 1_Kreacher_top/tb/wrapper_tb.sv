`timescale 1ns/1ps

module tb_top_wrapper;

  // Parameters
  localparam XLEN = 64;
  localparam CLK_PERIOD_NS = 10;           
  localparam RESET_CYCLES = 2;            
  localparam MAX_CYCLES = 10000;       
  localparam ECALL_INSTR = 32'h00000073;  

  localparam ADDR_BYTE_W = 17;
  localparam DATA_W      = 64;
  localparam RAM_WORDS   = 8192;
  localparam RAM_ADDR_W  = 14;


  // Clock & reset
  reg clk;
  reg reset;
  reg I_INTR_H;
  reg O_INTR_ACK;

  // Wires to connect to DUT
`ifndef SYNTHESIS
  wire           commit_valid;
  wire [XLEN-1:0] commit_PC;
  wire [31:0]   commit_instruction;
  wire [4:0]     commit_rd_addr;
  wire [XLEN-1:0] commit_rd_value;
`endif

  // Instantiate DUT (kreacher_top and external mem)
  top_wrapper #(
  .ADDR_BYTE_W(ADDR_BYTE_W),
  .DATA_W(DATA_W),
  .RAM_WORDS(RAM_WORDS),
  .RAM_ADDR_W(RAM_ADDR_W)
  ) dut(
	.I_CLK(clk),
    .I_A_RESET_L(reset),
	.I_INTR_H(I_INTR_H),
	.O_INTR_ACK(O_INTR_ACK),
  
  `ifndef SYNTHESIS
    .commit_valid(commit_valid),
    .commit_PC(commit_PC),
    .commit_instruction(commit_instruction),
    .commit_rd_addr(commit_rd_addr),
    .commit_rd_value(commit_rd_value)
`endif
  );

  // clock generation
  initial begin
    clk = 0;
    forever #(CLK_PERIOD_NS/2) clk = ~clk;
  end

  // Simulation control: reset, waveform, trace file
  integer cycle_count;
  integer trace_fd;

  initial begin
    //check waveform
    
    //$wlfdump("kreacher_tb.wdb");  // 

    // Open trace file (CSV)
    trace_fd = $fopen("kreacher_trace.csv", "w");
    if (trace_fd == 0) begin
      $display("ERROR: Could not open kreacher_trace.csv for writing.");
      $finish;
    end

    // Write CSV header
    $fwrite(trace_fd, "time_ns,pc,inst,rd,rd_value\n");

    // Apply reset
    
    reset = 0;
    cycle_count = 0;
    repeat (RESET_CYCLES) @(posedge clk);
    # 1
    reset = 1;

    // Main simulation loop: monitor commits, write trace, stop on ECALL or timeout
    // We'll run until ECALL commit is observed or MAX_CYCLES reached.
    while (cycle_count < MAX_CYCLES) begin
      @(posedge clk);
      cycle_count = cycle_count + 1;

`ifndef SYNTHESIS
      if (commit_valid) begin
        // Print to console for interactive debugging
        $display("[%0t ns] COMMIT: PC=0x%08h INST=0x%08h rd=%0d rd_val=0x%0h",
                 $time, commit_PC, commit_instruction, commit_rd_addr, commit_rd_value);

        // Write a CSV line: time (ns), PC, instruction, rd, rd_value
        // Use fixed-width hex for PC and inst for easy diffing (08h for 32-bit)
        $fwrite(trace_fd, "%0d,0x%08h,0x%08h,%0d,0x%0h\n",
                $time, commit_PC, commit_instruction, commit_rd_addr, commit_rd_value);
      end
      else begin
        if (commit_instruction == ECALL_INSTR) begin
          $display("[%0t ns] ECALL observed. Finishing simulation after %0d cycles.", $time, cycle_count);
            // Clean up
          $fclose(trace_fd);
        #100; // let final events settle
          //print_coverage_report();
          $finish;
        end
      end

//      if ($isunknown(commit_instruction)) begin
//        $display("[%0t ns] Program finished. Terminating simulation.", $time);
//        // disable SIMULATION_LOOP;
//          // Clean up
//        $fclose(trace_fd);
//      #100; // let final events settle
        //print_coverage_report();
//        $finish;
//      end
`endif
    end // while

    // If reached here due to max cycles:
    if (cycle_count >= MAX_CYCLES) begin
      $display("Maximum cycle count (%0d) reached. Terminating simulation.", MAX_CYCLES);
//      $fclose(trace_fd);
//      #100; // let final events settle
        //print_coverage_report();
//      $finish;
    end

  
  end

  // Optional: print final stats at simulation end (will appear before $finish)
  final begin
    $writememh("DMEM_result.mem", RAM.memory);
    $display("Simulation finished at time %0t ns, cycles = %0d", $time, cycle_count);
  end

endmodule
