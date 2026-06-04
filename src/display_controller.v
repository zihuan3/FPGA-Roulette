module display_controller (
    input  wire       clk,
    input  wire       rst,

    input  wire       score_mode,
    input  wire       show_player1_score,
    input  wire       show_player2_score,
// show_player2_score is held high by btnD_clean (level, not edge).
// P1 score is shown by default; P2 score is shown only while btnD is held.
// show_player1_score (btnU) is wired but unused — P1 is the default fallback.
    input  wire [3:0] player1_score,
    input  wire [3:0] player2_score,

    input  wire [2:0] game_display_mode,
    input  wire [3:0] mine_count,
    input  wire       current_player,
    input  wire [3:0] countdown_dp_mask,

    output reg  [6:0] seg,
    output reg  [3:0] an,
    output reg        dp
);

    localparam DISP_SETUP     = 3'd0;
    localparam DISP_WAIT      = 3'd1;
    localparam DISP_COUNTDOWN = 3'd2;
    localparam DISP_SAFE      = 3'd3;
    localparam DISP_LOSE      = 3'd4;
    localparam DISP_INVALID   = 3'd5;

    localparam SEG_BLANK = 7'b1111111;
    localparam SEG_DASH  = 7'b1111110;
    localparam SEG_A     = 7'b0001000;
    localparam SEG_E     = 7'b0110000;
    localparam SEG_F     = 7'b0111000;
    localparam SEG_I     = 7'b1001111;
    localparam SEG_L     = 7'b1110001;
    localparam SEG_N     = 7'b0001001;
    localparam SEG_O     = 7'b0000001;
    localparam SEG_P     = 7'b0011000;
    localparam SEG_S     = 7'b0100100;
    localparam SEG_V     = 7'b1000001;

    reg [15:0] refresh_counter;
    wire [1:0] digit_select;
    reg [6:0] digit0;
    reg [6:0] digit1;
    reg [6:0] digit2;
    reg [6:0] digit3;

    assign digit_select = refresh_counter[15:14];

    function [6:0] digit_to_seg;
        input [3:0] value;
        begin
            case (value)
                4'd0: digit_to_seg = 7'b0000001;
                4'd1: digit_to_seg = 7'b1001111;
                4'd2: digit_to_seg = 7'b0010010;
                4'd3: digit_to_seg = 7'b0000110;
                4'd4: digit_to_seg = 7'b1001100;
                4'd5: digit_to_seg = 7'b0100100;
                4'd6: digit_to_seg = 7'b0100000;
                4'd7: digit_to_seg = 7'b0001111;
                4'd8: digit_to_seg = 7'b0000000;
                4'd9: digit_to_seg = 7'b0000100;
                default: digit_to_seg = SEG_BLANK;
            endcase
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst)
            refresh_counter <= 16'd0;
        else
            refresh_counter <= refresh_counter + 16'd1;
    end

    always @(*) begin
        digit3 = SEG_BLANK;
        digit2 = SEG_BLANK;
        digit1 = SEG_BLANK;
        digit0 = SEG_BLANK;

        if (score_mode) begin
            digit3 = SEG_P;

            if (show_player2_score) begin
                digit2 = digit_to_seg(4'd2);
                digit1 = SEG_DASH;
                digit0 = digit_to_seg(player2_score);
            end else begin
                digit2 = digit_to_seg(4'd1);
                digit1 = SEG_DASH;
                digit0 = digit_to_seg(player1_score);
            end
        end else begin
            case (game_display_mode)
                DISP_SETUP: begin
                    digit3 = SEG_BLANK;
                    digit2 = SEG_BLANK;
                    digit1 = SEG_DASH;
                    digit0 = digit_to_seg(mine_count);
                end

                DISP_WAIT: begin
                    digit3 = SEG_P;
                    digit2 = digit_to_seg(current_player ? 4'd2 : 4'd1);
                    digit1 = SEG_DASH;
                    digit0 = SEG_DASH;
                end

                DISP_COUNTDOWN: begin
                    digit3 = SEG_DASH;
                    digit2 = SEG_DASH;
                    digit1 = SEG_DASH;
                    digit0 = SEG_DASH;
                end

                DISP_SAFE: begin
                    digit3 = SEG_S;
                    digit2 = SEG_A;
                    digit1 = SEG_F;
                    digit0 = SEG_E;
                end

                DISP_LOSE: begin
                    digit3 = SEG_L;
                    digit2 = SEG_O;
                    digit1 = SEG_S;
                    digit0 = SEG_E;
                end

                DISP_INVALID: begin
                    digit3 = SEG_I;
                    digit2 = SEG_N;
                    digit1 = SEG_V;
                    digit0 = SEG_BLANK;
                end

                default: begin
                    digit3 = SEG_BLANK;
                    digit2 = SEG_BLANK;
                    digit1 = SEG_BLANK;
                    digit0 = SEG_BLANK;
                end
            endcase
        end
    end

    always @(*) begin
        dp = 1'b1;

        case (digit_select)
            2'd0: begin
                an  = 4'b1110;
                seg = digit0;
                if (game_display_mode == DISP_COUNTDOWN)
                    dp = ~countdown_dp_mask[0];
            end

            2'd1: begin
                an  = 4'b1101;
                seg = digit1;
                if (game_display_mode == DISP_COUNTDOWN)
                    dp = ~countdown_dp_mask[1];
            end

            2'd2: begin
                an  = 4'b1011;
                seg = digit2;
                if (game_display_mode == DISP_COUNTDOWN)
                    dp = ~countdown_dp_mask[2];
            end

            default: begin
                an  = 4'b0111;
                seg = digit3;
                if (game_display_mode == DISP_COUNTDOWN)
                    dp = ~countdown_dp_mask[3];
            end
        endcase
    end

endmodule
