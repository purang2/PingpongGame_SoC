# 핑퐁게임: SOC 설계 및 프로그래밍(System-On-chip Design & Programming Project: Pingpong Game)  

---

## 저장소 유형

---

- 유형: 교과목형
- 수강정보

    ITEC412/SoC 설계 및 프로그래밍/2020년/1학기/문병인 교수님


---
## 설명(요약문)

---

**SoC 설계 및 프로그래밍 강의를 수강하면서 제작한 프로젝트에 대한 내용을 정리/공유한 Github 포트폴리오입니다.**

- HW 설계 및 SW 프로그래밍의 Co-design을 통한 TFT LCD(게임 화면)과 4개의 Switch(방향키 제어) 기반의 Ping-pong Game을 제작 
: HW-SW 데이터 통신 실시간/동적(Realtime and Dynamic)으로 화면 픽셀을 조절하여 두명의 플레이어 1p,2p가 즐길 수 있는 탁구 게임을 구현함.
<img src="/SOC발표JPG/SoC 텀프 최종 발표_0003.jpg" height="80%" width="80%">

- **SW개발 : Xilinx Vivado SoC Embedded Design&Programming Tool**
- **HW개발(SoC)  :  Text LCD와 LED, 7-Segment, TFT-LCD 화면(적당한 크기의 디스플레이 화면에 해당)이 탑재된 Xilinx Zynq-7000 SoC(System-on-Chip) Kit 이용**

  

Xilinx사의 Vivado라는 SoC 칩을 실습에 사용함 

- Verilog를 이용한 하드웨어(논리회로 IP 모듈)을 설계
- 해당 하드웨어 모듈의 포트 번호를 받아 칩을 소프트웨어적으로 제어하기 위한 C언어 기반의 SDK Firmware를 설계함



---    
    
## 1. 프로젝트 설명(개요)


---
### Hardware 설계

Verilog를 통해서 SOC Kit에 탑재된 입출력을 제어하는 하드웨어 모듈(IP)을 설계함. 

<img src="/SOC발표JPG/SoC 텀프 최종 발표_0004.jpg" height="60%" width="60%">

---
### Software 설계

C 기반의 SDK(Software Development Kit) 개발 툴을 통해서 프로그래밍 함.  

SOC의 Main Logic을 제어하는 두뇌 역할. HW의 IP별 Port를 Read/Write하여 직접적으로 SW 제어문을 통해 HW를 실시간 제어함 

<img src="/SOC발표JPG/SoC 텀프 최종 발표_0006.jpg" height="60%" width="60%">

---





## 2. HARDWARE 설계 (AXI Registers IP)

---

## TFT LCD를 제어하는 IP 

#### [설계/설명]

<img src="/SOC발표JPG/SoC 텀프 최종 발표_0007.jpg" height="60%" width="60%">

<img src="/SOC발표JPG/SoC 텀프 최종 발표_0008.jpg" height="60%" width="60%">


### [verilog 코드]

```
module TFTLCDCtrl
(
   input CLK,                                 // = 25MHz
   input nRESET,                                //  ?
   input [1:0] mode,                   // It comes from <Mode AXI Register> <4 modes = 2 bits>                //  Declarations For SoC Programming 
   input [3:0] button,                 // It comes from <Switch AXI Register> < 4 buttons = 4 bits>
  output TCLK,                   // TFT needs <12.5MHz>
  output reg Hsync,       // TFT-LCD HSYNC
  output reg Vsync,	     // TFT-LCD VSYNC
  output wire DE_out,	 // TFT-LCD Data enable ( Alaways "1" )
  output [7:3] R,            
  output [7:2] G,            
  output [7:3] B,         
  output Tpower            // Backlight  ( Always "1" )
);

parameter HCNT             =  524;          // 0~524 Counter
parameter VCNT             =  285;          // 0~285 Counter
parameter WIDTH           =  480;         // Active Width Area
parameter HEIGHT         =  272;         // Active Height Area
parameter HDELAY        =  40;            // At <hcnt = 41>, HSYNC is rising.
parameter VDELAY        =  9;              // At <vcnt = 10>, VSYNC is rising.
parameter EN_DELAY        =  2;

parameter PADDLE_HEIGHT         =  100;
parameter PADDLE_WIDTH           =  20;
parameter PADDLE_COL_P1         =  0;
parameter PADDLE_COL_P2         =  WIDTH - PADDLE_WIDTH;
parameter BALL_SIZE                     = 10;

parameter CORR_X = 43;                  // hDE = 44~523 High
parameter CORR_Y = 12;                  // vDE = 13~284 High

wire [9:0] hcnt, vcnt;
wire vDE, hDE;
wire Vsyncimage, Hsyncimage;

wire Draw_Ball, Draw_Paddle_P1, Draw_Paddle_P2;
wire [8:0] Paddle_Y_P1, Paddle_Y_P2;
wire [8:0] Ball_X, Ball_Y;
wire Draw_Any;
wire Game_Active;

assign Tpower = 1'd1;
assign DE_out = 1'd1;
assign DEimage = hDE & vDE;

// The reason why this always block is written ?
always @ (posedge TCLK or negedge nRESET)
    begin
      if (nRESET == 1'd0)
      begin
        Vsync <= 1'b0;
        Hsync <= 1'b0;
      end
      else
      begin
        Vsync <= Vsyncimage;
        Hsync <= Hsyncimage;
      end
    end 

// Clock Generator ( 25MHz ---> 12.5 MHz )
clk_divider clk_divider_U0
(
    .clk(CLK),
    .nrst(nRESET),
    .oclk(TCLK)
) ;

// Hsync Generator (By Hsync Counter)
sync_generator #(.SYNC_DELAY(HDELAY),   .EN_DELAY(EN_DELAY),  .COUNT(HCNT)) Hsync_generator_U0
(
    .clk(TCLK),
    .nrst(nRESET),
    .cnt(hcnt),
    .sync(Hsyncimage),
    .de(hDE),
    .fall_sync(hclk)
);

// Vsync Generator (By Vsync Coutner) ( clocked by <HSYNC> )
sync_generator #(.SYNC_DELAY(VDELAY),   .EN_DELAY(EN_DELAY),  .COUNT(VCNT)) Vsync_generator_U0
(
    .clk(hclk),
    .nrst(nRESET),
    .cnt(vcnt),
    .sync(Vsyncimage),
    .de(vDE)
);

// RGB Drawing Logic ( Location is always set by Hcount, Vcount, <mode STATUS>)
// Ball, Paddle 1, Paddle 2  -  Logics
paddle_cltr 
#(
    .PADDLE_X(PADDLE_COL_P1),
    .PADDLE_WIDTH(PADDLE_WIDTH), 
    .PADDLE_HEIGHT(PADDLE_HEIGHT),  
    .GAME_HEIGHT(HEIGHT),
    .CORR_X(CORR_X),
    .CORR_Y(CORR_Y)
) paddle_P1
(
    .clk(TCLK),
    .nrst(nRESET),
    .vcnt(vcnt),
    .hcnt(hcnt),
    .de(DEimage),
    .up_Paddle(button[0]),
    .down_Paddle(button[1]),
    .move_en(mode[0] & mode[1]),
    // Input & Output
    .draw_Paddle(Draw_Paddle_P1),
    .paddle_Y(Paddle_Y_P1)
);

paddle_cltr 
#(
    .PADDLE_X(PADDLE_COL_P2),
    .PADDLE_WIDTH(PADDLE_WIDTH), 
    .PADDLE_HEIGHT(PADDLE_HEIGHT),  
    .GAME_HEIGHT(HEIGHT),
    .CORR_X(CORR_X),
    .CORR_Y(CORR_Y)
) paddle_P2
(
    .clk(TCLK),
    .nrst(nRESET),
    .vcnt(vcnt),
    .hcnt(hcnt),
    .de(DEimage),
    .up_Paddle(button[2]),
    .down_Paddle(button[3]),
    .move_en(mode[0] & mode[1]),
    // Input & Output
    .draw_Paddle(Draw_Paddle_P2),
    .paddle_Y(Paddle_Y_P2)
);

ball_cltr
#(
    .GAME_WIDTH(WIDTH), 
    .GAME_HEIGHT(HEIGHT),   
    .BALL_SIZE(BALL_SIZE),
    .CORR_X(CORR_X),
    .CORR_Y(CORR_Y)
) 
ball_U0
(
    .clk(TCLK),
    .nrst(nRESET),
    .vcnt(vcnt),
    .hcnt(hcnt),
    .de(DEimage),
    .game_active(Game_Active),
    // Input & Output
    .draw_Ball(Draw_Ball),
    .ball_X(Ball_X),
    .ball_Y(Ball_Y)
);

// Exception Control ( Ball is OUT(next game), Game is Over )

// State Infomation ( mode = 00 --> Basic mode / = 01 --> Ready mode / = 10 --> Score mode / = 11 --> Game mode
assign Game_Active = mode[0] & mode[1] ? 1'd1 : 1'd0;                                                        // In the Game mode, The Ball starts moving.
assign Draw_Any = mode[0] ? Draw_Ball | Draw_Paddle_P1 | Draw_Paddle_P2 : 1'd0;     // Only <Ready , Game mode> draw something

// Drawing
assign R = Draw_Any ?  5'b1_1111 : 5'b0_0000;           // Red or Green
assign G = Draw_Any ?  6'b00_0000 : 6'b11_1111;
assign B = Draw_Any ?  5'b0_0000 : 5'b0_0000;

endmodule
```


---

## PushButton을 제어하는 IP

#### [설계/설명]

<img src="/SOC발표JPG/SoC 텀프 최종 발표_0009.jpg" height="60%" width="60%">


### [verilog 코드]

```
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

```


---


## Text LCD를 제어하는 IP


#### [설계/설명]
<img src="/SOC발표JPG/SoC 텀프 최종 발표_0010.jpg" height="60%" width="60%">

### [verilog 코드]

```
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


```

## 7-Segment를 제어하는 IP

#### [설계/설명]
<img src="/SOC발표JPG/SoC 텀프 최종 발표_0011.jpg" height="60%" width="60%">

### [Verilog 코드]

```
module seven_seg(
input	wire			resetn,
input	wire			clk,
input	wire	[31:0]	data, 
output	reg		[7:0]	seg_en, 
output	reg		[7:0]	seg_data
);

wire	[7:0]	seg0;
wire	[7:0]	seg1;
wire	[7:0]	seg2;
wire	[7:0]	seg3;
wire	[7:0]	seg4;
wire	[7:0]	seg5;
wire	[7:0]	seg6;
wire	[7:0]	seg7;

reg		[14:0]	clk_cnt; 

bin2seg	bin2seg_u0(	.bin(data[31:28]),	.seg(seg7)	);
bin2seg	bin2seg_u1(	.bin(data[27:24]),	.seg(seg6)	);
bin2seg	bin2seg_u2(	.bin(data[23:20]),	.seg(seg5)	);
bin2seg	bin2seg_u3(	.bin(data[19:16]),	.seg(seg4)	);
bin2seg	bin2seg_u4(	.bin(data[15:12]),	.seg(seg3)	);
bin2seg	bin2seg_u5(	.bin(data[11:8 ]),	.seg(seg2)	);
bin2seg	bin2seg_u6(	.bin(data[7 :4 ]),	.seg(seg1)	);
bin2seg	bin2seg_u7(	.bin(data[3 :0 ]),	.seg(seg0)	);

always @(posedge clk or negedge resetn)
begin
	if(!resetn) begin
		clk_cnt <= 15'd0;
	end
	else begin
		if(clk_cnt == 15'd16384) begin
			clk_cnt <= 15'd0;
		end
		else begin
			clk_cnt <= clk_cnt + 15'd1;
		end
	end
end

always @(posedge clk or negedge resetn)
begin
	if(!resetn) begin
		seg_en <= 8'b0000_0001;
	end
	else begin
		if(clk_cnt == 15'd16384) begin
			seg_en <= {seg_en[6:0], seg_en[7]};
		end
		else begin
			seg_en <= seg_en;
		end
	end
end

always @(seg_en or seg0 or seg1 or seg2 or seg3 or seg4 or seg5 or seg6 or seg7)
begin
	case(seg_en)
		8'h01	:	seg_data = seg0;
		8'h02	:	seg_data = seg1;
		8'h04	:	seg_data = seg2;
		8'h08	:	seg_data = seg3;
		8'h10	:	seg_data = seg4;
		8'h20	:	seg_data = seg5;
		8'h40	:	seg_data = seg6;
		8'h80	:	seg_data = seg7;
		default	:	seg_data = 8'b1111_1111;
	endcase
end

endmodule

```


---

## 3. SOFTWARE 프로그래밍 (SDK, Firmware) 

**C 코드를 통한 HW(SOC)의 레지스터(AXI) 값을 직접적으로 변경하여 상태를 전달/변경하여 제어하는 역할.**

---

#### [설계/설명]

<img src="/SOC발표JPG/SoC 텀프 최종 발표_0012.jpg" height="100%" width="100%">

<img src="/SOC발표JPG/SoC 텀프 최종 발표_0013.jpg" height="100%" width="100%">

---

### SDK 코드 


```c

#include <stdio.h>
#include <stdlib.h>
#include "xil_exception.h"
#include "xparameters.h"
#include "xscugic.h"
#include "pushbutton.h"
#include "tftlcd_pong.h"
#include "textlcd_pong.h"
#include "sevenseg_pong.h"
#include <sleep.h>

#define INTC_DEVICE_ID      XPAR_SCUGIC_0_DEVICE_ID
#define INTC_DEVICE_INT_ID   31
#define TRUE 1

int GicConfigure(u16 DeviceId);
void ServiceRoutine(void* CallbackRef); //

XScuGic InterruptController;         // Instance of the Interrupt Controller
static XScuGic_Config* GicConfig;    // The configuration parameters of the controller

static char TFTmode = 0;
static int score = 1; //스코어모드 스코어
static int restart_flag=0;
static int isWin=0;

int main(void)
{
    int Status;

    int TFTslv_reg2;
    int Temp_value_TFT, Temp_value_SEG;

    xil_printf("PING PONG GAME \r\n");

    Status = GicConfigure(INTC_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        xil_printf("GIC Configure Failed\r\n");
        return XST_FAILURE;
    }

    TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 0); // 2020_0617 초기화 (혹시 몰라서 )
    TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, 0);
    TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8, 0);
    SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 0, 0);
    SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 4, 0);
    TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 0, 0);
    TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 4, 0);
    PUSHBUTTON_mWriteReg(XPAR_PUSHBUTTON_0_S00_AXI_BASEADDR, 0, 0);
    PUSHBUTTON_mWriteReg(XPAR_PUSHBUTTON_0_S00_AXI_BASEADDR, 4, 0);

    while (TRUE) {
        // P1 Score, P2 Score, Final Score를 업데이트 (TFTLCD, 7SEG)
        TFTslv_reg2 = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8);

        Temp_value_TFT = (score & 0x0000000f) | (TFTslv_reg2 & 0x00003ff0); // TFT가 필요한 것 : PS의 Final Score 정보
        Temp_value_SEG = (score & 0x0000000f) | (TFTslv_reg2 & 0x00000ff0); // SEG가 필요한 것 : TFT의 P1,P2 Score 정보
        //Temp_value_SEG = TFTslv_reg2 & 0x00000fff; // 이렇게 하면 안되나?(20200617) //ㄱㄱ(0618)

        SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 4, Temp_value_SEG);
        TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8, Temp_value_TFT);

        //(게임이끝났는지?) (TFT slave 2 INFO : Winner, P2 Score, P1 Score, Final Score) ( 2bit, 4bit, 4bit, 4bit )
        isWin = TFTslv_reg2 >> 12;
        isWin = 0x00000003 & isWin;

        if (isWin == 1) { // Player 1 win
            xil_printf(":::Main Loop ::: Player 1 win\r\n");
            xil_printf("Restart -> Press any button\r\n");

            // textLCD에 승리자 표시 06_18_kmk
            TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 4, isWin);

            //0618은찬 ->
            do { ; } while (restart_flag <=1);
   
 	isWin= 0;
	restart_flag =0;            
	TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 0); // 기본 모드(2'b00)로 초기화
            SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 0, 0);
            TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 0, 0);
        }
        else if (isWin == 2) { // Player 2 win
            xil_printf(":::Main Loop ::: Player 2 win\r\n");
            xil_printf("Restart -> Press any button\r\n");

            // textLCD에 승리자 표시 06_18_kmk
            TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 4, isWin);

            //0618은찬 
            do { ; } while (restart_flag <= 1);


	isWin= 0;            // 기본 모드(2'b00)로 초기화
	restart_flag =0;
            TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 0);
            SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 0, 0);
            TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 0, 0);
        }
        else;
    }
    return XST_SUCCESS;
}


int GicConfigure(u16 DeviceId)
{
    int Status;

    GicConfig = XScuGic_LookupConfig(DeviceId);
    if (NULL == GicConfig) {
        return XST_FAILURE;
    }

    Status = XScuGic_CfgInitialize(&InterruptController, GicConfig,
        GicConfig->CpuBaseAddress);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
        (Xil_ExceptionHandler)XScuGic_InterruptHandler,
        &InterruptController);

    Xil_ExceptionEnable();

    Status = XScuGic_Connect(&InterruptController, INTC_DEVICE_INT_ID,
        (Xil_ExceptionHandler)ServiceRoutine,
        (void*)&InterruptController);

    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XScuGic_Enable(&InterruptController, INTC_DEVICE_INT_ID);

    return XST_SUCCESS;
}

void ServiceRoutine(void* CallbackRef)
{
    char intr;
    int TFTbutton;
    int Local_SEVENslv_reg1, Local_TFTslv_reg2;

    // 인터럽트가 어디서 왔는지 알려고 PushButton 읽기
    intr = PUSHBUTTON_mReadReg(XPAR_PUSHBUTTON_0_S00_AXI_BASEADDR, 0);
    // 읽고 나서 0으로 Reset
    PUSHBUTTON_mWriteReg(XPAR_PUSHBUTTON_0_S00_AXI_BASEADDR, 0, 0);
    TFTmode = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0); // slv_reg0 : Mode 레지스터

    //종료시 재시작 플래그 기능  :: 은찬
    //게임종료 시 버튼 인터럽트 flag ->anybutton 감지시 restart flag 1됨/ 사용 이후 자동 초기화(=0) 됨

   //세번 버튼 감지시 빠져나가게
    if (isWin > 0) {
        restart_flag++;
    }
    else {
        restart_flag = 0;
    }

    if (restart_flag == 0) {

        switch (TFTmode)
        {
            //->기본모드는 'default' branch로 흘러감

        case 1: //mode ==READY

           //PB1  : 모드 ++ 후 TFT REG에 WRITE
           //PB2  : 모드 게임모드 셋 후 TFT REG에 WRITE
           //PB3,4: NOTHING

            if ((intr & 1) == 1) { //Button 1 모드이동
                xil_printf(":::READY MODE::: S1 Switch is pushed->NEXT MODE\r\n");
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 2); // 다음 모드로 넘어가기
                SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 0, 2);
                TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 0, 2);
            }
            else if ((intr & 2) == 2) { //Button 2 게임시작모드로이동
                xil_printf(":::READY MODE::: S2 Switch is pushed->GAME MODE\r\n");   // Test Code
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 3); //게임모드 직행
                SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 0, 3);
                TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 0, 3);

                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, 0); // 2020_0616 민기 : 이제 게임시작하니까 더럽혀진 조작버튼(reg1) 초기화?
            }
            else if ((intr & 4) == 4) { //Button 3 nothing
                xil_printf(":::READY MODE::: S3 Switch is pushed ->Default\r\n");
            }
            else if ((intr & 8) == 8) { //Button 4 nothing
                xil_printf(":::READY MODE::: S4 Switch is pushed ->Default\r\n");
            }
            break;

        case 2: //mode ==SCORE

           //PB 1 : TFT MODE REG 플러스 후 WRITE
           //PB 2,3(1~4중)로 스코어 세팅 후 SEVENSEG_S01 REG에 WRITE
           //PB 4 : NOTHING

            if ((intr & 1) == 1) { //Button 1 모드이동
                xil_printf(":::SCORE MODE::: S1 Switch is pushed->NEXT MODE\r\n");
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 0);
                SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 0, 0);
                TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 0, 0);
            }
            else if ((intr & 2) == 2) { //Button 2 스코어증가
                if (score + 1 <= 9) score++;
                Local_SEVENslv_reg1 = SEVENSEG_PONG_mReadReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 4);
                SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 4, (Local_SEVENslv_reg1 & 0xfffffff0) | score);

                Local_TFTslv_reg2 = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8);
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8, (Local_TFTslv_reg2 & 0xfffffff0) | score);
                xil_printf(":::SCORE MODE::: S2 Switch is pushed->SCORE++: %d \r\n", score);
            }
            else if ((intr & 4) == 4) { //Button 3 스코어감소
                if (score - 1 > 0) score--;
                Local_SEVENslv_reg1 = SEVENSEG_PONG_mReadReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 4);
                SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 4, (Local_SEVENslv_reg1 & 0xfffffff0) | score);

                Local_TFTslv_reg2 = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8);
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 8, (Local_TFTslv_reg2 & 0xfffffff0) | score);
                xil_printf(":::SCORE MODE::: S3 Switch is pushed ->SCORE--: %d \r\n", score);
            }
            else if ((intr & 8) == 8) { //Button 4 nothing
                xil_printf(":::SCORE MODE::: S4 Switch is pushed ->Default\r\n");
            }
            break;

        case 3: //mode ==GAME
           //readreg 후 TFT의 현재 REG 값에다가 버튼 입력 정보를 WRITE
           //PB1,2: 1P UP/DOWN
           //PB3,4: 2P UP/DOWN

            TFTbutton = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4);

            if ((intr & 8) == 8) { // Button 4 -> 2pdown
                xil_printf(":::GAME MODE::: S1 Switch is pushed-> 2P DOWN\r\n");
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton | 0x00000001);
                usleep(200000);
                /*민기*/TFTbutton = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4);
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton & 0xfffffffe);
            }
            else if ((intr & 4) == 4) { // Button 3 2pUP
                xil_printf(":::GAME MODE::: S2 Switch is pushed->2P UP \r\n");
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton | 0x00000002);
                usleep(200000);
                /*민기*/TFTbutton = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4);
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton & 0xfffffffd);
            }
            else if ((intr & 2) == 2) { // Button 2 1PDOWN
                xil_printf(":::GAME MODE::: S3 Switch is pushed ->1P DOWN\r\n");
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton | 0x00000004);
                usleep(200000);
                /*민기*/TFTbutton = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4);
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton & 0xfffffffb);
            }
            else if ((intr & 1) == 1) { // Button 1 1PUP
                xil_printf(":::GAME MODE::: S4 Switch is pushed ->1P UP \r\n");
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton | 0x00000008);
                usleep(200000);
                /*민기*/TFTbutton = TFTLCD_PONG_mReadReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4);
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 4, TFTbutton & 0xfffffff7);
            }
            break;

        default: //mode==기본
           //PB1    : 모드이동
           //PB2,3,4: NOTHING
            if ((intr & 1) == 1) { //Button 1 모드이동
                xil_printf(":::BASIC MODE::: S1 Switch is pushed->NEXT MODE\r\n");
                TFTLCD_PONG_mWriteReg(XPAR_TFTLCD_PONG_0_S01_AXI_BASEADDR, 0, 1); // 다음 모드로 넘어가기
                SEVENSEG_PONG_mWriteReg(XPAR_SEVENSEG_PONG_0_S00_AXI_BASEADDR, 0, 1);
                TEXTLCD_PONG_mWriteReg(XPAR_TEXTLCD_PONG_0_S00_AXI_BASEADDR, 0, 1);
            }
            else if ((intr & 2) == 2) { //Button 2 =nothing
                xil_printf(":::BASIC MODE::: S2 Switch is pushed(No interrupt)\r\n");
            }
            else if ((intr & 4) == 4) { //Button 3 =nothing
                xil_printf(":::BASIC MODE::: S3 Switch is pushed(No interrupt)\r\n");
            }
            else if ((intr & 8) == 8) { //Button 4 =nothing
                xil_printf(":::BASIC MODE::: S4 Switch is pushed(No interrupt)\r\n");
            }
            break;
        }
    }
}
```





