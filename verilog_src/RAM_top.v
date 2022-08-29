// TOP RAM MODULE
// INSTANTIATES THE CRAM INTERFACE AND RAM ARBITER

`include "RAM_arbiter.v"
`include "cRAMinterface.v"

module RAM_TOP #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N)
) (
    input wire clk, reset,
    input wire fft_busy, 
    input wire io_wr_en, fft_wr_en,
    input wire bank_select,


    input wire [address_width-1: 0] io_wr_address1, io_wr_address2,
    input wire [address_width-1: 0] io_rd_address1, io_rd_address2,

    input wire [word_size*2-1: 0] io_wr_sample1, io_wr_sample2,
    output reg [word_size*2-1: 0] io_rd_sample1, io_rd_sample2,

    input wire [address_width-1: 0] fft_wr_address1, fft_wr_address2,
    input wire [address_width-1: 0] fft_rd_address1, fft_rd_address2,

    input wire [word_size*2-1: 0] fft_wr_sample1, fft_wr_sample2,
    output reg [word_size*2-1: 0] fft_rd_sample1, fft_rd_sample2
);


    wire [word_size*2-1: 0] cram_rd_data1, cram_rd_data2;
        
    wire [word_size*2-1: 0] cram_wr_data1, cram_wr_data2;
    wire [address_width-1: 0] cram_rd_address1, cram_rd_address2;
    wire [address_width-1: 0] cram_wr_address1, cram_wr_address2;

    wire cram_wr_en;

    RAM_arbiter #(.N(N), .word_size(word_size), .address_width(address_width)) ram_arbiter
        (.clk(clk), .reset(reset),
        .fft_busy(fft_busy), .io_wr_en(io_wr_en), .fft_wr_en(fft_wr_en),
        .io_wr_address1(io_wr_address1), .io_wr_address2(io_wr_address2),
        .io_rd_address1(io_rd_address1), .io_rd_address2(io_rd_address2),
        .io_wr_sample1(io_wr_sample1), .io_wr_sample2(io_wr_sample2),
        .io_rd_sample1(io_rd_sample1), .io_rd_sample2(io_rd_sample2), 
        .fft_wr_address1(fft_wr_address1), .fft_wr_address2(fft_wr_address2),
        .fft_rd_address1(fft_rd_address1), .fft_rd_address2(fft_rd_address2),
        .fft_wr_sample1(fft_wr_sample1), .fft_wr_sample2(fft_wr_sample2),
        .fft_rd_sample1(fft_rd_sample1), .fft_rd_sample2(fft_rd_sample2),
        .cram_rd_data1(cram_rd_data1), .cram_rd_data2(cram_rd_data2),
        .cram_wr_data1(cram_wr_data1), .cram_wr_data2(cram_wr_data2),
        .cram_rd_address1(cram_rd_address1), .cram_rd_address2(cram_rd_address2),
        .cram_wr_address1(cram_wr_address1), .cram_wr_address2(cram_wr_address2));
        
    

    interfaceRAM #(.N(N), .word_size(word_size), .address_width(address_width)) interRAM
        (.clk(clk), .reset(reset),
        .bank_select(bank_select), .wr_en(cram_wr_en),
        .wr_address1(cram_wr_address1), .wr_address2(cram_wr_address2),
        .rd_address1(cram_rd_address1), .rd_address2(cram_rd_address2),
        .comp1(cram_wr_data1), .comp2(cram_wr_address2), 
        .samp1(cram_rd_data1), .samp2(cram_rd_data2));


endmodule