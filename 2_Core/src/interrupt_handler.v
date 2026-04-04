// =============================================================================
// File        : interrupt_handler.v
// Author      : Jhon Steven Pinto Hernandez
// Email       : jhonstevenpintoh@gmail.com
// Description :
//   Monitors interrupt signals and controls interrupt entry, MEPC updates, acknowledge outputs, and take conditions.
// =============================================================================

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
    input                   core_program_jump,
    input                   next_stage_en,
    input                   mie,

    // Outputs to core
    output reg              interrupt_mepc_we,    
    output reg [XLEN-1:0]   interrupt_PC_to_mepc,
    output wire             take_interrupt_0,
    output wire             take_interrupt_1
);

wire next_stage_valid = mie && next_stage_en;

// ------------------------------------------------------------
// Stage tracking
// ------------------------------------------------------------
localparam S_IF  = 3'd0;
localparam S_EX  = 3'd2;

// ------------------------------------------------------------
// FSM states
// ------------------------------------------------------------
localparam S_IDLE                 = 2'd0;
localparam S_TRACK                = 2'd1;
localparam S_TAKE_WAIT_CLEAR_0    = 2'd2;
localparam S_TAKE_WAIT_CLEAR_1    = 2'd3;

reg [1:0] state, next_state;

wire interrupt_request;
assign interrupt_request = irq0_sync | irq1_sync;

// ------------------------------------------------------------
// Stage tracker
// ------------------------------------------------------------
reg [2:0] stage_tracker;
//Next stage
wire [2:0] next_stage = stage_tracker + 3'd1;

//Stage tracker
always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        stage_tracker <= S_IF;
    else if (state != S_TRACK)
        stage_tracker <= S_IF;
    else if (next_stage_valid)
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
        core_program_jump &&
        (stage_tracker <= S_EX)
    );

assign take_natural = (state == S_TRACK) && (next_stage >= WB); // Lifetime finished naturally
assign take_interrupt = mie & (take_forced | take_natural);

// Priority: irq0 > irq1
assign take_interrupt_0 = take_interrupt & irq0_sync;
assign take_interrupt_1 = take_interrupt & irq1_sync & ~irq0_sync;

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
always @( * ) begin
    next_state = state;

    case (state)

        S_IDLE: begin
            //Gets out of IDLE only if an interrupt occurs and it is globally enabled
            if (interrupt_request)
                next_state = S_TRACK;
        end

        S_TRACK: begin
            if(next_stage_valid)begin
                if (take_interrupt_0)
                    next_state = S_TAKE_WAIT_CLEAR_0;
                else if(take_interrupt_1)
                    next_state = S_TAKE_WAIT_CLEAR_1;
            end
        end

        S_TAKE_WAIT_CLEAR_0: begin
            if (!irq0_sync)
                next_state = S_IDLE;
        end

        S_TAKE_WAIT_CLEAR_1: begin
            if (!irq1_sync)
                next_state = S_IDLE;
        end

    endcase
end

// ------------------------------------------------------------
// mepc saving logic
// ------------------------------------------------------------
always @( * ) begin
    //Defaults
    interrupt_mepc_we = 1'b0;
    interrupt_PC_to_mepc = {XLEN{1'b0}};
    
    if(next_stage_valid)begin
        // Initial probe at S_IF
        if (state == S_TRACK && stage_tracker == S_IF && !core_program_jump)begin
                interrupt_PC_to_mepc = PC_step;
                interrupt_mepc_we = 1'b1;           
        end

        // Forced finish: override with next_program_PC
        else if (take_forced)begin
            interrupt_PC_to_mepc = next_program_PC;
            interrupt_mepc_we = 1'b1;
        end
        // Natural finish: PC_saved will be the same as the one from the probe
    end
end

// ------------------------------------------------------------
// Acknowledge generation (one-cycle pulse)
// ------------------------------------------------------------
reg irq0_zrd, irq1_zrd;
always @(posedge clk, negedge reset_n) begin
    if(!reset_n)begin
        irq0_zrd <= 1'b1;
        irq1_zrd <= 1'b1;
    end
    else begin
        if(state == S_TAKE_WAIT_CLEAR_0)
            irq0_zrd <= 1'b0;
        else
            irq0_zrd <= 1'b1;
        if(state == S_TAKE_WAIT_CLEAR_1)
            irq1_zrd <= 1'b0;
        else
            irq1_zrd <= 1'b1;
    end
    
end
assign acknowledge_irq0 = (state == S_TAKE_WAIT_CLEAR_0) & irq0_zrd;
assign acknowledge_irq1 = (state == S_TAKE_WAIT_CLEAR_1) & irq1_zrd;

endmodule