// A Q.16 fixed point complex multiplier
// This is intended to be pipelined and operates in 3 stages
// 1. Do multiplications
// 2. Do additions to generate output
// 3. Do shifting necessary to maintain the Q.N fixed point format
module cMult #(
    parameter N = 32,
    word_size = 16
) (
    input wire reset,
    input wire clk,
    input wire [word_size*2-1:0] A, 
    input wire [word_size*2-1:0] B,
    output reg [word_size*2-1:0] C
);

wire [word_size-1: 0] Ar = A[word_size*2-1: word_size];
wire [word_size-1: 0] Ai = A[word_size-1: 0];
wire [word_size-1: 0] Br = B[word_size*2-1: word_size];
wire [word_size-1: 0] Bi = B[word_size-1: 0];
wire [word_size-1: 0] Cr, Ci;

// signal declaration
reg [2*N-1: 0] RR; // product of the two real components -> Ar * Br
reg [2*N-1: 0] II; // product of the two complex components -> Ai * Bi
reg [2*N-1: 0] RI; // product of Real1 with complex2 -> Ar * Br
reg [2*N-1: 0] IR; // complex1 * real2 -> Ai * Br

reg [2*N-1: 0] R_sum; // sum of real components -> RR + II
reg [2*N-1: 0] I_sum; // sum of complex components -> RI + IR


// multipy block
// 1 cycle delay
always @(posedge clk, posedge reset) begin

    if (reset) begin
        RR <= 0;
        II <= 0;
        RI <= 0;
        IR <= 0;
    end else begin    
        RR <= Ar * Br;
        II <= Ai * Bi;
        RI <= Ar * Bi;
        IR <= Ai * Br;
    end
end


// add block
// 1 cycle delay
always @(posedge clk, posedge reset) begin

    if(reset) begin
        R_sum <= 0;
        I_sum <= 0;
    end
    else begin
        R_sum <= RR + II;
        I_sum <= RI + IR; 
    end   
end

// shift block
// 1 cycle delay
always @* begin
    C = {R_sum[2*word_size-1: word_size], I_sum[2*word_size-1: word_size]}; 
end

    
endmodule
