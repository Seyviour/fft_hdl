module AGU #(
    parameter N = 8
) (
    input wire clk,
    input wire [$clog2(N)-1: 0] stage,
    input wire [$clog2(N/2) - 1: 0] pair_id, 
    output reg [$clog2(N) -1 : 0] address1, address2
);



localparam log2N = $clog2(N);
 

reg [log2N-1: 0] stage_reg;
reg [(log2N -1)- 1: 0] pair_id_reg;
reg [log2N -1: 0] i_address1, i_address2;  


reg  [log2N-1 : 0] pair_id_x_2, pair_id_x_2_1; 

always @(*)begin
    pair_id_x_2 = {1'b0, pair_id_reg} + {1'b0, pair_id_reg}; 
    pair_id_x_2_1 = pair_id_x_2 + 1;
    i_address1 = barrel_shift_left(pair_id_x_2, stage_reg);
    i_address2 = barrel_shift_left(pair_id_x_2_1, stage_reg);

end

always @(posedge clk) begin
    pair_id_reg <= pair_id; 
    stage_reg <= stage;
    address1 <= i_address1;
    address2 <= i_address2; 
end


function [log2N-1:0] barrel_shift_left;
    input [log2N-1:0] j; //vector to be barrel shifted
    input [log2N-1:0] i; // amount to shift by

    reg [log2N-1: 0] max_index;
    reg [2*log2N-1:0] doublej;
    reg  [log2N-1:0] temp;
    begin
        max_index = {log2N{1'b1}};
        doublej = {j, j};
        temp = max_index - i; 
        barrel_shift_left = doublej[temp+:log2N];   
    end 
    
    
endfunction
    
endmodule
