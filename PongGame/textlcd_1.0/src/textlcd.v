module textlcd(
input	wire			resetn,			// reset
input	wire			lcdclk,			// clock

input 	wire [31:0]	reg_a,
input	wire [31:0]	reg_b,
input	wire [31:0]	reg_c,
input	wire [31:0]	reg_d,
input	wire [31:0]	reg_e,
input	wire [31:0]	reg_f,
input	wire [31:0]	reg_g,
input	wire [31:0]	reg_h,

output	wire			lcd_rs,			// register selection
output	wire			lcd_rw,			// read / write
output	reg				lcd_en,			// lcd enable
output	wire	[7:0]	lcd_data		// data for CG / DDRAM
);

// data line for printing on text lcd
//parameter	[31:0]	reg_a		=	32'h54_65_78_74;	// Text
//parameter	[31:0]	reg_b		=	32'h2d_4c_43_44;	// -LCD 
//parameter	[31:0]	reg_c		=	32'h20_43_6f_6e;	// Con
//parameter	[31:0]	reg_d		=	32'h74_72_6f_6c;	// trol
//parameter	[31:0]	reg_e		=	32'h53_75_63_63;	// Succ 
//parameter	[31:0]	reg_f		=	32'h65_73_73_20;	// ess
//parameter	[31:0]	reg_g		=	32'h53_6f_43_20;	// SoC
//parameter	[31:0]	reg_h		=	32'h4c_61_62_20;	// Lab

// define mode
parameter	[3:0]	mode_pwron	=	4'd1;				// power on
parameter	[3:0]	mode_fnset	=	4'd2;				// function set
parameter	[3:0]	mode_onoff	=	4'd3;				// display on / off control
parameter	[3:0]	mode_entr1	=	4'd4;				// 
parameter	[3:0]	mode_entr2	=	4'd5;				// 
parameter	[3:0]	mode_entr3	=	4'd6;				// 
parameter	[3:0]	mode_seta1	=	4'd7;				// set addr 1st line
parameter	[3:0]	mode_wr1st	=	4'd8;				// write 1st line
parameter	[3:0]	mode_seta2	=	4'd9;				// set addr 2nd line
parameter	[3:0]	mode_wr2nd	=	4'd10;				// write 2nd line
parameter	[3:0]	mode_delay	=	4'd11;				// dealy

reg		[10:0]	count_lcdclk;		// clock counter
reg		[5:0]	count_mode;			// mode state counter
reg		[3:0]	lcd_mode;			// mode state
reg		[9:0]	set_data;			// set data decoder

// enable signal
always@(posedge lcdclk or negedge resetn)
begin
	if(resetn == 1'b0) begin
		lcd_en <= 1'b0;
	end
	else begin
		if(count_lcdclk == 11'd200) begin
			lcd_en <= 1'b1;
		end
		else if(count_lcdclk == 11'd1800) begin
			lcd_en <= 1'b0;
		end
		else begin
			lcd_en <= lcd_en;
		end
	end
end

// clock counter 
always@(posedge lcdclk or negedge resetn)
begin	
	if(resetn == 1'b0) begin
		count_lcdclk <= 11'd0;
	end
	else begin
		if(count_lcdclk < 11'd1999) begin
			count_lcdclk <= count_lcdclk + 11'd1;
		end
		else begin
			count_lcdclk <= 11'd0;
		end
	end
end

// mode state counter
always@(posedge lcdclk or negedge resetn)
begin
	if(resetn == 1'b0) begin
		count_mode <= 6'd0;
	end
	else begin
		if(count_lcdclk == 11'd1999) begin 
			if(count_mode < 6'd40) begin
				count_mode <= count_mode + 6'd1;
			end
			else begin
				count_mode <= 6'd7;
			end
		end
		else begin
			count_mode <= count_mode;
		end
	end
end

// mode state
always@(posedge lcdclk or negedge resetn)
begin
	if(resetn == 1'b0) begin
		lcd_mode <= mode_pwron;
	end
	else begin
		// mode change
		case(count_mode)
			6'd0	:	lcd_mode	<=	mode_pwron;
			6'd1	:	lcd_mode	<=	mode_fnset;
			6'd2	:	lcd_mode	<=	mode_onoff;
			6'd3	:	lcd_mode	<=	mode_entr1;
			6'd4	:	lcd_mode	<=	mode_entr2;
			6'd5	:	lcd_mode	<=	mode_entr3;
			6'd6	:	lcd_mode	<=	mode_seta1;
			6'd7	:	lcd_mode	<=	mode_wr1st;
			6'd23	:	lcd_mode	<=	mode_seta2;
			6'd24	:	lcd_mode	<=	mode_wr2nd;
			6'd40	:	lcd_mode	<=	mode_delay;
			default	:	lcd_mode	<=	lcd_mode;
		endcase	
	end
end

// assign output
assign lcd_rs	=	set_data[9];
assign lcd_rw	=	set_data[8];
assign lcd_data	=	set_data[7:0];

// set data decoder 
always @(lcd_mode or count_mode or reg_a or reg_b or reg_c or reg_d or reg_e or reg_f or reg_g or reg_h)
begin 
	case(lcd_mode)
		mode_pwron	:	set_data = {2'b00, 8'h38};
		mode_fnset	:	set_data = {2'b00, 8'h38};
		mode_onoff	:	set_data = {2'b00, 8'h0e};
		mode_entr1	:	set_data = {2'b00, 8'h06};
		mode_entr2	:	set_data = {2'b00, 8'h02};
		mode_entr3	:	set_data = {2'b00, 8'h01};
		mode_seta1	:	set_data = {2'b00, 8'h80};
		mode_wr1st	:
		begin
			case(count_mode)
				6'd7	:	set_data = {1'b1, 1'b0, reg_a[31:24]};
				6'd8	:	set_data = {1'b1, 1'b0, reg_a[23:16]};
				6'd9	:	set_data = {1'b1, 1'b0, reg_a[15: 8]}; 
				6'd10	:	set_data = {1'b1, 1'b0, reg_a[7 : 0]}; 
				6'd11	:	set_data = {1'b1, 1'b0, reg_b[31:24]};
				6'd12	:	set_data = {1'b1, 1'b0, reg_b[23:16]};
				6'd13	:	set_data = {1'b1, 1'b0, reg_b[15: 8]}; 
				6'd14	:	set_data = {1'b1, 1'b0, reg_b[7 : 0]}; 
				6'd15	:	set_data = {1'b1, 1'b0, reg_c[31:24]};
				6'd16	:	set_data = {1'b1, 1'b0, reg_c[23:16]};
				6'd17	:	set_data = {1'b1, 1'b0, reg_c[15: 8]}; 
				6'd18	:	set_data = {1'b1, 1'b0, reg_c[7 : 0]}; 
				6'd19	:	set_data = {1'b1, 1'b0, reg_d[31:24]};
				6'd20	:	set_data = {1'b1, 1'b0, reg_d[23:16]};
				6'd21	:	set_data = {1'b1, 1'b0, reg_d[15: 8]};
				default :	set_data = {1'b1, 1'b0, reg_d[7 : 0]};
			endcase
		end
		mode_seta2	:	set_data = {2'b00, 8'ha8};
		mode_wr2nd	: 
		begin
			case(count_mode)
				6'd24	:	set_data = {1'b1, 1'b0, reg_e[31:24]};
				6'd25	:	set_data = {1'b1, 1'b0, reg_e[23:16]};
				6'd26	:	set_data = {1'b1, 1'b0, reg_e[15: 8]}; 
				6'd27	:	set_data = {1'b1, 1'b0, reg_e[7 : 0]}; 
				6'd28	:	set_data = {1'b1, 1'b0, reg_f[31:24]};
				6'd29	:	set_data = {1'b1, 1'b0, reg_f[23:16]};
				6'd30	:	set_data = {1'b1, 1'b0, reg_f[15: 8]}; 
				6'd31	:	set_data = {1'b1, 1'b0, reg_f[7 : 0]}; 
				6'd32	:	set_data = {1'b1, 1'b0, reg_g[31:24]};
				6'd33	:	set_data = {1'b1, 1'b0, reg_g[23:16]};
				6'd34	:	set_data = {1'b1, 1'b0, reg_g[15: 8]}; 
				6'd35	:	set_data = {1'b1, 1'b0, reg_g[7 : 0]}; 
				6'd36	:	set_data = {1'b1, 1'b0, reg_h[31:24]};
				6'd37	:	set_data = {1'b1, 1'b0, reg_h[23:16]};
				6'd38	:	set_data = {1'b1, 1'b0, reg_h[15: 8]};
				default :	set_data = {1'b1, 1'b0, reg_h[7 : 0]};
			endcase
		end
		default		:	set_data = {2'b00, 8'h02};
	endcase
end

endmodule

