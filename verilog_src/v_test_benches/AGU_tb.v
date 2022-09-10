// AGU Testbench

module AGU_tb;

// Parameters
localparam  N = 32;
localparam stage_id_width = $clog2($clog2(N));
localparam pair_id_width = $clog2(N/2);
localparam address_width = $clog2(N);


// Ports
reg  clk = 0;
reg reset; 
reg [stage_id_width-1: 0] stage_id;
reg [pair_id_width - 1: 0] pair_id;
wire [address_width -1 : 0] address1, address2;
wire [address_width -1: 0] twiddle_address;

AGU #(.N ( N )) AGU_dut (
  .clk (clk ),
  .reset(reset),
  .stage (stage_id ),
  .pair_id (pair_id ),
  .address1 (address1 ),
  .address2 (address2 ),
  .twiddle_address (twiddle_address)
);


initial begin
    $dumpfile("AGU.vcd");
    $dumpvars(0, AGU_tb);
end

initial begin
  begin 
    stage_id <= {stage_id_width{1'b0}};
    pair_id <= {pair_id_width{1'b0}};
    //$finish;
  end
end

initial begin 
  reset = 1'b1;
  #(10);
  reset = 1'b0; 
end

always @(posedge clk) begin
    pair_id <= pair_id + 1'b1;
    if (pair_id == 15)begin
      if ((stage_id == 4))
        $finish;
      else stage_id <= stage_id + 1'b1; 
    end
end

always
  #20  clk = ! clk ;

endmodule
