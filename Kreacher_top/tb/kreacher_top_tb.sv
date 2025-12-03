// tb_kreacher_top.sv
`timescale 1ns/1ps

module tb_kreacher_top;

  // Parameters
  localparam XLEN = 32;
  localparam CLK_PERIOD_NS = 10;           
  localparam RESET_CYCLES = 2;            
  localparam MAX_CYCLES = 10000;       
  localparam ECALL_INSTR = 32'h00000073;   


  // Clock & reset
  reg clk;
  reg reset;

  // Wires to connect to DUT
`ifndef SYNTHESIS
  wire           commit_valid;
  wire [XLEN-1:0] commit_PC;
  wire [31:0]   commit_instruction;
  wire [4:0]     commit_rd_addr;
  wire [XLEN-1:0] commit_rd_value;
`endif

  // Instantiate DUT (kreacher_top)
  kreacher_top #(.XLEN(XLEN)) dut (
    .clk(clk),
    .reset(reset),

`ifndef SYNTHESIS
    .commit_valid(commit_valid),
    .commit_PC(commit_PC),
    .commit_instruction(commit_instruction),
    .commit_rd_addr(commit_rd_addr),
    .commit_rd_value(commit_rd_value)
`endif
  );

// ============================================================
// RV32I Instruction Functional Coverage
// ============================================================
//covergroup cg_rv32i @(posedge clk);

//    option.per_instance = 1;

//    // Only sample when instruction commits
//    coverpoint commit_instruction iff (commit_valid) {

//        wildcard bins lb   = {32'b?????????????????000?????0000011};
//        wildcard bins lh   = {32'b?????????????????001?????0000011};
//        wildcard bins lw   = {32'b?????????????????010?????0000011};
//        wildcard bins lbu  = {32'b?????????????????100?????0000011};
//        wildcard bins lhu  = {32'b?????????????????101?????0000011};

//        wildcard bins sb   = {32'b?????????????????000?????0100011};
//        wildcard bins sh   = {32'b?????????????????001?????0100011};
//        wildcard bins sw   = {32'b?????????????????010?????0100011};

//        wildcard bins addi = {32'b?????????????????000?????0010011};
//        wildcard bins slti = {32'b?????????????????010?????0010011};
//        wildcard bins sltiu= {32'b?????????????????011?????0010011};
//        wildcard bins xori = {32'b?????????????????100?????0010011};
//        wildcard bins ori  = {32'b?????????????????110?????0010011};
//        wildcard bins andi = {32'b?????????????????111?????0010011};
//        wildcard bins slli = {32'b0000000??????????001?????0010011};
//        wildcard bins srli = {32'b0000000??????????101?????0010011};
//        wildcard bins srai = {32'b0100000??????????101?????0010011};

//        wildcard bins add  = {32'b0000000??????????000?????0110011};
//        wildcard bins sub  = {32'b0100000??????????000?????0110011};
//        wildcard bins sll  = {32'b0000000??????????001?????0110011};
//        wildcard bins slt  = {32'b0000000??????????010?????0110011};
//        wildcard bins sltu = {32'b0000000??????????011?????0110011};
//        wildcard bins xor_ = {32'b0000000??????????100?????0110011};
//        wildcard bins srl  = {32'b0000000??????????101?????0110011};
//        wildcard bins sra  = {32'b0100000??????????101?????0110011};
//        wildcard bins or_  = {32'b0000000??????????110?????0110011};
//        wildcard bins and_ = {32'b0000000??????????111?????0110011};

//        wildcard bins beq  = {32'b?????????????????000?????1100011};
//        wildcard bins bne  = {32'b?????????????????001?????1100011};
//        wildcard bins blt  = {32'b?????????????????100?????1100011};
//        wildcard bins bge  = {32'b?????????????????101?????1100011};
//        wildcard bins bltu = {32'b?????????????????110?????1100011};
//        wildcard bins bgeu = {32'b?????????????????111?????1100011};

//        wildcard bins jal  = {32'b?????????????????????????1101111};
//        wildcard bins jalr = {32'b?????????????????000?????1100111};

//        wildcard bins lui   = {32'b?????????????????????????0110111};
//        wildcard bins auipc = {32'b?????????????????????????0010111};

//        bins ecall  = {32'h00000073};
//        bins ebreak = {32'h00100073};

//        bins others = default;
//    }

//    // --------------------------------------------------------
//    // RD register write coverage
//    // --------------------------------------------------------
//    rd_cp : coverpoint commit_rd_addr iff (commit_valid) {
//        bins regs[] = {[0:31]};
//    }

//    // PC range bins (example)
//    pc_cp : coverpoint commit_PC iff (commit_valid) {
//        bins low  = {[32'h0000_0000 : 32'h0000_0FFF]};
//        bins mid  = {[32'h0000_1000 : 32'h0000_1FFF]};
//        bins high = default;
//    }

    
//    opcode_x_rd : cross commit_instruction, commit_rd_addr iff (commit_valid && !reset);

//endgroup

//cg_rv32i cg_inst = new();


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
    reset = 1;
    cycle_count = 0;
    repeat (RESET_CYCLES) @(posedge clk);
    reset = 0;

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

        // End simulation on ECALL (common signal for program termination on RISC-V)
        if (commit_instruction == ECALL_INSTR) begin
          $display("[%0t ns] ECALL observed. Finishing simulation after %0d cycles.", $time, cycle_count);
            // Clean up
          $fclose(trace_fd);
        #100; // let final events settle
          //print_coverage_report();
          $finish;
        end
      end

      if ($isunknown(commit_instruction)) begin
        $display("[%0t ns] Program finished. Terminating simulation.", $time);
        // disable SIMULATION_LOOP;
          // Clean up
        $fclose(trace_fd);
      #100; // let final events settle
        //print_coverage_report();
        $finish;
      end
`endif
    end // while

    // If reached here due to max cycles:
    if (cycle_count >= MAX_CYCLES) begin
      $display("Maximum cycle count (%0d) reached. Terminating simulation.", MAX_CYCLES);
      $fclose(trace_fd);
      #100; // let final events settle
        //print_coverage_report();
      $finish;
    end

  
  end

//  task print_coverage_report();
//    real inst_cov, rd_cov, pc_cov, cross_cov, total_cov;
//    integer cov_fd;
    
//    $display("\n");
//    $display("==================================================================");
//    $display("                  FUNCTIONAL COVERAGE REPORT");
//    $display("==================================================================");
//    $display("Simulation Time:      %0t ns", $time);
//    $display("Total Cycles:         %0d", cycle_count);
//    $display("------------------------------------------------------------------");
    
//    // ��ȡ���� coverpoint �ĸ�����
//    inst_cov  = $get_coverage(cg_inst.commit_instruction);
//    rd_cov    = $get_coverage(cg_inst.rd_cp);
//    pc_cov    = $get_coverage(cg_inst.pc_cp);
//    cross_cov = $get_coverage(cg_inst.opcode_x_rd);
//    total_cov = $get_coverage(cg_inst);
    
//    $display("Instruction Coverage:         %6.2f%%", inst_cov);
//    $display("RD Register Coverage:         %6.2f%%", rd_cov);
//    $display("PC Range Coverage:            %6.2f%%", pc_cov);
//    $display("Inst x RD Cross Coverage:     %6.2f%%", cross_cov);
//    $display("------------------------------------------------------------------");
//    $display("TOTAL COVERAGE:               %6.2f%%", total_cov);
//    $display("==================================================================");
//    $display("\n");
    
//    // �������ʱ���д���ļ�
//    cov_fd = $fopen("coverage_summary.txt", "w");
//    if (cov_fd != 0) begin
//      $fwrite(cov_fd, "==================================================================\n");
//      $fwrite(cov_fd, "                  FUNCTIONAL COVERAGE REPORT\n");
//      $fwrite(cov_fd, "==================================================================\n");
//      $fwrite(cov_fd, "Simulation Time:      %0t ns\n", $time);
//      $fwrite(cov_fd, "Total Cycles:         %0d\n", cycle_count);
//      $fwrite(cov_fd, "------------------------------------------------------------------\n");
//      $fwrite(cov_fd, "Instruction Coverage:         %6.2f%%\n", inst_cov);
//      $fwrite(cov_fd, "RD Register Coverage:         %6.2f%%\n", rd_cov);
//      $fwrite(cov_fd, "PC Range Coverage:            %6.2f%%\n", pc_cov);
//      $fwrite(cov_fd, "Inst x RD Cross Coverage:     %6.2f%%\n", cross_cov);
//      $fwrite(cov_fd, "------------------------------------------------------------------\n");
//      $fwrite(cov_fd, "TOTAL COVERAGE:               %6.2f%%\n", total_cov);
//      $fwrite(cov_fd, "==================================================================\n");
//      $fclose(cov_fd);
//      $display("INFO: Coverage report written to 'coverage_summary.txt'");
//    end else begin
//      $display("WARNING: Could not open coverage_summary.txt for writing.");
//    end
//  endtask

  // Provide a label to allow 'disable' to exit the loop from inside `if (ECALL)` above
  // We wrap the main while inside a named block so disable works:
  // initial begin : SIMULATION_LOOP
  //   // The main loop body is driven in the other initial block. This block exists only
  //   // to provide a label that can be disabled. No action here.
  //   wait(0); // no-op
  // end

  // Optional: print final stats at simulation end (will appear before $finish)
  final begin
    $display("Simulation finished at time %0t ns, cycles = %0d", $time, cycle_count);
  end

endmodule
