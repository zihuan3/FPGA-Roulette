module score_keeper (
    input  wire       clk,
    input  wire       rst,

    // High when the game controller is showing the LOSE result.
    input  wire       match_lost,

    // Tells us which player hit the mine:
    // 0 = Player 1 lost -> Player 2 gets a point
    // 1 = Player 2 lost -> Player 1 gets a point
    input  wire       losing_player,

    // Clears both scores to 0.
    // This should come from left button while in Score Mode only.
    input  wire       reset_scores,

    output reg  [3:0] player1_score,
    output reg  [3:0] player2_score
);

    // Stores the previous value of match_lost so we can detect
    // the moment when the game first enters the LOSE condition.
    // This prevents us from repeatedly adding points while the LOSE
    // condition remains true for several cycles.
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

            // Resets the score board (highest prio)
            if (reset_scores) begin
                player1_score <= 4'd0;
                player2_score <= 4'd0;
            end else if (new_loss_event) begin
                if (losing_player == 1'b0) begin
                    // Player 1 hit a mine, so player 2 wins, increment player 2's score.
                    if (player2_score < 4'd9)
                        player2_score <= player2_score + 4'd1;
                end else begin
                    // Player 2 hit a mine, so player 1 wins, increment player 1's score.
                    if (player1_score < 4'd9)
                        player1_score <= player1_score + 4'd1;
                end
            end
        end
    end

endmodule