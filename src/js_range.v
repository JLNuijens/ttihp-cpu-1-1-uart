// Clock range. Identity is 1 oscillation. The rest is holds on the same clock.
`default_nettype none

module js_range (
  input  wire [2:0]  sel,
  output reg  [15:0] clks
);
  always @* begin
    case (sel)
      3'd0: clks = 16'd1;    // floor — 50 Mbit at 50 MHz
      3'd1: clks = 16'd4;    // USB FS bit
      3'd2: clks = 16'd5;    // 10 Mbit Ethernet
      3'd3: clks = 16'd8;
      3'd4: clks = 16'd16;
      3'd5: clks = 16'd33;   // USB LS ~1.5 Mbit
      3'd6: clks = 16'd125;  // I2C 400 kHz
      default: clks = 16'd434; // UART 115200
    endcase
  end
endmodule
