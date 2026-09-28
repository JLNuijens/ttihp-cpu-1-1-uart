// I2C as the same FIRE walk. Open-drain SDA, driven SCL.
// One FIRE = START + seq[7:0] (MSB first) + ACK + STOP. Count is SCL half-period.
`default_nettype none

module js_i2c_fire (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        fire,
  input  wire [7:0]  seq,
  input  wire [15:0] clks,
  input  wire        sda_in,
  output reg         scl,
  output reg         sda_oe,
  output wire        sda_out,
  output wire        busy,
  output reg         ack,
  output reg         rx_got
);
  // Drive 0 when oe=1. High is release (board pull-up).
  assign sda_out = 1'b0;

  wire [15:0] cpb = (clks == 16'd0) ? 16'd1 : clks;
  reg        go;
  reg [4:0]  ph;
  reg [7:0]  sh;
  reg [15:0] ck;
  reg [15:0] hold;

  assign busy = go;

  // phases: 0 start, 1 scl low, 2..17 data (even=sda+scl0, odd=scl1), 18 ack setup, 19 ack sample, 20 stop scl1 sda0, 21 stop release
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      scl    <= 1'b1;
      sda_oe <= 1'b0;
      go     <= 1'b0;
      ph     <= 5'd0;
      sh     <= 8'd0;
      ck     <= 16'd0;
      hold   <= 16'd1;
      ack    <= 1'b1;
      rx_got <= 1'b0;
    end else begin
      if (fire) rx_got <= 1'b0;
      if (fire && !go) begin
        go     <= 1'b1;
        ph     <= 5'd0;
        sh     <= seq;
        ck     <= 16'd0;
        hold   <= cpb;
        scl    <= 1'b1;
        sda_oe <= 1'b1; // START: SDA falls while SCL high
      end else if (go) begin
        if (ck == hold - 16'd1) begin
          ck <= 16'd0;
          ph <= ph + 5'd1;
          case (ph)
            5'd0: begin scl <= 1'b0; end
            5'd1, 5'd3, 5'd5, 5'd7, 5'd9, 5'd11, 5'd13, 5'd15: begin
              sda_oe <= ~sh[7];
              sh     <= {sh[6:0], 1'b0};
              scl    <= 1'b0;
            end
            5'd2, 5'd4, 5'd6, 5'd8, 5'd10, 5'd12, 5'd14, 5'd16: begin
              scl <= 1'b1;
            end
            5'd17: begin
              sda_oe <= 1'b0;
              scl    <= 1'b0;
            end
            5'd18: begin
              scl <= 1'b1;
              ack <= sda_in;
            end
            5'd19: begin
              scl    <= 1'b0;
              sda_oe <= 1'b1;
            end
            5'd20: begin
              scl <= 1'b1;
            end
            default: begin
              sda_oe <= 1'b0;
              scl    <= 1'b1;
              go     <= 1'b0;
              rx_got <= 1'b1;
            end
          endcase
        end else begin
          ck <= ck + 16'd1;
        end
      end
    end
  end
endmodule
