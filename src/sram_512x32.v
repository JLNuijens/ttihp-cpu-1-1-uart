// 512 x 32 foundry macro. Sim is the array. The GDS build uses the blackbox
// and the CMOS5L LEF. Four copies. 8 KB.
`default_nettype none

`ifdef COCOTB_SIM
module RM_IHPSG13_1P_512x32_c2_bm_bist (
  input  wire        A_CLK,
  input  wire        A_MEN,
  input  wire        A_WEN,
  input  wire        A_REN,
  input  wire [8:0]  A_ADDR,
  input  wire [31:0] A_DIN,
  input  wire        A_DLY,
  output reg  [31:0] A_DOUT,
  input  wire [31:0] A_BM,
  input  wire        A_BIST_CLK,
  input  wire        A_BIST_EN,
  input  wire        A_BIST_MEN,
  input  wire        A_BIST_WEN,
  input  wire        A_BIST_REN,
  input  wire [8:0]  A_BIST_ADDR,
  input  wire [31:0] A_BIST_DIN,
  input  wire [31:0] A_BIST_BM
);
  reg [31:0] mem [0:511];
  integer i;
  initial begin
    for (i = 0; i < 512; i = i + 1) mem[i] = 32'd0;
    A_DOUT = 32'd0;
  end
  always @(posedge A_CLK) begin
    if (A_MEN && A_WEN) mem[A_ADDR] <= A_DIN & A_BM;
    if (A_MEN && A_REN) A_DOUT <= mem[A_ADDR];
  end
  wire _tied = &{A_DLY, A_BIST_CLK, A_BIST_EN, A_BIST_MEN, A_BIST_WEN,
                 A_BIST_REN, A_BIST_ADDR, A_BIST_DIN, A_BIST_BM};
endmodule
`else
(* blackbox *)
module RM_IHPSG13_1P_512x32_c2_bm_bist (
  input  wire        A_CLK,
  input  wire        A_MEN,
  input  wire        A_WEN,
  input  wire        A_REN,
  input  wire [8:0]  A_ADDR,
  input  wire [31:0] A_DIN,
  input  wire        A_DLY,
  output wire [31:0] A_DOUT,
  input  wire [31:0] A_BM,
  input  wire        A_BIST_CLK,
  input  wire        A_BIST_EN,
  input  wire        A_BIST_MEN,
  input  wire        A_BIST_WEN,
  input  wire        A_BIST_REN,
  input  wire [8:0]  A_BIST_ADDR,
  input  wire [31:0] A_BIST_DIN,
  input  wire [31:0] A_BIST_BM
);
endmodule
`endif
`default_nettype wire
