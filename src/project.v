/*
 * Copyright (c) 2026 RodRedRiver
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Adapter between the standard Tiny Tapeout pins and our calculator core.
//   ui_in[7:0]  -> b (the number you type in)
//   uio_in[2:0] -> op (which operation)
//   uio_in[3]   -> go (1 = apply the operation on the next clock tick)
//   uo_out[7:0] <- acc (the result / display)
//   uio_out[4]  <- carry, uio_out[5] <- zero
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

  wire carry, zero;

  calc_core core (
      .clk  (clk),
      .rst  (~rst_n),
      .go   (uio_in[3]),
      .op   (uio_in[2:0]),
      .b    (ui_in),
      .acc  (uo_out),
      .carry(carry),
      .zero (zero)
  );

  // uio[3:0] are inputs (op, go); uio[5:4] are outputs (carry, zero); uio[7:6] unused
  assign uio_out = {2'b00, zero, carry, 4'b0000};
  assign uio_oe  = 8'b0011_0000;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in[7:4], 1'b0};

endmodule
