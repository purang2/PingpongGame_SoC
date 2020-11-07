module sync_generator
#(
    parameter SYNC_DELAY = 40,
    parameter EN_DELAY = 2,
    parameter COUNT = 524
)
(
    input clk,
    input nrst,
    output [9:0] cnt,   // It wasn't able to be generalized
    output reg sync,
    output reg de,
    output reg fall_sync
);

always @ (posedge clk or negedge nrst)
begin
    if(nrst == 1'd0)
    begin
        sync <= 1'd0;
        de <= 1'd0;
        fall_sync <= 1'd0;
    end
    else
    begin
        fall_sync <= ~sync;
        if(cnt <= SYNC_DELAY) // 0~40
        begin
            sync <= 1'd0;
            de <= 1'd0;
        end
        else if((cnt > SYNC_DELAY) && (cnt <= SYNC_DELAY + EN_DELAY)) // 41~42
        begin
            sync <= 1'd1;
            de <= 1'd0;
        end
        else if((cnt > SYNC_DELAY + EN_DELAY) && (cnt <= COUNT - EN_DELAY)) // 43~522
        begin
            sync <= 1'd1;
            de <= 1'd1;
        end
        else if((cnt > COUNT - EN_DELAY) && (cnt <= COUNT)) // 523, 524
        begin
            sync <= 1'd1;
            de <= 1'd0;
        end
        else;
    end
end

sync_counter #(.COUNT(COUNT)) sync_counter_U0
(
    .clk(clk),
    .nrst(nrst),
    .cnt(cnt)
);

endmodule