`timescale 1ns/1ps

module radix_4_booth_multiplier_tb;

    localparam XLEN   = 64;
    localparam P_XLEN = 128;

    reg  clk;
    reg  reset_n;
    reg  start;
    reg  rs1_is_signed;
    reg  rs2_is_signed;
    reg  [XLEN-1:0] in_multiplicand;
    reg  [XLEN-1:0] in_multiplier;

    wire [P_XLEN-1:0] prod_result;
    wire busy;
    wire done;

    // DUT
    radix_4_booth_multiplier #(
        .XLEN(XLEN),
        .P_XLEN(P_XLEN)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .pause(1'b0),
        .start(start),
        .rs1_is_signed(rs1_is_signed),
        .rs2_is_signed(rs2_is_signed),
        .in_multiplicand(in_multiplicand),
        .in_multiplier(in_multiplier),
        .prod_result(prod_result),
        .busy(busy),
        .done(done)
    );

    // Clock
    initial clk = 1'b0;
    always #5 clk = ~clk;  // 100MHz

    // ---------------------------
    // Golden reference functions
    // ---------------------------
    function [P_XLEN-1:0] ref_mul_ss;
        input [XLEN-1:0] a;
        input [XLEN-1:0] b;
        reg signed [XLEN-1:0] as;
        reg signed [XLEN-1:0] bs;
        reg signed [P_XLEN-1:0] ps;
        begin
            as = a;
            bs = b;
            ps = as * bs;
            ref_mul_ss = ps;
        end
    endfunction

    function [P_XLEN-1:0] ref_mul_uu;
        input [XLEN-1:0] a;
        input [XLEN-1:0] b;
        reg [P_XLEN-1:0] pu;
        begin
            pu = a * b;
            ref_mul_uu = pu;
        end
    endfunction

    function [P_XLEN-1:0] ref_mul_su;
        input [XLEN-1:0] a;
        input [XLEN-1:0] b;
        reg signed [XLEN-1:0] as;
        reg [XLEN-1:0] bu;
        reg signed [P_XLEN-1:0] psu;
        begin
            as = a;
            bu = b;
            psu = as * $signed({1'b0, bu}); // force unsigned b
            ref_mul_su = psu;
        end
    endfunction

    // ---------------------------
    // Task: run one test
    // ---------------------------
    task run_case;
        input [8*16-1:0] name;
        input [XLEN-1:0] a;
        input [XLEN-1:0] b;
        input mode_rs1_signed;
        input mode_rs2_signed;
        input [1:0] op_sel; // 0=MUL, 1=MULH, 2=MULHU, 3=MULHSU

        reg [P_XLEN-1:0] expected128;
        reg [XLEN-1:0]   expected64;
        reg [XLEN-1:0]   got64;
        begin
            // Select expected product based on op
            case (op_sel)
                2'd0: expected128 = ref_mul_ss(a,b); // MUL uses signed×signed in RISC-V
                2'd1: expected128 = ref_mul_ss(a,b); // MULH signed×signed
                2'd2: expected128 = ref_mul_uu(a,b); // MULHU unsigned×unsigned
                2'd3: expected128 = ref_mul_su(a,b); // MULHSU signed×unsigned
                default: expected128 = {P_XLEN{1'b0}};
            endcase

            // Expected 64-bit output depending on op
            case (op_sel)
                2'd0: expected64 = expected128[63:0];
                default: expected64 = expected128[127:64];
            endcase

            // Drive DUT
            @(negedge clk);
            rs1_is_signed    = mode_rs1_signed;
            rs2_is_signed    = mode_rs2_signed;
            in_multiplicand  = a;
            in_multiplier    = b;
            start            = 1'b1;

            @(negedge clk);
            start = 1'b0;

            // Wait done
            wait(done === 1'b1);
            @(posedge clk);

            // Compare
            case (op_sel)
                2'd0: got64 = prod_result[63:0];
                default: got64 = prod_result[127:64];
            endcase

            if (got64 !== expected64) begin
                $display("❌ FAIL [%0s] op=%0d", name, op_sel);
                $display("   A = 0x%016h", a);
                $display("   B = 0x%016h", b);
                $display("   DUT  prod_result = 0x%032h", prod_result);
                $display("   EXP  product128  = 0x%032h", expected128);
                $display("   GOT64 = 0x%016h  EXP64 = 0x%016h", got64, expected64);
                $stop;
            end else begin
                $display("✅ PASS [%0s] op=%0d  GOT=0x%016h", name, op_sel, got64);
            end
        end
    endtask

    // ---------------------------
    // Reset + tests
    // ---------------------------
    initial begin
        // init
        reset_n = 1'b0;
        start   = 1'b0;
        rs1_is_signed = 1'b0;
        rs2_is_signed = 1'b0;
        in_multiplicand = 64'd0;
        in_multiplier   = 64'd0;

        // reset pulse
        repeat(5) @(posedge clk);
        reset_n = 1'b1;
        repeat(2) @(posedge clk);

        // ---------------------------
        // EDGE CASES
        // ---------------------------

        // ===== MUL (low 64, signed×signed) =====
        run_case("MUL 0*0",          64'h0, 64'h0, 1, 1, 2'd0);
        run_case("MUL 1*1",          64'h1, 64'h1, 1, 1, 2'd0);
        run_case("MUL -1*1",         64'hFFFF_FFFF_FFFF_FFFF, 64'h1, 1, 1, 2'd0);
        run_case("MUL -1*-1",        64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF, 1, 1, 2'd0);
        run_case("MUL INT_MIN*1",    64'h8000_0000_0000_0000, 64'h1, 1, 1, 2'd0);
        run_case("MUL INT_MIN*-1",   64'h8000_0000_0000_0000, 64'hFFFF_FFFF_FFFF_FFFF, 1, 1, 2'd0);
        run_case("MUL INT_MAX*2",    64'h7FFF_FFFF_FFFF_FFFF, 64'h2, 1, 1, 2'd0);

        // ===== MULH (high 64, signed×signed) =====
        run_case("MULH 0*0",             64'h0, 64'h0, 1, 1, 2'd1);
        run_case("MULH -1*1",            64'hFFFF_FFFF_FFFF_FFFF, 64'h1, 1, 1, 2'd1);
        run_case("MULH INT_MIN*2",       64'h8000_0000_0000_0000, 64'h2, 1, 1, 2'd1);
        run_case("MULH INT_MAX*INT_MAX", 64'h7FFF_FFFF_FFFF_FFFF, 64'h7FFF_FFFF_FFFF_FFFF, 1, 1, 2'd1);

        // ===== MULHU (high 64, unsigned×unsigned) =====
        run_case("MULHU 0*0",            64'h0, 64'h0, 0, 0, 2'd2);
        run_case("MULHU 1*1",            64'h1, 64'h1, 0, 0, 2'd2);
        run_case("MULHU FFFF..*2",       64'hFFFF_FFFF_FFFF_FFFF, 64'h2, 0, 0, 2'd2);
        run_case("MULHU FFFF..*FFFF..",  64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF, 0, 0, 2'd2);

        // ===== MULHSU (high 64, signed×unsigned) =====
        run_case("MULHSU -1 * 1",       64'hFFFF_FFFF_FFFF_FFFF, 64'h1, 1, 0, 2'd3);
        run_case("MULHSU -1 * FFFF..",  64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF, 1, 0, 2'd3);
        run_case("MULHSU INT_MIN * 2",  64'h8000_0000_0000_0000, 64'h2, 1, 0, 2'd3);
        run_case("MULHSU 5 * FFFF..",   64'h5, 64'hFFFF_FFFF_FFFF_FFFF, 1, 0, 2'd3);

        $display("\n🎉 ALL EDGE CASE TESTS PASSED!");
        $finish;
    end

endmodule
