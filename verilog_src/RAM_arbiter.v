// MODULE TO ARBITRATE ACCESS TO RAM BETWEEN I/O AND FFT_COMPUTE
// SIMPLE RULES: 
// 1. WHEN I/O BUSY, I/O GETS MEMORY
// 2. WHEN COMPUTE BUSY, COMPUTE GETS RAM
// AYE. LET'S GET IT

module RAM_arbiter #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N)
) (
    input wire clk, reset,
    input wire fft_busy, 

    
    input wire io_wr_en, fft_wr_en, 


    input wire [address_width-1: 0] io_wr_address1, io_wr_address2,
    input wire [address_width-1: 0] io_rd_address1, io_rd_address2,

    input wire [word_size*2-1: 0] io_wr_sample1, io_wr_sample2,
    output reg [word_size*2-1: 0] io_rd_sample1, io_rd_sample2,

    input wire [address_width-1: 0] fft_wr_address1, fft_wr_address2,
    input wire [address_width-1: 0] fft_rd_address1, fft_rd_address2,

    input wire [word_size*2-1: 0] fft_wr_sample1, fft_wr_sample2,
    output reg [word_size*2-1: 0] fft_rd_sample1, fft_rd_sample2,


    input wire [word_size*2-1: 0] cram_rd_data1, cram_rd_data2,
    
    output reg [word_size*2-1: 0] cram_wr_data1, cram_wr_data2,
    output reg [address_width-1: 0] cram_rd_address1, cram_rd_address2,
    output reg [address_width-1: 0] cram_wr_address1, cram_wr_address2,

    output reg cram_wr_en
);

// as long as all input signals are registered (on the outputs of their respective modules),
// the inputs here are implicitly registered
// All that's happening here is routing. This module is purely combinatorial
// I don't expect that the tools collapse cascaded flip-flops


always @(*) begin
    {io_rd_sample1, io_rd_sample2} = {cram_rd_data1, cram_rd_data2};
    {fft_rd_sample1, fft_rd_sample2} = {cram_rd_data1, cram_rd_data2};

end

always @(*) begin

    if (fft_busy) begin
        cram_rd_address1 = fft_rd_address1;
        cram_rd_address2 = fft_rd_address2;
        cram_wr_address1 = fft_wr_address1;
        cram_wr_address2 = fft_wr_address2;
        cram_wr_en = fft_wr_en;
        {cram_wr_data1, cram_wr_data2} = {fft_wr_sample1, fft_wr_sample2};

        
    end else begin
        cram_rd_address1 = io_rd_address1;
        cram_rd_address2 = io_rd_address2;
        cram_wr_address1 = io_wr_address1;
        cram_wr_address2 = io_wr_address2;
        cram_wr_en = io_wr_en;
        {cram_wr_data1, cram_wr_data2} = {io_wr_sample1, io_wr_sample2};
    end
    
end

endmodule