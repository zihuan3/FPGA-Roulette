module game_controller #(
    parameter RESULT_TICKS = 100_000_000
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        game_mode,
    input  wire        match_reset,

    input  wire        btn_left,
    input  wire        btn_right,

    input  wire        move_valid,
    input  wire        invalid_move,
    input  wire [13:0] selected_switch,
    input  wire [13:0] mine_mask,

    input  wire        countdown_done,

    output reg         accept_moves,
    output reg         clear_used,
    output reg         regenerate_mines,
    output reg         countdown_start,

    output reg  [3:0]  mine_count,
    output reg         current_player,
    output reg         losing_player,
    output reg         match_lost,
    output reg  [2:0]  display_mode
);

    localparam STATE_SETUP     = 3'd0;
    localparam STATE_WAIT_MOVE = 3'd1;
    localparam STATE_COUNTDOWN = 3'd2;
    localparam STATE_SAFE      = 3'd3;
    localparam STATE_LOSE      = 3'd4;
    localparam STATE_INVALID   = 3'd5;

    localparam DISP_SETUP      = 3'd0;
    localparam DISP_WAIT       = 3'd1;
    localparam DISP_COUNTDOWN  = 3'd2;
    localparam DISP_SAFE       = 3'd3;
    localparam DISP_LOSE       = 3'd4;
    localparam DISP_INVALID    = 3'd5;

    reg [2:0] state;
    reg [13:0] latched_switch;
    reg btn_left_prev;
    reg btn_right_prev;
    reg [31:0] result_counter;

    wire btn_left_press;
    wire btn_right_press;
    wire selected_is_mine;

    assign btn_left_press  = btn_left && !btn_left_prev;
    assign btn_right_press = btn_right && !btn_right_prev;
    assign selected_is_mine = |(latched_switch & mine_mask);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state            <= STATE_SETUP;
            latched_switch   <= 14'b0;
            btn_left_prev    <= 1'b0;
            btn_right_prev   <= 1'b0;
            result_counter   <= 32'd0;
            accept_moves     <= 1'b0;
            clear_used       <= 1'b1;
            regenerate_mines <= 1'b1;
            countdown_start  <= 1'b0;
            mine_count       <= 4'd3;
            current_player   <= 1'b0;
            losing_player    <= 1'b0;
            match_lost       <= 1'b0;
            display_mode     <= DISP_SETUP;
        end else begin
            btn_left_prev    <= btn_left;
            btn_right_prev   <= btn_right;
            clear_used       <= 1'b0;
            regenerate_mines <= 1'b0;
            countdown_start  <= 1'b0;

            if (match_reset) begin
                state            <= STATE_SETUP;
                latched_switch   <= 14'b0;
                result_counter   <= 32'd0;
                accept_moves     <= 1'b0;
                clear_used       <= 1'b1;
                regenerate_mines <= 1'b1;
                current_player   <= 1'b0;
                losing_player    <= 1'b0;
                match_lost       <= 1'b0;
                display_mode     <= DISP_SETUP;
            end else begin
                case (state)
                    STATE_SETUP: begin
                        accept_moves <= game_mode;
                        match_lost   <= 1'b0;
                        display_mode <= DISP_SETUP;
                        regenerate_mines <= 1'b1;

                        if (btn_left_press && mine_count > 4'd1)
                            mine_count <= mine_count - 4'd1;
                        else if (btn_right_press && mine_count < 4'd9)
                            mine_count <= mine_count + 4'd1;

                        if (game_mode && move_valid) begin
                            latched_switch  <= selected_switch;
                            countdown_start <= 1'b1;
                            accept_moves    <= 1'b0;
                            state           <= STATE_COUNTDOWN;
                            display_mode    <= DISP_COUNTDOWN;
                        end else if (invalid_move) begin
                            accept_moves   <= 1'b0;
                            result_counter <= 32'd0;
                            state          <= STATE_INVALID;
                            display_mode   <= DISP_INVALID;
                        end
                    end

                    STATE_WAIT_MOVE: begin
                        accept_moves <= game_mode;
                        display_mode <= DISP_WAIT;

                        if (game_mode && move_valid) begin
                            latched_switch  <= selected_switch;
                            countdown_start <= 1'b1;
                            accept_moves    <= 1'b0;
                            state           <= STATE_COUNTDOWN;
                            display_mode    <= DISP_COUNTDOWN;
                        end else if (invalid_move) begin
                            accept_moves   <= 1'b0;
                            result_counter <= 32'd0;
                            state          <= STATE_INVALID;
                            display_mode   <= DISP_INVALID;
                        end
                    end

                    STATE_COUNTDOWN: begin
                        accept_moves <= 1'b0;
                        display_mode <= DISP_COUNTDOWN;

                        if (countdown_done) begin
                            result_counter <= 32'd0;

                            if (selected_is_mine) begin
                                losing_player <= current_player;
                                match_lost    <= 1'b1;
                                state         <= STATE_LOSE;
                                display_mode  <= DISP_LOSE;
                            end else begin
                                state        <= STATE_SAFE;
                                display_mode <= DISP_SAFE;
                            end
                        end
                    end

                    STATE_SAFE: begin
                        accept_moves <= 1'b0;
                        display_mode <= DISP_SAFE;

                        if (result_counter >= RESULT_TICKS - 1) begin
                            result_counter <= 32'd0;
                            current_player <= ~current_player;
                            state          <= STATE_WAIT_MOVE;
                            display_mode   <= DISP_WAIT;
                        end else begin
                            result_counter <= result_counter + 32'd1;
                        end
                    end

                    STATE_INVALID: begin
                        accept_moves <= 1'b0;
                        display_mode <= DISP_INVALID;

                        if (result_counter >= RESULT_TICKS - 1) begin
                            result_counter <= 32'd0;
                            state          <= STATE_WAIT_MOVE;
                            display_mode   <= DISP_WAIT;
                        end else begin
                            result_counter <= result_counter + 32'd1;
                        end
                    end

                    STATE_LOSE: begin
                        accept_moves <= 1'b0;
                        match_lost   <= 1'b1;
                        display_mode <= DISP_LOSE;
                    end

                    default: begin
                        state        <= STATE_SETUP;
                        display_mode <= DISP_SETUP;
                    end
                endcase
            end
        end
    end

endmodule
