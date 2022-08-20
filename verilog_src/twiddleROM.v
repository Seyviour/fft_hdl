module twiddleROM #(
    parameter
    N = 16,
    word_size = 16,
    memory_file_real = "/home/saviour/study/fft_hdl/helper/out.real",
    memory_file_im = "/home/saviour/study/fft_hdl/helper/out.im"
) (
    input wire clk,
    input wire [$clog2(N)-1: 0] read_address,
    output reg [word_size-1: 0] twiddle_real,
    output reg [word_size-1: 0] twiddle_im
);



reg [word_size-1:0] twiddle_real_ROM [N-1:0];
reg [word_size-1:0] twiddle_im_ROM [N-1:0];

reg [$clog2(N)-1: 0] reg_read_address; 

initial begin
    $readmemh(memory_file_im, twiddle_im_ROM);
    $readmemh(memory_file_real, twiddle_real_ROM);
end


always @(posedge clk) begin
    reg_read_address <= read_address; 
    twiddle_real <= twiddle_real_ROM[reg_read_address];
    twiddle_im  <= twiddle_im_ROM[reg_read_address]; 
end

endmodule


