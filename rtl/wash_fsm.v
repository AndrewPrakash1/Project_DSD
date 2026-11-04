// Washing machine controller - Moore FSM with the stage timer.
//
// IDLE --start (door closed)--> FILL -> WASH -> RINSE -> SPIN -> DONE --start--> IDLE
// FILL/WASH/RINSE/SPIN --door open or pause--> PAUSE --resume (door closed)--> same stage
// reset --> IDLE
module wash_fsm(
    input clk,
    input reset,
    input start,        // one-clock pulses from the buttons
    input pause,
    input resume,
    input door,         // 1 = door closed
    input tick,         // one pulse per second
    input [1:0] mode,   // 00 quick, 01 normal, 10 heavy, 11 delicate

    output reg [2:0] state,
    output reg [2:0] saved_state,   // stage to go back to after PAUSE
    output reg [5:0] stage_left,    // seconds left in this stage
    output reg [5:0] total_left,    // seconds left in the whole cycle

    // Moore outputs (depend only on the state)
    output running,
    output fill_valve,
    output wash_motor,
    output rinse_valve,
    output spin_motor,
    output door_lock,
    output done_led,
    output paused_led,
    output [3:0] stage_leds,   // {spin, rinse, wash, fill}
    output [2:0] rgb           // {red, green, blue}
);
    // state codes
    parameter IDLE  = 3'd0,
              FILL  = 3'd1,
              WASH  = 3'd2,
              RINSE = 3'd3,
              SPIN  = 3'd4,
              DONE  = 3'd5,
              PAUSE = 3'd6;

    // ---------- stage times for each mode ----------
    // The mode is saved in run_mode when the cycle starts,
    // so moving the switches during a cycle does nothing.
    reg [1:0] run_mode;
    reg [5:0] fill_t, wash_t, rinse_t, spin_t;
    wire [1:0] m = (state == IDLE) ? mode : run_mode;

    always @(*) begin
        case (m)
            2'b00:   begin fill_t = 3; wash_t = 8;  rinse_t = 4; spin_t = 5;  end // Quick    (20 s)
            2'b01:   begin fill_t = 5; wash_t = 12; rinse_t = 6; spin_t = 8;  end // Normal   (31 s)
            2'b10:   begin fill_t = 6; wash_t = 16; rinse_t = 8; spin_t = 10; end // Heavy    (40 s)
            default: begin fill_t = 4; wash_t = 10; rinse_t = 6; spin_t = 3;  end // Delicate (23 s)
        endcase
    end

    // ---------- state register + timer ----------
    always @(posedge clk) begin
        if (reset) begin
            state       <= IDLE;
            saved_state <= FILL;
            stage_left  <= 0;
        end else begin
            case (state)
                IDLE: begin
                    total_left <= fill_t + wash_t + rinse_t + spin_t;
                    if (start && door) begin
                        run_mode   <= mode;
                        stage_left <= fill_t;
                        state      <= FILL;
                    end
                end

                FILL: begin
                    if (!door || pause) begin
                        saved_state <= FILL;
                        state       <= PAUSE;
                    end else if (tick) begin
                        total_left <= total_left - 1;
                        if (stage_left == 1) begin
                            stage_left <= wash_t;
                            state      <= WASH;
                        end else
                            stage_left <= stage_left - 1;
                    end
                end

                WASH: begin
                    if (!door || pause) begin
                        saved_state <= WASH;
                        state       <= PAUSE;
                    end else if (tick) begin
                        total_left <= total_left - 1;
                        if (stage_left == 1) begin
                            stage_left <= rinse_t;
                            state      <= RINSE;
                        end else
                            stage_left <= stage_left - 1;
                    end
                end

                RINSE: begin
                    if (!door || pause) begin
                        saved_state <= RINSE;
                        state       <= PAUSE;
                    end else if (tick) begin
                        total_left <= total_left - 1;
                        if (stage_left == 1) begin
                            stage_left <= spin_t;
                            state      <= SPIN;
                        end else
                            stage_left <= stage_left - 1;
                    end
                end

                SPIN: begin
                    if (!door || pause) begin
                        saved_state <= SPIN;
                        state       <= PAUSE;
                    end else if (tick) begin
                        total_left <= total_left - 1;
                        if (stage_left == 1) begin
                            stage_left <= 0;
                            state      <= DONE;
                        end else
                            stage_left <= stage_left - 1;
                    end
                end

                PAUSE: begin
                    if (resume && door)
                        state <= saved_state;
                end

                DONE: begin
                    if (start)
                        state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // ---------- Moore outputs ----------
    assign running     = (state == FILL) || (state == WASH) || (state == RINSE) || (state == SPIN);
    assign fill_valve  = (state == FILL);
    assign wash_motor  = (state == WASH);
    assign rinse_valve = (state == RINSE);
    assign spin_motor  = (state == SPIN);
    assign door_lock   = running;
    assign done_led    = (state == DONE);
    assign paused_led  = (state == PAUSE);

    // stage LEDs also show which stage was paused
    assign stage_leds[0] = (state == FILL)  || (state == PAUSE && saved_state == FILL);
    assign stage_leds[1] = (state == WASH)  || (state == PAUSE && saved_state == WASH);
    assign stage_leds[2] = (state == RINSE) || (state == PAUSE && saved_state == RINSE);
    assign stage_leds[3] = (state == SPIN)  || (state == PAUSE && saved_state == SPIN);

    // RGB: blue = idle, green = running, red = paused, white = done
    assign rgb = running          ? 3'b010 :
                 (state == PAUSE) ? 3'b100 :
                 (state == DONE)  ? 3'b111 :
                                    3'b001;
endmodule
