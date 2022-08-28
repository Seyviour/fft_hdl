module IOmodule #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N)
) (
    input wire clk, reset, en,
    
    input wire fft_busy, // FROM FFT MODULE 
    input wire input_valid, receiver_ready,  //FROM OUTSIDE WORLD
     
    input wire [word_size*2-1: 0] i_input_sample1, i_input_sample2, //FROM OUTSIDE WORLD
    output reg [word_size*2-1: 0] o_input_comp1, o_input_comp2, // TO FFT BLOCK

    output reg [address_width-1: 0] o_input_wr_addr1, o_input_wr_addr2, // TO FFT BLOCK

    input wire [word_size*2-1: 0] i_output_sample1, i_output_sample2, // FROM FFT BLOCK
    output reg [word_size*2-1: 0] o_output_sample1, o_output_sample2, // TO OUTSIDE WORLD
     
    output reg [address_width-1: 0] o_output_rd_addr1, o_output_rd_addr2, // TO FFT BLOCK

    output wire rd_en, wr_en,

    output wire output_valid, 

    output reg io_busy
);

reg o_output_valid; 
reg o_input_wr_en;
reg o_output_rd_en; 
reg o_input_busy, o_output_busy; 
reg input_enable, output_enable;
reg input_reset, output_reset; 



always @(*) begin
    io_busy = o_input_busy | o_output_busy;
    rd_en = o_output_rd_en;
    wr_en = o_input_wr_en;
    input_enable = en & input_valid & ~fft_busy;
    output_enable = en & fft_valid & ~fft_busy & receiver_ready;
    input_reset = fft_busy | reset;
    output_reset = fft_busy | reset;
    output_valid = o_output_valid; 
end

fftInput #(.N(N), .word_size(word_size), .address_width(address_width)) fft_input
    (.clk(clk),
    .reset(input_reset),
    .en(input_enable),
    .in_valid(input_valid),
    .sample1(i_input_sample1),
    .sample2(i_input_sample2),
    .comp1(o_input_comp1),
    .comp2(o_input_comp2),
    .addr1(o_input_wr_addr1),
    .addr2(o_input_wr_addr2),
    .wr_en(o_input_wr_en),
    .busy(o_input_busy));


fftOutput #(.N(N), .word_size(word_size), .address_width(address_width)) fft_output
    (.clk(clk),
    .reset(reset),
    .en(output_enable),
    .in_samp1(i_output_sample1),
    .in_samp2(i_output_sample2),
    .out_addr1(o_output_rd_addr1),
    .out_addr2(o_output_rd_addr2),
    .out_samp1(o_output_sample1),
    .out_samp2(o_output_sample2),
    .out_valid(o_output_valid),
    .rd_en(o_output_rd_en),
    .done(o_output_busy)
    );

endmodule


// THIS MODULE HAS CONTRACTS WITH THE OUTSIDE WORLD AND THE FFT BLOCK

// CONTRACT WITH THE OUTSIDE WORLD:
// 1. This module will never accept inputs while the fft block is processing
// 2. This module will tell the fft_block to stop processing when reset is asserted
// 3. This module will provide outputs as soon as the fftblock is done processing
// 4. A handshake must be established before input is accepted or output is given

// *** FFT MODULE ONLY NEEDS TO KNOW I/O IS NOT BUSY
// FFT BLOCK MUST ***NEVER*** ENTER A BUSY STATE IF IT HAAS NOT RECEIVED VALID INPUT

// THE MEMORY OF THE FFT BLOCK SHOULD BE "HANDED OVER" TO THE IO MODULE during I/O



// HARDWARE IS CONTRACTS, CONTRACTS, CONTRACTS
// IN GOOD HARDWARE, EVERY MODULE SIGNS THE CONTRACTS
// AND EVERY MODULE KEEPS TO THE CONTRACTS