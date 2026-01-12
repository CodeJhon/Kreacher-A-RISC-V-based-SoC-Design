module pause_handler (
    //Global
    input clk,
    input reset_n,
    
    //Control
    input external_pause,

    //Pause requests
    input IF_pause_request,
    //Output to stages
    output pause_IF,
    output pause_ID
);

// Reset synchronizer -> async assert / sync deassert
reg reset_n_sync;
always @(posedge clk or negedge reset_n) begin
    if (!reset_n)  reset_n_sync <= 1'b0;
    else           reset_n_sync <= 1'b1;
end

//General pause -> external or sync reset
wire pause_core_general = ~reset_n_sync | external_pause;

//Pause output to stages
assign pause_IF = pause_core_general;
assign pause_ID = pause_core_general | IF_pause_request;

endmodule