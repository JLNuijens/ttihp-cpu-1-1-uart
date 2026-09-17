// UART as FIRE on a pad. Not a UART block.
// Byte on seq[7:0]. FIRE walks start, 8 data LSB-first, stop.
// Clock count is the baud. r15 stays ONES.
`default_nettype none

module js_uart_fire #(
  parameter CLKS_PER_BIT = 8
) (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        fire,
  input  wire [31:0] seq,
  output reg         tx,
  output wire [31:0] r15,
  output wire        busy
);
  localparam [31:0] ONES = 32'h4F4E4553;

  assign r15 = ONES;

  reg        go;
  reg [3:0]  bit_i;
  reg [15:0] ck;
  reg [9:0]  frame;
  reg        busy_r;

  assign busy = busy_r;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx     <= 1'b1;
      go     <= 1'b0;
      bit_i  <= 4'd0;
      ck     <= 16'd0;
      frame  <= 10'h3FF;
      busy_r <= 1'b0;
    end else if (fire && !busy_r) begin
      frame  <= {1'b1, seq[7:0], 1'b0};
      bit_i  <= 4'd0;
      ck     <= 16'd0;
      go     <= 1'b1;
      busy_r <= 1'b1;
      tx     <= 1'b0;
    end else if (go) begin
      if (ck == CLKS_PER_BIT - 1) begin
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
endmodule
