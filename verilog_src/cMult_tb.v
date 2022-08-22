// test bench for complex multiplir

`timescale 1 ns/ 10 ps

module cMult_tb();

localparam T = 20;
localparam N = 16; 

initial begin
    $dumpfile("cMult.vcd");
    $dumpvars(0, cMult_tb);
end

// signal declaration

reg reset, clk;
reg [N-1:0] Ar, Ai, Br, Bi, Testr, Testi; 
wire [N-1:0] Cr, Ci; 

cMult UUT
    (.reset(reset), .clk(clk), .Ar(Ar), .Ai(Ai),
    .Br(Br), .Bi(Bi), .Cr(Cr), .Ci(Ci));

initial begin
    Ar = -2 ** 15; 
    Ai = 0;
    Br = 0; 
    Bi = -2 ** 15 ; 
    clk = 1'b1; 
    reset = 1'b1;
    #(T/2);
    reset = 1'b0;
end

always begin 
    clk = 1'b1;
    #(T/2);
    clk = 1'b0;
    #(T/2);
end

integer i , j; 

always @(posedge clk) begin
    Testr <= (Ar * Br - (Ai * Bi))/2**16; 
    Testi <= (Ar * Bi + Ai * Br)/2**16; 
end

always @(negedge clk) begin
    Ar <= Ar + 1;
    Ai <= Ai + 1; 
    Br <= Br + 1;
    Bi <= Bi + 1; 

    if (Ar == 2** 15) $stop; 
end


endmodule