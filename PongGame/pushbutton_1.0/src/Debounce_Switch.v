module Debounce_Switch (
	input wire i_Clk,
	input wire i_Switch,
	output wire o_Switch 
);

parameter c_DEBOUNCE_LIMIT = 250000; // 10ms at 25MHz

reg r_State = 1'd0;
reg [17:0] r_Count = 18'd0;

always @(posedge i_Clk)
	begin
		if(i_Switch !== r_State && r_Count < c_DEBOUNCE_LIMIT)
			r_Count <= r_Count + 18'd1; // This is Counter
		else if(r_Count == c_DEBOUNCE_LIMIT)
			begin
				r_Count <= 18'd0;
				r_State <= i_Switch;
			end
		else
			r_Count <= 18'd0;
	end

assign o_Switch = r_State;

endmodule