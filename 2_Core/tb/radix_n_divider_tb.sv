`timescale 1ns/1ps

module tb_radix_4_divider_edge64_no_div0;

    localparam XLEN = 64;
    localparam CLK_PERIOD = 10;

    reg clk;
    reg reset_n;
    reg pause;
    reg start;
    reg rs1_is_signed;
    reg rs2_is_signed;
    reg [XLEN-1:0] dividend;
    reg [XLEN-1:0] divisor;

    wire [XLEN:0]   remainder;
    wire [XLEN-1:0] quotient;
    wire busy;
    wire done;

    // DUT
    radix_4_divider #(.XLEN(XLEN)) dut (
        .clk(clk),
        .reset_n(reset_n),
        .pause(pause),
        .start(start),
        .rs1_is_signed(rs1_is_signed),
        .rs2_is_signed(rs2_is_signed),
        .dividend(dividend),
        .divisor(divisor),
        .remainder(remainder),
        .quotient(quotient),
        .busy(busy),
        .done(done)
    );

    // Clock
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -----------------------------------------
    // Run one op: DIV / DIVU / REM / REMU
    // op_sel:
    // 0 = DIV
    // 1 = DIVU
    // 2 = REM
    // 3 = REMU
    // -----------------------------------------
    task automatic run_op;
        input [8*32-1:0] name;
        input [1:0] op_sel;
        input [XLEN-1:0] a;
        input [XLEN-1:0] b;

        reg signed [XLEN-1:0] as, bs;
        reg [XLEN-1:0] au, bu;

        reg signed [XLEN-1:0] exp_q_s;
        reg signed [XLEN-1:0] exp_r_s;
        reg [XLEN-1:0] exp_q_u;
        reg [XLEN-1:0] exp_r_u;

        integer timeout;

        begin
            // no div-by-zero in this TB
            if (b == 0) begin
                $display("SKIP (div0 not allowed): %s", name);
                return;
            end

            as = a; bs = b;
            au = a; bu = b;

            // Signed overflow case: INT_MIN / -1
            if ((a == 64'h8000_0000_0000_0000) && (b == 64'hFFFF_FFFF_FFFF_FFFF)) begin
                exp_q_s = 64'h8000_0000_0000_0000;
                exp_r_s = 0;
            end else begin
                exp_q_s = as / bs;
                exp_r_s = as % bs;
            end

            exp_q_u = au / bu;
            exp_r_u = au % bu;

            // set signed mode like instructions
            case (op_sel)
                2'd0, 2'd2: begin // DIV / REM
                    rs1_is_signed = 1'b1;
                    rs2_is_signed = 1'b1;
                end
                default: begin     // DIVU / REMU
                    rs1_is_signed = 1'b0;
                    rs2_is_signed = 1'b0;
                end
            endcase

            // Apply
            @(posedge clk);
            dividend = a;
            divisor  = b;
            start    = 1'b1;

            @(posedge clk);
            start = 1'b0;

            // Wait done
            timeout = 0;
            while (!done) begin
                @(posedge clk);
                timeout++;
                if (timeout > (XLEN + 40))
                    $fatal("TIMEOUT: %s a=0x%h b=0x%h", name, a, b);
            end

            // Check
            case (op_sel)
                2'd0: begin // DIV
                    if ($signed(quotient) !== exp_q_s) begin
                        $display("❌ FAIL DIV [%s]", name);
                        $display("   A=%0d (0x%h)  B=%0d (0x%h)", as, a, bs, b);
                        $display("   GOT Q=%0d (0x%h)  EXP Q=%0d (0x%h)",
                                 $signed(quotient), quotient, exp_q_s, exp_q_s);
                        $stop;
                    end
                end
                2'd1: begin // DIVU
                    if (quotient !== exp_q_u) begin
                        $display("❌ FAIL DIVU [%s]", name);
                        $display("   A=0x%h  B=0x%h", au, bu);
                        $display("   GOT Q=0x%h  EXP Q=0x%h", quotient, exp_q_u);
                        $stop;
                    end
                end
                2'd2: begin // REM
                    if ($signed(remainder[XLEN-1:0]) !== exp_r_s) begin
                        $display("❌ FAIL REM [%s]", name);
                        $display("   A=%0d (0x%h)  B=%0d (0x%h)", as, a, bs, b);
                        $display("   GOT R=%0d (0x%h)  EXP R=%0d (0x%h)",
                                 $signed(remainder[XLEN-1:0]), remainder[XLEN-1:0],
                                 exp_r_s, exp_r_s);
                        $stop;
                    end
                end
                2'd3: begin // REMU
                    if (remainder[XLEN-1:0] !== exp_r_u) begin
                        $display("❌ FAIL REMU [%s]", name);
                        $display("   A=0x%h  B=0x%h", au, bu);
                        $display("   GOT R=0x%h  EXP R=0x%h", remainder[XLEN-1:0], exp_r_u);
                        $stop;
                    end
                end
            endcase

            $display("✅ PASS %-4s [%s] A=0x%h B=0x%h Q=0x%h R=0x%h",
                     (op_sel==0)?"DIV":
                     (op_sel==1)?"DIVU":
                     (op_sel==2)?"REM":"REMU",
                     name, a, b, quotient, remainder[XLEN-1:0]);

            @(posedge clk);
        end
    endtask

    task automatic run_all_ops;
        input [8*32-1:0] name;
        input [XLEN-1:0] a;
        input [XLEN-1:0] b;
        begin
            run_op(name, 2'd0, a, b); // DIV
            run_op(name, 2'd1, a, b); // DIVU
            run_op(name, 2'd2, a, b); // REM
            run_op(name, 2'd3, a, b); // REMU
        end
    endtask

    initial begin
        // init
        reset_n = 0;
        pause   = 0;
        start   = 0;
        rs1_is_signed = 0;
        rs2_is_signed = 0;
        dividend = 0;
        divisor  = 1;

        // reset
        repeat(5) @(posedge clk);
        reset_n = 1;

        // ---------------------------------------
        // Edge cases (no divisor = 0)
        // ---------------------------------------

        // 0 cases
        run_all_ops("0/1", 64'd0, 64'd1);

        // 1 and -1
        run_all_ops("1/1",   64'sd1,  64'sd1);
        run_all_ops("-1/1", -64'sd1,  64'sd1);
        run_all_ops("1/-1",  64'sd1, -64'sd1);
        run_all_ops("-1/-1",-64'sd1, -64'sd1);

        // small negatives
        run_all_ops("-13/3",    -64'sd13,  64'sd3);
        run_all_ops("13/-3",     64'sd13, -64'sd3);
        run_all_ops("-13/-3",   -64'sd13, -64'sd3);

        // dividend < divisor
        run_all_ops("3/5", 64'd3, 64'd5);
        run_all_ops("5/7", 64'd5, 64'd7);

        // powers of two divisors
        run_all_ops("1024/2",   64'd1024, 64'd2);
        run_all_ops("1024/4",   64'd1024, 64'd4);
        run_all_ops("1024/8",   64'd1024, 64'd8);
        run_all_ops("1024/16",  64'd1024, 64'd16);

        // max values
        run_all_ops("MAX/1",     64'hFFFF_FFFF_FFFF_FFFF, 64'd1);
        run_all_ops("MAX/2",     64'hFFFF_FFFF_FFFF_FFFF, 64'd2);
        run_all_ops("MAX/MAX",   64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF);

        // signed bounds
        run_all_ops("INT_MAX/3", 64'h7FFF_FFFF_FFFF_FFFF, 64'd3);
        run_all_ops("INT_MIN/1", 64'h8000_0000_0000_0000, 64'd1);
        run_all_ops("INT_MIN/2", 64'h8000_0000_0000_0000, 64'd2);

        // signed overflow
        run_all_ops("INT_MIN/-1",64'h8000_0000_0000_0000, 64'hFFFF_FFFF_FFFF_FFFF);

        $display("=================================");
        $display("ALL EDGE TESTS (NO DIV0) PASSED ✅");
        $display("=================================");
        #20;
        $finish;
    end

endmodule