module fftInput #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N)
) (
    input wire clk, reset, en, 
    input wire in_valid, 
    input wire [word_size-1: 0] sample1, sample2, 
    output reg [word_size-1: 0] comp1, comp2,
    output reg [address_width-1: 0] addr1, addr2,
    output reg wr_en, done
);
    



always @(posedge clk) begin

    if (reset) begin
        comp1 <= 0;
        comp2 <= 0;
        addr1 <= 0;
        addr2 <= 2;
        wr_en <= 0;
        done <= 0; 
    end

    else begin
        if (in_valid & en) begin
            if (addr2 == N-1)
                done <= 1'b1; 
            else begin
                wr_en <= 1'b1; 
                comp1 <= sample1 + sample2;
                comp2 <= sample1 - sample2;
                addr1 <= addr1 + 2;
                addr2 <= addr2 + 2; 
            end
        end
    end  
end


endmodule