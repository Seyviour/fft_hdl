module BPU #(
    parameter N = 16, 
    vector_size = 16
) (
    input wire clk,
    input wire [N-1: 0] Tr, Ti,  //Twiddle factor
    input wire [N-1: 0] Ar, Ai,  // A
    input wire [N-1: 0] Br, Bi,  // B -> term to be multiplied by twiddle
    output reg [N*2-1: 0] Cr, Ci, // A + (B * Twiddle_factor)
    output reg [N*2-1: 0] Dr, Di  // A - (B * Twiddle_factor)

);


// Ultimately, the BPU should operate as a state machine
// when Done => send out current output, take in new input, set state to processing
// state will be tracked using a counter.
// will ultimately need flags for some things

localparam mult_latency = 4; 

localparam PROCESSING = 2'b00; 
localparam DONE = 2'b01;

integer i; 

wire [N*2-1: 0] A_buf;
wire [N-1: 0] A_buf_real, A_buf_im;
wire [N-1: 0] tempi, tempr;



cMult unit1
    (.clk(clk), .Ai(Ti), .Ar(Tr), .Br(Br), .Bi(Bi), .Ci(tempi), .Cr(tempr));



// buffer

buffer #(.vector_size(vector_size*2), .buffer_length(1)) bpu_buffer
    (.clk(clk), .en(1'b1), .in_valid(1'b1), .reset(1'b0),
    .d_in({Ar, Ai}), .d_out(A_buf));



assign A_buf_real = A_buf[vector_size*2-1: vector_size];
assign A_buf_im = A_buf[vector_size-1: 0];

always @(posedge clk ) begin

    if (stateBPU == DONE) begin

        Cr <= A_buf_real + tempr;
        Ci <= A_buf_im + tempi; 

        Dr <= A_buf_real - tempr; 
        Di <= A_buf_im - tempi; 
    end
end
    
endmodule
