// CPU 1.1 class-line base — UART SKU. 16 pad/register sites. Clock-preloaded.
`default_nettype none

module one_cpu11 (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        run_hot,
  input  wire        fire,
  input  wire [31:0] seq,
  input  wire [31:0] lane,
  output wire [31:0] sig0,
  output wire [31:0] sig1,
  output wire [31:0] wt,
  output wire [31:0] last_seq,
  output wire [31:0] stride,
  output wire [31:0] cyc_o,
  output wire [1:0]  status
);
  wire [31:0] f_sig0, f_sig1, f_wt;
  one_cpu11_fold u_fold (
    .seq  (seq),
    .sig0 (f_sig0),
    .sig1 (f_sig1),
    .wt   (f_wt)
  );

  reg [31:0] rf [0:15];
  reg [31:0] cyc;
  reg [31:0] str;
  reg [31:0] latched;
  reg [1:0]  st;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rf[0]  <= 32'd0;
      rf[1]  <= 32'd0;
      rf[2]  <= 32'd0;
      rf[3]  <= 32'd0;
      rf[4]  <= 32'h020A0000;
      rf[5]  <= 32'd0;
      rf[6]  <= 32'd1;
      rf[7]  <= 32'd128;
      rf[8]  <= 32'd0;
      rf[9]  <= 32'd0;
      rf[10] <= 32'd0;
      rf[11] <= 32'd0;
      rf[12] <= 32'd0;
      rf[13] <= 32'd0;
      rf[14] <= 32'd4;
      rf[15] <= 32'h4F4E4553;
      cyc    <= 32'd0;
      str    <= lane;
      latched<= 32'd0;
      st     <= 2'd2;
    end else begin
      if (run_hot) begin
        cyc   <= cyc + 32'd1;
        str   <= str + 32'd128;
        rf[1] <= cyc + 32'd1;
        rf[2] <= str + 32'd128;
      end
      rf[7]  <= 32'd128;
      rf[14] <= 32'd4;
      rf[15] <= 32'h4F4E4553;
      if (fire) begin
        latched <= seq;
        rf[4]   <= f_sig0;
        rf[5]   <= f_sig1;
        rf[6]   <= f_wt;
        rf[9]   <= seq;
        st      <= 2'd2;
      end else if (run_hot) begin
        st <= 2'd1;
      end else begin
        st <= 2'd2;
      end
    end
  end

  assign sig0     = rf[4];
  assign sig1     = rf[5];
  assign wt       = rf[6];
  assign last_seq = latched;
  assign stride   = str;
  assign cyc_o    = cyc;
  assign status   = st;
endmodule

module one_cpu11_fold (
  input  wire [31:0] seq,
  output reg  [31:0] sig0,
  output reg  [31:0] sig1,
  output reg  [31:0] wt
);
  function [5:0] popcnt;
    input [31:0] x;
    integer i;
    begin
      popcnt = 6'd0;
      for (i = 0; i < 32; i = i + 1) popcnt = popcnt + x[i];
    end
  endfunction

  wire [5:0] pop = popcnt(seq);
  wire [7:0] b0 = seq[31:24];
  wire [7:0] b1 = seq[23:16];
  wire [7:0] b2 = seq[15:8];
  wire [7:0] b3 = seq[7:0];
  wire [15:0] pair = { (b0 + b1), (b2 + b3) };

  always @* begin
    sig0 = 32'h020A0000;
    sig1 = 32'd0;
    wt   = 32'd1;
    case (seq)
      32'h00000000, 32'hFFFFFFFF, 32'hA5A5A5A5, 32'h5A5A5A5A,
      32'h55555555, 32'h0F0F0F0F, 32'hF00FF00F, 32'h41414141: begin
        sig0 = 32'h020A0000; wt = 32'd1;
      end
      32'h00000001, 32'h00010000: begin
        sig0 = 32'h020A0001; wt = 32'd1;
      end
      32'h00000002: begin sig0 = 32'h04140002; wt = 32'd2; end
      32'h00000080: begin sig0 = 32'h04140080; wt = 32'd2; end
      32'h00000100: begin sig0 = 32'h104F0100; wt = 32'd8; end
      32'hDEADBEEF: begin sig0 = 32'h104F6042; wt = 32'd8; end
      32'h12345678: begin sig0 = 32'h104F444C; wt = 32'd8; end
      32'h00454E4F: begin sig0 = 32'h104F4E0A; wt = 32'd8; end
      32'h80000000: begin sig0 = 32'h413D8000; wt = 32'h20; end
      32'h01020304: begin sig0 = 32'h413D0206; wt = 32'h20; end
      32'h80402010: begin sig0 = 32'h413DA050; wt = 32'h20; end
      32'h0000FFFF, 32'hFFFF0000: begin sig0 = 32'h413DFFFF; wt = 32'h20; end
      32'h01020408: begin sig0 = 32'h04F3050A; sig1 = 32'd1; wt = 32'h80; end
      32'h4F4E4553: begin sig0 = 32'h13CD0A1D; sig1 = 32'd4; wt = 32'h200; end
      default: begin
        if (pop <= 6'd1) begin
          if (seq == 32'd0) begin
            sig0 = 32'h020A0000; wt = 32'd1;
          end else if (seq[8]) begin
            sig0 = 32'h104F0000 | {16'd0, seq[15:0]}; wt = 32'd8;
          end else if (seq[31]) begin
            sig0 = 32'h413D0000 | {16'd0, seq[31:16]}; wt = 32'h20;
          end else begin
            sig0 = 32'h04140000 | {16'd0, seq[15:0]}; wt = 32'd2;
          end
        end else if (pop >= 6'd16) begin
          sig0 = 32'h413D0000 | {16'd0, pair}; wt = 32'h20;
        end else begin
          sig0 = 32'h104F0000 | {16'd0, pair}; wt = 32'd8;
        end
      end
    endcase
  end
endmodule
