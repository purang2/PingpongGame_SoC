module bin2seg(
input	wire	[3:0]	bin,

output	reg		[7:0]	seg
);

always @(bin)
begin
	case(bin)
		4'd0	:	seg	=	8'b0000_0011;	// 0
		4'd1	:	seg	=	8'b1001_1111; 	// 1
		4'd2	:	seg	=	8'b0010_0101; 	// 2
		4'd3	:	seg	=	8'b0000_1101; 	// 3
		4'd4	:	seg	=	8'b1001_1001; 	// 4
		4'd5	:	seg	=	8'b0100_1001; 	// 5
		4'd6	:	seg	=	8'b0100_0001; 	// 6
		4'd7	:	seg	=	8'b0001_1011; 	// 7
		4'd8	:	seg	=	8'b0000_0001; 	// 8
		4'd9	:	seg	=	8'b0001_1001; 	// 9
		4'd10	:	seg	=	8'b1111_1101;	// Dash
		default	:	seg	=	8'b0000_0011;
	endcase
end

endmodule
