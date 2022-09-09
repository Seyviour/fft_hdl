// RAM for storing intermediate computations
// should be able to store real and complex values simultaneously
// potentially, I could do that here in a 2*Q.N vector => 32 bits in this case
// Let's get it !!!

module cRAM #(
    parameter vector_size = 16,
    N = 20
) (
    input wire clk,
    input wire [$clog2(N)-1:0] read_address1, write_address1,
    input wire [$clog2(N)-1:0] read_address2, write_address2,
    input wire wr_en, sel, 
    input wire [vector_size-1: 0] in_real1, in_im1,
    output wire [vector_size-1: 0] out_real1, out_im1,
    input wire [vector_size-1: 0] in_real2, in_im2,
    output wire [vector_size-1: 0] out_real2, out_im2
);
    
    // RAM DECLARATION -> complex and real concatenated into a single
    //  2*vector_size integer
    
    reg [2*vector_size-1: 0] memory [N-1:0] ;
   

    always @(posedge clk)
        if (wr_en & sel) begin
            memory[write_address1] <= {in_real1, in_im1};
            memory[write_address2] <= {in_real2, in_im2};
        end

    assign out_real1 = memory[read_address1][2*vector_size-1:vector_size];
    assign out_im1 = memory[read_address1][vector_size-1:0];

    assign out_real2 = memory[read_address2][2*vector_size-1:vector_size];
    assign out_im2 = memory[read_address2][vector_size-1:0];

endmodule