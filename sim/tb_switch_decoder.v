`timescale 1ns / 1ps

module tb_switch_decoder;

    reg         clk;
    reg         rst;
    reg         clear_used;
    reg         accept_moves;
    reg         confirm_btn;
    reg  [13:0] game_switches;

    wire        move_valid;
    wire        invalid_move;
    wire [13:0] selected_switch;
    wire [13:0] used_switches;

    integer failures;

    // Convenient names for specific game switches.
    localparam [13:0] S1  = 14'd2;      // SW1
    localparam [13:0] S3  = 14'd8;      // SW3
    localparam [13:0] S5  = 14'd32;     // SW5
    localparam [13:0] S6  = 14'd64;     // SW6
    localparam [13:0] S8  = 14'd256;    // SW8
    localparam [13:0] S10 = 14'd1024;   // SW10

    switch_decoder uut (
        .clk(clk),
        .rst(rst),
        .clear_used(clear_used),
        .accept_moves(accept_moves),
        .confirm_btn(confirm_btn),
        .game_switches(game_switches),
        .move_valid(move_valid),
        .invalid_move(invalid_move),
        .selected_switch(selected_switch),
        .used_switches(used_switches)
    );

    // Fake 100 MHz-style clock for simulation:
    // changes every 5 ns, so one full cycle is 10 ns.
    always #5 clk = ~clk;

    task check_state;
        input             expected_valid;
        input             expected_invalid;
        input [13:0]      expected_selected;
        input [13:0]      expected_used;
        input [8*80-1:0] test_name;
        begin
            if (move_valid      === expected_valid   &&
                invalid_move    === expected_invalid &&
                selected_switch === expected_selected &&
                used_switches   === expected_used) begin

                $display("PASS: %0s | valid=%0d invalid=%0d selected=%014b used=%014b",
                         test_name,
                         move_valid,
                         invalid_move,
                         selected_switch,
                         used_switches);
            end else begin
                $display("FAIL: %0s", test_name);
                $display("      Expected: valid=%0d invalid=%0d selected=%014b used=%014b",
                         expected_valid,
                         expected_invalid,
                         expected_selected,
                         expected_used);
                $display("      Got:      valid=%0d invalid=%0d selected=%014b used=%014b",
                         move_valid,
                         invalid_move,
                         selected_switch,
                         used_switches);
                failures = failures + 1;
            end
        end
    endtask

    // Presses the center button and stops immediately after the
    // clock edge where switch_decoder should react.
    task press_confirm;
        begin
            @(negedge clk);
            confirm_btn = 1'b1;

            @(posedge clk);
            #1;
        end
    endtask

    // Releases the center button so another future press can be detected.
    task release_confirm;
        begin
            @(negedge clk);
            confirm_btn = 1'b0;

            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        clk           = 1'b0;
        rst           = 1'b0;
        clear_used    = 1'b0;
        accept_moves  = 1'b1;
        confirm_btn   = 1'b0;
        game_switches = 14'b0;
        failures      = 0;

        // --------------------------------------------------
        // Test 1: Reset clears all stored switch information.
        // --------------------------------------------------
        rst = 1'b1;
        #12;
        rst = 1'b0;

        @(posedge clk);
        #1;
        check_state(1'b0, 1'b0, 14'b0, 14'b0,
                    "System reset clears switch history");

        // --------------------------------------------------
        // Test 2: Player selects SW3 as the first valid move.
        // --------------------------------------------------
        game_switches = S3;

        press_confirm;
        check_state(1'b1, 1'b0, S3, S3,
                    "Selecting exactly one new switch is valid");

        // --------------------------------------------------
        // Test 3: Holding center button must not process
        // a second move, even if another switch is raised.
        // --------------------------------------------------
        game_switches = S3 | S8;

        @(posedge clk);
        #1;
        check_state(1'b0, 1'b0, S3, S3,
                    "Holding confirm does not accept another move");

        release_confirm;

        // --------------------------------------------------
        // Test 4: After releasing and pressing center again,
        // SW8 is accepted as the new move.
        // --------------------------------------------------
        press_confirm;
        check_state(1'b1, 1'b0, S8, S3 | S8,
                    "Second player can select one additional switch");

        release_confirm;

        // --------------------------------------------------
        // Test 5: Raising two new switches at once is invalid.
        // SW5 and SW6 were both newly raised.
        // --------------------------------------------------
        game_switches = S3 | S8 | S5 | S6;

        press_confirm;
        check_state(1'b0, 1'b1, S8, S3 | S8,
                    "Selecting multiple new switches is invalid");

        release_confirm;

        // --------------------------------------------------
        // Test 6: After fixing the switches, a valid move
        // can still be made. Select SW10.
        // --------------------------------------------------
        game_switches = S3 | S8 | S10;

        press_confirm;
        check_state(1'b1, 1'b0, S10, S3 | S8 | S10,
                    "Valid move works after an invalid attempt");

        release_confirm;

        // --------------------------------------------------
        // Test 7: Lowering a previously used switch is invalid.
        // SW3 has been lowered even though it was already used.
        // --------------------------------------------------
        game_switches = S8 | S10;

        press_confirm;
        check_state(1'b0, 1'b1, S10, S3 | S8 | S10,
                    "Lowering a previously used switch is invalid");

        release_confirm;

        // --------------------------------------------------
        // Test 8: When moves are disabled, center press is ignored.
        // This represents animation, score mode, or LOSE state.
        // --------------------------------------------------
        accept_moves  = 1'b0;
        game_switches = S3 | S8 | S10 | S1;

        press_confirm;
        check_state(1'b0, 1'b0, S10, S3 | S8 | S10,
                    "Move input is ignored when game is not accepting moves");

        release_confirm;

        // --------------------------------------------------
        // Test 9: Starting a new match clears used switches.
        // Players have lowered all physical game switches first.
        // --------------------------------------------------
        accept_moves  = 1'b1;
        game_switches = 14'b0;

        @(negedge clk);
        clear_used = 1'b1;

        @(posedge clk);
        #1;
        check_state(1'b0, 1'b0, 14'b0, 14'b0,
                    "New match clears all used switches");

        @(negedge clk);
        clear_used = 1'b0;

        @(posedge clk);
        #1;

        // --------------------------------------------------
        // Test 10: A switch from the old match may now be
        // selected again because history was cleared.
        // --------------------------------------------------
        game_switches = S3;

        press_confirm;
        check_state(1'b1, 1'b0, S3, S3,
                    "Cleared switch may be used again in new match");

        release_confirm;

        $display("--------------------------------------------");

        if (failures == 0)
            $display("ALL SWITCH_DECODER TESTS PASSED.");
        else
            $display("%0d SWITCH_DECODER TEST(S) FAILED.", failures);

        $display("--------------------------------------------");

        $finish;
    end

endmodule