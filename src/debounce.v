module debouncer #(
    parameter CLK_FRQ    = 100_000_000,
    parameter SAMPLE_FRQ = 1000
)(
    input  wire clk,
    input  wire rst,
    input  wire noisy_in,
    output reg  clean_out
);

    reg sync_ff1, sync_ff2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_ff1 <= 0;
            sync_ff2 <= 0;
        end else begin
            sync_ff1 <= noisy_in;
            sync_ff2 <= sync_ff1;
        end
    end

    /* clock divider */
    localparam DIVISOR = CLK_FRQ / SAMPLE_FRQ;

    reg [$clog2(DIVISOR)-1:0] counter;
    reg sample_tick;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            sample_tick <= 1'b0;
        end else begin
            if (counter == DIVISOR - 1) begin
                counter <= 0;
                sample_tick <= 1'b1;
            end else begin
                counter <= counter + 1;
                sample_tick <= 1'b0;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clean_out <= 0;
        end else begin
            if (sample_tick) begin
                clean_out <= sync_ff2;
            end
        end
    end

endmodule
