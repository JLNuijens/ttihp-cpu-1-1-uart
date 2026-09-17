// SPI as the same FIRE walk. Mode 0, 8 bits, MSB first.
// MOSI / SCLK / CS_n. MISO sampled on the rising edge. clks = half-period holds.
`default_nettype none

module js_spi_fire (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        fire,
  input  wire [7:0]  seq,
  input  wire [15:0] clks,
  input  wire        miso,
  output reg         mosi,
  output reg         sclk,
  output reg         csn,
  output wire        busy,
  output reg  [7:0]  rx_byte,
  output reg         rx_got
);
  wire [15:0] cpb = (clks == 16'd0) ? 16'd1 : clks;
  reg        go;
  reg        phase;
  reg [2:0]  bi;
  reg [7:0]  sh;
  reg [7:0]  rh;
  reg [15:0] ck;
  reg [15:0] hold;

  assign busy = go;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mosi   <= 1'b0;
      sclk   <= 1'b0;
      csn    <= 1'b1;
      go     <= 1'b0;
      phase  <= 1'b0;
      bi     <= 3'd0;
      sh     <= 8'd0;
      rh     <= 8'd0;
      ck     <= 16'd0;
      hold   <= 16'd1;
      rx_byte<= 8'd0;
      rx_got <= 1'b0;
    end else begin
      if (fire) rx_got <= 1'b0;
      if (fire && !go) begin
        go    <= 1'b1;
        csn   <= 1'b0;
        sclk  <= 1'b0;
        sh    <= seq;
        rh    <= 8'd0;
        bi    <= 3'd7;
        phase <= 1'b0;
        ck    <= 16'd0;
        hold  <= cpb;
        mosi  <= seq[7];
      end else if (go) begin
        if (ck == hold - 16'd1) begin
          ck <= 16'd0;
          if (phase == 1'b0) begin
            sclk  <= 1'b1;
            rh    <= {rh[6:0], miso};
            phase <= 1'b1;
          end else begin
            sclk <= 1'b0;
            if (bi == 3'd0) begin
              go      <= 1'b0;
              csn     <= 1'b1;
              rx_byte <= rh;
              rx_got  <= 1'b1;
              mosi    <= 1'b0;
            end else begin
              bi    <= bi - 3'd1;
              sh    <= {sh[6:0], 1'b0};
              mosi  <= sh[6];
              phase <= 1'b0;
            end
          end
        end else begin
          ck <= ck + 16'd1;
        end
      end
    end
  end
endmodule
