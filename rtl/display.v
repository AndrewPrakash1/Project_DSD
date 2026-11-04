// Drives both 4-digit 7-segment displays.
// Right display: seconds left (2 digits). Left display: state word.
// Segments and anodes are active-low (0 = on). Segment order: {dp,g,f,e,d,c,b,a}.
// Only one digit is on at a time; a counter switches digits every ~1.3 ms,
// which is too fast for the eye to see.
module display(
    input clk,
    input [2:0] state,
    input [5:0] time_left,
    output reg [7:0] seg_r,
    output reg [3:0] an_r,
    output reg [7:0] seg_l,
    output [3:0] an_l
);
    reg [18:0] count = 0;
    always @(posedge clk)
        count <= count + 1;

    wire [1:0] digit = count[18:17];   // which digit is on: 0 = rightmost

    // ---------- right display: time ----------
    wire [3:0] tens = time_left / 10;
    wire [3:0] ones = time_left % 10;
    reg  [3:0] num;

    always @(*) begin
        case (digit)
            2'd0:    begin an_r = 4'b1110; num = ones; end
            2'd1:    begin an_r = 4'b1101; num = tens; end
            default: begin an_r = 4'b1111; num = 0;    end   // left two digits off
        endcase

        case (num)
            4'd0: seg_r = 8'hC0;
            4'd1: seg_r = 8'hF9;
            4'd2: seg_r = 8'hA4;
            4'd3: seg_r = 8'hB0;
            4'd4: seg_r = 8'h99;
            4'd5: seg_r = 8'h92;
            4'd6: seg_r = 8'h82;
            4'd7: seg_r = 8'hF8;
            4'd8: seg_r = 8'h80;
            4'd9: seg_r = 8'h90;
            default: seg_r = 8'hFF;
        endcase
    end

    // ---------- left display: state word ----------
    // letter patterns
    // I=F9 d=A1 L=C7 E=86 F=8E U=C1 A=88 S=92 H=89 r=AF n=AB P=8C o=A3
    reg [7:0] c3, c2, c1, c0;   // c3 = leftmost letter

    always @(*) begin
        case (state)
            3'd0:    begin c3 = 8'hF9; c2 = 8'hA1; c1 = 8'hC7; c0 = 8'h86; end // IdLE
            3'd1:    begin c3 = 8'h8E; c2 = 8'hF9; c1 = 8'hC7; c0 = 8'hC7; end // FILL
            3'd2:    begin c3 = 8'hC1; c2 = 8'h88; c1 = 8'h92; c0 = 8'h89; end // UASH
            3'd3:    begin c3 = 8'hAF; c2 = 8'hF9; c1 = 8'hAB; c0 = 8'h92; end // rInS
            3'd4:    begin c3 = 8'h92; c2 = 8'h8C; c1 = 8'hF9; c0 = 8'hAB; end // SPIn
            3'd5:    begin c3 = 8'hA1; c2 = 8'hA3; c1 = 8'hAB; c0 = 8'h86; end // donE
            3'd6:    begin c3 = 8'h8C; c2 = 8'h88; c1 = 8'hC1; c0 = 8'h92; end // PAUS
            default: begin c3 = 8'hFF; c2 = 8'hFF; c1 = 8'hFF; c0 = 8'hFF; end
        endcase

        case (digit)
            2'd0: seg_l = c0;
            2'd1: seg_l = c1;
            2'd2: seg_l = c2;
            default: seg_l = c3;
        endcase
    end

    // left display uses all 4 digits
    assign an_l = (digit == 2'd0) ? 4'b1110 :
                  (digit == 2'd1) ? 4'b1101 :
                  (digit == 2'd2) ? 4'b1011 :
                                    4'b0111;
endmodule
