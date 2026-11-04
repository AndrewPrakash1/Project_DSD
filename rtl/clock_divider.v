// Clock divider: makes a 1-clock "tick" pulse once per second from the 100 MHz clock.
// turbo = 1 makes the tick 10 times faster (10 ticks per second).
// enable = 0 stops the counter (used when the machine is paused).
module clock_divider(
    input clk,
    input turbo,
    input enable,
    output reg tick
);
    reg [26:0] count = 0;

    always @(posedge clk) begin
        tick <= 0;
        if (enable) begin
            if ((turbo == 0 && count >= 99999999) || (turbo == 1 && count >= 9999999)) begin
                count <= 0;
                tick  <= 1;
            end else begin
                count <= count + 1;
            end
        end
    end
endmodule
