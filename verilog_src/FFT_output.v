module fftOutput #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N)
) (
    input wire clk, reset, en,
    input wire [word_size-1: 0] in_samp1, in_samp2,
    output reg [address_width-1: 0] out_addr1, out_addr2,
    output reg [word_size-1: 0] out_samp1, out_samp2, 
    output reg out_valid, rd_en, busy
);      
    

always @(posedge clk) begin
    if (reset) begin
        out_addr1 <= 0;
        out_addr2 <= 1;
        out_valid <= 0;
        rd_en <= 0;
        busy <= 0; 
    end

    else if (en) begin
        if (out_addr2 == N-1) begin
            busy <= 0; 
        end else begin
            busy <= 1; 
            out_valid <= 1; 
            rd_en <= 1;
            out_samp1 <= in_samp1;
            out_samp2 <= in_samp2;
            out_addr1 <= out_addr1 + 2;
            out_addr2 <= out_addr1 + 2;
        end 
    end

end
endmodule