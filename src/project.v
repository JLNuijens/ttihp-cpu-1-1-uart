/*
 * Copyright (c) 2026 Axiom 1 Technology, LLC
 * SPDX-License-Identifier: Apache-2.0
 *
 * Tiny Tapeout 6x4 — CPU 1.1 UART
 * One oscillator. FIRE. Pads. Clock count is the range.
 * UART / SPI / I2C walks. Stretch USB LS + 10 Mbit Manchester.
 * 16 bases, 16 pad/register sites. Not pasted IP.
 */
`default_nettype none

module tt_um_jlnuijens_one11_uart #(
  parameter N_BASES = 16
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
  wire line_in  = ui_in[2];
  wire [1:0] map  = ui_in[4:3];
  wire [2:0] rsel = ui_in[7:5];
  wire [31:0] seq = {24'd0, uio_in};

  reg fire_d;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) fire_d <= 1'b0;
    else        fire_d <= fire_pin;
  end
  wire fire = fire_pin & ~fire_d;
  wire hot  = hot_pin | ena;

  wire [15:0] cpb;
  js_range u_range (.sel(rsel), .clks(cpb));

  wire uart_f = fire & (map == 2'd0);
  wire spi_f  = fire & (map == 2'd1);
  wire i2c_f  = fire & (map == 2'd2);
  wire line_f = fire & (map == 2'd3);

  wire [31:0] s0 [0:N_BASES-1];
  wire [31:0] s1 [0:N_BASES-1];
  wire [31:0] sw [0:N_BASES-1];
  wire [31:0] sl [0:N_BASES-1];
  wire [31:0] ss [0:N_BASES-1];
  wire [31:0] cc [0:N_BASES-1];
  wire [1:0]  st [0:N_BASES-1];
  wire [31:0] px [0:N_BASES-1];

  wire        uart_tx, uart_busy, uart_rxb, uart_got;
  wire [31:0] r15_ones;
  wire [7:0]  uart_byte;

  js_uart_fire u_uart (
    .clk      (clk),
    .rst_n    (rst_n),
    .fire     (uart_f),
    .seq      (seq),
    .clks     (cpb),
    .rx       (line_in),
    .tx       (uart_tx),
    .r15      (r15_ones),
    .tx_busy  (uart_busy),
    .rx_byte  (uart_byte),
    .rx_busy  (uart_rxb),
    .rx_got   (uart_got)
  );

  wire spi_mosi, spi_sclk, spi_csn, spi_busy, spi_got;
  wire [7:0] spi_byte;
  js_spi_fire u_spi (
    .clk     (clk),
    .rst_n   (rst_n),
    .fire    (spi_f),
    .seq     (uio_in),
    .clks    (cpb),
    .miso    (line_in),
    .mosi    (spi_mosi),
    .sclk    (spi_sclk),
    .csn     (spi_csn),
    .busy    (spi_busy),
    .rx_byte (spi_byte),
    .rx_got  (spi_got)
  );

  wire i2c_scl, i2c_oe, i2c_sda, i2c_busy, i2c_ack, i2c_got;
  js_i2c_fire u_i2c (
    .clk     (clk),
    .rst_n   (rst_n),
    .fire    (i2c_f),
    .seq     (uio_in),
    .clks    (cpb),
    .sda_in  (uio_in[0]),
    .scl     (i2c_scl),
    .sda_oe  (i2c_oe),
    .sda_out (i2c_sda),
    .busy    (i2c_busy),
    .ack     (i2c_ack),
    .rx_got  (i2c_got)
  );

  wire line_dm, line_dp, line_busy;
  js_line_fire u_line (
    .clk       (clk),
    .rst_n     (rst_n),
    .fire      (line_f),
    .seq       (uio_in),
    .clks      (cpb),
    .usb_n_eth (rsel >= 3'd3),
    .dm        (line_dm),
    .dp        (line_dp),
    .busy      (line_busy)
  );

  wire [7:0] rx_byte =
      (map == 2'd1) ? spi_byte :
      uart_byte;
  wire got = uart_got | spi_got | i2c_got;
  wire busy = uart_busy | spi_busy | i2c_busy | line_busy | uart_rxb;

  reg got_d;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) got_d <= 1'b0;
    else        got_d <= got;
  end
  wire rx_strobe = got & ~got_d;

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

  assign uo_out[0] = (map == 2'd0) ? uart_tx : (map == 2'd3) ? line_dm : 1'b1;
  assign uo_out[1] = busy;
  assign uo_out[2] = (r15_ones == 32'h4F4E4553);
  assign uo_out[3] = (map == 2'd2) ? (got | ~i2c_ack) : (got | uart_rxb);
  assign uo_out[4] = (map == 2'd1) ? spi_mosi : (map == 2'd2) ? i2c_scl : wt_x[N_BASES][0];
  assign uo_out[5] = (map == 2'd1) ? spi_sclk : wt_x[N_BASES][1];
  assign uo_out[6] = (map == 2'd1) ? spi_csn  : wt_x[N_BASES][2];
  assign uo_out[7] = (map == 2'd3) ? line_dp : (wt_x[N_BASES][3] ^ px_x[N_BASES][0] ^ cy_x[N_BASES]);

  assign uio_out = {7'd0, i2c_sda};
  assign uio_oe  = {7'd0, (map == 2'd2) & i2c_oe};

  wire _unused = &{ena, s0[0], s1[0], sl[0], ss[0], st[0], i2c_ack, 1'b0};
endmodule
