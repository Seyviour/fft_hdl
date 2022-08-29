`include "cMult.v"
`include "buffer.v"

module BPU #(
    parameter N = 32, 
    word_size = 16,
    mult_latency = 2,
    address_size = $clog2(N)
) (
    input wire clk, reset, 
    input wire i_valid,

    input wire [address_size-1: 0] address1, address2, 
    input wire [word_size-1: 0] twiddle,  //Twiddle factor
    input wire [word_size*2-1: 0] sample1,  // A
    input wire [word_size*2-1: 0] sample2,  // B -> term to be multiplied by twiddle
    output wire [word_size*2-1: 0] comp1, // A + (B * Twiddle_factor)
    output wire [word_size*2-1: 0] comp2,  // A - (B * Twiddle_factor)
    output reg d_valid,
    output reg [address_size-1: 0] wr_address1, wr_address2
);


// Ultimately, the BPU should operate as a state machine

// Scratch the state machine, we gonna pipeline this !!!!

// when Done => send out current output, take in new input, set state to processing
// state will be tracked using a counter.
// will ultimately need flags for some things

//localparam mult_latency = 4; 

// input wire clk,


localparam memory_buffer_length = mult_latency + 1;

wire [word_size*2-1: 0] temp;
wire [word_size*2-1: 0] o_buffer_sample1;
wire o_buffer_d_valid;

// CMULT: (Ci, Cr) = (Ar, Ai) * (Br, Bi)
cMult unit1
    (.clk(clk), 
    .A(twiddle), 
    .B(sample2),
    .C(temp));

buffer #(.word_size(word_size*2), .buffer_length(mult_latency)) bpu_buffer
    (.clk(clk), .reset(reset), .en(1'b1), 
    .in_valid(i_valid),
    .d_in({sample1}), 
    .d_valid(o_buffer_d_valid),
    .d_out(o_buffer_sample1));


wire [address_size*2-1: 0] o_address_buffer;
buffer #(.word_size(address_size*2), .buffer_length(mult_latency)) address_buffer
    (.clk(clk), .reset(reset), .en(1'b1),
    .in_valid(i_valid),
    .d_in({address1, address2}),
    .d_out(o_address_buffer));


reg [word_size-1: 0] Cr, Ci, Dr, Di; 
always @(posedge clk, posedge reset ) begin

    if (reset) begin
        d_valid <= 0;
        Cr <= 0;
        Ci <= 0; 
        Dr <= 0;
        Di <= 0; 
    end else begin
        wr_address1 <= o_address_buffer[address_size*2-1: address_size];
        wr_address2 <= o_address_buffer[address_size-1: 0];
        
        d_valid <= o_buffer_d_valid;

        Cr <= o_buffer_sample1[word_size*2-1: word_size] + temp[word_size*2-1: word_size];
        Ci <= o_buffer_sample1[word_size-1: 0] + temp[word_size-1: 0];

        Dr <= o_buffer_sample1[word_size*2-1: word_size] - temp[word_size*2-1: word_size]; 
        Di <= o_buffer_sample1[word_size-1: 0] - temp[word_size-1: 0];
    end
end

assign comp1 = {Cr, Ci};
assign comp2 = {Dr, Di};
    
endmodule
