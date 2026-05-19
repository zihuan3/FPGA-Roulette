# FPGA-Roulette
A two-player Mine Roulette game implemented on a Basys 3 board.


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
│   └── .gitkeep
│
└── docs/
    ├── proposal.md             # Original project proposal
    ├── fsm_diagram.pdf         # State machine diagram
    └── block_diagram.pdf       # Top-level block diagram
```
