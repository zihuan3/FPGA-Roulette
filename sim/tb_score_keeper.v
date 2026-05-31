`timescale 1ns / 1ps

module tb_score_keeper;

    // Fake input signals that we control in the simulation.
    reg clk;
    reg rst;
    reg match_lost;
    reg losing_player;
    reg reset_scores;

    // Outputs coming from the score_keeper module.
    wire [3:0] player1_score;
    wire [3:0] player2_score;

    integer i;

    // Create the score_keeper module that we are testing.
    score_keeper uut (
        .clk(clk),
        .rst(rst),
        .match_lost(match_lost),
        .losing_player(losing_player),
        .reset_scores(reset_scores),
        .player1_score(player1_score),
        .player2_score(player2_score)
    );

    // Make a fake clock.
    // Every 5 nanoseconds the clock switches value.
    // This makes one full clock cycle take 10 nanoseconds.
    always #5 clk = ~clk;

    // Helper task that checks whether the score is correct.
    task check_score;
        input [3:0] expected_player1;
        input [3:0] expected_player2;
        input [8*60-1:0] test_name;
        begin
            if (player1_score == expected_player1 &&
                player2_score == expected_player2) begin
                $display("PASS: %0s | P1 = %0d, P2 = %0d",
                         test_name, player1_score, player2_score);
            end else begin
                $display("FAIL: %0s | Expected P1 = %0d, P2 = %0d, but got P1 = %0d, P2 = %0d",
                         test_name,
                         expected_player1, expected_player2,
                         player1_score, player2_score);
            end
        end
    endtask

    initial begin
        // Initial values.
        clk           = 1'b0;
        rst           = 1'b0;
        match_lost    = 1'b0;
        losing_player = 1'b0;
        reset_scores  = 1'b0;

        // --------------------------------------------
        // Test 1: Full reset starts both scores at zero
        // --------------------------------------------
        rst = 1'b1;
        #12;
        rst = 1'b0;

        @(posedge clk);
        #1;
        check_score(4'd0, 4'd0, "System reset clears both scores");

        // --------------------------------------------
        // Test 2: Player 1 loses, so Player 2 gains one point
        // --------------------------------------------
        @(negedge clk);
        losing_player = 1'b0;
        match_lost    = 1'b1;

        @(posedge clk);
        #1;
        check_score(4'd0, 4'd1, "Player 1 loses, Player 2 gains a point");

        // --------------------------------------------
        // Test 3: LOSE remains displayed for several cycles
        // Score must not keep increasing
        // --------------------------------------------
        repeat (3) begin
            @(posedge clk);
            #1;
        end

        check_score(4'd0, 4'd1, "Holding LOSE does not repeatedly add points");

        // Clear the loss condition before the next match.
        @(negedge clk);
        match_lost = 1'b0;

        @(posedge clk);
        #1;

        // --------------------------------------------
        // Test 4: Player 2 loses, so Player 1 gains one point
        // --------------------------------------------
        @(negedge clk);
        losing_player = 1'b1;
        match_lost    = 1'b1;

        @(posedge clk);
        #1;
        check_score(4'd1, 4'd1, "Player 2 loses, Player 1 gains a point");

        // Clear loss before resetting scores.
        @(negedge clk);
        match_lost = 1'b0;

        @(posedge clk);
        #1;

        // --------------------------------------------
        // Test 5: Score reset clears both scores
        // --------------------------------------------
        @(negedge clk);
        reset_scores = 1'b1;

        @(posedge clk);
        #1;
        check_score(4'd0, 4'd0, "Score reset returns scoreboard to zero");

        @(negedge clk);
        reset_scores = 1'b0;

        // --------------------------------------------
        // Test 6: Player 1 score stops increasing at 9
        // Simulate Player 2 losing ten times.
        // --------------------------------------------
        for (i = 0; i < 10; i = i + 1) begin
            @(negedge clk);
            losing_player = 1'b1;
            match_lost    = 1'b1;

            @(posedge clk);
            #1;

            @(negedge clk);
            match_lost = 1'b0;

            @(posedge clk);
            #1;
        end

        check_score(4'd9, 4'd0, "Player 1 score is capped at nine");

        $display("--------------------------------------------");
        $display("Finished testing score_keeper.");
        $display("--------------------------------------------");

        $finish;
    end

endmodule