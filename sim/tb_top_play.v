`timescale 1ns / 1ps

module tb_top_play;

    reg clk;
    reg [15:0] sw;
    reg btnC;
    reg btnU;
    reg btnL;
    reg btnR;
    reg btnD;

    wire [6:0] seg;
    wire [3:0] an;
    wire dp;

    integer failures;

    top #(
        .COUNTDOWN_STEP_TICKS(4),
        .RESULT_TICKS(8),
        .DEBOUNCE_CLK_FRQ(100_000_000),
        .DEBOUNCE_SAMPLE_FRQ(10_000_000)
    ) uut (
        .clk(clk),
        .sw(sw),
        .btnC(btnC),
        .btnU(btnU),
        .btnL(btnL),
        .btnR(btnR),
        .btnD(btnD),
        .seg(seg),
        .an(an),
        .dp(dp)
    );

    always #5 clk = ~clk;

    task wait_cycles;
        input integer cycles;
        integer i;
        begin
            for (i = 0; i < cycles; i = i + 1)
                @(posedge clk);
        end
    endtask

    task press_center;
        begin
            btnC = 1'b1;
            wait_cycles(20);
            btnC = 1'b0;
            wait_cycles(20);
        end
    endtask

    task press_right;
        begin
            btnR = 1'b1;
            wait_cycles(20);
            btnR = 1'b0;
            wait_cycles(20);
        end
    endtask

    task press_up;
        begin
            btnU = 1'b1;
            wait_cycles(20);
            btnU = 1'b0;
            wait_cycles(20);
        end
    endtask

    task check_score;
        input [3:0] expected_p1;
        input [3:0] expected_p2;
        begin
            if (uut.player1_score == expected_p1 && uut.player2_score == expected_p2) begin
                $display("PASS: score P1=%0d P2=%0d", uut.player1_score, uut.player2_score);
            end else begin
                $display("FAIL: expected score P1=%0d P2=%0d, got P1=%0d P2=%0d",
                         expected_p1, expected_p2, uut.player1_score, uut.player2_score);
                failures = failures + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        sw = 16'b0;
        btnC = 1'b0;
        btnU = 1'b0;
        btnL = 1'b0;
        btnR = 1'b0;
        btnD = 1'b0;
        failures = 0;

        $dumpfile("FPGA-Roulette/sim_output/top_play.vcd");
        $dumpvars(0, tb_top_play);

        wait_cycles(40000);

        force uut.mine_mask = 14'b00000000000001;
        $display("Forced mine layout: SW0 is a mine, all other switches are safe.");

        press_right;
        $display("Mine count after pressing right: %0d", uut.mine_count);

        sw[1] = 1'b1;
        press_center;
        wait_cycles(40);
        $display("After Player 1 selects SW1: display_mode=%0d match_lost=%0d current_player=%0d",
                 uut.game_display_mode, uut.match_lost, uut.current_player);

        wait_cycles(20);

        sw[0] = 1'b1;
        press_center;
        wait_cycles(40);
        $display("After Player 2 selects SW0: display_mode=%0d match_lost=%0d losing_player=%0d",
                 uut.game_display_mode, uut.match_lost, uut.losing_player);

        wait_cycles(5);
        check_score(4'd1, 4'd0);

        sw[13:0] = 14'b0;
        sw[14] = 1'b1;
        wait_cycles(10);
        press_up;
        $display("Score mode=%0d, showing Player 1 score=%0d", uut.score_mode, uut.player1_score);

        if (failures == 0)
            $display("TOP PLAY SIM PASSED.");
        else
            $display("%0d TOP PLAY SIM FAILURE(S).", failures);

        $finish;
    end

endmodule
