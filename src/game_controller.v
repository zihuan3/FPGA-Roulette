module game_controller (
    input  wire        clk,
    input  wire        rst,
    // switches
    input  wire [15:0] sw,
    // buttons
    input  wire        btnC,
    input  wire        btnU,
    input  wire        btnL,
    input  wire        btnR,
    input  wire        btnD,
    // display
    output reg  [2:0]  display_mode,
    // mine generator
    output reg  [3:0]  mine_count,
    // score keeper
    output reg  [7:0]  score_p1,
    output reg  [7:0]  score_p2
);

    // TODO: implement FSM
    // States: MINE_SELECT, PLAYER_TURN, COUNTDOWN, SHOW_RESULT, MATCH_OVER, SCORE_MODE

endmodule