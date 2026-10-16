/*
 * Copyright (c) 2026 RodRedRiver
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Adapter between the standard Tiny Tapeout pins and the Tiny8 CPU.
//   uo_out[7:0]  -> address bus: which program byte the CPU wants
//   ui_in[7:0]   <- data bus: the program byte at that address (from an external memory / the RP2040)
//   uio_out[7:0] -> output port: whatever the program last OUTput
module tt_um_rodredriver_calc (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire halted;

  cpu core (
      .clk     (clk),
      .rst     (~rst_n),
      .mem_addr(uo_out),
      .mem_data(ui_in),
      .out_port(uio_out),
      .halted  (halted)
  );

  assign uio_oe = 8'hFF;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in, halted, 1'b0};

endmodule
