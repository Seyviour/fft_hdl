// AGU Testbench

module AGU_tb;

// Parameters
localparam  N = 32;

// Ports
reg  clk = 0;
reg [$clog2(N)-1: 0] stage_id;
reg [$clog2(N/2) - 1: 0] pair_id;
wire [$clog2(N) -1 : 0] address1, address2;
wire [$clog2(N) -1: 0] twiddle_address;

AGU #(.N ( N )) AGU_dut (
  .clk (clk ),
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
    stage_id <= 0;
    pair_id <= 0; 
    //$finish;
  end
end

always @(posedge clk) begin
    pair_id <= pair_id + 1;
    if (pair_id == 15)begin
      if ((stage_id == 4))
        $finish;
      else stage_id <= stage_id + 1; 
    end
end

always
  #20  clk = ! clk ;

endmodule
