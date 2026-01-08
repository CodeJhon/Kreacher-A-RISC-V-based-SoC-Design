module up_counter #(
    parameter INCR      = 8, 
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
