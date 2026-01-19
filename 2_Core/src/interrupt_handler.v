module interrupt_handler #(parameter XLEN = 64, parameter WB = 3'd4)(// In pipelined cores = 4 ; in single cycle cores = 1
    //Global
    input clk,
    input reset_n,

    // Interrupt pins (assumed to be synchronous)
    input irq0_sync,       
    input irq1_sync,

    output acknowledge_irq0,
    output acknowledge_irq1,       
    
    //PC signals (from housekeeping)
    input [XLEN-1:0]        PC_step,
    input [XLEN-1:0]        next_program_PC,

    //Control
    input                   control_transfer_en,
    input                   next_stage_en,
    input                   mie,

    // Outputs to core
    output reg              mepc_we,    
    output reg [XLEN-1:0]   PC_to_mepc
);

// ------------------------------------------------------------
// Pipeline stages
// ------------------------------------------------------------
localparam IF  = 3'd0;
localparam EX  = 3'd2;

// ------------------------------------------------------------
// FSM states
// ------------------------------------------------------------
localparam S_IDLE               = 2'd0;
localparam S_TRACK              = 2'd1;
localparam S_TAKE_WAIT_CLEAR    = 2'd2;

reg [1:0] state, next_state;

wire interrupt_active;
assign interrupt_active = irq0_sync | irq1_sync;

// ------------------------------------------------------------
// Stage tracker
// ------------------------------------------------------------
reg [2:0] stage_tracker;
reg [2:0] next_stage;
//Next stage
always @(*) begin
    next_stage = stage_tracker;

    if (state != S_TRACK)
        next_stage = IF;
    else if (next_stage_en)
        next_stage = stage_tracker + 3'd1;
end
//Stage tracker
always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        stage_tracker <= IF;
    else
        stage_tracker <= next_stage;
end

// ------------------------------------------------------------
// Interrupt take causes
// ------------------------------------------------------------
wire take_interrupt;
wire take_forced;
wire take_natural;

assign take_forced  = // Force the finish of lifetime
    (state == S_TRACK) && 
    (
        control_transfer_en &&
        (stage_tracker <= EX)
    );

assign take_natural = (state == S_TRACK) && (next_stage >= WB); // Lifetime finished naturally

assign take_interrupt = take_forced | take_natural;

// ------------------------------------------------------------
// FSM state register
// ------------------------------------------------------------
always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        state <= S_IDLE;
    else
        state <= next_state;
end

// ------------------------------------------------------------
// FSM next-state logic
// ------------------------------------------------------------
always @(*) begin
    next_state = state;

    case (state)

        S_IDLE: begin
            //Gets out of IDLE only if an interrupt occurs and it is globally enabled
            if (interrupt_active && mie)
                next_state = S_TRACK;
        end

        S_TRACK: begin
            if (take_interrupt)
                next_state = S_TAKE_WAIT_CLEAR;
        end

        S_TAKE_WAIT_CLEAR: begin
            if (!interrupt_active)
                next_state = S_IDLE;
        end

        default:
            next_state = S_IDLE;

    endcase
end

// ------------------------------------------------------------
// mepc saving logic
// ------------------------------------------------------------
always @(*) begin
    //Defaults
    mepc_we = 1'b0;
    PC_to_mepc = {XLEN{1'b0}};

    // Initial probe at IF
    if (state == S_TRACK && stage_tracker == IF && !control_transfer_en)begin
            PC_to_mepc = PC_step;
            mepc_we = 1'b1;           
        end

    // Forced finish: override with next_program_PC
    else if (take_forced)begin
        PC_to_mepc = next_program_PC;
        mepc_we = 1'b1;
    end
    // Natural finish: PC_saved will be the same as the one from the probe
end

// ------------------------------------------------------------
// Acknowledge generation (one-cycle pulse)
// ------------------------------------------------------------

// Priority: irq0 > irq1
assign acknowledge_irq0 = take_interrupt & irq0_sync;
assign acknowledge_irq1 = take_interrupt & irq1_sync & ~irq0_sync;

endmodule