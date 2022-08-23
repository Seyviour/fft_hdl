module AGU #(
    parameter N = 1024
) (
    input wire clk,
    input wire [$clog2(N)-1: 0] stage,
    input wire [$clog2(N/2) - 1: 0] pair_id, 
    output reg [$clog2(N) -1 : 0] address1, address2, 
    output reg [$clog2(N) -1: 0] twiddle_address
);


// N is the number of samples in the fourier transform
// log2N is the number of bits neccessary to represent N different states
// since the FFT has log2(N) stages, we need log2N bits to encode the stages
// we operate on pairs of samples => we need log(N/2) == logN2 -1 bits to encode pairs
localparam log2N = $clog2(N);
 
// signal declaration
//reg [log2N-1: 0] stage_reg;
//reg [(log2N -1)- 1: 0] pair_id_reg;
reg [log2N -1: 0] i_address1, i_address2;  

// addresses for the samples in the pair are computed as
// ROT_N_(2*pair_id, stage), ROT_N_(2*pair_id+1, stage)

// Twiddle address is computed by masking the LS log2N-stage-1 bits of pair_id

reg  [log2N-1 : 0] pair_id_x_2, pair_id_x_2_1; // (pair_id*2, pair_id*2+1)
reg [log2N-1: 0] twiddle_address_reg;
reg [log2N: 0] mask;
reg [log2N: 0] mask_;
reg [log2N-1: 0] shift_by;  


// integer i; 

always @(pair_id, stage)begin
    pair_id_x_2 = {1'b0, pair_id} + {1'b0, pair_id}; 
    pair_id_x_2_1 = pair_id_x_2 + 1;
    i_address1 = barrel_shift_left(pair_id_x_2, stage);
    i_address2 = barrel_shift_left(pair_id_x_2_1, stage);
    mask = (1 << stage);
    mask_ = mask - 1;
    twiddle_address_reg = mask_[log2N-1:0] & pair_id; 
    
    //generate 
    // for (i = 0; i<log2N-1; i = i + 1) begin
    //     if (i < log2N-stage-1) 
    //         twiddle_address_reg[i] = pair_id[i]; 
    //     else
    //         twiddle_address_reg[i] = 1'b0; 
    // end
    //endgenerate

end

always @(posedge clk) begin
    // pair_id_reg <= pair_id; 
    // stage_reg <= stage;
    address1 <= i_address1;
    address2 <= i_address2;
    twiddle_address <= twiddle_address_reg;
end


// barrel shift vector j by vector i
function [log2N-1:0] barrel_shift_left;
    input [log2N-1:0] j; //vector to be barrel shifted
    input [log2N-1:0] i; // amount to shift by

    reg [log2N-1: 0] max_index;
    reg [2*log2N-1:0] doublej;
    reg  [log2N-1:0] temp;
    begin
        max_index = log2N;
        doublej = {j, j};
        temp = max_index - i; 
        barrel_shift_left = doublej[temp+:log2N];   
    end 
    
    
endfunction
    
endmodule