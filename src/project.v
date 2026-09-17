/*
 * Copyright (c) 2026 Axiom 1 Technology, LLC
 * SPDX-License-Identifier: Apache-2.0
 *
 * Tiny Tapeout 6x4 — CPU 1.1 UART
 * 1.1 class line. 16 pad/register sites inside. 16 bases on the same clock.
 * UART is a FIRE bitstream on TX.
 */
`default_nettype none

module tt_um_jlnuijens_one11_uart #(
  parameter N_BASES      = 16,
  parameter CLKS_PER_BIT = 8
) (
  input  wire [7:0] ui_in,
  output wire [7:0] uo_out,
  input  wire [7:0] uio_in,
  output wire [7:0] uio_out,
  output wire [7:0] uio_oe,
  input  wire       ena,
  input  wire       clk,
  input  wire       rst_n
);
  wire fire_pin = ui_in[0];
  wire hot_pin  = ui_in[1];
  wire [31:0] seq = {24'd0, uio_in};

  reg fire_d;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) fire_d <= 1'b0;
    else        fire_d <= fire_pin;
  end
  wire fire = fire_pin & ~fire_d;
  wire hot  = hot_pin | ena;

  wire [31:0] s0 [0:N_BASES-1];
  wire [31:0] s1 [0:N_BASES-1];
  wire [31:0] sw [0:N_BASES-1];
  wire [31:0] sl [0:N_BASES-1];
  wire [31:0] ss [0:N_BASES-1];
  wire [31:0] cc [0:N_BASES-1];
  wire [1:0]  st [0:N_BASES-1];

  genvar k;
  generate
    for (k = 0; k < N_BASES; k = k + 1) begin : bases
      one_cpu11 u_cpu (
        .clk      (clk),
        .rst_n    (rst_n),
        .run_hot  (hot),
        .fire     (fire),
        .seq      (seq + k),
        .lane     (k),
        .sig0     (s0[k]),
        .sig1     (s1[k]),
        .wt       (sw[k]),
        .last_seq (sl[k]),
        .stride   (ss[k]),
        .cyc_o    (cc[k]),
        .status   (st[k])
      );
    end
  endgenerate

  wire        tx, busy;
  wire [31:0] r15_ones;

  js_uart_fire #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_uart (
    .clk   (clk),
    .rst_n (rst_n),
    .fire  (fire),
    .seq   (seq),
    .tx    (tx),
    .r15   (r15_ones),
    .busy  (busy)
  );

  assign uo_out[0] = tx;
  assign uo_out[1] = busy;
  assign uo_out[2] = (r15_ones == 32'h4F4E4553);
  assign uo_out[3] = cc[0][16];
  assign uo_out[7:4] = sw[0][3:0];

  assign uio_out = 8'd0;
  assign uio_oe  = 8'd0;

  wire _unused = &{ena, ui_in[7:2], s0[0], s1[0], sl[0], ss[0], st[0], 1'b0};
endmodule
