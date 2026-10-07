/*
 * Copyright (c) 2026 Axiom 1 Technology, LLC
 * SPDX-License-Identifier: Apache-2.0
 *
 * Tiny Tapeout 6x4 — CPU 1.1 UART
 * One oscillator. FIRE. Pads. Clock count is the range.
 * UART / SPI / I2C walks. Stretch USB LS + 10 Mbit Manchester.
 * 2 stacks, 32 bases. 16 pad/register sites. UART walk is one copy.
 * Bank: 128 fired bytes, 128 received bytes, same clock.
 * OAM: the same CPU 1.1 again. Count off. The input is the low byte
 * of the live face, top 24 bits zero, same as the pad byte.
 */
`default_nettype none

module tt_um_jlnuijens_one11_uart #(
  parameter N_BASES = 32
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
  wire tap_sel = (rsel == 3'd1) || (rsel == 3'd3) || (rsel == 3'd4) || (rsel == 3'd6);
  wire on_tap = (map == 2'd3) && tap_sel;
  wire line_f = fire & (map == 2'd3) & ~tap_sel;
  wire tap_f  = fire & (map == 2'd3) & tap_sel;
  wire [1:0] tap_kind =
      (rsel == 3'd1) ? 2'd0 :
      (rsel == 3'd3) ? 2'd1 :
      (rsel == 3'd4) ? 2'd2 : 2'd3;

  wire [31:0] s0 [0:N_BASES-1];
  wire [31:0] s1 [0:N_BASES-1];
  wire [31:0] sw [0:N_BASES-1];
  wire [31:0] sl [0:N_BASES-1];
  wire [31:0] ss [0:N_BASES-1];
  wire [31:0] cc [0:N_BASES-1];
  wire [1:0]  st [0:N_BASES-1];
  wire [31:0] px [0:N_BASES-1];

  wire [31:0] os0 [0:N_BASES-1];
  wire [31:0] os1 [0:N_BASES-1];
  wire [31:0] osw [0:N_BASES-1];
  wire [31:0] osl [0:N_BASES-1];
  wire [31:0] oss [0:N_BASES-1];
  wire [31:0] occ [0:N_BASES-1];
  wire [1:0]  ost [0:N_BASES-1];
  wire [31:0] opx [0:N_BASES-1];

  wire        uart_tx, uart_busy, uart_rxb, uart_got, uart_have;
  wire [31:0] r15_ones;
  wire [7:0]  uart_byte;
  wire [3:0]  uart_diff;

  reg         uart_got_d;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) uart_got_d <= 1'b0;
    else        uart_got_d <= uart_got;
  end
  wire uart_rx_we = uart_got & ~uart_got_d;

  wire [7:0]  bank_look;
  wire [13:0] frame_w;
  wire [9:0]  n_saved;
  wire        replay = hot_pin & (map == 2'd0);

  js_bank u_bank (
    .clk     (clk),
    .rst_n   (rst_n),
    .fire_we (uart_f),
    .fire_b  (uio_in),
    .rx_we   (uart_rx_we),
    .rx_b    (uart_byte),
    .replay  (replay),
    .look    (bank_look),
    .frame_w (frame_w),
    .n_saved (n_saved)
  );

  js_uart_fire u_uart (
    .clk      (clk),
    .rst_n    (rst_n),
    .fire     (uart_f),
    .seq      (seq),
    .clks     (cpb),
    .rx       (map == 2'd0 ? line_in : 1'b1),
    .tx       (uart_tx),
    .r15      (r15_ones),
    .tx_busy  (uart_busy),
    .rx_byte  (uart_byte),
    .rx_busy  (uart_rxb),
    .rx_got   (uart_got),
    .diff     (uart_diff),
    .have     (uart_have)
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
    .usb_n_eth ((rsel == 3'd5) || (rsel == 3'd7)),
    .dm        (line_dm),
    .dp        (line_dp),
    .busy      (line_busy)
  );

  wire tap_tck, tap_tms, tap_tdi, tap_dio, tap_oe, tap_clk_od, tap_clk_oe, tap_can, tap_busy, tap_got;
  wire [7:0] tap_rx;
  js_tap_fire u_tap (
    .clk    (clk),
    .rst_n  (rst_n),
    .fire   (tap_f),
    .seq    (uio_in),
    .clks   (cpb),
    .kind   (tap_kind),
    .din    (line_in),
    .tck    (tap_tck),
    .tms    (tap_tms),
    .tdi    (tap_tdi),
    .dio    (tap_dio),
    .dio_oe (tap_oe),
    .clk_od (tap_clk_od),
    .clk_oe (tap_clk_oe),
    .can_tx (tap_can),
    .rx_byte(tap_rx),
    .rx_got (tap_got),
    .busy   (tap_busy)
  );

  wire [7:0] rx_byte =
      (map == 2'd1) ? spi_byte :
      on_tap ? tap_rx :
      uart_byte;
  wire got = uart_got | spi_got | i2c_got | tap_got;
  wire busy = uart_busy | spi_busy | i2c_busy | line_busy | tap_busy | uart_rxb;

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

  // OAM. The same CPU 1.1. Count off. The live face byte is the input,
  // top 24 bits zero, same shape as the pad. FIRE maps it. The clock holds it.
  generate
    for (k = 0; k < N_BASES; k = k + 1) begin : oam
      one_cpu11 #(.LANE(k)) u_hold (
        .clk       (clk),
        .rst_n     (rst_n),
        .run_hot   (1'b0),
        .fire      (fire),
        .seq       ({24'd0, s0[k][7:0]}),
        .rx_strobe (1'b0),
        .rx_data   (8'd0),
        .sig0      (os0[k]),
        .sig1      (os1[k]),
        .wt        (osw[k]),
        .last_seq  (osl[k]),
        .stride    (oss[k]),
        .cyc_o     (occ[k]),
        .status    (ost[k]),
        .pad_xor   (opx[k])
      );
    end
  endgenerate

  // Pairwise mix. Same XOR as a chain, five deep instead of 32.
  wire [7:0]  w0 [0:31];
  wire        c0 [0:31];
  wire [31:0] p0 [0:31];
  wire [7:0]  w1 [0:15];
  wire        c1 [0:15];
  wire [31:0] p1 [0:15];
  wire [7:0]  w2 [0:7];
  wire        c2 [0:7];
  wire [31:0] p2 [0:7];
  wire [7:0]  w3 [0:3];
  wire        c3 [0:3];
  wire [31:0] p3 [0:3];
  wire [7:0]  w4 [0:1];
  wire        c4 [0:1];
  wire [31:0] p4 [0:1];
  wire [7:0]  wt_all;
  wire        cy_all;
  wire [31:0] px_all;

  genvar m;
  generate
    for (m = 0; m < 32; m = m + 1) begin : lv0
      assign w0[m] = sw[m][7:0] ^ osw[m][7:0] ^ os0[m][7:0];
      assign c0[m] = cc[m][16];
      assign p0[m] = px[m];
    end
    for (m = 0; m < 16; m = m + 1) begin : lv1
      assign w1[m] = w0[2*m] ^ w0[2*m+1];
      assign c1[m] = c0[2*m] ^ c0[2*m+1];
      assign p1[m] = p0[2*m] ^ p0[2*m+1];
    end
    for (m = 0; m < 8; m = m + 1) begin : lv2
      assign w2[m] = w1[2*m] ^ w1[2*m+1];
      assign c2[m] = c1[2*m] ^ c1[2*m+1];
      assign p2[m] = p1[2*m] ^ p1[2*m+1];
    end
    for (m = 0; m < 4; m = m + 1) begin : lv3
      assign w3[m] = w2[2*m] ^ w2[2*m+1];
      assign c3[m] = c2[2*m] ^ c2[2*m+1];
      assign p3[m] = p2[2*m] ^ p2[2*m+1];
    end
    for (m = 0; m < 2; m = m + 1) begin : lv4
      assign w4[m] = w3[2*m] ^ w3[2*m+1];
      assign c4[m] = c3[2*m] ^ c3[2*m+1];
      assign p4[m] = p3[2*m] ^ p3[2*m+1];
    end
  endgenerate
  assign wt_all = w4[0] ^ w4[1];
  assign cy_all = c4[0] ^ c4[1];
  assign px_all = p4[0] ^ p4[1];

  // Same mix as the walker. The hold is already in it. No second tree.
  wire [3:0] mix_rise = {wt_all[3] ^ px_all[0] ^ cy_all, wt_all[2:0]};
  wire [3:0] face_rise = replay ? bank_look[3:0] :
                         (map == 2'd0 && uart_have) ? frame_w[3:0] : mix_rise;
  wire [3:0] face_fall = replay ? bank_look[7:4] :
                         (map == 2'd0 && uart_have) ? frame_w[3:0] : wt_all[7:4];
  reg        face_ph;
  reg  [3:0] face;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      face_ph <= 1'b0;
      face    <= 4'd0;
    end else begin
      face_ph <= ~face_ph;
      face    <= face_ph ? face_fall : face_rise;
    end
  end

  assign uo_out[0] = (map == 2'd0) ? uart_tx :
                     (on_tap && (tap_kind == 2'd3)) ? tap_can :
                     (map == 2'd3 && !on_tap) ? line_dm : 1'b1;
  assign uo_out[1] = busy;
  assign uo_out[2] = (r15_ones == 32'h4F4E4553);
  assign uo_out[3] = (map == 2'd2) ? (got | ~i2c_ack) : (got | uart_rxb);
  assign uo_out[4] = (map == 2'd1) ? spi_mosi :
                     (map == 2'd2) ? i2c_scl :
                     (on_tap && (tap_kind == 2'd0)) ? tap_tdi : face[0];
  assign uo_out[5] = (map == 2'd1) ? spi_sclk :
                     (on_tap && (tap_kind == 2'd0 || tap_kind == 2'd1)) ? tap_tck : face[1];
  assign uo_out[6] = (map == 2'd1) ? spi_csn :
                     (on_tap && (tap_kind == 2'd0)) ? tap_tms : face[2];
  assign uo_out[7] = (map == 2'd3 && !on_tap) ? line_dp : face[3];

  assign uio_out = {6'd0, tap_clk_od, (map == 2'd2) ? i2c_sda : tap_dio};
  assign uio_oe  = {6'd0, on_tap & tap_clk_oe, ((map == 2'd2) & i2c_oe) | (on_tap & tap_oe)};

  wire _unused = &{ena, s0[0], s1[0], sl[0], ss[0], st[0], os1[0], osw[0], oss[0], occ[0], ost[0], i2c_ack, n_saved, frame_w, 1'b0};
endmodule
