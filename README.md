# FPGA-Roulette
A two-player Mine Roulette game implemented on a Basys 3 board.

# Game Details
Each game/match is initialized with player-specified number of landmines placed randomly between switches 0-13, inclusive. Players will take turns flipping these switches. For each switch, the digit display will show whether the player is "SAFE" or if they "LOSE". This repeats until someone loses. A point will then be incremented for the winning player.

# Game State/Modes
Game Mode
- Switch 14 = 0
- Active mode for gameplay

Score Mode
- Switch 14 = 1
- Pause gameplay and enable button functionality for options

# Controls
- Switches 0-13:    Player/landmine switches
- Switch 14:        Score/game mode toggle
- Switch 15:        Match reset toggle
- BTNC (Mid)        Confirm switch flip
- BTNL (Left)       Decrease mine count at match start. Hard reset in Score Mode
- BTNR (Right)      Increase mine count at match start
- BTNU (Up)         Show Player 1 score in Score mode
- BTND (Down)       Show Player 2 score in Score mode


# Initial Structure
```
FPGA-Roulette/
│
├── README.md
│
├── src/                        # Verilog source files
│   ├── top.v                   # Top-level module; connects all submodules
│   ├── game_controller.v       # Main FSM: turn logic, win/loss detection
│   ├── mine_generator.v        # Pseudorandom mine assignment (LFSR or similar)
│   ├── switch_decoder.v        # Decodes SW0–SW13 input and debounces
│   ├── display_controller.v    # 7-segment mux, segment encoding, decimal points
│   ├── countdown.v             # Decimal-point blink sequencer
│   ├── score_keeper.v          # Win tally registers for Player 1 and Player 2
│   ├── mode_controller.v       # SW14/SW15 mode and reset logic
│   └── debounce.v              # Button/switch debouncer (shared utility)
│
├── constraints/
│   └── basys3.xdc              # Pin and timing constraints for the Basys 3 board
│
├── sim/                        # Simulation/testbench files
│   ├── tb_top.v                # Top-level testbench
│   ├── tb_game_controller.v    # FSM unit tests
│   ├── tb_mine_generator.v     # Mine randomization tests
│   ├── tb_display_controller.v # Display output tests
│   └── tb_score_keeper.v       # Score tracking tests
│
├── synth/                      # Vivado project and output files (gitignored except sources)
    └── .gitkeep
```
