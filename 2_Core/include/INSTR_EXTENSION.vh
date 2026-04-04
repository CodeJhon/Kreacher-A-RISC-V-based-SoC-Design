// =============================================================================
// File        : INSTR_EXTENSION.vh
// Author      : Jhon Steven Pinto Hernandez
// Email       : jhonstevenpintoh@gmail.com
// Description :
//   Declares instruction extension encodings, support macros, and extension-related constants for compressed and custom instructions.
// =============================================================================
    `ifndef INSTR_EXTENSION_VH
    `define INSTR_EXTENSION_VH
    
    // Quadrant
    `define QUADRANT_0 2'b00
    `define QUADRANT_1 2'b01
    `define QUADRANT_2 2'b10
    
    `define X_0 5'b00000
    `define X_1 5'b00001
    `define X_2 5'b00010

    `define FUNCT_6_OP   6'b100011		
    `define FUNCT_6_OPW  6'b100111		

    `define C_FUNCT4_JR_MV     4'b1000
    `define C_FUNCT4_JALR_ADD  4'b1001

    `define FUNCT7_ALU_ADD  7'b0000000
    `define FUNCT7_ALU_SUB  7'b0100000

    `define FUNCT6_SHIFT_LOGICAL   6'b000000
    `define FUNCT6_SHIFT_ARITHMETIC 6'b010000
		
		
    

    `endif
