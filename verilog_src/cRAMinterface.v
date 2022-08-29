//Module for controlling what memory bank is read from/written to
//At each stage of the FFT
`include "cRAM.v"

module interfaceRAM #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N)
) (
    input wire clk, reset, 
    input wire bank_select, wr_en,

    input wire [$clog2(N)-1: 0] wr_address1, wr_address2,
    input wire [$clog2(N)-1: 0] rd_address1, rd_address2, 

    input wire [2*word_size-1:0] comp1, comp2, //Computations to write
    output reg [2*word_size-1:0] samp1, samp2 //"samples" to read

);

    localparam log2N = $clog2(N);

    reg b0_wr_en, b1_wr_en; 
    reg b0_select, b1_select;
    reg [address_width-1: 0] b0_address1, b0_address2, b1_address1, b1_address2; 
    wire [word_size-1: 0] b0_sample1, b0_sample2;
    wire [word_size-1: 0] b1_sample1, b1_sample2; 
    wire [word_size-1: 0] b0_comp1, b1_comp1;
    

    cRAM #(.word_size(word_size), .N(N), .address_width(address_width)) cRAM0
        (.clk(clk), .address1(b0_address1), .address2(b0_address2),
        .wr_en(b0_wr_en), .sel(1'b1), .in1(comp1), .in2(comp2),
        .out1(b0_sample1), .out2(b0_sample2));

    cRAM #(.word_size(word_size), .N(N), .address_width(address_width)) cRAM1
        (.clk(clk), .address1(b1_address1), .address2(b1_address2),
        .wr_en(b1_wr_en), .sel(1'b1), .in1(comp1), .in2(comp2),
        .out1(b1_sample1), .out2(b1_sample2));

    // write enable for cRAM0 and cRAM1; 
    always @(*)
        if (bank_select == 1'b0)begin
            b0_wr_en = 1'b1 & wr_en;
            b1_wr_en = 1'b0;
        end
        else begin
            b0_wr_en = 1'b0;
            b1_wr_en = 1'b1 & wr_en; 
        end
    
    // route the right addreses/data to the right CRAMs
    always @(*) begin
        if (bank_select == 1'b0) begin
            b0_address1 = wr_address1;
            b0_address2 = wr_address2;

            b1_address1 = rd_address1;
            b1_address2 = rd_address2;
        
        end else begin
            b0_address1 = rd_address1;
            b0_address2 = rd_address2;

            b1_address1 = wr_address1;
            b1_address2 = wr_address2; 
        end
    end
    
    // route read data from the right bank back
    always @(*) begin
        if (bank_select == 1'b0) begin
            samp1 = b1_sample1;
            samp2 = b1_sample2;
        end else begin
            samp1 = b0_sample1;
            samp2 = b0_sample2; 
        end
    end
        
endmodule
