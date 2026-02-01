`include "../../include/CORE_CONSTANTS.vh"

module mini_controller (
    //Global
    input clk,
    input reset_n,
    input pause,

    // Quadrants of upper and lower halfs of EIB
    input [1:0] EIB_1_quad,
    input [1:0] EIB_2_quad,
    
    input       pointer,          //-> points to the begginning or to the middle of the row
    input       core_jump,

    //Control
    output reg concatenate_in_next_cycle,
    output reg  concatenate_flag,
    output reg pause_to_concatenate,

    output reg  instr_type,
    output reg  sel_PC_step
    

);

//----------------------------------------rvi_lower, rvi_higher -> Determines if each part is an rvi instruction or not
wire rvi_lower;
wire rvi_higher;

assign rvi_lower = (EIB_1_quad == 2'b11);
assign rvi_higher = (EIB_2_quad == 2'b11);

// old core_jump -> retain the signal from previous instruction
reg old_core_jump;
always @(posedge clk, negedge reset_n) begin
    if(!reset_n)                       old_core_jump <= 1'b0;
    else if(pause_to_concatenate)      old_core_jump <= 1'b0; //Clean its value while making 1-cycle pause

    else if(!pause) begin
                                        old_core_jump <= core_jump;
    end
end

//------------------------------------------------- Outputs
// -> internal pause core to wait 1 extra cycle to fetch 2RV
always @( * ) begin
        pause_to_concatenate = 1'b0;

    if(!pause)
        pause_to_concatenate = rvi_higher & pointer & old_core_jump;
end

always @(*) begin
    concatenate_in_next_cycle = 1'b0;

    if(pause_to_concatenate)
        concatenate_in_next_cycle = 1'b1;
    else if(core_jump)                         //Clean if current instr is a jump
        concatenate_in_next_cycle = 1'b0;
    else if((rvi_higher & ~rvi_lower & ~pointer) || (rvi_higher & pointer))
        // -> concatenate in next cycle
        //   | 1RV | C  | , | 1RV | C  | , | 1RV | 2RV |
        concatenate_in_next_cycle = 1'b1;
end


// -> concatenate flag 
always @(posedge clk, negedge reset_n) begin
    if(!reset_n)                concatenate_flag <= 1'b0;

    else if(!pause)             concatenate_flag <= concatenate_in_next_cycle;
end


// -> instruction type & related PC step
always @( * ) begin
    sel_PC_step  = 1'b0;//X
    instr_type   = 1'b0;//X

    if(concatenate_flag)
            sel_PC_step  = `PC_STEP_4;
    else begin
        if((!rvi_lower && !pointer) || (!rvi_higher && pointer)) begin
            instr_type   = `C_INSTR;
            sel_PC_step  = `PC_STEP_2;
        end
            
        else if(rvi_lower && !pointer)begin
            instr_type   = `RVI_INSTR;
            sel_PC_step  = `PC_STEP_4;
        end
    end
end



endmodule