/*
 * Copyright (c) 2026 Axiom 1 Technology, LLC
 * SPDX-License-Identifier: Apache-2.0
 *
 * Tiny Tapeout 6x4 — CPU 1.1 UART
 * One oscillator. FIRE. Pads. Clock count is the range.
 * UART / SPI / I2C walks. Stretch USB LS + 10 Mbit Manchester.
 * 2 stacks, 32 bases. 16 pad/register sites. UART walk is one copy.
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
  wire [1:0] pad_map  = ui_in[4:3];
  wire [2:0] pad_rsel = ui_in[7:5];

  // The pads arm a load. Memory map with HOT and FIRE stores it.
  // After that the word sets the map, the count, and the byte.
  reg       prog_on;
  reg [1:0] prog_map, arm_map;
  reg [2:0] prog_count, arm_count;
  reg [7:0] prog_byte, arm_byte;
  reg       run_list;
  reg [9:0] pc, rd;
  reg [12:0] list_q;
  wire      pad_mem = (pad_map == 2'd3) && (pad_rsel == 3'd0);

  reg fire_d;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) fire_d <= 1'b0;
    else        fire_d <= fire_pin;
  end
  wire fire = fire_pin & ~fire_d;
  wire hot  = hot_pin | ena;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prog_on    <= 1'b0;
      prog_map   <= 2'd0;
      prog_count <= 3'd0;
      prog_byte  <= 8'd0;
      arm_map    <= 2'd0;
      arm_count  <= 3'd0;
      arm_byte   <= 8'd0;
    end else begin
      if (!pad_mem) begin
        arm_map   <= pad_map;
        arm_count <= pad_rsel;
        arm_byte  <= uio_in;
      end
      if (pad_mem && fire && hot_pin) begin
        prog_on    <= 1'b1;
        prog_map   <= arm_map;
        prog_count <= arm_count;
        prog_byte  <= arm_byte;
      end
    end
  end

  wire [1:0] map      = run_list ? list_q[1:0]  : (prog_on ? prog_map   : pad_map);
  wire [2:0] rsel     = run_list ? list_q[4:2]  : (prog_on ? prog_count : pad_rsel);
  wire [7:0] op_byte  = run_list ? list_q[12:5] : (prog_on ? prog_byte  : uio_in);
  wire [31:0] seq     = {24'd0, op_byte};

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

  wire        uart_tx, uart_busy, uart_rxb, uart_got;
  wire [31:0] r15_ones;
  wire [7:0]  uart_byte;

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
    .rx_got   (uart_got)
  );

  wire spi_mosi, spi_sclk, spi_csn, spi_busy, spi_got;
  wire [7:0] spi_byte;
  js_spi_fire u_spi (
    .clk     (clk),
    .rst_n   (rst_n),
    .fire    (spi_f),
    .seq     (op_byte),
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
    .seq     (op_byte),
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
    .seq       (op_byte),
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
    .seq    (op_byte),
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

  wire mem_face = pad_mem;
  // The pins pick the address. It stays there. FIRE writes the result next cycle.
  reg [8:0] addr_q;
  reg       wr_pend;
  reg [31:0] rung_q;
  reg        rung_arm;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_q   <= 9'd0;
      wr_pend  <= 1'b0;
      rung_q   <= 32'd0;
      rung_arm <= 1'b0;
    end else begin
      wr_pend <= mem_face & fire;
      if (fire) rung_q <= cc[0];
      if (mem_face && !fire) addr_q <= {1'b0, uio_in};
      rung_arm <= mem_face && !fire && !wr_pend && (addr_q == {1'b0, uio_in});
    end
  end

  genvar k;
  generate
    for (k = 0; k < N_BASES; k = k + 1) begin : bases
      wire [31:0] seq_k =
          (mem_face && !wr_pend && (k == 0)) ? dout0 :
          (seq + k);
      one_cpu11 #(.LANE(k)) u_cpu (
        .clk       (clk),
        .rst_n     (rst_n),
        .run_hot   (hot),
        .fire      (fire),
        .rung_back (rung_arm),
        .rung      (dout1),
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
      assign w0[m] = sw[m][7:0];
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

  // The first macro holds the signature of base 0.
  // The second holds the rung. FIRE stores the cycle. A later read puts it back.
  wire        mem_on   = rst_n & (mem_face | wr_pend);
  wire        mem_wr   = wr_pend;
  wire [8:0]  mem_addr = addr_q;
  wire [31:0] mem_bm   = 32'hffffffff;
  wire [31:0] dout0, dout1;
  RM_IHPSG13_1P_512x32_c2_bm_bist u_sram0 (
    .A_CLK(clk), .A_MEN(mem_on), .A_WEN(mem_wr), .A_REN(~mem_wr),
    .A_ADDR(mem_addr), .A_DIN(s0[0]), .A_DLY(1'b1), .A_DOUT(dout0), .A_BM(mem_bm),
    .A_BIST_CLK(1'b0), .A_BIST_EN(1'b0), .A_BIST_MEN(1'b0), .A_BIST_WEN(1'b0),
    .A_BIST_REN(1'b0), .A_BIST_ADDR(9'd0), .A_BIST_DIN(32'd0), .A_BIST_BM(32'd0)
  );
  RM_IHPSG13_1P_512x32_c2_bm_bist u_sram1 (
    .A_CLK(clk), .A_MEN(mem_on), .A_WEN(mem_wr), .A_REN(~mem_wr),
    .A_ADDR(mem_addr), .A_DIN(rung_q), .A_DLY(1'b1), .A_DOUT(dout1), .A_BM(mem_bm),
    .A_BIST_CLK(1'b0), .A_BIST_EN(1'b0), .A_BIST_MEN(1'b0), .A_BIST_WEN(1'b0),
    .A_BIST_REN(1'b0), .A_BIST_ADDR(9'd0), .A_BIST_DIN(32'd0), .A_BIST_BM(32'd0)
  );
  reg [31:0] mem_q;
  wire [31:0] dout2, dout3;
  wire        list_store = pad_mem & fire & hot_pin & (uio_in != 8'hFF);
  wire        list_start = pad_mem & fire & hot_pin & (uio_in == 8'hFF) & (pc != 10'd0);
  wire [31:0] list_din   = {19'd0, arm_byte, arm_count, arm_map};
  wire        list_hi    = list_store ? pc[9] : rd[9];
  wire [8:0]  list_ad    = list_store ? pc[8:0] : rd[8:0];
  wire        list_on    = rst_n & (list_store | run_list);
  RM_IHPSG13_1P_512x32_c2_bm_bist u_sram2 (
    .A_CLK(clk), .A_MEN(list_on & ~list_hi), .A_WEN(list_store & ~list_hi), .A_REN(~list_store),
    .A_ADDR(list_ad), .A_DIN(list_din), .A_DLY(1'b1), .A_DOUT(dout2), .A_BM(mem_bm),
    .A_BIST_CLK(1'b0), .A_BIST_EN(1'b0), .A_BIST_MEN(1'b0), .A_BIST_WEN(1'b0),
    .A_BIST_REN(1'b0), .A_BIST_ADDR(9'd0), .A_BIST_DIN(32'd0), .A_BIST_BM(32'd0)
  );
  RM_IHPSG13_1P_512x32_c2_bm_bist u_sram3 (
    .A_CLK(clk), .A_MEN(list_on & list_hi), .A_WEN(list_store & list_hi), .A_REN(~list_store),
    .A_ADDR(list_ad), .A_DIN(list_din), .A_DLY(1'b1), .A_DOUT(dout3), .A_BM(mem_bm),
    .A_BIST_CLK(1'b0), .A_BIST_EN(1'b0), .A_BIST_MEN(1'b0), .A_BIST_WEN(1'b0),
    .A_BIST_REN(1'b0), .A_BIST_ADDR(9'd0), .A_BIST_DIN(32'd0), .A_BIST_BM(32'd0)
  );
  wire [31:0] list_dout = rd[9] ? dout3 : dout2;
  reg busy_d;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      run_list <= 1'b0;
      pc       <= 10'd0;
      rd       <= 10'd0;
      list_q   <= 13'd0;
      busy_d   <= 1'b0;
    end else begin
      busy_d <= busy;
      if (list_start) begin
        run_list <= 1'b1;
        rd       <= 10'd0;
      end else if (list_store) begin
        pc <= pc + 10'd1;
      end else if (run_list && busy_d && !busy) begin
        if (rd + 10'd1 >= pc) run_list <= 1'b0;
        else                  rd <= rd + 10'd1;
      end
      if (run_list) list_q <= list_dout[12:0];
    end
  end
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) mem_q <= 32'd0;
    else        mem_q <= dout0;
  end

  // Eight bits of the mix. One nibble per rise. The clock is not data,
  // so the clock tree still builds.
  wire [3:0] face_rise = {wt_all[3] ^ px_all[0] ^ cy_all, wt_all[2:0]};
  wire [3:0] face_fall = wt_all[7:4];
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

  wire [7:0] uo_walk;
  assign uo_walk[0] = (map == 2'd0) ? uart_tx :
                     (on_tap && (tap_kind == 2'd3)) ? tap_can :
                     (map == 2'd3 && !on_tap) ? line_dm : 1'b1;
  assign uo_walk[1] = busy;
  assign uo_walk[2] = (r15_ones == 32'h4F4E4553);
  assign uo_walk[3] = (map == 2'd2) ? (got | ~i2c_ack) : (got | uart_rxb);
  assign uo_walk[4] = (map == 2'd1) ? spi_mosi :
                     (map == 2'd2) ? i2c_scl :
                     (on_tap && (tap_kind == 2'd0)) ? tap_tdi : face[0];
  assign uo_walk[5] = (map == 2'd1) ? spi_sclk :
                     (on_tap && (tap_kind == 2'd0 || tap_kind == 2'd1)) ? tap_tck : face[1];
  assign uo_walk[6] = (map == 2'd1) ? spi_csn :
                     (on_tap && (tap_kind == 2'd0)) ? tap_tms : face[2];
  assign uo_walk[7] = (map == 2'd3 && !on_tap) ? line_dp : face[3];
  assign uo_out = mem_face ? mem_q[7:0] : uo_walk;

  assign uio_out = {6'd0, tap_clk_od, (map == 2'd2) ? i2c_sda : tap_dio};
  assign uio_oe  = {6'd0, on_tap & tap_clk_oe, ((map == 2'd2) & i2c_oe) | (on_tap & tap_oe)};

  // The 512 seat is already the preload. r7 is 128. r14 is 4.
  // Two macros hold a signature. Two in front hold the list.
  wire _unused = &{ena, s0[0], s1[0], sl[0], ss[0], st[0], i2c_ack, 1'b0};
endmodule
