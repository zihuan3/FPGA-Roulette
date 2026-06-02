module mode_controller (
    input  wire        clk,
    input  wire        rst,
    input  wire [13:0] game_switches,
    input  wire        score_toggle,
    input  wire        reset_toggle,

    output reg         score_mode,
    output wire        game_mode,
    output reg         hard_reset_pulse,
    output wire        toggles_allowed
);

    reg reset_toggle_prev;

    assign game_mode       = ~score_mode;
    assign toggles_allowed = (game_switches == 14'b0);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            score_mode        <= 1'b0;
            reset_toggle_prev <= 1'b0;
            hard_reset_pulse  <= 1'b0;
        end else begin
            hard_reset_pulse  <= 1'b0;
            reset_toggle_prev <= reset_toggle;

            if (toggles_allowed) begin
                score_mode <= score_toggle;

                if (reset_toggle && !reset_toggle_prev)
                    hard_reset_pulse <= 1'b1;
            end
        end
    end

endmodule
