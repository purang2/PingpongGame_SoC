module clk_divider 
(
    input clk,
    input nrst,
    output reg oclk
);

always @ (posedge clk or negedge nrst)
begin
    if(nrst == 1'd0)
        oclk <= 1'd0;
    else
        oclk <= ~oclk;
end

endmodule