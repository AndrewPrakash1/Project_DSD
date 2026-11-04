// Button reader: looks at the button only once every ~20 ms so contact
// bounce is ignored. "press" is high for one clock when the button is pushed.
module button(
    input clk,
    input btn,
    output reg press
);
    reg [20:0] count = 0;   // counts 0 .. 2^21-1 (about 21 ms at 100 MHz)
    reg last = 0;           // button value at the previous check

    always @(posedge clk) begin
        count <= count + 1;
        press <= 0;
        if (count == 0) begin
            last <= btn;
            if (btn == 1 && last == 0)
                press <= 1;
        end
    end
endmodule
