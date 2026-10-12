// 512 stays on the processor. 720 is the pickup.
// Intake is IN+ minus IN-. The stack does not add power to the preload.
//   squares = intake * 512 / stack
//   degrees = intake * 720 / stack
// At stack 128, one intake sits at 4 squares and 5.625 degrees.
// The two outputs stay in the ratio 720/512 = 1.40625.
// deg8 is degrees * 8, so 5.625 is the integer 45.
// Count 0 is 1 degree. Each count doubles the units and halves the degree.
// The stack catches a count only when it can reach that count's units.
`default_nettype none

module range_front #(
  parameter integer STACK = 128
) (
  input  wire               clk,
  input  wire               rst_n,
  input  wire               hot,
  input  wire signed [15:0] inp,
  input  wire signed [15:0] inn,
  input  wire        [4:0]  count,
  output reg  signed [19:0] squares,
  output reg  signed [23:0] deg8,
  output reg                caught
);
  wire signed [16:0] intake = inp - inn;
  wire signed [19:0] sq     = intake * 20'sd4;
  wire signed [23:0] de     = intake * 24'sd45;
  wire [31:0]        units  = 32'd1 << count;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      squares <= 20'sd0;
      deg8    <= 24'sd0;
      caught  <= 1'b0;
    end else if (hot) begin
      squares <= sq;
      deg8    <= de;
      caught  <= (units <= STACK);
    end
  end
endmodule

module range_map (
  input  wire [4:0]  count,
  output wire [31:0] units,
  output wire [31:0] step_den
);
  assign units    = 32'd1 << count;
  assign step_den = units;
endmodule
