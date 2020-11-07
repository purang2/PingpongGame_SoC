module sync_counter
#(
    parameter COUNT = 524
)
(
    input clk,
    input nrst,
    output reg [9:0] cnt // It wasn't able to be generalized
);

always @ (posedge clk or negedge nrst)
begin
    if(nrst == 1'd0)
        cnt <= 10'd0;
    else
    begin
        if(cnt < COUNT)
            cnt <= cnt + 10'd1;
        else
            cnt <= 10'd0;
    end
end

endmodule