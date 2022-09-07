// TOP RAM MODULE
// INSTANTIATES THE CRAM INTERFACE AND RAM ARBITER

`include "/home/saviour/study/fft_hdl/verilog_src/RAM_arbiter.v"
`include "/home/saviour/study/fft_hdl/verilog_src/cRAMinterface.v"

module RAM_TOP #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N)
) (
    input wire clk, reset,
    input wire fft_busy, 
    input wire io_wr_en, fft_wr_en,
    input wire io_read_en, fft_read_en, 
    input wire bank_select,

    

    input wire [address_width-1: 0] io_wr_address1, io_wr_address2,
    input wire [address_width-1: 0] io_rd_address1, io_rd_address2,

    input wire [word_size*2-1: 0] io_wr_sample1, io_wr_sample2,
    output wire [word_size*2-1: 0] io_rd_sample1, io_rd_sample2,

    input wire [address_width-1: 0] fft_wr_address1, fft_wr_address2,
    input wire [address_width-1: 0] fft_rd_address1, fft_rd_address2,

    input wire [word_size*2-1: 0] fft_wr_sample1, fft_wr_sample2,
    output wire [word_size*2-1: 0] fft_rd_sample1, fft_rd_sample2,

    output wire o_valid
);


    wire [word_size*2-1: 0] cram_rd_data1, cram_rd_data2;
        
    wire [word_size*2-1: 0] cram_wr_data1, cram_wr_data2;
    wire [address_width-1: 0] cram_rd_address1, cram_rd_address2;
    wire [address_width-1: 0] cram_wr_address1, cram_wr_address2;

    wire cram_wr_en, cram_read_en;

    RAM_arbiter #(.N(N), .word_size(word_size), .address_width(address_width)) ram_arbiter
        (.clk(clk), .reset(reset),
        .fft_busy(fft_busy), .io_wr_en(io_wr_en), .fft_wr_en(fft_wr_en),
        .io_wr_address1(io_wr_address1), .io_wr_address2(io_wr_address2),
        .io_rd_address1(io_rd_address1), .io_rd_address2(io_rd_address2),
        .io_read_en(io_read_en), .fft_read_en(fft_read_en), 
        .io_wr_sample1(io_wr_sample1), .io_wr_sample2(io_wr_sample2),
        .io_rd_sample1(io_rd_sample1), .io_rd_sample2(io_rd_sample2), 
        .fft_wr_address1(fft_wr_address1), .fft_wr_address2(fft_wr_address2),
        .fft_rd_address1(fft_rd_address1), .fft_rd_address2(fft_rd_address2),
        .fft_wr_sample1(fft_wr_sample1), .fft_wr_sample2(fft_wr_sample2),
        .fft_rd_sample1(fft_rd_sample1), .fft_rd_sample2(fft_rd_sample2),

        .cram_read_en(cram_read_en), .cram_wr_en(cram_wr_en),
        .cram_rd_data1(cram_rd_data1), .cram_rd_data2(cram_rd_data2),
        .cram_wr_data1(cram_wr_data1), .cram_wr_data2(cram_wr_data2),
        .cram_rd_address1(cram_rd_address1), .cram_rd_address2(cram_rd_address2),
        .cram_wr_address1(cram_wr_address1), .cram_wr_address2(cram_wr_address2));
        
    

    interfaceRAM #(.N(N), .word_size(word_size), .address_width(address_width)) interRAM
        (.clk(clk), .reset(reset),
        .bank_select(bank_select), .wr_en(cram_wr_en), .read_en(cram_read_en),
        .wr_address1(cram_wr_address1), .wr_address2(cram_wr_address2),
        .rd_address1(cram_rd_address1), .rd_address2(cram_rd_address2),
        .comp1(cram_wr_data1), .comp2(cram_wr_data2), 
        .samp1(cram_rd_data1), .samp2(cram_rd_data2),
        .o_valid(o_valid));

    // always @(posedge clk) begin
    //     valid <= fft_wr_en;
    // end


endmodule