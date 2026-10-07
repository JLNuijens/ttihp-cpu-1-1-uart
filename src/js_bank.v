// On-chip bank. Flops, not a RAM macro. Holds while power is on.
// 1024 bytes sent, 1024 bytes received. Write only when a byte finishes.
// XOR-quiet: no write, the pattern stays. Power off, it is gone.
`default_nettype none

module js_bank #(
  parameter DEPTH = 1024
) (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        fire_we,
  input  wire [7:0]  fire_b,
  input  wire        rx_we,
  input  wire [7:0]  rx_b,
  input  wire        replay,
  output reg  [7:0]  look,
  output reg  [13:0] frame_w,
  output reg  [9:0]  n_saved
);
  localparam AW = 10;

  reg [7:0] sent [0:DEPTH-1];
  reg [7:0] gotb [0:DEPTH-1];
  reg [AW-1:0] sw;
  reg [AW-1:0] gw;
  reg [AW-1:0] look_i;
  reg          look_hi;

  function [3:0] pop8;
    input [7:0] x;
    integer i;
    begin
      pop8 = 4'd0;
      for (i = 0; i < 8; i = i + 1)
        pop8 = pop8 + x[i];
    end
  endfunction

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sw      <= {AW{1'b0}};
      gw      <= {AW{1'b0}};
      look_i  <= {AW{1'b0}};
      look_hi <= 1'b0;
      look    <= 8'd0;
      frame_w <= 14'd0;
      n_saved <= 10'd0;
    end else begin
      if (fire_we) begin
        sent[sw] <= fire_b;
        sw <= sw + {{(AW-1){1'b0}}, 1'b1};
      end
      if (rx_we) begin
        gotb[gw] <= rx_b;
        frame_w  <= frame_w + {10'd0, pop8(rx_b ^ sent[gw])};
        gw       <= gw + {{(AW-1){1'b0}}, 1'b1};
        n_saved  <= n_saved + 10'd1;
      end
      if (replay) begin
        look <= look_hi ? gotb[look_i] : sent[look_i];
        if (look_hi) begin
          look_hi <= 1'b0;
          look_i  <= look_i + {{(AW-1){1'b0}}, 1'b1};
        end else begin
          look_hi <= 1'b1;
        end
      end
    end
  end
endmodule
