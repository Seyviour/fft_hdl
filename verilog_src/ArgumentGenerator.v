`include "AGU.v"

module ArgumentGenerator #(
    parameter N = 32,
    word_size = 16,
    mult_latency = 2,
    address_width = $clog2(N),
    stage_width = $clog2($clog2(N)),
    pair_id_width = $clog2(N/2)
) (
    input wire clk, reset,
    input wire i_valid,
    input wire [stage_width-1: 0] stage,
    input wire [pair_id_width-1: 0] pair_id,

    input wire i_RAM_valid,
    input wire [word_size*2-1: 0] i_RAM_sample1, i_RAM_sample2,


    output reg [address_width-1: 0] wr_address1, wr_address2,

    output wire [address_width-1: 0] rd_address1, rd_address2,


    output wire [word_size*2-1: 0] o_BPU_sample1, o_BPU_sample2,

    output wire [word_size*2-1: 0] o_BPU_twiddle,
    
    output wire o_RAM_valid,

    output wire o_valid
);

wire [address_width-1: 0] address1, address2, twiddle_address;
wire o_AGU_valid;

assign rd_address1 = address1;
assign rd_address2 = address2; 

AGU #(.N(N), .stage_width(stage_width), .pair_id_width(pair_id_width), .addresss_width(address_width)) thisAGU
    (.clk(clk), .reset(reset), .i_valid(i_valid), 
    .stage(stage), .pair_id(pair_id),
    .address1(address1), .address2(address2), .twiddle_address(twiddle_address),
    .o_AGU_valid(o_RAM_valid));


wire [word_size*2-1: 0] twiddle;
twiddleROM #(.N(N), .word_size(word_size)) thisTwiddleROM
    (.clk(clk), 
    .read_address(twiddle_address),
    .twiddle(twiddle));

always @(*) begin
    o_valid = i_RAM_valid;
    o_BPU_sample1 = i_RAM_sample1; 
    o_BPU_sample2 = i_RAM_sample2; 
end

always @(posedge clk) begin
    wr_address1 <= address1;
    wr_address2 <= address2; 
end






    
endmodule