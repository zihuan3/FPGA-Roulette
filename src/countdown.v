module countdown #(
    parameter STEP_TICKS = 25_000_000
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       start,

    output reg        active,
    output reg        done,
    output reg [3:0]  dp_mask
);

    reg [1:0] step;
    reg [31:0] tick_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            active     <= 1'b0;
            done       <= 1'b0;
            dp_mask    <= 4'b0000;
            step       <= 2'd0;
            tick_count <= 32'd0;
        end else begin
            done <= 1'b0;

            if (start && !active) begin
                // Start with rightmost decimal point and advance one step every STEP_TICKS clocks.
                active     <= 1'b1;
                step       <= 2'd0;
                tick_count <= 32'd0;
                dp_mask    <= 4'b0001;
            end else if (active) begin
                if (tick_count >= STEP_TICKS - 1) begin
                    tick_count <= 32'd0;

                    if (step == 2'd3) begin
                        // After the fourth step, reset the display and pulse done so the game FSM can continue.
                        active  <= 1'b0;
                        done    <= 1'b1;
                        dp_mask <= 4'b0000;
                    end else begin
                        step    <= step + 2'd1;
                        dp_mask <= 4'b0001 << (step + 2'd1);
                    end
                end else begin
                    tick_count <= tick_count + 32'd1;
                end
            end else begin
                dp_mask <= 4'b0000;
            end
        end
    end

endmodule
