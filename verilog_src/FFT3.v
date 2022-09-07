
`include "/home/saviour/study/fft_hdl/verilog_src/AGU.v"
`include "/home/saviour/study/fft_hdl/verilog_src/IOmodule.v"
`include "/home/saviour/study/fft_hdl/verilog_src/RAM_top.v"
`include "/home/saviour/study/fft_hdl/verilog_src/twiddleROM.v"
`include "/home/saviour/study/fft_hdl/verilog_src/ComputeDriver.v"
`include "/home/saviour/study/fft_hdl/verilog_src/BPU.v"



module FFT_TOP #(
    parameter N = 32,
    word_size = 16
) (
    input wire clk, reset, en,
    input wire input_valid, receiver_ready,
    input wire [word_size*2-1: 0] i_input_sample1, i_input_sample2,

    output wire output_valid,
    output wire [word_size*2-1: 0] o_output_sample1, o_output_sample2
);

initial begin
        $dumpfile("FFT3.vcd");
        $dumpvars(0, FFT_TOP);// initial begin
end
    

localparam address_width = $clog2(N);
localparam stage_width = $clog2($clog2(N));
localparam pair_id_width = $clog2(N/2); 

wire [stage_width-1: 0] stage;
wire [pair_id_width-1: 0] pair_id;
wire o_driver_valid;
wire pipeline_clear;

// wire fft_busy;
wire fft_done;
wire [address_width-1: 0] o_io_wr_address1, o_io_wr_address2;
wire [address_width-1: 0] o_io_rd_address1, o_io_rd_address2;
wire [word_size*2-1: 0] i_output_sample1, i_output_sample2;
wire [word_size*2-1: 0] o_io_comp1, o_io_comp2;
wire fft_busy, io_busy, io_wr_en, io_rd_en;
wire io_output_valid; 
wire io_input_valid; 
wire bank_select;


assign pipeline_clear = ~o_BPU_valid;

fftDriver #(.N(N), .pair_id_width(pair_id_width), .stage_width(stage_width)) thisFFTDriver
    (.clk(clk), .reset(reset),
    .io_busy(io_busy), .input_valid(io_input_valid),
    .pipeline_clear(pipeline_clear),
    .stage(stage), .pair_id(pair_id), .bank_select(bank_select),
    .valid(o_driver_valid), .fft_done(fft_done), 
    .fft_busy(fft_busy));



assign output_valid = io_output_valid;



IOmodule #(.N(N), .word_size(word_size), .address_width(address_width)) thisIOModule
    (.clk(clk), .reset(reset), .en(en),
    .input_valid(input_valid), .receiver_ready(receiver_ready),
    .i_input_sample1(i_input_sample1), .i_input_sample2(i_input_sample2),
    .o_input_wr_addr1(o_io_wr_address1), .o_input_wr_addr2(o_io_wr_address2),
    .o_input_comp1(o_io_comp1), .o_input_comp2(o_io_comp2),
    .wr_en(io_wr_en),
    .fft_busy(fft_busy), .fft_valid(fft_done), .io_busy(io_busy),
    .i_output_sample1(i_output_sample1), .i_output_sample2(i_output_sample2),
    .o_output_sample1(o_output_sample1), .o_output_sample2(o_output_sample2),
    .o_output_rd_addr1(o_io_rd_address1), .o_output_rd_addr2(o_io_rd_address2),
    .rd_en(io_rd_en),
    .o_output_valid(io_output_valid), .o_input_valid(io_input_valid) );

wire [address_width-1: 0] fft_wr_address1, fft_wr_address2;
wire [address_width-1: 0] fft_rd_address1, fft_rd_address2;
wire [word_size*2-1: 0] fft_wr_sample1, fft_wr_sample2;
wire [word_size*2-1: 0] fft_rd_sample1, fft_rd_sample2;
wire fft_wr_en;
wire o_RAM_valid;

assign fft_wr_en = o_BPU_valid;
// assign bank_select = ~ stage[0]; 


wire [address_width-1: 0] o_AGU_address1, o_AGU_address2, twiddle_address; 
wire i_AGU_valid, o_AGU_valid;

RAM_TOP #(.N(N), .word_size(word_size), .address_width(address_width)) thisRAM
    (.clk(clk), .reset(reset),
    .fft_busy(fft_busy),
    .io_wr_en(io_wr_en), .fft_wr_en(fft_wr_en),
    .io_read_en(io_rd_en), .fft_read_en(o_AGU_valid),
    .bank_select(bank_select),
    .io_wr_address1(o_io_wr_address1), .io_wr_address2(o_io_wr_address2),
    .io_rd_address1(o_io_rd_address1), .io_rd_address2(o_io_rd_address2), 
    .io_wr_sample1(o_io_comp1), .io_wr_sample2(o_io_comp2),
    .io_rd_sample1(i_output_sample1), .io_rd_sample2(i_output_sample2),
    .fft_wr_address1(fft_wr_address1), .fft_wr_address2(fft_wr_address2),
    .fft_rd_address1(fft_rd_address1), .fft_rd_address2(fft_rd_address2),
    .fft_wr_sample1(fft_wr_sample1), .fft_wr_sample2(fft_wr_sample2),
    .fft_rd_sample1(fft_rd_sample1), .fft_rd_sample2(fft_rd_sample2),
    .o_valid(o_RAM_valid));

assign fft_rd_address1 = o_AGU_address1;
assign fft_rd_address2 = o_AGU_address2;

//fft_wr_en => input from fft to RAM is valid




AGU #(.N(N), .stage_width(stage_width), .pair_id_width(pair_id_width), .address_width(address_width)) thisAGU
    (.clk(clk), .reset(reset), .i_valid(o_driver_valid),
    .stage(stage), .pair_id(pair_id),
    .address1(o_AGU_address1), .address2(o_AGU_address2),
    .twiddle_address(twiddle_address), .o_valid(o_AGU_valid));

wire [word_size*2-1: 0] twiddle; 
twiddleROM #(.N(N), .word_size(word_size)) thisTwiddleROM
    (.clk(clk), .read_address(twiddle_address),
    .twiddle(twiddle));

localparam mult_latency = 2;

/// BITE ME

wire o_BPU_valid; 
BPU #(.N(N), .word_size(word_size), .address_width(address_width), .mult_latency(mult_latency)) thisBPU
    (.clk(clk), .reset(reset), .i_valid(o_RAM_valid), 
    .address1(o_AGU_address1), .address2(o_AGU_address2),
    .twiddle(twiddle), .sample1(fft_rd_sample1), .sample2(fft_rd_sample2),
    .comp1(fft_wr_sample1), .comp2(fft_wr_sample2),
    .wr_address1(fft_wr_address1), .wr_address2(fft_wr_address2), 
    .d_valid(o_BPU_valid));






endmodule