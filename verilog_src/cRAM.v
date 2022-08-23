// RAM for storing intermediate computations
// should be able to store real and complex values simultaneously
// potentially, I could do that here in a 2*Q.N vector => 32 bits in this case
// Let's get it !!!

module cRAM #(
    parameter vector_size = 16,
    N = 20
) (
    input wire clk,
    input wire [$clog2(N)-1:0] read_address, write_address,
    input wire wr_en, sel, 
    input wire [vector_size-1: 0] in_real, in_im,
    output wire [vector_size-1: 0] out_real, out_im
);
    
    // RAM DECLARATION -> complex and real concatenated into a single
    //  2*vector_size integer
    
    reg [2*vector_size-1: 0] memory [N-1:0] ;
    wire [2*vector_size-1: 0] combo_in;

    //assign combo_in = {in_real, in_im}; 

    always @(posedge clk)
        if (wr_en & sel)
            memory[write_address] <= {in_real, in_im}; 
        
    assign out_real = memory[read_address][2*vector_size-1:vector_size];
    assign out_im = memory[read_address][vector_size-1:0];

endmodule