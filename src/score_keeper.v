// Keeps track of Player 1 and Player 2 scores.
//
// Design choices:
// - player1_score and player2_score range from 0 to 9.
// - Scores stop increasing once they reach 9.
// - match_lost may remain high while "LOSE" is displayed.
//   This module detects only the rising edge so the winner receives
//   exactly one point per match.
// - reset_scores should only be asserted when:
//       score_mode == 1 and the left button is pressed.
// - Match reset using SW15 must NOT connect to reset_scores.

module score_keeper (
    input  wire       clk,
    input  wire       rst,

    // High while the game controller is showing the LOSE result.
    input  wire       match_lost,

    // Indicates which player hit the mine:
    // 0 = Player 1 lost, so Player 2 gets a point
    // 1 = Player 2 lost, so Player 1 gets a point
    input  wire       losing_player,

    // Clears both scores to 0.
    // This should come from BTNL while in Score Mode only.
    input  wire       reset_scores,

    output reg  [3:0] player1_score,
    output reg  [3:0] player2_score
);

    // Stores the previous value of match_lost so we can detect
    // only the moment the game first enters the LOSE condition.
    reg match_lost_prev;

    wire new_loss_event;

    assign new_loss_event = match_lost && !match_lost_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            player1_score  <= 4'd0;
            player2_score  <= 4'd0;
            match_lost_prev <= 1'b0;
        end else begin
            // Remember match_lost for rising-edge detection.
            match_lost_prev <= match_lost;

            // Resetting the scoreboard has highest priority.
            if (reset_scores) begin
                player1_score <= 4'd0;
                player2_score <= 4'd0;
            end else if (new_loss_event) begin
                if (losing_player == 1'b0) begin
                    // Player 1 hit a mine, so Player 2 wins.
                    if (player2_score < 4'd9)
                        player2_score <= player2_score + 4'd1;
                end else begin
                    // Player 2 hit a mine, so Player 1 wins.
                    if (player1_score < 4'd9)
                        player1_score <= player1_score + 4'd1;
                end
            end
        end
    end

endmodule