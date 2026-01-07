module mini_controller (
    //Global
    input clk,
    input reset,
    input pause,

    // Quadrants of upper and lower halfs of EIB
    input [1:0] EIB_1_quad,
    input [1:0] EIB_2_quad,

    input sel_next_PC,

    //Control
    output sel_concatenation,

        //To housekeeping
    output sel_PC_step,

        //To fetch
    output sel_EIB_2,
    output sel_instr_tpye
    

);

//----------------------------------------c_1, c_2 -> Determines if each part is a compressed instruction or not
wire c_1;
wire c_2;

assign c_1 = ~(EIB_1_quad == 2'b11);
assign c_2 = ~(EIB_2_quad == 2'b11);

//----------------------------------------sel_concatenate_rvi 
//                                         -> Used for when wanting to concatenate 1_RV1 and 2_RVI in | 1_RVI |  RVC  | , |  RVC  | 2_RVI |   
reg sel_concatenate_rvi;
always @(posedge clk) begin
    if(reset)                   sel_concatenate_rvi <= 1'b0;
    else if(!pause) begin
        if(sel_next_PC)         sel_concatenate_rvi <= 1'b0;
                                //Signal is activated if it recognizes it is in a row type -> | 1_RVI |  RVC  | 
        else                    sel_concatenate_rvi <= ({c_2 , c_1} == 2'b01);     
    end
    
end

//-------------------------------- Output control assignation
assign sel_concatenation = sel_concatenate_rvi;

    //To housekeeping
assign sel_PC_step       = !sel_concatenate_rvi & c_1;

    //To fetch
assign sel_EIB_2         = c_1 | sel_concatenate_rvi;
assign sel_instr_tpye    = c_1;


endmodule