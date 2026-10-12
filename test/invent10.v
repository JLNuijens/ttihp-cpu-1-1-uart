`timescale 1ns/1ps
`default_nettype none

module invent10;
  reg clk = 0;
  reg rst_n = 0;
  reg ena = 1;
  reg [7:0] ui_in = 0;
  reg [7:0] uio_in = 0;
  wire [7:0] uo_out, uio_out, uio_oe;

  tt_um_jlnuijens_one11_uart dut (
    .ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in),
    .uio_out(uio_out), .uio_oe(uio_oe),
    .ena(ena), .clk(clk), .rst_n(rst_n)
  );

  always #10 clk = ~clk;

  task fire;
    input [1:0] map;
    input [2:0] sel;
    input [7:0] bbyte;
    begin
      @(negedge clk);
      uio_in = bbyte;
      ui_in  = {sel, map, 1'b0, 1'b1, 1'b0};
      @(negedge clk);
      ui_in  = {sel, map, 1'b0, 1'b1, 1'b1};
      @(negedge clk);
      ui_in  = {sel, map, 1'b0, 1'b1, 1'b0};
    end
  endtask

  integer i, run, n;
  reg last;

  initial begin
    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (4) @(posedge clk);

    // 1. 8N1 at the count-4 hold. 12.5 Mbit. Byte A5.
    fire(2'd0, 3'd1, 8'hA5);
    last = uo_out[0]; run = 1;
    $write("1 UART count4 byte A5 TX ");
    for (i = 0; i < 48; i = i + 1) begin
      @(posedge clk);
      if (uo_out[0] !== last) begin
        $write("%0d%0b ", run, last);
        last = uo_out[0]; run = 1;
      end else run = run + 1;
    end
    $display("%0d%0b", run, last);

    // 2. 8N1 at the 10 Mbit count. Not Manchester.
    fire(2'd0, 3'd2, 8'h3C);
    last = uo_out[0]; run = 1;
    $write("2 UART count5 byte 3C TX ");
    for (i = 0; i < 60; i = i + 1) begin
      @(posedge clk);
      if (uo_out[0] !== last) begin
        $write("%0d%0b ", run, last);
        last = uo_out[0]; run = 1;
      end else run = run + 1;
    end
    $display("%0d%0b", run, last);

    // 3. 8N1 at the USB-LS count.
    fire(2'd0, 3'd5, 8'h55);
    last = uo_out[0]; run = 1;
    $write("3 UART count33 byte 55 start-hold ");
    for (i = 0; i < 40; i = i + 1) begin
      @(posedge clk);
      if (uo_out[0] !== last) begin
        $write("%0d%0b ", run, last);
        last = uo_out[0]; run = 1;
      end else run = run + 1;
    end
    $display("%0d%0b", run, last);

    // 4. SPI at the fast hold.
    fire(2'd1, 3'd0, 8'hC3);
    n = 0;
    $write("4 SPI count1 byte C3 SCLK-edges ");
    for (i = 0; i < 40; i = i + 1) begin
      @(posedge clk);
      if (uo_out[5] === 1'b1) n = n + 1;
    end
    $display("high-clocks %0d MOSI0 %b CS0 %b", n, uo_out[4], uo_out[6]);

    // 5. SPI at the I2C hold.
    fire(2'd1, 3'd6, 8'h96);
    n = 0; last = 0;
    $write("5 SPI count125 byte 96 ");
    for (i = 0; i < 140; i = i + 1) begin
      @(posedge clk);
      if (uo_out[5] === 1'b1 && last === 1'b0) n = n + 1;
      last = uo_out[5];
    end
    $display("sclk-rises-in-140 %0d mosi %b", n, uo_out[4]);

    // 6. SPI at count 16.
    fire(2'd1, 3'd4, 8'h0F);
    n = 0; last = 0;
    $write("6 SPI count16 byte 0F ");
    for (i = 0; i < 40; i = i + 1) begin
      @(posedge clk);
      if (uo_out[5] === 1'b1 && last === 1'b0) n = n + 1;
      last = uo_out[5];
    end
    $display("sclk-rises-in-40 %0d", n);

    // 7. I2C at the fast hold. SCL should move.
    fire(2'd2, 3'd0, 8'hA0);
    n = 0; last = uo_out[4];
    $write("7 I2C count1 byte A0 SCL ");
    for (i = 0; i < 30; i = i + 1) begin
      @(posedge clk);
      if (uo_out[4] !== last) begin
        $write("%0d%0b ", run, last);
        last = uo_out[4]; run = 1; n = n + 1;
      end else run = run + 1;
    end
    $display("edges %0d oe %b", n, uio_oe[0]);

    // 8. I2C at count 8.
    fire(2'd2, 3'd3, 8'h55);
    n = 0; last = 1'b1; run = 1;
    $write("8 I2C count8 byte 55 SCL ");
    for (i = 0; i < 24; i = i + 1) begin
      @(posedge clk);
      if (uo_out[4] !== last) begin
        $write("%0d%0b ", run, last);
        last = uo_out[4]; run = 1; n = n + 1;
      end else run = run + 1;
    end
    $display("edges %0d", n);

    // 9. I2C at the USB-LS count. Let the count-8 frame finish first.
    repeat (400) @(posedge clk);
    fire(2'd2, 3'd5, 8'h42);
    n = 0; last = uo_out[4]; run = 1;
    $write("9 I2C count33 byte 42 first-SCL-hold ");
    for (i = 0; i < 70; i = i + 1) begin
      @(posedge clk);
      if (uo_out[4] !== last) begin
        $write("%0d ", run);
        last = uo_out[4]; run = 1; n = n + 1;
        if (n == 2) i = 70;
      end else run = run + 1;
    end
    $display("clocks");

    // 10. 8N1 at the I2C hold.
    fire(2'd0, 3'd6, 8'h81);
    last = uo_out[0]; run = 1;
    $write("10 UART count125 byte 81 start-hold ");
    for (i = 0; i < 130; i = i + 1) begin
      @(posedge clk);
      if (uo_out[0] !== last) begin
        $write("%0d%0b ", run, last);
        last = uo_out[0];
        i = 130;
      end else run = run + 1;
    end
    $display("");
    $finish;
  end
endmodule
