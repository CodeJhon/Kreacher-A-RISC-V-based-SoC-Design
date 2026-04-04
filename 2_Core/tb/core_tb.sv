// =============================================================================
// File        : core_tb.sv
// Author      : Jhon Steven Pinto Hernandez
// Email       : jhonstevenpintoh@gmail.com
// Description :
//   SystemVerilog testbench for overall single-cycle core operation and memory interface verification.
// =============================================================================

`timescale 1ns/1ps

module tb_core_and_mem;

  // Parameters
  localparam XLEN = 64;
  localparam CLK_PERIOD_NS = 20;           
  localparam RESET_CYCLES = 2;            
  localparam MAX_COMMITS = 10000;       
  localparam ECALL_INSTR = 32'h7ff0801b;   

  localparam INTERRUPT_TIME = 705;

  // Clock & reset_n
  reg clk;
  reg reset_n;

  // Wires to connect to DUT
`ifndef SYNTHESIS
  wire           commit_valid;
  wire         commit_csr_valid;
  wire [XLEN-1:0] commit_PC;
  wire [4:0]     commit_rd_addr;
  wire [XLEN-1:0] commit_rd_value;
  wire [11:0]    commit_csr_addr;
  wire [XLEN-1:0] commit_csr_value;
  wire [31:0]   commit_instruction;

 
`endif

  // Instantiate DUT (core_and_mem)
  reg irq0;
  reg irq1;
  
  wire acknowledge_irq0;
  wire acknowledge_irq1;
  
  core_and_mem #(.XLEN(XLEN)) dut (
    .clk(clk),
    .reset_n(reset_n),

    .irq0(irq0),
    .irq1(irq1),

    .acknowledge_irq0(acknowledge_irq0),
    .acknowledge_irq1(acknowledge_irq1)
    );

  verification_commits #(.XLEN(XLEN)) verification_commits_inst (
    .IF_PC(dut.core_inst.IF_PC_ID),
    .IF_canonical_instruction(dut.core_inst.IF_canonical_instruction_ID),
    
    //Commit signals going to the regfile
    .WB_regfile_we(dut.core_inst.u_ID.u_regfile.regfile_we),
    .WB_csr_we(dut.core_inst.u_ID.u_csr_bank.csr_we),
    .WB_RD_addr(dut.core_inst.u_ID.u_regfile.RD_addr),
    .WB_RD(dut.core_inst.u_ID.u_regfile.RD),
    .WB_csr_addr(dut.core_inst.u_ID.u_csr_bank.csr_addr_wr),
    .WB_csr(dut.core_inst.u_ID.u_csr_bank.csr_data_wr),

    //Commit signals ready to print
    .commit_valid(commit_valid),
    .commit_csr_valid(commit_csr_valid),
    .commit_PC(commit_PC),
    .commit_rd_addr(commit_rd_addr),
    .commit_rd_value(commit_rd_value),
    .commit_csr_addr(commit_csr_addr),
    .commit_csr_value(commit_csr_value),
    .commit_instruction(commit_instruction)
    
    
  );

  // clock generation
  initial begin
    clk = 0;
    forever #(CLK_PERIOD_NS/2) clk = ~clk;
  end

  // Simulation control: reset_n, waveform, trace file
  integer commit_count;
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

    // Apply reset_n
    
    reset_n = 0;
    commit_count = 0;
    repeat (RESET_CYCLES) @(posedge clk);
    # 1
    reset_n = 1;

    // Main simulation loop: monitor commits, write trace, stop on ECALL or timeout
    // We'll run until ECALL commit is observed or MAX_COMMITS reached.
    while (commit_count < MAX_COMMITS) begin
      @(posedge clk);
      if(commit_valid) commit_count = commit_count + 1;

`ifndef SYNTHESIS
      if (commit_instruction == ECALL_INSTR) begin
          $display("[%0t ns] ECALL observed. Finishing simulation after %0d cycles.", $time, commit_count);
            // Clean up
          $fclose(trace_fd);
        #100; // let final events settle
          //print_coverage_report();
          $finish;
      end
      
      else begin
      if(commit_csr_valid && commit_valid && (commit_PC >= 32'h8000002c)) begin
        // Print to console for interactive debugging
        $display("[%0t ns] CSR COMMIT: PC=0x%08h INST=0x%08h rd=%0d rd_val=0x%0h csr_addr=0x%0d csr_val=0x%0h",
                 $time, commit_PC, commit_instruction, commit_rd_addr, commit_rd_value, commit_csr_addr, commit_csr_value);

        // Write a CSV line: time (ns), PC, instruction, rd, rd_value, csr_addr, csr_val
        // Use fixed-width hex for PC and inst for easy diffing (08h for 32-bit)
        $fwrite(trace_fd, "%0d,0x%08h,0x%08h,%0d,0x%0h,%0d,0x%0h\n",
                $time, commit_PC, commit_instruction, commit_rd_addr, commit_rd_value, commit_csr_addr, commit_csr_value);
      end
      else if(commit_csr_valid && (commit_PC >= 32'h8000002c)) begin
        // Print to console for interactive debugging
        $display("[%0t ns] CSR COMMIT: PC=0x%08h INST=0x%08h csr_addr=0x%0d csr_val=0x%0h",
                 $time, commit_PC, commit_instruction, commit_csr_addr, commit_csr_value);

        // Write a CSV line: time (ns), PC, instruction, csr_addr, csr_val
        // Use fixed-width hex for PC and inst for easy diffing (08h for 32-bit)
        $fwrite(trace_fd, "%0d,0x%08h,0x%08h,%0d,0x%0h\n",
                $time, commit_PC, commit_instruction, commit_csr_addr, commit_csr_value);
      end
      else if (commit_valid && (commit_PC >= 32'h8000002c)) begin
        // Print to console for interactive debugging
        $display("[%0t ns] COMMIT: PC=0x%08h INST=0x%08h rd=%0d rd_val=0x%0h",
                 $time, commit_PC, commit_instruction, commit_rd_addr, commit_rd_value);

        // Write a CSV line: time (ns), PC, instruction, rd, rd_value
        // Use fixed-width hex for PC and inst for easy diffing (08h for 32-bit)
        $fwrite(trace_fd, "%0d,0x%08h,0x%08h,%0d,0x%0h\n",
                $time, commit_PC, commit_instruction, commit_rd_addr, commit_rd_value);
      end  
      end
`endif
    end // while

    // If reached here due to max cycles:
    if (commit_count >= MAX_COMMITS) begin
      $display("Maximum commit count (%0d) reached. Terminating simulation.", MAX_COMMITS);
      $fclose(trace_fd);
      #100; // let final events settle
        //print_coverage_report();
      $finish;
    end

  
  end

  // ------------------------------------------------------------
  // Interrupt stimulus
  // ------------------------------------------------------------
  initial begin
    //Initialize interruot
    irq0 <= 1'b0;
    irq1 <= 1'b0;

    #(INTERRUPT_TIME - 30);
    // Assert interrupt
    $display("[%0t ns] TB: Asserting irq1", $time);
    irq1 <= 1'b1;

    // Hold interrupt until core acknowledges it
    @(posedge clk iff acknowledge_irq1);

    // Deassert interrupt
    $display("[%0t ns] TB: Deasserting irq1", $time);
    irq1 <= 1'b0;
  end


  // Optional: print final stats at simulation end (will appear before $finish)
  final begin
    $writememh("DMEM_result.mem", dut.external_memory.memory);
    $display("Simulation finished at time %0t ns, cycles = %0d", $time, commit_count);
  end

endmodule
