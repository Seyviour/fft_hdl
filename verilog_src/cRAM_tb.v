// Testbench for the RAM module

module cRAM_tb;

// Parameters
localparam  vector_size = 16;
localparam  N = 20;

// Ports
reg  clk = 0;
reg [$clog2(N)-1:0] read_address1, write_address1;
reg [$clog2(N)-1:0] read_address2, write_address2;
reg wr_en = 0;
reg sel = 0;
reg [vector_size-1: 0] in_real1, in_im1;
wire [vector_size-1: 0] out_real1, out_im1;
reg [vector_size-1: 0] in_real2, in_im2;
wire [vector_size-1: 0] out_real2, out_im2;


initial begin
    $dumpfile("cRAM.vcd");
    $dumpvars(0, cRAM_tb);
end


cRAM 
#(
  .vector_size(vector_size),
  .N (N)
)
cRAM_dut (
  .clk (clk ),
  .read_address1 (read_address1 ),
  .write_address1 (write_address1 ),
  .read_address2 (read_address2 ),
  .write_address2 (write_address2 ),
  .wr_en (wr_en ),
  .sel (sel ),
  .in_real1 (in_real1 ),
  .in_im1 (in_im1 ),
  .out_real1 (out_real1 ),
  .out_im1 (out_im1 ),
  .in_real2 (in_real2 ),
  .in_im2 (in_im2 ),
  .out_real2 (out_real2 ),
  .out_im2  ( out_im2)
);

initial begin
  begin
    @(negedge clk)
    write_address1 <= 0;
    write_address2 <= 1;
    wr_en <= 1; 
    sel <= 1;
    in_im1 <= 0;
    in_im2 <= 2;
    in_real1 <= 1;
    in_real2 <= 3;
    @(negedge clk)
    read_address1 <= 1; 
    read_address2 <= 0;
    wr_en = 0; 

    repeat(3) @(negedge clk);
    $finish;
  end
end

always
  #5  clk = ! clk ;

endmodule
