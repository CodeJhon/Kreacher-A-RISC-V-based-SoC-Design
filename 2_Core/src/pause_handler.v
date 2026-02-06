module pause_handler (
    //Global
    input clk,
    input reset_n,

    //Flags
    output reg reset_n_sync,

    // Interrupt pins (assumed to be synchronous)
    input irq0_sync,       
    input irq1_sync,
    
    //Control
    input sleep,

    //Pause requests (external)
    input pause_request_scheduler,
    input pause_request_initialization,
    input pause_request_load_store,
    input pause_request_partial_store,
    
    //Pause requests (internal)
    input IF_pause_request,
    input EX_pause_request,
    
    //Output to stages
    output pause_IF,
    output pause_ID,
    output pause_EX,
    output pause_MEM,
    //Indicator of next stage
    output next_stage_en
);

//Sleep mode: Activated through WFI and cleared when an interrupt is received

reg wake_up; //Delays the wake up for 1 cycle after the interrupt was pressed
always @(posedge clk or negedge reset_n) begin
    if (!reset_n)  
        wake_up <= 1'b0;
    else if(irq0_sync || irq1_sync)
        wake_up <= 1'b1;
    else
        wake_up <= 1'b0;
end

wire sleep_mode = ~wake_up & sleep;

// Reset synchronizer -> async assert / sync deassert
always @(posedge clk or negedge reset_n) begin
    if (!reset_n)  reset_n_sync <= 1'b0;
    else           reset_n_sync <= 1'b1;
end

//General pause -> external or sync reset
wire pause_core_general =   ~reset_n_sync                   |
                            sleep_mode                      |

                            pause_request_initialization    |
                            pause_request_load_store        |
                            pause_request_scheduler         |
                            pause_request_partial_store;

wire EX_pause_request_real = (~IF_pause_request) & EX_pause_request; //Give priority to the IF pause request

//------------- Pause output to stages
assign pause_IF  = pause_core_general                    | EX_pause_request_real;
assign pause_ID  = pause_core_general | IF_pause_request | EX_pause_request_real;
assign pause_EX  = pause_core_general | IF_pause_request;
assign pause_MEM = pause_core_general | IF_pause_request | EX_pause_request_real;

//Indicator of next stage
assign next_stage_en = ~(
    pause_core_general |
    IF_pause_request   |
    EX_pause_request_real
);


endmodule