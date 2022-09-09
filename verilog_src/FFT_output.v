module fftOutput #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N)
) (
    input wire clk, reset, en,
    input wire [2*word_size-1: 0] in_samp1, in_samp2,
    output reg [address_width-1: 0] out_addr1, out_addr2,
    output wire [2*word_size-1: 0] out_samp1, out_samp2, 
    output reg out_valid, rd_en, busy
);      

assign out_samp1 = in_samp1;
assign out_samp2 = in_samp2;

always @(posedge clk) begin
    out_valid <= rd_en; 
    if (reset) begin
        out_addr1 <= 0;
        // out_addr2 <= 1;
        out_valid <= 1'b0;
        rd_en <= 0;
        busy <= 0; 
    end

    ///THIS IS A HACK
    /// I SHOULD ROUTE THE valid SIGNAL FROM THE RAM HERE
    



    else  begin
        if (en) begin
            busy <= 1'b1;
            rd_en <= 1'b1; 
            if (out_addr2 == N-1) begin
                // out_addr1 <= 0; 
                busy <= 1'b0;
                rd_en <= 1'b0; 
            end else begin
                if(busy) begin 
                    out_addr1 <= out_addr1 + 2;
                end 
                // out_addr2 <= out_addr1 + 2;
            end
    end 
    end
end



always @(*) begin
    out_addr2 = out_addr1 | 1; 
end


endmodule