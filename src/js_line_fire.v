// Stretch walks on the same FIRE and the same count. Not a USB stack. Not an Ethernet MAC.
// usb_n_eth=1: low-speed USB NRZI on DM/DP (SYNC + byte + EOP).
// usb_n_eth=0: 10 Mbit-style Manchester on TX, inverted twin on DP.
`default_nettype none

module js_line_fire (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        fire,
  input  wire [7:0]  seq,
  input  wire [15:0] clks,
  input  wire        usb_n_eth,
  output reg         dm,
  output reg         dp,
  output wire        busy
);
  wire [15:0] cpb  = (clks == 16'd0) ? 16'd1 : clks;
  wire [15:0] half = (cpb > 16'd1) ? (cpb >> 1) : 16'd1;

  reg        go;
  reg        usb;
  reg [4:0]  bi;
  reg        phase;
  reg        lev;
  reg [15:0] sh;
  reg [15:0] ck;
  reg [15:0] hold;
  wire       nxt = sh[0] ? lev : ~lev;

  assign busy = go;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dm    <= 1'b1;
      dp    <= 1'b0;
      go    <= 1'b0;
      usb   <= 1'b0;
      bi    <= 5'd0;
      phase <= 1'b0;
      lev   <= 1'b1;
      sh    <= 16'd0;
      ck    <= 16'd0;
      hold  <= 16'd1;
    end else if (fire && !go) begin
      go    <= 1'b1;
      usb   <= usb_n_eth;
      bi    <= 5'd0;
      phase <= 1'b0;
      ck    <= 16'd0;
      hold  <= usb_n_eth ? cpb : half;
      sh    <= usb_n_eth ? {seq, 8'h80} : {8'd0, seq};
      lev   <= 1'b1;
      dm    <= usb_n_eth ? 1'b1 : 1'b0;
      dp    <= usb_n_eth ? 1'b0 : 1'b1;
    end else if (go) begin
      if (ck == hold - 16'd1) begin
        ck <= 16'd0;
        if (usb) begin
          if (bi < 5'd16) begin
            dm  <= nxt;
            dp  <= ~nxt;
            lev <= nxt;
            sh  <= {1'b1, sh[15:1]};
            bi  <= bi + 5'd1;
          end else if (bi < 5'd18) begin
            dm <= 1'b0;
            dp <= 1'b0;
            bi <= bi + 5'd1;
          end else begin
            dm <= 1'b1;
            dp <= 1'b0;
            go <= 1'b0;
          end
        end else begin
          if (bi < 5'd8) begin
            if (phase == 1'b0) begin
              dm    <= ~sh[0];
              dp    <=  sh[0];
              phase <= 1'b1;
            end else begin
              dm    <=  sh[0];
              dp    <= ~sh[0];
              phase <= 1'b0;
              sh    <= {1'b0, sh[15:1]};
              bi    <= bi + 5'd1;
            end
          end else begin
            dm <= 1'b1;
            dp <= 1'b0;
            go <= 1'b0;
          end
        end
      end else begin
        ck <= ck + 16'd1;
      end
    end
  end
endmodule
