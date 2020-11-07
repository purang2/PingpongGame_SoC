module paddle_cltr
#(
    parameter PADDLE_X = 0, // or 480 - 20
    parameter PADDLE_WIDTH   = 20,
    parameter PADDLE_HEIGHT = 100,
    parameter GAME_HEIGHT = 272,
    parameter CORR_X = 43, // hDE = 44~523 High
    parameter CORR_Y = 12 // vDE = 13~284 High
)
(
    input clk,
    input nrst,
    input [9:0] vcnt,
    input [9:0] hcnt,
    input de,
    input up_Paddle,
    input down_Paddle,
    input move_en,
    output reg draw_Paddle,
    output reg [8:0] paddle_Y
);

// Draw or Not
always@(de,hcnt,vcnt,nrst)
begin
    if(nrst == 1'd0)
    begin
        draw_Paddle <= 1'd0;
        paddle_Y <= GAME_HEIGHT / 2 - PADDLE_HEIGHT / 2 + CORR_Y; // 99
    end
    else if (de == 1'd1)              // Data is Valid
    begin
        if(hcnt > (PADDLE_X + CORR_X) && hcnt <= (PADDLE_X + CORR_X + PADDLE_WIDTH))                                            // paddle X Location
        begin
            //if ( (vcnt > 10'd84 + CORR_Y) && (vcnt <= 10'd84 + PADDLE_HEIGHT + CORR_Y) )
            if (vcnt > paddle_Y && (vcnt <= paddle_Y + PADDLE_HEIGHT) ) // paddle Y Location
                draw_Paddle <= 1'd1;
            else 
                draw_Paddle <= 1'd0;
        end
        else
            draw_Paddle <= 1'd0;
    end
    else            // Data is Invalid
        draw_Paddle <= 1'd0;
end

// Paddle Moving Logic

endmodule