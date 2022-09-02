// RAM for storing intermediate computations
// should be able to store real and complex values simultaneously
// potentially, I could do that here in a 2*Q.N vector => 32 bits in this case
// Let's get it !!!

module cRAM #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N)
    
) (
    input wire clk,
    input wire [$clog2(N)-1:0] address1, address2,
    input wire wr_en, sel, read_en,  
    input wire [word_size*2-1: 0] in1, in2,
    output reg [word_size*2-1: 0] out1, out2,
    output reg o_valid, wr_complete
);
    
    integer idx;
    initial begin
        $dumpfile("cRAM.vcd");
        $dumpvars(0, cRAM);
        for (idx = 0; idx < N; idx = idx + 1) begin
            $dumpvars(0, memory1[idx]);
        end
    end
    // RAM DECLARATION -> complex and real concatenated into a single
    //  2*vector_size integer
    
    reg [2*word_size-1: 0] memory1 [N-1: 0];

    //assign combo_in = {in_real, in_im}; 

    always @(posedge clk) begin
        
        if (wr_en & sel) begin
            memory1[address1] <= in1;
            memory1[address2] <= in2;
        end


        else if (read_en & sel)begin
            out1 <= memory1[address1];
            out2 <= memory1[address2];
        end

        wr_complete <= wr_en;
        o_valid <= read_en; 
    end


endmodule