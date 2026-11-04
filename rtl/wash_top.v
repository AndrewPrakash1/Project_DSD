// Washing Machine Controller - top module for the Boolean Board.
//
// BTN0 start, BTN1 pause, BTN2 resume, BTN3 reset
// SW1-SW0 mode, SW2 turbo, SW15 door (1 = closed)
module wash_top(
    input clk,
    input [3:0] btn,
    input [15:0] sw,
    output [15:0] led,
    output [2:0] rgb0,
    output [7:0] seg_r,
    output [3:0] an_r,
    output [7:0] seg_l,
    output [3:0] an_l
);
    wire start, pause, resume, tick, running;
    wire [2:0] state, saved_state;
    wire [5:0] stage_left, total_left;

    button b0 (.clk(clk), .btn(btn[0]), .press(start));
    button b1 (.clk(clk), .btn(btn[1]), .press(pause));
    button b2 (.clk(clk), .btn(btn[2]), .press(resume));

    clock_divider div (.clk(clk), .turbo(sw[2]), .enable(running), .tick(tick));

    wash_fsm fsm (
        .clk(clk), .reset(btn[3]),
        .start(start), .pause(pause), .resume(resume),
        .door(sw[15]), .tick(tick), .mode(sw[1:0]),
        .state(state), .saved_state(saved_state),
        .stage_left(stage_left), .total_left(total_left),
        .running(running),
        .fill_valve(led[0]), .wash_motor(led[1]), .rinse_valve(led[2]), .spin_motor(led[3]),
        .door_lock(led[4]), .done_led(led[5]), .paused_led(led[6]),
        .stage_leds(led[10:7]), .rgb(rgb0)
    );

    display disp (
        .clk(clk), .state(state), .time_left(total_left),
        .seg_r(seg_r), .an_r(an_r), .seg_l(seg_l), .an_l(an_l)
    );

    // extra LEDs: mode switches, turbo, door
    assign led[12:11] = sw[1:0];
    assign led[13]    = 0;
    assign led[14]    = sw[2];
    assign led[15]    = sw[15];
endmodule
