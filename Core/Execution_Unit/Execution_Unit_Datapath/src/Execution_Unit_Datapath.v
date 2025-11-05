module Execution_Unit_Datapath(
    input clk,
    input reset
    );


Internal_Bus Bus_A(
    .regfile_in(),
    .PC_in(),
    .T1_in(),
    
    .sel_in(),
    .sel_out(),
    
    operand(),
    regfile_out(),
    PC_out(),
    T1_out()
);

endmodule
