// GENERATE ADDRESSES FOR COMPUTE READ/WRITE
// TRANSFORM DATA RECEIVED FROM ADDRESSES
// WRITE DATA BACK TO MEMORY AT RECEIVED ADDRESSES

// 
// `include "BPU.v"
// `include "twiddleROM.v"
// `include "AGU.v"

module ComputeTop #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N),
    stage_width = $clog2($clog2(N)),
    pair_id_width = $clog2(N/2)
) (
    input wire clk, reset, en, i_valid,

    input wire [stage_width-1: 0] stage,
    input wire [pair_id_width-1: 0] pair_id,

    input wire [word_size*2-1: 0] sample1, sample2,
    output reg [word_size*2-1: 0] comp1, comp2,
    output wire [address_width-1: 0] fft_wr_address1, fft_wr_address2,
    output wire [address_width-1: 0] fft_rd_address1, fft_rd_address2,


    output wire o_valid, 
    output wire d_valid
);




assign fft_rd_address1 = address1;
assign fft_rd_address2 = address2; 

ArgumentGenerator #(.N(N), .word_size(word_size), .mult_latency(mult_latency), 
    .address_width(address_width), .stage_width(stage_width), 
    .pair_id_width(pair_id_width)) thisArgumentGenerator
    (.clk(clk), .reset(reset), .i_valid(i_valid), .stage(stage), .pair_id(pair_id),)





BPU #(.N(N), .word_size(word_size), .mult_latency(2), .addresss_width(address_width)) thisBPU
    (.clk(clk), 
    .reset(reset), .i_valid(i_valid),
    .address1(address1), .address2(address2),
    .twiddle(twiddle), .sample1(sample1), .sample2(sample2),
    .comp1(comp1), .comp2(comp2),
    .wr_address1(fft_wr_address1), .wr_address2(fft_wr_address2),
    .d_valid(d_valid));

endmodule

