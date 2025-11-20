module HCU #(parameter XLEN = 32)(
    //----------------------------ID Stage
    input [4:0]      EX_RS1_addr,
    input [4:0]      EX_RS2_addr,

    //----------------------------EX Stage
    output [1:0]     EX_sel_opa,
    output [1:0]     EX_sel_opb,

    //----------------------------MEM Stage
    input [4:0]      MEM_RD_addr_in,
    input            MEM_regfile_we_in,

    //----------------------------WB Stage
    input [4:0]      WB_RD_addr_in,
    input            WB_regfile_we_in

);
    
endmodule