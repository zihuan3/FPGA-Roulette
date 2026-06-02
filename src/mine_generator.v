// Generates the hidden mine layout for switches SW0-SW13.
// A small LFSR keeps changing every clock to generate a roughly random starting point
module mine_generator (
    input  wire       clk,
    input  wire       rst,
    input  wire       regenerate,
    input  wire [3:0] mine_count,

    output reg [13:0] mine_mask
);

    reg [15:0] lfsr;
    integer i;
    integer idx;
    reg [13:0] next_mask;

    // Feedback taps for the 16-bit LFSR.
    wire feedback;
    assign feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr      <= 16'hACE1;
            mine_mask <= 14'b00000000000111;
        end else begin
            lfsr <= {lfsr[14:0], feedback};

            if (regenerate) begin
                next_mask = 14'b0;

                for (i = 0; i < 14; i = i + 1) begin
                    idx = (lfsr[3:0] + (i * 5) + lfsr[7:4]) % 14;

                    if (i < mine_count)
                        next_mask = next_mask | (14'b1 << idx);
                end

                mine_mask <= next_mask;
            end
        end
    end

endmodule
