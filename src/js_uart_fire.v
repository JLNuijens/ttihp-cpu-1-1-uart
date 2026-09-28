// UART as FIRE on a pad. RX and TX. Clock is the oscillator, not the data.
// clks is the range: 1 = one oscillation per bit. r15 stays ONES.
`default_nettype none

module js_uart_fire (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        fire,
  input  wire [31:0] seq,
  input  wire [15:0] clks,
  input  wire        rx,
  output reg         tx,
  output wire [31:0] r15,
  output wire        tx_busy,
  output reg  [7:0]  rx_byte,
  output wire        rx_busy,
  output reg         rx_got
);
  localparam [31:0] ONES = 32'h4F4E4553;
  assign r15 = ONES;

  wire [15:0] cpb = (clks == 16'd0) ? 16'd1 : clks;

  reg        go;
  reg [3:0]  bit_i;
  reg [15:0] ck;
  reg [9:0]  frame;
  reg        busy_r;
  reg [15:0] hold;

  assign tx_busy = busy_r;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx     <= 1'b1;
      go     <= 1'b0;
      bit_i  <= 4'd0;
      ck     <= 16'd0;
      frame  <= 10'h3FF;
      busy_r <= 1'b0;
      hold   <= 16'd1;
    end else if (fire && !busy_r) begin
      frame  <= {1'b1, seq[7:0], 1'b0};
      bit_i  <= 4'd0;
      ck     <= 16'd0;
      go     <= 1'b1;
      busy_r <= 1'b1;
      hold   <= cpb;
      tx     <= 1'b0;
    end else if (go) begin
      if (ck == hold - 16'd1) begin
        ck <= 16'd0;
        if (bit_i == 4'd9) begin
          go     <= 1'b0;
          busy_r <= 1'b0;
          tx     <= 1'b1;
        end else begin
          bit_i <= bit_i + 4'd1;
          tx    <= frame[bit_i + 4'd1];
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

  assign rx_busy = rx_busy_r;
  wire rx_fall = rx_d & ~rx;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_d      <= 1'b1;
      rx_go     <= 1'b0;
      rx_i      <= 4'd0;
      rx_ck     <= 16'd0;
      rx_shift  <= 8'd0;
      rx_byte   <= 8'd0;
      rx_busy_r <= 1'b0;
      rx_got    <= 1'b0;
      rx_hold   <= 16'd1;
    end else begin
      rx_d <= rx;
      if (fire) rx_got <= 1'b0;
      if (rx_fall && !rx_busy_r) begin
        rx_go     <= 1'b1;
        rx_busy_r <= 1'b1;
        rx_i      <= 4'd0;
        rx_ck     <= 16'd0;
        rx_shift  <= 8'd0;
        rx_hold   <= cpb;
      end else if (rx_go) begin
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
            rx_got    <= 1'b1;
            rx_go     <= 1'b0;
            rx_busy_r <= 1'b0;
          end
        end else begin
          rx_ck <= rx_ck + 16'd1;
        end
      end
    end
  end
endmodule
