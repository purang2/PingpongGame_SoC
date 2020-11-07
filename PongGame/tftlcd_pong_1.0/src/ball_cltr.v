module ball_cltr 
#(
    parameter GAME_WIDTH = 480,
    parameter GAME_HEIGHT = 272,
    parameter BALL_SIZE = 10,
    parameter CORR_X = 43, // hDE = 44~523 High
    parameter CORR_Y = 12 // vDE = 13~284 High
)
(
    input clk,
    input nrst,
    input [9:0] vcnt,
    input [9:0] hcnt,
    input de,
    input game_active,
    output reg draw_Ball,
    output reg [8:0] ball_X,
    output reg [8:0] ball_Y
);

// Draw or Not
always@(de,hcnt,vcnt,nrst)
begin
    if(nrst == 1'd0)
    begin
        draw_Ball <= 1'd0;
        ball_X <= GAME_WIDTH / 2 - BALL_SIZE / 2 + CORR_X;       // 279
        ball_Y <= GAME_HEIGHT / 2 - BALL_SIZE / 2 + CORR_Y;     // 144
    end
    else if (de == 1'd1)              // Data is Valid
    begin
        if(hcnt > ball_X && hcnt <= ball_X + BALL_SIZE) // Ball X Location
        begin
            if (vcnt > ball_Y && vcnt <= ball_Y + BALL_SIZE) // Ball Y Location
                draw_Ball <= 1'd1;
            else 
                draw_Ball <= 1'd0;
        end
        else
            draw_Ball <= 1'd0;
    end
    else            // Data is Invalid
        draw_Ball <= 1'd0;
end

// Ball Moving Logic

endmodule