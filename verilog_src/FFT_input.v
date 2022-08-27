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
    output reg wr_en, done
);
    
initial begin
    $dumpfile("fftInput.vcd");
    $dumpvars(0, fftInput);
end


always @(posedge clk, posedge reset) begin

    if (reset) begin
        comp1 <= 0;
        comp2 <= 0;
        addr1 <= 0;
        // addr2 <= 1;
        wr_en <= 0; 
        done <= 0; 
    end

    else if (addr2 == N-1) begin
        done <= 1;
        wr_en <= 0;
    end else begin     
        comp1 <= {Cr, Ci}; 
        comp2 <= {Dr, Di}; 
        addr1 <= addr1 + 2;
        // addr2 <= addr2 + 2;
        wr_en <= in_valid & en;
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