// UART as FIRE on a pad. RX and TX. Clock is the oscillator, not the data.
// Count 1 uses both edges of the 50 MHz wave: 10 ns cell, 100 Mbit/s.
// Count > 1 stays on the rising edge, so 434 is still 115200.
// r15 stays ONES. The stage does not move on the fall.
`default_nettype none

module js_uart_fire (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        fire,
  input  wire [31:0] seq,
  input  wire [15:0] clks,
  input  wire        rx,
  output wire        tx,
  output wire [31:0] r15,
  output wire        tx_busy,
  output reg  [7:0]  rx_byte,
  output wire        rx_busy,
  output reg         rx_got,
  output reg  [3:0]  diff,
  output reg         have
);
  localparam [31:0] ONES = 32'h4F4E4553;
  assign r15 = ONES;

  wire [15:0] cpb = (clks == 16'd0) ? 16'd1 : clks;

  reg        tx_hi;
  reg        tx_lo;
  // High half shows the rise bit. Low half shows the fall bit.
  // Slow counts write the same bit into both, so the fall is not a new bit.
  assign tx = clk ? tx_hi : tx_lo;

  reg        go;
  reg [3:0]  bit_i;
  reg [15:0] ck;
  reg [9:0]  frame;
  reg        busy_r;
  reg [15:0] hold;
  reg        fast;

  assign tx_busy = busy_r;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_hi  <= 1'b1;
      tx_lo  <= 1'b1;
      go     <= 1'b0;
      bit_i  <= 4'd0;
      ck     <= 16'd0;
      frame  <= 10'h3FF;
      busy_r <= 1'b0;
      hold   <= 16'd1;
      fast   <= 1'b0;
    end else if (fire && !busy_r) begin
      frame  <= {1'b1, seq[7:0], 1'b0};
      ck     <= 16'd0;
      go     <= 1'b1;
      busy_r <= 1'b1;
      hold   <= cpb;
      fast   <= (cpb == 16'd1);
      tx_hi  <= 1'b0;
      if (cpb == 16'd1) begin
        tx_lo <= seq[0];
        bit_i <= 4'd2;
      end else begin
        tx_lo <= 1'b0;
        bit_i <= 4'd0;
      end
    end else if (go && fast) begin
      if (bit_i >= 4'd10) begin
        go     <= 1'b0;
        busy_r <= 1'b0;
        tx_hi  <= 1'b1;
        tx_lo  <= 1'b1;
        bit_i  <= 4'd0;
      end else begin
        tx_hi <= frame[bit_i];
        tx_lo <= frame[bit_i + 4'd1];
        bit_i <= bit_i + 4'd2;
      end
    end else if (go) begin
      if (ck == hold - 16'd1) begin
        ck <= 16'd0;
        if (bit_i == 4'd9) begin
          go     <= 1'b0;
          busy_r <= 1'b0;
          tx_hi  <= 1'b1;
          tx_lo  <= 1'b1;
        end else begin
          bit_i <= bit_i + 4'd1;
          tx_hi <= frame[bit_i + 4'd1];
          tx_lo <= frame[bit_i + 4'd1];
        end
      end else begin
        ck <= ck + 16'd1;
      end
    end
  end

  reg        rx_d;
  reg        rx_go;
  reg [3:0]  rx_i;
  reg [15:0] rx_ck;
  reg [7:0]  rx_shift;
  reg        rx_busy_r;
  reg [15:0] rx_hold;
  reg        rx_fast;
  reg        rx_fall_bit;
  reg        rx_fall_d;
  reg [7:0]  sent;

  function [3:0] pop8;
    input [7:0] x;
    integer i;
    begin
      pop8 = 4'd0;
      for (i = 0; i < 8; i = i + 1)
        pop8 = pop8 + x[i];
    end
  endfunction

  assign rx_busy = rx_busy_r;
  wire rx_fall = rx_d & ~rx;

  always @(negedge clk or negedge rst_n) begin
    if (!rst_n) rx_fall_bit <= 1'b1;
    else        rx_fall_bit <= rx;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_d        <= 1'b1;
      rx_go       <= 1'b0;
      rx_i        <= 4'd0;
      rx_ck       <= 16'd0;
      rx_shift    <= 8'd0;
      rx_byte     <= 8'd0;
      rx_busy_r   <= 1'b0;
      rx_got      <= 1'b0;
      rx_hold     <= 16'd1;
      rx_fast     <= 1'b0;
      rx_fall_d   <= 1'b1;
      sent        <= 8'd0;
      diff        <= 4'd0;
      have        <= 1'b0;
    end else begin
      rx_d <= rx;
      rx_fall_d <= rx_fall_bit;
      if (fire) rx_got <= 1'b0;
      if (!rx_go && cpb == 16'd1 && rx_fall_d == 1'b1 && rx_fall_bit == 1'b0) begin
        // Start sat on the fall. This rise is data bit 0.
        rx_go     <= 1'b1;
        rx_busy_r <= 1'b1;
        rx_fast   <= 1'b1;
        rx_i      <= 4'd1;
        rx_shift  <= {7'd0, rx};
        rx_hold   <= cpb;
      end else if (!rx_go && cpb != 16'd1 && rx_fall && !rx_busy_r) begin
        rx_go     <= 1'b1;
        rx_busy_r <= 1'b1;
        rx_fast   <= 1'b0;
        rx_i      <= 4'd0;
        rx_ck     <= 16'd0;
        rx_shift  <= 8'd0;
        rx_hold   <= cpb;
      end else if (rx_go && rx_fast && rx_i < 4'd7) begin
        rx_shift[rx_i]     <= rx_fall_bit;
        rx_shift[rx_i + 1] <= rx;
        rx_i               <= rx_i + 4'd2;
      end else if (rx_go && rx_fast && rx_i == 4'd7) begin
        rx_byte   <= {rx_fall_bit, rx_shift[6:0]};
        diff      <= pop8({rx_fall_bit, rx_shift[6:0]} ^ sent);
        have      <= 1'b1;
        rx_got    <= 1'b1;
        rx_go     <= 1'b0;
        rx_busy_r <= 1'b0;
        rx_fast   <= 1'b0;
        rx_i      <= 4'd0;
      end else if (rx_go && !rx_fast) begin
        if (rx_ck == rx_hold - 16'd1) begin
          rx_ck <= 16'd0;
          if (rx_i == 4'd0) begin
            rx_shift[0] <= rx;
            rx_i        <= 4'd1;
          end else if (rx_i < 4'd8) begin
            rx_shift[rx_i] <= rx;
            rx_i           <= rx_i + 4'd1;
          end else begin
            rx_byte   <= rx_shift;
            diff      <= pop8(rx_shift ^ sent);
            have      <= 1'b1;
            rx_got    <= 1'b1;
            rx_go     <= 1'b0;
            rx_busy_r <= 1'b0;
          end
        end else begin
          rx_ck <= rx_ck + 16'd1;
        end
      end
      if (fire) begin
        sent <= seq[7:0];
        have <= 1'b0;
      end
    end
  end
endmodule
