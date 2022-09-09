// TOP module
// Controls and instantiates others
module FFT #(
    parameter N = 16,
    vector_size = 16
) (
    input wire clk, reset,
    input wire input_valid, 
    input wire [vector_size-1: 0] sample_in,
    output reg [vector_size-1: 0] fft_out
);
    

// ============= LOCAL PARAMETERS =============
localparam twiddle_adr_size = $clog2(N);
localparam pair_id_size = $clog2(N/2);
localparam stage_id_size = $clog2($clog2(N)) + 1; 
localparam log2N = $clog2(N); 

reg [stage_id_size-1: 0] stage_id; // transform stage
reg [pair_id_size-1: 0] pair_id;  // sample pair to be "transformed"

reg [twiddle_adr_size-1: 0] addr_sample1, addr_sample2, addr_twiddle;
reg [twiddle_adr_size-1: 0] addr_comp1, addr_comp2;
reg [vector_size-1: 0] sample1, sample2, comp1, comp2;
reg bank_select;

// =============== THE NUMBERS !!! ===================
reg [vector_size-1: 0] Tr, Ti; // Twiddle factor- real, imaginary
reg [vector_size-1: 0] Ar, Ai; // "top" input in butterfly
reg [vector_size-1: 0] Br, Bi; // "bottom" input butterfly
wire [vector_size-1: 0] Cr, Ci; // "top" result of butterfly
wire [vector_size-1: 0] Dr, Di; // "bottom" result of butterfly




// =============== STATE REGISTERS AND DEFINITIONS ===========
reg [1:0] FFT_state ;
localparam IDLE = 2'b00;
localparam IO = 2'b01;
localparam BUSY = 2'b10; 



// Memory selection logic
always @(posedge clk)
    bank_select <= stage_id[0]; 

// Control Logic
always @(posedge clk) begin
    if (FFT_state == BUSY) begin
        if (pair_id < max_pair)
            pair_id <= pair_id + 1;

        else if (stage < max_stage) begin
            stage_id <= stage_id + 1;
            pair_id <= 0;
        end 

        else begin
            FFT_state <= IO;
            pair_id <= 0;
            stage_id <= 0; 
        end    
    end
end

always @(posedge clk) begin
    if (FFT_state == IO) begin
        IO_idx <= IO_idx + 1;
        comp1 <= sample_in; 
    end
end



always @(*) begin
    if (FFT_state == IO)
        addr_comp1 = IO_idx;
    else
        addr_comp1 = addr_sample1; 

end


// // control logic
// always @(posedge clk)
//     casex (FFT_state)
//         IDLE: begin
//             if (input_valid)
//                 FFT_state <= IO;
//                 addr_comp1 <= -1; 
//         end

//         IO: begin
            
//         end

//         default: 
//     endcase

// I/O


// ================ ADDRESS GENERATION UNIT =======================
AGU #(.N(N)) iAGU
    (.clk(clk), .stage(stage_id), .pair_id(pair_id), .address(addr_sample1),
    .address2(addr_sample2), .twiddle_address(addr_twiddle));


// ================ TWIDDLE FACTOR ROM ============================ 
twiddleROM #(.N(N), .word_size(vector_size)) twiddle
    (.clk(clk), .read_address(addr_twiddle),
    .twiddle_real(Tr), .twiddle_im(Ti)); 



// ================ RAM INTERFACE INSTANTIATION ====================
interfaceRAM #(.vector_size(vector_size), .N(N)) RAMinterface
    (.clk(clk), .bank_select(bank_select),
    
    .wr_address1(addr_comp1), .wr_address2(addr_comp2),
    .comp1(comp1), .comp2(comp2), 

    .rd_address1(addr_sample1), .rd_address2(addr_sample2),
    .samp1(sample1), .samp2(sample2));
////////////////////////////////////////////////////////////////////

always @(*) begin
    Ar = sample1[2*vector_size-1: vector_size];
    Ai = sample1[vector_size-1: 0];

    Br = sample2[2*vector_size-1: vector_size];
    Bi = sample2[vector_size-1: 0];
end

// ================ BUTTERFLY PROCESSING UNIT ======================
BPU #(.N(N), .vector_size(vector_size)) iBPU
    (.clk(clk), .read_address(addr_twiddle),
    .Tr(Tr), .Ti(Ti),
    .Ar(Ar), .Br(Br),
    .Br(Br), .Bi(Bi),
    .Cr(Cr), .Ci(Ci),
    .Dr(Dr), .Di(Di));








endmodule




