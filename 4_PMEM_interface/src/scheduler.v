module scheduler#(
    parameter ADDR_BYTE_W = 17
)(
  // -------------------------------------------------------------------------
  // Global control inputs
  // -------------------------------------------------------------------------
    input wire clk,
    input wire reset_n,

    input wire [ADDR_BYTE_W-1:0]addr_inst,
    input wire [ADDR_BYTE_W-1:0]addr_data,
    input wire addr_inst_valid,
    input wire addr_data_valid,
    input wire cs_odd,
    input wire cs_even,


    output wire pause_to_schedule,
    output reg [ADDR_BYTE_W-1:0]addr_handler
);

// --------------------------------- Temp address holders
reg  [ADDR_BYTE_W-1:0]holded_addr;          // instruction fetch address that is stored in register to schedule for the next clock cycle
wire [ADDR_BYTE_W-1:0]scheduled_addr;       // addr that is used when address scheduler is enabled

// --------------------------------- flag signals
reg  a_hold_cycle;                   // flag that is used indicate which phase of scheduler   
wire addr_stall_enable = a_hold_cycle ? (addr_inst_valid && addr_data_valid) && (cs_odd && cs_even) // flag that is used as write enable for the register and to pause core
                                    : 1'b0;


// ==========================================================================
// Scheduler mode
// ==========================================================================
always@(posedge clk or negedge reset_n)begin
    if(!reset_n)begin
        holded_addr <= {ADDR_BYTE_W{1'b0}};  //deafult address 0 
        a_hold_cycle <= 1'b1;
    end
    else if(addr_stall_enable)begin
        holded_addr <= addr_inst;
        a_hold_cycle <= 1'b0;
    end
    else begin
        holded_addr <= {ADDR_BYTE_W{1'b0}};
        a_hold_cycle <= 1'b1;
    end
end

assign scheduled_addr = a_hold_cycle ? addr_data
                                     : holded_addr; 

// ==========================================================================
// Normal mode
// ==========================================================================
always@( * )begin
    if(!a_hold_cycle)begin
        addr_handler = scheduled_addr;
    end
    else if(addr_data_valid)begin
        addr_handler = addr_data;
    end
    else if(addr_inst_valid)begin
        addr_handler = addr_inst;
    end
    else begin
        addr_handler = {ADDR_BYTE_W{1'b0}};
    end
end

assign pause_to_schedule = addr_stall_enable;

endmodule