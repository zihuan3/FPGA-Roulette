module top #(
    parameter COUNTDOWN_STEP_TICKS = 100_000_000,
    parameter RESULT_TICKS         = 100_000_000,
    parameter DEBOUNCE_CLK_FRQ     = 100_000_000,
    parameter DEBOUNCE_SAMPLE_FRQ  = 1000
)(
    input  wire        clk,
    input  wire [15:0] sw,
    input  wire        btnC,
    input  wire        btnU,
    input  wire        btnL,
    input  wire        btnR,
    input  wire        btnD,

    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire        dp
);

    reg [15:0] startup_counter = 16'd0;
    wire startup_rst;

    wire btnC_clean;
    wire btnU_clean;
    wire btnL_clean;
    wire btnR_clean;
    wire btnD_clean;

    wire score_mode;
    wire game_mode;
    wire hard_reset_pulse;
    wire toggles_allowed;

    wire move_valid;
    wire invalid_move;
    wire [13:0] selected_switch;
    wire [13:0] used_switches;

    wire accept_moves;
    wire clear_used_game;
    wire regenerate_mines_game;
    wire countdown_start;
    wire [3:0] mine_count;
    wire current_player;
    wire losing_player;
    wire match_lost;
    wire [2:0] game_display_mode;

    wire [13:0] mine_mask;
    wire countdown_active;
    wire countdown_done;
    wire [3:0] countdown_dp_mask;

    wire [3:0] player1_score;
    wire [3:0] player2_score;
    wire score_reset;
    wire clear_used;
    wire regenerate_mines;

    wire [6:0] seg_internal;
    wire hard_reset;
    wire match_reset_only;

    assign startup_rst = ~startup_counter[15];
    assign score_reset = hard_reset | (score_mode && btnL_clean);
    assign clear_used = clear_used_game | hard_reset;
    assign regenerate_mines = regenerate_mines_game | hard_reset;
    assign seg = {seg_internal[0], seg_internal[1], seg_internal[2], 
                  seg_internal[3], seg_internal[4], seg_internal[5], seg_internal[6]};
    assign hard_reset = hard_reset_pulse && btnC_clean;
    assign match_reset_only = hard_reset_pulse && !btnC_clean;

    always @(posedge clk) begin
        if (!startup_counter[15])
            startup_counter <= startup_counter + 16'd1;
    end

    debouncer #(
        .CLK_FRQ(DEBOUNCE_CLK_FRQ),
        .SAMPLE_FRQ(DEBOUNCE_SAMPLE_FRQ)
    ) db_center (
        .clk(clk),
        .rst(startup_rst),
        .noisy_in(btnC),
        .clean_out(btnC_clean)
    );

    debouncer #(
        .CLK_FRQ(DEBOUNCE_CLK_FRQ),
        .SAMPLE_FRQ(DEBOUNCE_SAMPLE_FRQ)
    ) db_up (
        .clk(clk),
        .rst(startup_rst),
        .noisy_in(btnU),
        .clean_out(btnU_clean)
    );

    debouncer #(
        .CLK_FRQ(DEBOUNCE_CLK_FRQ),
        .SAMPLE_FRQ(DEBOUNCE_SAMPLE_FRQ)
    ) db_left (
        .clk(clk),
        .rst(startup_rst),
        .noisy_in(btnL),
        .clean_out(btnL_clean)
    );

    debouncer #(
        .CLK_FRQ(DEBOUNCE_CLK_FRQ),
        .SAMPLE_FRQ(DEBOUNCE_SAMPLE_FRQ)
    ) db_right (
        .clk(clk),
        .rst(startup_rst),
        .noisy_in(btnR),
        .clean_out(btnR_clean)
    );

    debouncer #(
        .CLK_FRQ(DEBOUNCE_CLK_FRQ),
        .SAMPLE_FRQ(DEBOUNCE_SAMPLE_FRQ)
    ) db_down (
        .clk(clk),
        .rst(startup_rst),
        .noisy_in(btnD),
        .clean_out(btnD_clean)
    );

    mode_controller mode_unit (
        .clk(clk),
        .rst(startup_rst),
        .game_switches(sw[13:0]),
        .score_toggle(sw[14]),
        .reset_toggle(sw[15]),
        .score_mode(score_mode),
        .game_mode(game_mode),
        .hard_reset_pulse(hard_reset_pulse),
        .toggles_allowed(toggles_allowed)
    );

    switch_decoder switch_unit (
        .clk(clk),
        .rst(startup_rst),
        .clear_used(clear_used),
        .accept_moves(accept_moves && game_mode),
        .confirm_btn(btnC_clean),
        .game_switches(sw[13:0]),
        .move_valid(move_valid),
        .invalid_move(invalid_move),
        .selected_switch(selected_switch),
        .used_switches(used_switches)
    );

    game_controller #(
        .RESULT_TICKS(RESULT_TICKS)
    ) game_unit (
        .clk(clk),
        .rst(startup_rst),
        .game_mode(game_mode),
        .match_reset(hard_reset_pulse),
        .btn_left(btnL_clean && game_mode),
        .btn_right(btnR_clean && game_mode),
        .move_valid(move_valid),
        .invalid_move(invalid_move),
        .selected_switch(selected_switch),
        .mine_mask(mine_mask),
        .countdown_done(countdown_done),
        .accept_moves(accept_moves),
        .clear_used(clear_used_game),
        .regenerate_mines(regenerate_mines_game),
        .countdown_start(countdown_start),
        .mine_count(mine_count),
        .current_player(current_player),
        .losing_player(losing_player),
        .match_lost(match_lost),
        .display_mode(game_display_mode)
    );

    mine_generator mine_unit (
        .clk(clk),
        .rst(startup_rst),
        .regenerate(regenerate_mines),
        .mine_count(mine_count),
        .mine_mask(mine_mask)
    );

    countdown #(
        .STEP_TICKS(COUNTDOWN_STEP_TICKS)
    ) countdown_unit (
        .clk(clk),
        .rst(startup_rst),
        .start(countdown_start),
        .active(countdown_active),
        .done(countdown_done),
        .dp_mask(countdown_dp_mask)
    );

    score_keeper score_unit (
        .clk(clk),
        .rst(startup_rst),
        .match_lost(match_lost),
        .losing_player(losing_player),
        .reset_scores(score_reset),
        .player1_score(player1_score),
        .player2_score(player2_score)
    );

    display_controller display_unit (
        .clk(clk),
        .rst(startup_rst),
        .score_mode(score_mode),
        .show_player1_score(btnU_clean),
        .show_player2_score(btnD_clean),
        .player1_score(player1_score),
        .player2_score(player2_score),
        .game_display_mode(game_display_mode),
        .mine_count(mine_count),
        .current_player(current_player),
        .countdown_dp_mask(countdown_dp_mask),
        .seg(seg_internal),
        .an(an),
        .dp(dp)
    );

endmodule
