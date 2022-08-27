module FFT #(
    parameter word_size = 16,
    N = 32
) (
    input wire clk, reset,
    input wire [word_size*2-1: 0] sample1, sample2,
    input wire input_valid,

    output wire [word_size-1: 0] out_comp1, out_comp2,
    output wire output_valid
);

localparam mult_latency = 2; 

localparam log2N = $clog2(N);

localparam address_width = $clog2(N);
localparam twiddle_address_width = $clog2(N);
localparam stage_width = $clog2($clog2(N));
localparam pair_id_width = $clog2(N/2); 


wire [address_width-1: 0] s1_addr, s2_addr, tw_addr;

wire [stage_width-1: 0] stage; 
wire [pair_id_width-1: 0] pair_id;

reg bank_select; 


reg [address_width-1: 0] wr_address1, wr_address2;
reg [word_size-1: 0] comp1, comp2; 

reg [address_width-1: 0] rd_address1, rd_address2;
wire [word_size-1: 0] ram_samp1, ram_samp2;

reg [address_width-1: 0] tw_rd_address;


wire [word_size-1: 0] tw_ROM_real, tw_ROM_im; 


reg [address_width*2-1: 0] in_buffer_address; 
wire [address_width*2-1: 0] out_buffer_address;
reg in_buffer_valid, out_buffer_valid, buffer_enable;  







// INPUT MODULE
reg [word_size*2-1: 0] input_comp1, input_comp2;
reg [address_width-1: 0] input_addr1, input_addr2;
reg input_wr_en, input_done, input_en;


fftInput #(.N(N), .word_size(word_size), .address_width(address_width)) sampler
    (
    .clk(clk), .reset(reset), .en(input_en),
    .sample1(sample1), .sample2(sample2),
    .comp1(input_comp1), .comp2(input_comp2),
    .addr1(input_addr1), .addr2(input_addr2),
    .wr_en(input_wr_en), .done(input_done)
    );


// MEMORY WRITE ARBITRATION 
// when Receiving input (input_en == 1), the input module has access to memory
// Else the AGU dictates addresses (delayed by a buffer), and the BPU dictates data
always @(*) begin
    if (input_en) begin
        wr_address1 = input_addr1;
        wr_address2 = input_addr2;
        comp1 = input_comp1;
        comp2 = input_comp2;
    end else begin
        wr_address1 <= out_buffer_address[address_width*2-1: address_width];
        wr_address2 <= out_buffer_address[address_width-1: 0];
        comp1 = o_BPU_comp1;
        comp2 = o_BPU_comp2; 
    end
end





//CODE IS ART, CODE IS ART, CODE IS ART, CODE IS ART !!!
AGU #(.N(N)) thisAGU
    (.clk(clk), .reset(reset), 
    .stage(stage), .pair_id(pair_id), 
    .address1(s1_addr), .address2(s2_addr), .twiddle_address(tw_addr)); // Output


// ROUTE AGU OUTPUT TO BUFFER

always @(*) begin
    in_buffer_address = {s1_addr, s2_addr};
    in_buffer_valid = 1; //can't think of a use right now
    buffer_enable = 1; // ditto as above
end


buffer #(.buffer_length(mult_latency), .vector_size(address_width*2)) address1_buffer
    (.clk(clk), .en(buffer_enable), .reset(reset),
    .d_in(in_buffer_address), .in_valid(in_buffer_valid),  
    .dout(out_buffer_address), .d_valid(out_buffer_valid));


twiddleROM #(.N(N), .word_size(word_size)) thisTwiddleROM
    (.clk(clk),
    .read_address(tw_rd_address), 
    .twiddle_real(tw_ROM_real), .twiddle_im(tw_ROM_im));

interfaceRAM #(.vector_size(word_size), .N(N)) thisRamInterface
    (.clk(clk), 
    .bank_select(bank_select),

    .wr_address1(wr_address1), .wr_address2(wr_address2),
    .comp1(comp1), .comp2(comp2),
    
    .rd_address1(rd_address1), .rd_address2(rd_address2),
    .samp1(ram_samp1), .samp2(ram_samp2));

// GET MEMORY READ ADDRESS FROM AGU WHEN NOT GENERATING OUTPUT
// WHEN GENERATING OUTPUT, GET ADDRESSES FROM OUTPUT MODULE

always @(*) begin
    if (output_en) begin
        rd_address1 = out_addr1;
        rd_address2 = out_addr2;
    end else begin
        rd_address1 = s1_addr;
        rd_address2 = s2_addr; 
    end

    out_samp1 = ram_samp1;
    out_samp2 = ram_samp2;
    i_BPU_A = ram_samp1;
    i_BPU_B = ram_samp2;

    // TWIDDLE FACTOR
    twiddle = {tw_ROM_real, tw_ROM_im};
end



reg [word_size-1: 0] twiddle, i_BPU_A, i_BPU_B;
wire [word_size-1: 0] o_BPU_comp1, o_BPU_comp2;

BPU #(.N(N), .word_size(word_size), .mult_latency(mult_latency)) thisBPU
    (.clk(clk), 
    .twiddle(twiddle), .samp1(i_BPU_A), .samp2(i_BPU_B),
    .comp1(o_BPU_comp1), .comp2(o_BPU_comp2));


wire output_en; 
reg [word_size*2-1: 0] i_out_samp1, i_out_samp2;
reg [address_width-1: 0] out_addr1, out_addr2;
wire [word_size*2-1: 0] out_samp1, out_samp2;
wire out_valid, out_rd_en, output_done; 

fftOutput #(.N(N), .word_size(word_size), .address_width(address_width)) fftOut
    (.clk(clk), .reset(reset), .en(output_en),
    .in_samp1(i_out_samp1), .in_samp2(i_out_samp2), 
    .out_addr1(out_addr1), .out_addr2(out_addr2),
    .out_samp1(out_samp1), .out_samp2(out_samp2),
    .out_valid(out_valid), .rd_en(out_rd_en), .done(output_done));

always @(*) begin
    out_comp1 = out_samp1;
    out_compo2 = out_samp2; 
end

endmodule