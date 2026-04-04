// =============================================================================
// File        : extend_instr_tb.v
// Author      : Jhon Steven Pinto Hernandez
// Email       : jhonstevenpintoh@gmail.com
// Description :
//   Testbench verifying compressed instruction expansion into canonical instruction encodings.
// =============================================================================

`timescale 1ns / 1ps

module extend_instr_tb;

    // DUT inputs
    reg  [15:0] compressed_instruction;

    // DUT outputs
    wire [31:0] extended_instruction;

    // Instantiate the DUT
    extend_instruction dut (
        .compressed_instruction(compressed_instruction),
        .extended_instruction  (extended_instruction)
    );

    initial begin
        $display("\n-----------Start simulation report-----------\n");

        $display("\n**QUADRANT0 TESTING**\n");

        // -------------------------------------------------
        // C.ADDI4SPN -> ADDI x8, x2, 4
        // -------------------------------------------------
        compressed_instruction = 16'h0020; // C.ADDI4SPN x8, sp, 4
        #1;
        if (extended_instruction !== 32'h00810413) begin
            $display("ERROR: C.ADDI4SPN failed");
            $display("  Expected: 0x00410413");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.LW -> LW x8, 0(x8)
        // -------------------------------------------------
        compressed_instruction = 16'h4000; // C.LW x8, 0(x8)
        #1;
        if (extended_instruction !== 32'h00042403) begin
            $display("ERROR: C.LW failed");
            $display("  Expected: 0x00042403");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.LD -> LD x8, 0(x8)   (RV64 only)
        // -------------------------------------------------
        compressed_instruction = 16'h6000; // C.LD x8, 0(x8)
        #1;
        if (extended_instruction !== 32'h00043403) begin
            $display("ERROR: C.LD failed (RV64 only)");
            $display("  Expected: 0x00043403");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.SW -> SW x8, 0(x8)
        // -------------------------------------------------
        compressed_instruction = 16'hC000; // C.SW x8, 0(x8)
        #1;
        if (extended_instruction !== 32'h00842023) begin
            $display("ERROR: C.SW failed");
            $display("  Expected: 0x00842023");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.SD -> SD x8, 0(x8)   (RV64 only)
        // -------------------------------------------------
        compressed_instruction = 16'hE000; // C.SD x8, 0(x8)
        #1;
        if (extended_instruction !== 32'h00843023) begin
            $display("ERROR: C.SD failed (RV64 only)");
            $display("  Expected: 0x00843023");
            $display("  Got     : 0x%08x", extended_instruction);
        end
        
        $display("\n**QUADRANT1 TESTING**\n");
        // -------------------------------------------------
        // C.ADDI -> ADDI x1, x1, 1
        // -------------------------------------------------
        compressed_instruction = 16'h0085; // C.ADDI x1, +1
        #1;

        if (extended_instruction !== 32'h00108093) begin
            $display("ERROR: C.ADDI failed");
            $display("  Expected: 0x00108093");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.ADDIW -> ADDIW x1, x1, 1   (RV64 only)
        // -------------------------------------------------
        compressed_instruction = 16'h2085; // C.ADDIW x1, +1
        #1;

        if (extended_instruction !== 32'h0010809B) begin
            $display("ERROR: C.ADDIW failed");
            $display("  Expected: 0x0010809B");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.LI -> ADDI x1, x0, 1
        // -------------------------------------------------
        compressed_instruction = 16'h4085; // C.LI x1, +1
        #1;

        if (extended_instruction !== 32'h00100093) begin
            $display("ERROR: C.LI (LI) failed");
            $display("  Expected: 0x00100093");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.ADDI16SP -> ADDI x2, x2, 16
        // -------------------------------------------------
        compressed_instruction = 16'h6141; // C.ADDI16SP +16
        #1;
        if (extended_instruction !== 32'h01010113) begin
            $display("ERROR: C.ADDI16SP failed");
            $display("  Expected: 0x01010113");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.LUI -> LUI x3, 0x00001   (i.e., x3 = 0x00001000)
        // -------------------------------------------------
        compressed_instruction = 16'h6185; // C.LUI x3, 1
        #1;
        if (extended_instruction !== 32'h000011B7) begin
            $display("ERROR: C.LUI failed");
            $display("  Expected: 0x000011B7");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.SRLI -> SRLI x8, x8, 31   (RV32: shamt[5]=0)
        // -------------------------------------------------
        compressed_instruction = 16'h807D; // C.SRLI x8, 31
        #1;
        if (extended_instruction !== 32'h01F45413) begin
            $display("ERROR: C.SRLI failed");
            $display("  Expected: 0x01F45413");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.SRAI -> SRAI x8, x8, 31   (RV32: shamt[5]=0)
        // -------------------------------------------------
        compressed_instruction = 16'h847D; // C.SRAI x8, 31
        #1;
        if (extended_instruction !== 32'h41F45413) begin
            $display("ERROR: C.SRAI failed");
            $display("  Expected: 0x41F45413");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.ANDI -> ANDI x8, x8, -1   (tests sign-extension)
        // -------------------------------------------------
        compressed_instruction = 16'h987D; // C.ANDI x8, -1
        #1;
        if (extended_instruction !== 32'hFFF47413) begin
            $display("ERROR: C.ANDI failed");
            $display("  Expected: 0xFFF47413");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.SUB -> SUB x8, x8, x9
        // -------------------------------------------------
        compressed_instruction = 16'h8C05; // C.SUB x8, x9
        #1;
        if (extended_instruction !== 32'h40940433) begin
            $display("ERROR: C.SUB failed");
            $display("  Expected: 0x40940433");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.XOR -> XOR x8, x8, x9
        // -------------------------------------------------
        compressed_instruction = 16'h8C25; // C.XOR x8, x9
        #1;
        if (extended_instruction !== 32'h00944433) begin
            $display("ERROR: C.XOR failed");
            $display("  Expected: 0x00944433");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.OR -> OR x8, x8, x9
        // -------------------------------------------------
        compressed_instruction = 16'h8C45; // C.OR x8, x9
        #1;
        if (extended_instruction !== 32'h00946433) begin
            $display("ERROR: C.OR failed");
            $display("  Expected: 0x00946433");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.AND -> AND x8, x8, x9
        // -------------------------------------------------
        compressed_instruction = 16'h8C65; // C.AND x8, x9
        #1;
        if (extended_instruction !== 32'h00947433) begin
            $display("ERROR: C.AND failed");
            $display("  Expected: 0x00947433");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.SUBW -> SUBW x8, x8, x9   (RV64 only)
        // -------------------------------------------------
        compressed_instruction = 16'h9C05; // C.SUBW x8, x9
        #1;
        if (extended_instruction !== 32'h4094043B) begin
            $display("ERROR: C.SUBW failed (RV64 only)");
            $display("  Expected: 0x4094043B");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.ADDW -> ADDW x8, x8, x9   (RV64 only)
        // -------------------------------------------------
        compressed_instruction = 16'h9C25; // C.ADDW x8, x9
        #1;
        if (extended_instruction !== 32'h0094043B) begin
            $display("ERROR: C.ADDW failed (RV64 only)");
            $display("  Expected: 0x0094043B");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.J -> JAL x0, +64
        // -------------------------------------------------
        compressed_instruction = 16'hA081; // C.J +64
        #1;
        if (extended_instruction !== 32'h0400006F) begin
            $display("ERROR: C.J failed");
            $display("  Expected: 0x0400006F");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.BEQZ -> BEQ x8, x0, +32
        // -------------------------------------------------
        compressed_instruction = 16'hC005; // C.BEQZ x8, +32
        #1;
        if (extended_instruction !== 32'h02040063) begin
            $display("ERROR: C.BEQZ failed");
            $display("  Expected: 0x02040063");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.BNEZ -> BNE x8, x0, +32
        // -------------------------------------------------
        compressed_instruction = 16'hE005; // C.BNEZ x8, +32
        #1;
        if (extended_instruction !== 32'h02041063) begin
            $display("ERROR: C.BNEZ failed");
            $display("  Expected: 0x02041063");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        $display("\n**QUADRANT2 TESTING**\n");

        // -------------------------------------------------
        // C.SLLI -> SLLI x1, x1, 1
        // -------------------------------------------------
        compressed_instruction = 16'h0086; // C.SLLI x1, 1
        #1;
        if (extended_instruction !== 32'h00109093) begin
            $display("ERROR: C.SLLI failed");
            $display("  Expected: 0x00109093");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.LWSP -> LW x1, 4(x2)
        // -------------------------------------------------
        compressed_instruction = 16'h4092; // C.LWSP x1, 4(sp)
        #1;
        if (extended_instruction !== 32'h00412083) begin
            $display("ERROR: C.LWSP failed");
            $display("  Expected: 0x00412083");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.LDSP -> LD x1, 8(x2)   (RV64 only)
        // -------------------------------------------------
        compressed_instruction = 16'h60A2; // C.LDSP x1, 8(sp)
        #1;
        if (extended_instruction !== 32'h00813083) begin
            $display("ERROR: C.LDSP failed (RV64 only)");
            $display("  Expected: 0x00813083");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.JR -> JALR x0, 0(x1)
        // -------------------------------------------------
        compressed_instruction = 16'h8082; // C.JR x1
        #1;
        if (extended_instruction !== 32'h00008067) begin
            $display("ERROR: C.JR failed");
            $display("  Expected: 0x00008067");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.MV -> ADD x1, x0, x2
        // -------------------------------------------------
        compressed_instruction = 16'h808A; // C.MV x1, x2
        #1;
        if (extended_instruction !== 32'h002000B3) begin
            $display("ERROR: C.MV failed");
            $display("  Expected: 0x002000B3");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.JALR -> JALR x1, 0(x1)
        // -------------------------------------------------
        compressed_instruction = 16'h9082; // C.JALR x1
        #1;
        if (extended_instruction !== 32'h000080E7) begin
            $display("ERROR: C.JALR failed");
            $display("  Expected: 0x000080E7");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.ADD -> ADD x1, x1, x2
        // -------------------------------------------------
        compressed_instruction = 16'h908A; // C.ADD x1, x2
        #1;
        if (extended_instruction !== 32'h002080B3) begin
            $display("ERROR: C.ADD failed");
            $display("  Expected: 0x002080B3");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.SWSP -> SW x1, 4(x2)
        // -------------------------------------------------
        compressed_instruction = 16'hC206; // C.SWSP x1, 4(sp)
        #1;
        if (extended_instruction !== 32'h00112223) begin
            $display("ERROR: C.SWSP failed");
            $display("  Expected: 0x00112223");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        // -------------------------------------------------
        // C.SDSP -> SD x1, 8(x2)   (RV64 only)
        // -------------------------------------------------
        compressed_instruction = 16'hE406; // C.SDSP x1, 8(sp)
        #1;
        if (extended_instruction !== 32'h00113423) begin
            $display("ERROR: C.SDSP failed (RV64 only)");
            $display("  Expected: 0x00113423");
            $display("  Got     : 0x%08x", extended_instruction);
        end

        #10;
        $display("\n-----------Finish simulation report-----------\n");
        $finish;
    end

endmodule
