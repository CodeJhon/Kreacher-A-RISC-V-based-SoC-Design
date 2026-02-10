`timescale 1ns/1ps

module tb_top_wrapper;

  // Parameters
  localparam XLEN = 64;
  localparam CLK_PERIOD_NS = 30;           
  localparam RESET_CYCLES = 2;            
  localparam MAX_COMMITS = 10000;       
  localparam ECALL_INSTR = 32'h7ff0801b;  

  localparam ADDR_BYTE_W = 17;
  localparam DATA_W      = 64;
  localparam external_mem_WORDS   = 8192;
  localparam external_mem_ADDR_W  = 14;

  // Clock & reset_n
  reg clk;
  reg reset_n;
  // reg I_INTR_H;
  // reg O_INTR_ACK;

  // Wires to connect to DUT
`ifndef SYNTHESIS
  wire           commit_valid;
  wire [XLEN-1:0] commit_PC;
  wire [31:0]   commit_instruction;
  wire [4:0]     commit_rd_addr;
  wire [XLEN-1:0] commit_rd_value;
`endif

  // Instantiate DUT (kreacher_top and external mem)
  reg irq0;
  reg irq1;
  
  wire acknowledge_irq0;
  wire acknowledge_irq1;
  
  top_wrapper #(
  .ADDR_BYTE_W(ADDR_BYTE_W),
  .DATA_W(DATA_W),
  .external_mem_WORDS(external_mem_WORDS),
  .external_mem_ADDR_W(external_mem_ADDR_W)
  ) dut(
	.I_CLK(clk),
  .I_A_RESET_L(reset_n),
	.I_INTR_H({irq1, irq0}),
	.O_INTR_ACK({acknowledge_irq1, acknowledge_irq0})
  );

  
  verification_commits #(.XLEN(XLEN)) verification_commits_inst (
    .IF_PC(dut.u_kreacher_top.core_inst.IF_PC_ID),
    .IF_canonical_instruction(dut.u_kreacher_top.core_inst.IF_canonical_instruction_ID),
    
    //Commit signals going to the regfile
    .WB_regfile_we(dut.u_kreacher_top.core_inst.u_ID.u_regfile.regfile_we),
    .WB_RD_addr(dut.u_kreacher_top.core_inst.u_ID.u_regfile.RD_addr),
    .WB_RD(dut.u_kreacher_top.core_inst.u_ID.u_regfile.RD),

    //Commit signals ready to print
    .commit_valid(commit_valid),
    .commit_PC(commit_PC),
    .commit_instruction(commit_instruction),
    .commit_rd_addr(commit_rd_addr),
    .commit_rd_value(commit_rd_value)
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
      if (commit_valid && (commit_PC >= 32'h8000002c)) begin
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
  // Interrupt stimulus (halfcycle latency-based assert, ack-based deassert)
  // ------------------------------------------------------------

  parameter IRQ_ASSERT_CYCLES = 264274;

  int irq_cycle_cnt;
  bit irq_asserted;

  initial begin
    irq0 <= 1'b0;
    irq1 <= 1'b0;
    irq_cycle_cnt = 0;
    irq_asserted  = 0;
  end

  // Count cycles only until IRQ is asserted
  always @(posedge clk) begin
    if (!irq_asserted)
      irq_cycle_cnt++;
  end

  // Drive IRQ on negedge clk
  always @(negedge clk) begin
    // Assert IRQ when counter reaches threshold
    if (!irq_asserted && irq_cycle_cnt >= IRQ_ASSERT_CYCLES) begin
      $display("[%0t] TB: Asserting irq0 (cycle=%0d)", $time, irq_cycle_cnt);
      irq0 <= 1'b1;
      irq_asserted <= 1'b1;
    end

    // Deassert IRQ ONLY on acknowledge
    if (irq_asserted && acknowledge_irq0) begin
      #CLK_PERIOD_NS;
      $display("[%0t] TB: Deasserting irq0 (acknowledged)", $time);
      irq0 <= 1'b0;
      irq_asserted  <= 1'b0;
      irq_cycle_cnt <= 0;   // reset for next interrupt
    end
  end


  // Optional: print final stats at simulation end (will appear before $finish)
  final begin
    $writememh("DMEM_result.mem", dut.external_memory.memory);
    $writememh("PMEM_result_0.mem", dut.u_kreacher_top.PMEM_interface_top_inst.GEN_EVEN_MACROS[0].PRAM_even.sram_core_i.memory);
    $writememh("PMEM_result_1.mem", dut.u_kreacher_top.PMEM_interface_top_inst.GEN_ODD_MACROS[0].PRAM_odd.sram_core_i.memory);
    $writememh("PMEM_result_2.mem", dut.u_kreacher_top.PMEM_interface_top_inst.GEN_EVEN_MACROS[1].PRAM_even.sram_core_i.memory);
    $writememh("PMEM_result_3.mem", dut.u_kreacher_top.PMEM_interface_top_inst.GEN_ODD_MACROS[1].PRAM_odd.sram_core_i.memory);
    $writememh("PMEM_result_4.mem", dut.u_kreacher_top.PMEM_interface_top_inst.GEN_EVEN_MACROS[2].PRAM_even.sram_core_i.memory);
    $writememh("PMEM_result_5.mem", dut.u_kreacher_top.PMEM_interface_top_inst.GEN_ODD_MACROS[2].PRAM_odd.sram_core_i.memory);
    $writememh("PMEM_result_6.mem", dut.u_kreacher_top.PMEM_interface_top_inst.GEN_EVEN_MACROS[3].PRAM_even.sram_core_i.memory);
    $writememh("PMEM_result_7.mem", dut.u_kreacher_top.PMEM_interface_top_inst.GEN_ODD_MACROS[3].PRAM_odd.sram_core_i.memory);
    
    $display("Simulation finished at time %0t ns, cycles = %0d", $time, commit_count);
  end

endmodule
