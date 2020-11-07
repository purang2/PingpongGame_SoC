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