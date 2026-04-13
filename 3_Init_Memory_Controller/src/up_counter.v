// =============================================================================
// File        : up_counter.v
// Author      : Sanjai Palanisamy
// Email       : sanjai.palanisamy171@gmail.com
// Description :
//   This module implements a parameterized address counter that increments by a fixed 
// step on enable and wraps back to a base address when the maximum limit is reached.
// =============================================================================
module up_counter #(
    parameter integer ADDR_W         = 17,  
    parameter [ADDR_W-1:0] INCR       = 8, 
    parameter LOAD_DIM  = 17,
    parameter COUNT_DIM = 17
)(
    input clk,
    input enable,
    input reset_n,
    input  [LOAD_DIM-1:0]  load_value,
    input  [COUNT_DIM-1:0]  max_value,
    output reg [LOAD_DIM-1:0] count
);

always @(posedge clk, negedge reset_n) begin
    if (!reset_n) begin // base address should be loaded 
        count <= load_value;
    end
    else if(enable) begin// when during initialization and r valid, it should be incremented for the new address
        if((count + INCR) > max_value)begin
            count <= load_value;
        end
        else begin
            count <= count + INCR;
        end
    end
    else begin
        count <= count;
    end
end

endmodule
