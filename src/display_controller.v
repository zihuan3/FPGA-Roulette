// 7-segment signals are active low 
// 0 turns on the segment, 1 turns it off

module display_controller (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] display_mode,
    input  wire [3:0] mine_count, 
    input  wire [7:0] score,
    output reg  [6:0] seg,
    output reg  [3:0] an,
    output reg        dp
);

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
localparam MODE_MINE_SELECT = 3'd0;
localparam MODE_SAFE = 3'd1;
localparam MODE_LOSE = 3'd2;
localparam MODE_SCORE = 3'd3;
localparam MODE_COUNTDOWN = 3'd4;

always @(*) begin
    dp = 1'b1; // off by default
end

// refresh counter for multiplexing the 4 digits
reg [16:0] refresh_counter;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        refresh_counter <= 0;
    end else begin
        refresh_counter <= refresh_counter + 1;
    end
end

// top 2 bits of refresh counter determine which digit is active
wire [1:0] active_digit = refresh_counter[16:15];

// drive an and seg based on active_digit
always @(*) begin
    case (active_digit)
        2'b00: begin an = 4'b1110; seg = digit0_seg; end
        2'b01: begin an = 4'b1101; seg = digit1_seg; end
        2'b10: begin an = 4'b1011; seg = digit2_seg; end
        2'b11: begin an = 4'b0111; seg = digit3_seg; end
    endcase
end

// outputs to 7-segment display
reg [6:0] digit3_seg, digit2_seg, digit1_seg, digit0_seg;

// Function to convert a 4-bit digit (0-9) to its corresponding 7-segment encoding
function [6:0] digit_to_seg;
    input [3:0] digit;
    case (digit)
        4'd0: digit_to_seg = SEG_0;
        4'd1: digit_to_seg = SEG_1;
        4'd2: digit_to_seg = SEG_2;
        4'd3: digit_to_seg = SEG_3;
        4'd4: digit_to_seg = SEG_4;
        4'd5: digit_to_seg = SEG_5;
        4'd6: digit_to_seg = SEG_6;
        4'd7: digit_to_seg = SEG_7;
        4'd8: digit_to_seg = SEG_8;
        4'd9: digit_to_seg = SEG_9;
        default: digit_to_seg = 7'b1111111; // blank
    endcase
endfunction

always@(*) begin
    case (display_mode)
        MODE_SAFE: begin
            digit3_seg = SEG_S;
            digit2_seg = SEG_A;
            digit1_seg = SEG_F;
            digit0_seg = SEG_E;
        end
        MODE_LOSE: begin
            digit3_seg = SEG_L;
            digit2_seg = SEG_O;
            digit1_seg = SEG_S;
            digit0_seg = SEG_E;
        end
        MODE_MINE_SELECT: begin
            digit3_seg = 7'b1111111; // blank
            digit2_seg = 7'b1111111; // blank
            digit1_seg = digit_to_seg(mine_count / 10); // tens place of mine_count
            digit0_seg = digit_to_seg(mine_count % 10); // ones place of mine_count
        end
        MODE_SCORE: begin
            digit3_seg = 7'b1111111; // blank
            digit2_seg = 7'b1111111; // blank
            digit1_seg = digit_to_seg(score / 10); // tens place of score
            digit0_seg = digit_to_seg(score % 10); // ones place of score
        end
        MODE_COUNTDOWN: begin
            // decimal point blinking handled by countdown.v
            digit3_seg = 7'b1111111; // blank
            digit2_seg = 7'b1111111; // blank
            digit1_seg = 7'b1111111; // blank
            digit0_seg = 7'b1111111; // blank 
        end
        default: begin
            digit3_seg = 7'b1111111; // blank
            digit2_seg = 7'b1111111; // blank
            digit1_seg = 7'b1111111; // blank
            digit0_seg = 7'b1111111; // blank
        end
    endcase
end

endmodule