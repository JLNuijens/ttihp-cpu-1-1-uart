`timescale 1ns/1ps
`default_nettype none

module range_front_tb;
  reg clk = 0;
  reg rst_n = 0;
  reg hot = 1;
  reg signed [15:0] inp = 0;
  reg signed [15:0] inn = 0;
  reg [4:0] count = 0;
  wire signed [19:0] squares;
  wire signed [23:0] deg8;
  wire caught;
  wire [31:0] units, step_den;

  always #10 clk = ~clk;

  range_front dut (
    .clk(clk), .rst_n(rst_n), .hot(hot),
    .inp(inp), .inn(inn), .count(count),
    .squares(squares), .deg8(deg8), .caught(caught)
  );
  range_map map (.count(count), .units(units), .step_den(step_den));

  integer fails;
  task check;
    input signed [19:0] want_sq;
    input signed [23:0] want_de;
    input want_hit;
    input [31:0] want_units;
    begin
      @(posedge clk);
      #1;
      if (squares !== want_sq || deg8 !== want_de || caught !== want_hit
          || units !== want_units || step_den !== want_units
          || (deg8 * 512) !== (squares * 720 * 8)) begin
        $display("FAIL count %0d sq %0d deg8 %0d hit %b units %0d",
                 count, squares, deg8, caught, units);
        fails = fails + 1;
      end
    end
  endtask

  initial begin
    fails = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;

    // One intake. Seat is 4 squares and 45 eighths (5.625 degrees).
    inp = 16'sd1; inn = 16'sd0; count = 5'd0;
    check(20'sd4, 24'sd45, 1'b1, 32'd1);

    // The stack adds no power.
    inp = 16'sd0; inn = 16'sd0; count = 5'd7;
    check(20'sd0, 24'sd0, 1'b1, 32'd128);

    // Differential. IN+ minus IN-.
    inp = 16'sd3; inn = 16'sd5; count = 5'd1;
    check(-20'sd8, -24'sd90, 1'b1, 32'd2);

    // Count 7 is the stack. Count 8 is past it, so it does not catch.
    inp = 16'sd1; inn = 16'sd0; count = 5'd7;
    check(20'sd4, 24'sd45, 1'b1, 32'd128);
    count = 5'd8;
    check(20'sd4, 24'sd45, 1'b0, 32'd256);

    count = 5'd10;
    check(20'sd4, 24'sd45, 1'b0, 32'd1024);
    count = 5'd16;
    check(20'sd4, 24'sd45, 1'b0, 32'd65536);

    if (fails == 0) $display("PASS");
    else $display("FAILS %0d", fails);
    $finish;
  end
endmodule
