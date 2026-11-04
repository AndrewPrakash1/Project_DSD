# Washing Machine Controller

UEC612 Digital System Design (Thapar Institute), Sr. No. 11.

A Moore FSM washing-machine controller in Verilog, simulated in Vivado and implemented on the **Real Digital Boolean Board** (AMD Spartan-7 `xc7s50csga324-1`).

## Features

- Stages: **IDLE → FILL → WASH → RINSE → SPIN → DONE**
- Four wash modes (Quick, Normal, Heavy, Delicate)
- Door interlock: start is blocked while the door is open
- Pause / resume: opening the door or pressing Pause freezes the timer and turns actuators off; Resume only works when the door is closed
- Reset returns to IDLE from any state
- Remaining cycle time on the right 7-segment display
- State word on the left 7-segment display (`IdLE`, `FILL`, `UASH`, `rInS`, `SPIn`, `PAUS`, `donE`)
- Turbo switch runs the tick about 10× faster for demos

Mode is latched when a cycle starts, so flipping the mode switches mid-cycle does nothing.

## Hardware

| Item | Value |
|---|---|
| Board | Real Digital Boolean Board |
| FPGA | XC7S50CSGA324-1 |
| Clock | 100 MHz on pin F14 |
| Tools | Vivado 2026.1 (WebPACK) |

## Board mapping

| Control | Function |
|---|---|
| BTN0 | Start |
| BTN1 | Pause |
| BTN2 | Resume |
| BTN3 | Reset (hold) |
| SW[1:0] | Mode: 00 Quick, 01 Normal, 10 Heavy, 11 Delicate |
| SW2 | Turbo (10 Hz ticks vs 1 Hz) |
| SW15 | Door (1 = closed, 0 = open) |
| LED0–3 | Fill valve, wash motor, rinse valve, spin motor |
| LED4 | Door lock |
| LED5–6 | Done, paused |
| LED[10:7] | One-hot stage (fill / wash / rinse / spin) |
| LED[12:11] | Active mode |
| LED14 | Turbo |
| LED15 | Door closed |
| RGB0 | Blue idle, green running, red paused, white done |
| Right 7-seg | Remaining cycle time (seconds) |
| Left 7-seg | State word |

### Stage times (seconds)

| Mode | SW[1:0] | Fill | Wash | Rinse | Spin | Total |
|---|---|---|---|---|---|---|
| Quick | 00 | 3 | 8 | 4 | 5 | 20 |
| Normal | 01 | 5 | 12 | 6 | 8 | 31 |
| Heavy | 10 | 6 | 16 | 8 | 10 | 40 |
| Delicate | 11 | 4 | 10 | 6 | 3 | 23 |

## Repository layout

```
rtl/
  wash_top.v        Top-level pin connections
  wash_fsm.v        Moore FSM + stage / total timers
  clock_divider.v   1 Hz / 10 Hz tick from 100 MHz
  button.v          ~21 ms button debounce + press pulse
  display.v         Dual 4-digit 7-segment scanner
constraints/
  boolean.xdc       Boolean Board pins (LVCMOS33)
sim/
  tb_wash_fsm.v     Behavioral tests for the six plan cases
scripts/
  build.tcl         Create project, simulate, write bitstream
  program.tcl       Program the board over USB
```

Generated Vivado files (`vivado/`, logs) are gitignored. Rebuild them with `scripts/build.tcl`.

## Build and simulate

From a Vivado Tcl Shell, or:

```bat
C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -source scripts\build.tcl
```

This creates `vivado/wash_machine.xpr`, runs `tb_wash_fsm`, then writes:

`vivado/wash_machine.runs/impl_1/wash_top.bit`

To open the GUI project:

```bat
C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat vivado\wash_machine.xpr
```

## Program the board

1. Connect a data USB-C cable to the board port labeled **USB**.
2. Confirm the PWR LED is on (USB/EXTP jumper on USB if needed).
3. In Vivado: **Open Hardware Manager → Open target → Auto Connect**.
4. Right-click `xc7s50_0` → **Program Device** → `wash_top.bit`.

Or, with the board already connected:

```bat
C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -source scripts\program.tcl
```

After programming, the left display should show `IdLE` and the right display `31` (Normal mode).

## Demo checklist

1. SW15 up, SW[1:0] = 01, press BTN0 — full Normal cycle, timer from 31.
2. At `donE`, press BTN0 — back to `IdLE`.
3. SW15 down, press BTN0 — stays IDLE (door interlock).
4. Start, then open the door during `UASH` — `PAUS`, timer frozen, motor LED off.
5. Close the door and wait — still paused.
6. Press BTN2 — resume the same stage with remaining time.
7. Press BTN3 during `SPIn` — return to IDLE.
8. Mode 00 + SW2 up — Quick cycle in about 2 seconds.

## Course concepts

- D flip-flops for state and saved-stage registers
- Counters for the 1 s tick, debounce, stage timer, and display scan
- Multiplexer + decoder for the 7-segment displays
- Moore FSM (outputs depend only on the current state)
