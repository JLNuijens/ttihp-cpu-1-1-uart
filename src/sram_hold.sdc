# 50 MHz. Same numbers the flow was already using.
create_clock [get_ports clk] -name clk -period 20
set_input_delay 4.0 -clock clk [all_inputs]
set_output_delay 4.0 -clock clk [all_outputs]
set_clock_uncertainty 0.25 [get_clocks clk]
set_clock_transition 0.15 [get_clocks clk]
set_load 0.006 [all_outputs]

# The word written into the memory is the signature. It is already held,
# and the write is the next edge, not this one. Do not build a delay
# chain into the memories.
set_false_path -hold -to [get_pins {u_sram0/* u_sram1/* u_sram2/* u_sram3/*}]
