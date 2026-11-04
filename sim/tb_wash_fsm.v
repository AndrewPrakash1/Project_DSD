`timescale 1ns / 1ps
// Testbench for the washing machine FSM.
// A fake "1 second" tick is made every 11 clocks so the test runs quickly.
module tb_wash_fsm;
    reg clk = 0;
    reg reset = 0;
    reg start = 0, pause = 0, resume = 0;
    reg door = 1;
    reg tick = 0;
    reg [1:0] mode = 2'b01;

    wire [2:0] state, saved_state;
    wire [5:0] stage_left, total_left;
    wire running, fill_valve, wash_motor, rinse_valve, spin_motor;
    wire door_lock, done_led, paused_led;
    wire [3:0] stage_leds;
    wire [2:0] rgb;

    integer errors = 0;
    reg [5:0] frozen;

    wash_fsm uut (
        .clk(clk), .reset(reset), .start(start), .pause(pause), .resume(resume),
        .door(door), .tick(tick), .mode(mode),
        .state(state), .saved_state(saved_state),
        .stage_left(stage_left), .total_left(total_left),
        .running(running), .fill_valve(fill_valve), .wash_motor(wash_motor),
        .rinse_valve(rinse_valve), .spin_motor(spin_motor), .door_lock(door_lock),
        .done_led(done_led), .paused_led(paused_led), .stage_leds(stage_leds), .rgb(rgb)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    // fake 1-second tick: high for one clock edge every 110 ns
    always begin
        #100 tick = 1;
        #10  tick = 0;
    end

    // print every state change
    always @(state)
        $display("time=%0t  state=%0d  stage_left=%0d  total_left=%0d", $time, state, stage_left, total_left);

    // state codes: 0 IDLE, 1 FILL, 2 WASH, 3 RINSE, 4 SPIN, 5 DONE, 6 PAUSE
    initial begin
        // reset
        reset = 1;
        #20 reset = 0;
        #20;

        // ---------- Test 1: normal mode full cycle ----------
        $display("--- Test 1: normal mode ---");
        mode = 2'b01;
        @(negedge clk) start = 1;
        @(negedge clk) start = 0;
        if (state == 1 && stage_left == 5 && total_left == 31) $display("PASS: FILL loads 5, total 31");
        else begin $display("FAIL: FILL"); errors = errors + 1; end

        wait (state == 2); #1;
        if (stage_left == 12) $display("PASS: WASH loads 12");
        else begin $display("FAIL: WASH"); errors = errors + 1; end

        mode = 2'b10;   // changing mode mid-cycle should be ignored
        wait (state == 3); #1;
        if (stage_left == 6) $display("PASS: RINSE loads 6 (mode change ignored)");
        else begin $display("FAIL: RINSE"); errors = errors + 1; end

        wait (state == 4); #1;
        if (stage_left == 8) $display("PASS: SPIN loads 8");
        else begin $display("FAIL: SPIN"); errors = errors + 1; end

        wait (state == 5); #1;
        if (total_left == 0 && done_led == 1) $display("PASS: DONE, timer at 0");
        else begin $display("FAIL: DONE"); errors = errors + 1; end

        @(negedge clk) start = 1;
        @(negedge clk) start = 0;
        if (state == 0) $display("PASS: DONE -> IDLE on start");
        else begin $display("FAIL: DONE -> IDLE"); errors = errors + 1; end
        mode = 2'b01;

        // ---------- Test 2: start with door open ----------
        $display("--- Test 2: start with door open ---");
        door = 0;
        @(negedge clk) start = 1;
        @(negedge clk) start = 0;
        #500;
        if (state == 0) $display("PASS: stays in IDLE with door open");
        else begin $display("FAIL: started with door open"); errors = errors + 1; end
        door = 1;

        // ---------- Test 3: door opened during wash ----------
        $display("--- Test 3: door open during wash ---");
        @(negedge clk) start = 1;
        @(negedge clk) start = 0;
        wait (state == 2);
        #400;
        @(negedge clk) door = 0;
        @(negedge clk);
        if (state == 6 && wash_motor == 0) $display("PASS: door open -> PAUSE, motor off");
        else begin $display("FAIL: PAUSE"); errors = errors + 1; end
        frozen = stage_left;
        #1000;
        if (stage_left == frozen) $display("PASS: timer frozen at %0d", frozen);
        else begin $display("FAIL: timer moved"); errors = errors + 1; end

        door = 1;
        #500;
        if (state == 6) $display("PASS: closing door alone does not resume");
        else begin $display("FAIL: resumed without button"); errors = errors + 1; end

        @(negedge clk) resume = 1;
        @(negedge clk) resume = 0;
        if (state == 2 && stage_left == frozen) $display("PASS: resume -> WASH with same time");
        else begin $display("FAIL: resume"); errors = errors + 1; end

        @(negedge clk) pause = 1;
        @(negedge clk) pause = 0;
        if (state == 6) $display("PASS: pause button -> PAUSE");
        else begin $display("FAIL: pause button"); errors = errors + 1; end
        @(negedge clk) resume = 1;
        @(negedge clk) resume = 0;

        // ---------- Test 4: reset during spin ----------
        $display("--- Test 4: reset during spin ---");
        wait (state == 4);
        #200;
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;
        if (state == 0) $display("PASS: reset -> IDLE");
        else begin $display("FAIL: reset"); errors = errors + 1; end

        // ---------- Test 5: quick and heavy modes ----------
        $display("--- Test 5: quick vs heavy ---");
        mode = 2'b00;
        @(negedge clk) start = 1;
        @(negedge clk) start = 0;
        if (stage_left == 3 && total_left == 20) $display("PASS: quick FILL 3, total 20");
        else begin $display("FAIL: quick"); errors = errors + 1; end
        wait (state == 2); #1;
        if (stage_left == 8) $display("PASS: quick WASH 8");
        else begin $display("FAIL: quick WASH"); errors = errors + 1; end
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;

        mode = 2'b10;
        @(negedge clk) start = 1;
        @(negedge clk) start = 0;
        if (stage_left == 6 && total_left == 40) $display("PASS: heavy FILL 6, total 40");
        else begin $display("FAIL: heavy"); errors = errors + 1; end
        wait (state == 2); #1;
        if (stage_left == 16) $display("PASS: heavy WASH 16");
        else begin $display("FAIL: heavy WASH"); errors = errors + 1; end
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;

        // ---------- result ----------
        if (errors == 0) $display("===== FSM TESTS PASSED =====");
        else             $display("===== %0d FSM TEST(S) FAILED =====", errors);
    end

    // ---------- Test 6: turbo tick from the real clock divider ----------
    reg turbo = 1;
    wire real_tick;
    time t1, t2;

    clock_divider div (.clk(clk), .turbo(turbo), .enable(1'b1), .tick(real_tick));

    initial begin
        @(posedge real_tick) t1 = $time;
        @(posedge real_tick) t2 = $time;
        $display("--- Test 6: turbo ---");
        $display("turbo tick every %0d clocks (normal mode: 100000000 clocks = 1 s)", (t2 - t1) / 10);
        if ((t2 - t1) / 10 == 10000000) $display("PASS: turbo is 10x faster");
        else $display("FAIL: turbo");
        $finish;
    end
endmodule
