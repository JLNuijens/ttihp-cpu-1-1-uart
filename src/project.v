/*
 * Copyright (c) 2026 Axiom 1 Technology, LLC
 * SPDX-License-Identifier: Apache-2.0
 *
 * Tiny Tapeout 6x4 — CPU 1.1 UART
 * Clock is the oscillator. RX and TX are the data pair.
 * 16 pad/register sites. 16 bases on the same clock.
 * 1 clock = 1 bit. UART is FIRE on the pads.
 */
`default_nettype none

module tt_um_jlnuijens_one11_uart #(
  parameter N_BASES      = 16,
  parameter CLKS_PER_BIT = 1
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
  wire rx_pin   = ui_in[2];
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
  wire [31:0] px [0:N_BASES-1];

  wire        tx, tx_busy, rx_busy, rx_got;
  wire [31:0] r15_ones;
  wire [7:0]  rx_byte;
  wire        rx_strobe;

  js_uart_fire #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_uart (
    .clk      (clk),
    .rst_n    (rst_n),
    .fire     (fire),
    .seq      (seq),
    .rx       (rx_pin),
    .tx       (tx),
    .r15      (r15_ones),
    .tx_busy  (tx_busy),
    .rx_byte  (rx_byte),
    .rx_busy  (rx_busy),
    .rx_got   (rx_got)
  );

  // rx_got is sticky; pulse one clock into the pads when it rises.
  reg rx_got_d;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) rx_got_d <= 1'b0;
    else        rx_got_d <= rx_got;
  end
  assign rx_strobe = rx_got & ~rx_got_d;

  genvar k;
  generate
    for (k = 0; k < N_BASES; k = k + 1) begin : bases
      wire [31:0] seq_k = seq + k;
      one_cpu11 #(.LANE(k)) u_cpu (
        .clk       (clk),
        .rst_n     (rst_n),
        .run_hot   (hot),
        .fire      (fire),
        .seq       (seq_k),
        .rx_strobe (rx_strobe),
        .rx_data   (rx_byte),
        .sig0      (s0[k]),
        .sig1      (s1[k]),
        .wt        (sw[k]),
        .last_seq  (sl[k]),
        .stride    (ss[k]),
        .cyc_o     (cc[k]),
        .status    (st[k]),
        .pad_xor   (px[k])
      );
    end
  endgenerate

  // Reduction so every base and every site is in the output cone.
  wire [3:0]  wt_x [0:N_BASES];
  wire        cy_x [0:N_BASES];
  wire [31:0] px_x [0:N_BASES];
  assign wt_x[0] = 4'd0;
  assign cy_x[0] = 1'b0;
  assign px_x[0] = 32'd0;
  generate
    for (k = 0; k < N_BASES; k = k + 1) begin : mix
      assign wt_x[k+1] = wt_x[k] ^ sw[k][3:0];
      assign cy_x[k+1] = cy_x[k] ^ cc[k][16];
      assign px_x[k+1] = px_x[k] ^ px[k];
    end
  endgenerate

  assign uo_out[0] = tx;
  assign uo_out[1] = tx_busy;
  assign uo_out[2] = (r15_ones == 32'h4F4E4553);
  assign uo_out[3] = rx_got | rx_busy;
  assign uo_out[7:4] = wt_x[N_BASES] ^ rx_byte[3:0] ^ {3'b000, cy_x[N_BASES]} ^ px_x[N_BASES][3:0];

  assign uio_out = 8'd0;
  assign uio_oe  = 8'd0;

  wire _unused = &{ena, ui_in[7:3], s0[0], s1[0], sl[0], ss[0], st[0], 1'b0};
endmodule
