// 7-segment signals are active low 
// 0 turns on the segment, 1 turns it off

// Segment mapping for characters S, A, F, E, L, O, U and digits 0-9
localparam SEG_S = 7'b0100100; // S
localparam SEG_A = 7'b0001000; // A
localparam SEG_F = 7'b0111000; // F
localparam SEG_E = 7'b0110000; // E
localparam SEG_L = 7'b1110001; // L
localparam SEG_O = 7'b0000001; // O
localparam SEG_U = 7'b1000001; // U
localparam SEG_0 = 7'b0000001; // 0
localparam SEG_1 = 7'b1001111; // 1
localparam SEG_2 = 7'b0010010; // 2
localparam SEG_3 = 7'b0000110; // 3
localparam SEG_4 = 7'b1001100; // 4
localparam SEG_5 = 7'b0100100; // 5
localparam SEG_6 = 7'b0100000; // 6
localparam SEG_7 = 7'b0001111; // 7
localparam SEG_8 = 7'b0000000; // 8
localparam SEG_9 = 7'b0000100; // 9

