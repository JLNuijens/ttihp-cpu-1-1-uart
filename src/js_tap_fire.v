// Real walks on hook 11. Same clock. Not pasted IP.
// kind 0 JTAG bit-bang: FIRE TMS, FIRE TDI, eight TCK, TDO returned.
// kind 1 SWD: FIRE request, FIRE data. Header, turn, ACK, one data byte.
// kind 2 PS/2 device frame at 12.5 kHz. Start, byte, odd parity, stop.
// kind 3 CAN bit cell. Eight bits. Not a frame.
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
  output reg         clk_od,
  output reg         clk_oe,
  output reg         can_tx,
  output reg  [7:0]  rx_byte,
  output reg         rx_got,
  output wire        busy
);
  wire [15:0] cpb = (clks == 16'd0) ? 16'd1 : clks;
  localparam [15:0] PS2 = 16'd4000;

  reg        go, armed, phase;
  reg [1:0]  k, armed_k;
  reg [4:0]  bi;
  reg [7:0]  sh, tms_r, data_r;
  reg [10:0] fr;
  reg [15:0] ck, hold;
  reg [2:0]  ack;
  wire       rn_w = tms_r[1];
  wire [7:0] hdr  = {1'b1, 1'b0, ^tms_r[3:0], tms_r[3:0], 1'b1};

  assign busy = go;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tck <= 0; tms <= 0; tdi <= 0;
      dio <= 1; dio_oe <= 0; clk_od <= 0; clk_oe <= 0;
      can_tx <= 1; rx_byte <= 0; rx_got <= 0;
      go <= 0; armed <= 0; phase <= 0;
      k <= 0; armed_k <= 0; bi <= 0;
      sh <= 0; tms_r <= 0; data_r <= 0; fr <= 0;
      ck <= 0; hold <= 1; ack <= 0;
    end else begin
      if (rx_got) rx_got <= 0;
      if (fire && !go && (kind == 2'd0 || kind == 2'd1) && (!armed || armed_k != kind)) begin
        armed   <= 1;
        armed_k <= kind;
        tms_r   <= seq;
      end else if (fire && !go) begin
        go    <= 1;
        armed <= 0;
        phase <= 0;
        bi    <= 0;
        ck    <= 0;
        k     <= kind;
        if (kind == 2'd0) begin
          hold    <= cpb;
          sh      <= seq;
          data_r  <= tms_r;
          rx_byte <= 0;
          tdi     <= seq[7];
          tms     <= tms_r[7];
          tck     <= 0;
        end else if (kind == 2'd1) begin
          hold    <= cpb;
          data_r  <= seq;
          sh      <= hdr;
          rx_byte <= 0;
          dio     <= hdr[0];
          dio_oe <= 1;
          tck    <= 0;
          ack    <= 0;
        end else if (kind == 2'd2) begin
          hold   <= PS2;
          fr     <= {1'b1, ~(^seq), seq, 1'b0};
          dio    <= 0;
          dio_oe <= 1;
          clk_oe <= 0;
        end else begin
          hold   <= cpb;
          sh     <= seq;
          can_tx <= seq[7];
        end
      end else if (go && ck != hold - 16'd1) begin
        ck <= ck + 16'd1;
      end else if (go) begin
        ck <= 0;
        if (k == 2'd3) begin
          if (bi == 5'd7) begin
            go     <= 0;
            can_tx <= 1;
          end else begin
            bi     <= bi + 5'd1;
            can_tx <= sh[6];
            sh     <= {sh[6:0], 1'b0};
          end
        end else if (k == 2'd2) begin
          if (phase == 0) begin
            phase  <= 1;
            clk_oe <= 1;
            clk_od <= 0;
          end else if (bi == 5'd10) begin
            go     <= 0;
            phase  <= 0;
            dio_oe <= 0;
            clk_oe <= 0;
            dio    <= 1;
          end else begin
            phase  <= 0;
            bi     <= bi + 5'd1;
            clk_oe <= 0;
            dio    <= fr[bi + 5'd1];
            dio_oe <= ~fr[bi + 5'd1];
          end
        end else if (phase == 0) begin
          phase <= 1;
          tck   <= 1;
          if (k == 2'd1 && bi >= 5'd9 && bi <= 5'd11)
            ack <= {ack[1:0], din};
          if (k == 2'd1 && bi >= 5'd13 && rn_w)
            rx_byte <= {rx_byte[6:0], din};
          if (k == 2'd0)
            rx_byte <= {rx_byte[6:0], din};
        end else begin
          phase <= 0;
          tck   <= 0;
          tms   <= 0;
          if (k == 2'd0 && bi == 5'd7) begin
            go     <= 0;
            tdi    <= 0;
            rx_got <= 1;
          end else if (k == 2'd0) begin
            bi     <= bi + 5'd1;
            tdi    <= sh[6];
            tms    <= data_r[6];
            sh     <= {sh[6:0], 1'b0};
            data_r <= {data_r[6:0], 1'b0};
          end else if (k == 2'd1 && bi == 5'd20) begin
            go     <= 0;
            dio_oe <= 0;
            dio    <= 1;
            tck    <= 0;
            rx_got <= 1;
            if (!rn_w) rx_byte <= {5'd0, ack};
          end else if (k == 2'd1) begin
            bi <= bi + 5'd1;
            if (bi < 5'd7) begin
              dio    <= sh[1];
              dio_oe <= 1;
              sh     <= {1'b0, sh[7:1]};
            end else if (bi == 5'd7 || bi == 5'd11) begin
              dio_oe <= 0;
            end else if (bi >= 5'd12 && !rn_w) begin
              dio    <= data_r[0];
              dio_oe <= 1;
              data_r <= {1'b0, data_r[7:1]};
            end else begin
              dio_oe <= 0;
            end
          end
        end
      end
    end
  end
endmodule
`default_nettype wire
