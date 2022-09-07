module fftInput #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N)
) (
    input wire clk, reset, en, 
    input wire in_valid, 
    input wire [word_size*2-1: 0] sample1, sample2, 
    output reg [word_size*2-1: 0] comp1, comp2,
    output reg [address_width-1: 0] addr1, addr2,
    output reg wr_en, busy, o_input_valid
);
    
// initial begin
//     $dumpfile("fftInput.vcd");
//     $dumpvars(0, fftInput);
// end

///FOR TESTING CONVENIENCE
wire start;
assign start = en && in_valid;


always @(posedge clk, posedge reset) begin

    comp1 <= {Cr, Ci}; 
    comp2 <= {Dr, Di}; 
                
    if (reset) begin
        addr1 <= 0;
        // addr2 <= 1;
        wr_en <= 0; 
        busy <= 0;
        o_input_valid <= 0; 
    end

    else  begin
        if (start) begin
            o_input_valid <= 1'b0; 
            busy <= 1'b1;
            wr_en <= 1'b1; 
            if (addr2 == N-1) begin
                busy <= 1'b0;
                wr_en <= 1'b0;
                o_input_valid <= 1'b1; 
            end else begin 
                if (busy)
                    addr1 <= addr1 + 2;
                
            end
        end
    end        
end 
reg [word_size-1: 0] Cr, Ci, Dr, Di;

always @(*) begin
    Cr = sample1[word_size*2-1: word_size] + sample2[word_size*2-1: word_size];
    Ci = sample1[word_size-1: 0] + sample2[word_size-1: 0];
    Dr = sample1[word_size*2-1: word_size] - sample2[word_size*2-1: word_size];
    Di = sample1[word_size-1: 0] - sample2[word_size-1: 0];
end

always @(*) begin
    // Since addr1 is always even(lsb is 0), addr1 + 1 == addr1 | 1
    addr2 <= addr1 | 1'b1;
end



endmodule