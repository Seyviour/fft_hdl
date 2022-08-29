module buffer #(
    parameter vector_size = 16,
    buffer_length = 1
) (
    input wire clk, en, in_valid, reset,   
    input wire [vector_size-1: 0] d_in,
    output reg [vector_size-1: 0] d_out,
    output reg d_valid
);


//SIGNAL DECLARATION
reg [vector_size: 0] ibuffer [buffer_length-1: 0];
integer i;

always @(posedge clk, posedge reset) begin

    if (reset) begin
        for (i = 0; i <= buffer_length-2; i = i + 1) begin
            ibuffer[i] <= 0;
        end
    end
    else if (en) begin
        ibuffer[buffer_length-1] <= {in_valid, d_in};

        //generate
        for (i = 0; i <= buffer_length-2; i = i + 1) begin
            ibuffer[i] <= ibuffer[i + 1];
        end
        //endgenerate
        
        d_out <= ibuffer[0][vector_size-1: 0];
        d_valid <= ibuffer[0][vector_size];
    
    end
end
    
endmodule