module cMult #(
    N = 16
) (
    input wire clk,
    input wire [N-1:0] Ar, Ai, 
    input wire [N-1:0] Br, Bi,
    output reg [N*2-1:0] Cr, Ci
);


always @(posedge clk) begin
    //placeholder for complex multiplier
    Cr <= Ar * Br;
    Ci <= Ai * Bi;
end

    
endmodule
