`timescale 1ns/1ps

module random_interrupt_gen (
    input wire clk,
    input wire rst_n,
    input wire ack_0,
    output reg interrupt_0,
    input wire ack_1,
    output reg interrupt_1
);

integer cnt_0, cnt_1;

localparam
    IDLE = 1'b0,
    WAIT_ACK = 1'b1;

reg state_0, state_1;

reg [18:0] delay_cnt;
reg interrupt_begin;

parameter SEQ_LEN = 22;

reg [31:0] seq0 [0:SEQ_LEN-1];
reg [31:0] seq1 [0:SEQ_LEN-1];

integer idx0;
integer idx1;

initial begin
    seq0[0]=175; seq0[1]=131; seq0[2]=125; seq0[3]=129;
    seq0[4]=128; seq0[5]=178; seq0[6]=198; seq0[7]=102;
    seq0[8]=175; seq0[9]=189; seq0[10]=164; seq0[11]=169;
    seq0[12]=132; seq0[13]=194; seq0[14]=137; seq0[15]=140;
    seq0[16]=149; seq0[17]=133; seq0[18]=175; seq0[19]=113;
    seq0[20]=126; seq0[21]=145;

    seq1[0]=175; seq1[1]=175; seq1[2]=125; seq1[3]=129;
    seq1[4]=128; seq1[5]=178; seq1[6]=178; seq1[7]=198;
    seq1[8]=102; seq1[9]=175; seq1[10]=189; seq1[11]=164;
    seq1[12]=164; seq1[13]=169; seq1[14]=194; seq1[15]=137;
    seq1[16]=140; seq1[17]=133; seq1[18]=175; seq1[19]=175;
    seq1[20]=126; seq1[21]=145;
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        delay_cnt <= 19'h40033;
        interrupt_begin <= 0;
    end
    else begin
        if (delay_cnt == 0) begin
            interrupt_begin <= 1;
        end
        else begin
            delay_cnt <= delay_cnt - 1;
        end
    end
end


always @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_0 <= IDLE;
        interrupt_0 <= 0;
        idx0 <= 0;
        cnt_0 <= seq0[0];
    end
    else begin
        if (interrupt_begin) begin
            case (state_0)

                IDLE: begin
                    if (cnt_0 == 0) begin

                        if (idx0 == SEQ_LEN-1)
                            idx0 <= 0;
                        else
                            idx0 <= idx0 + 1;

                        cnt_0 <= seq0[idx0];

                        interrupt_0 <= 1;
                        state_0 <= WAIT_ACK;
                    end
                    else begin
                        cnt_0 <= cnt_0 - 1;
                    end
                end

                WAIT_ACK: begin
                    if (ack_0) begin
                        interrupt_0 <= 0;
                        state_0 <= IDLE;
                    end
                end

            endcase
        end
    end
end


always @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_1 <= IDLE;
        interrupt_1 <= 0;
        idx1 <= 0;
        cnt_1 <= seq1[0];
    end
    else begin
        if (interrupt_begin) begin
            case (state_1)

                IDLE: begin
                    if (cnt_1 == 0) begin

                        if (idx1 == SEQ_LEN-1)
                            idx1 <= 0;
                        else
                            idx1 <= idx1 + 1;

                        cnt_1 <= seq1[idx1];

                        interrupt_1 <= 1;
                        state_1 <= WAIT_ACK;
                    end
                    else begin
                        cnt_1 <= cnt_1 - 1;
                    end
                end

                WAIT_ACK: begin
                    if (ack_1) begin
                        interrupt_1 <= 0;
                        state_1 <= IDLE;
                    end
                end

            endcase
        end
    end
end

endmodule