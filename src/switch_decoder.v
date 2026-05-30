// Decodes switches SW0-SW13 into a single valid player move.
//
// Game rule supported by this module:
// - Once a switch has been successfully selected, it stays raised
//   for the rest of the match.
// - Each new move must add exactly one new raised switch.
// - Previously selected switches may not be lowered during a match.
// - The center button confirms the player's attempted move.

module switch_decoder (
    input  wire        clk,
    input  wire        rst,

    // Goes high for one cycle when a new match begins.
    // Clears the history of previously used switches.
    input  wire        clear_used,

    // High only when the game controller is accepting player moves.
    // For example, this should be low during LOSE or the animation.
    input  wire        accept_moves,

    // Debounced center-button level.
    // This module converts it into a one-cycle press event internally.
    input  wire        confirm_btn,

    // Physical positions of SW0-SW13.
    input  wire [13:0] game_switches,

    // Pulses high for one cycle when a valid new switch is confirmed.
    output reg         move_valid,

    // Pulses high for one cycle when an invalid attempted move is confirmed.
    output reg         invalid_move,

    // One-hot value for the newest accepted switch.
    // Example: switch 3 selected => 14'b00000000001000
    output reg  [13:0] selected_switch,

    // One-hot history of every accepted switch during this match.
    output reg  [13:0] used_switches
);

    // Stores the previous cleaned center-button value.
    // This lets us detect one press instead of repeatedly accepting
    // moves while the button remains held down.
    reg confirm_btn_prev;

    // High for exactly one clock cycle when the center button
    // changes from not pressed to pressed.
    wire confirm_press;
    assign confirm_press = confirm_btn && !confirm_btn_prev;

    // Bits that are currently raised but have not already been used.
    wire [13:0] newly_raised_switches;
    assign newly_raised_switches = game_switches & ~used_switches;

    // Detects whether a player lowered a previously accepted switch.
    // That is illegal because safe switches stay raised for the match.
    wire lowered_used_switch;
    assign lowered_used_switch = |(used_switches & ~game_switches);

    // Returns 1 only when exactly one switch bit is high.
    function exactly_one_switch;
        input [13:0] switch_value;
        begin
            case (switch_value)
                14'b00000000000001,
                14'b00000000000010,
                14'b00000000000100,
                14'b00000000001000,
                14'b00000000010000,
                14'b00000000100000,
                14'b00000001000000,
                14'b00000010000000,
                14'b00000100000000,
                14'b00001000000000,
                14'b00010000000000,
                14'b00100000000000,
                14'b01000000000000,
                14'b10000000000000:
                    exactly_one_switch = 1'b1;

                default:
                    exactly_one_switch = 1'b0;
            endcase
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            confirm_btn_prev <= 1'b0;
            move_valid        <= 1'b0;
            invalid_move      <= 1'b0;
            selected_switch   <= 14'b0;
            used_switches     <= 14'b0;
        end else begin
            // Remember the button state for press detection.
            confirm_btn_prev <= confirm_btn;

            // These outputs are pulses, so they normally return to 0
            // every clock cycle unless a move is confirmed below.
            move_valid   <= 1'b0;
            invalid_move <= 1'b0;

            // At the beginning of a new match, forget all old selections.
            if (clear_used) begin
                selected_switch <= 14'b0;
                used_switches   <= 14'b0;
            end else if (accept_moves && confirm_press) begin

                // Invalid: an already-used switch was lowered.
                if (lowered_used_switch) begin
                    invalid_move <= 1'b1;

                // Valid: exactly one new switch was added.
                end else if (exactly_one_switch(newly_raised_switches)) begin
                    selected_switch <= newly_raised_switches;
                    used_switches   <= used_switches | newly_raised_switches;
                    move_valid      <= 1'b1;

                // Invalid: no new switch, or multiple new switches,
                // were raised before center was pressed.
                end else begin
                    invalid_move <= 1'b1;
                end
            end
        end
    end

endmodule