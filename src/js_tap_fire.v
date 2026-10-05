// Same FIRE, same count. Not a TAP, not a CAN controller, not a PS/2 port.
// kind 0 JTAG shift, 1 SWD byte, 2 PS/2 frame, 3 CAN bit cell.
// Timing is whatever count is selected. We set that.
`default_nettype none

module js_tap_fire (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        fire,
  input  wire [7:0]  seq,
  input  wire [15:0] clks,
  input  wire [1:0]  kind,
  input  wire        din,
  output reg         tck,
  output reg         tms,
  output reg         tdi,
  output reg         dio,
  output reg         dio_oe,
  output reg         can_tx,
  output wire        busy
);
  wire [15:0] cpb = (clks == 16'd0) ? 16'd1 : clks;

  reg        go;
  reg        phase;
  reg [3:0]  bi;
  reg [3:0]  last;
  reg [10:0] sh;
  reg [15:0] ck;
  reg [15:0] hold;
  reg [1:0]  k;

  assign busy = go;

  wire ps2_bit = sh[0];
  wire parity  = ~(^seq);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tck    <= 1'b0;
      tms    <= 1'b0;
      tdi    <= 1'b0;
      dio    <= 1'b1;
      dio_oe <= 1'b0;
      can_tx <= 1'b1;
      go     <= 1'b0;
      phase  <= 1'b0;
      bi     <= 4'd0;
      last   <= 4'd0;
      sh     <= 11'd0;
      ck     <= 16'd0;
      hold   <= 16'd1;
      k      <= 2'd0;
    end else if (fire && !go) begin
      go    <= 1'b1;
      phase <= 1'b0;
      ck    <= 16'd0;
      hold  <= cpb;
      k     <= kind;
      bi    <= 4'd0;
      tck   <= 1'b0;
      tms   <= 1'b0;
      if (kind == 2'd2) begin
        sh   <= {1'b1, parity, seq, 1'b0};
        last <= 4'd10;
        dio  <= 1'b0;
        dio_oe <= 1'b1;
        can_tx <= 1'b1;
        tdi  <= 1'b0;
      end else if (kind == 2'd3) begin
        sh   <= {3'd0, seq};
        last <= 4'd7;
        can_tx <= seq[7];
        dio_oe <= 1'b0;
        tdi  <= 1'b0;
      end else if (kind == 2'd1) begin
        sh   <= {3'd0, seq};
        last <= 4'd8;
        dio  <= seq[7];
        dio_oe <= 1'b1;
        tdi  <= 1'b0;
        can_tx <= 1'b1;
      end else begin
        sh   <= {3'd0, seq};
        last <= 4'd7;
        tdi  <= seq[7];
        dio_oe <= 1'b0;
        can_tx <= 1'b1;
      end
    end else if (go) begin
      if (ck == hold - 16'd1) begin
        ck <= 16'd0;
        if (k == 2'd3) begin
          if (bi == last) begin
            go     <= 1'b0;
            can_tx <= 1'b1;
          end else begin
            bi     <= bi + 4'd1;
            can_tx <= sh[6];
            sh     <= {sh[9:0], 1'b0};
          end
        end else if (phase == 1'b0) begin
          tck   <= 1'b1;
          phase <= 1'b1;
          if (k == 2'd0) tms <= (bi == last);
        end else begin
          tck   <= 1'b0;
          phase <= 1'b0;
          tms   <= 1'b0;
          if (bi == last) begin
            go     <= 1'b0;
            dio_oe <= 1'b0;
            dio    <= 1'b1;
            tdi    <= 1'b0;
          end else begin
            if (k == 2'd2) begin
              bi     <= bi + 4'd1;
              dio    <= sh[1];
              dio_oe <= ~sh[1];
              sh     <= {1'b0, sh[10:1]};
            end else begin
              bi <= bi + 4'd1;
              if (k == 2'd1 && (bi + 4'd1 == last)) dio_oe <= 1'b0;
              else if (k == 2'd1) dio <= sh[6];
              else tdi <= sh[6];
              sh <= {sh[9:0], 1'b0};
            end
          end
        end
      end else begin
        ck <= ck + 16'd1;
      end
    end
  end
endmodule
`default_nettype wire
