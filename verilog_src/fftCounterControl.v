module fftCounterControl #(
    parameter N = 32,
    pair_id_width = $clog2(N/2), 
    stage_width = $clog2($clog2(N))

) (
    input wire clk, en, reset,
    input wire input_done, output_done, 
    input wire pipeline_clear,
    output reg fft_done,
    output reg [pair_id_width -1 : 0] pair_id,
    output reg [stage_width-1: 0] stage_counter 
);


localparam log2N = $clog2(N);
localparam max_pair_id = N/2 - 1; 
localparam max_stage = log2N-2; 



// POSSIBLE STATES
localparam IDLE = 2'b00;
localparam IO = 2'b01;
localparam FFT = 2'b10;
localparam DONE = 2'b11; 

reg [1:0] fft_state; 


always @(posedge clk, posedge reset) begin

    if (reset) begin
        fft_state <= IDLE;
        pair_id <= 0;
        stage_counter <= 0;
        fft_done <= 0;
    end
    
    else 
    case (fft_state)
        IDLE:
        begin
            fft_state <= IDLE;
            pair_id <= 0;
            stage_counter <= 0;
            fft_done <= 0; 
            if (en) begin 
                if (input_done & output_done) begin
                    fft_state <= FFT;
                end
                else fft_state <= IO; 
            end
        end

        FFT: begin
            fft_state <= FFT;
            fft_done <= 1'b0;
            stage_counter <= stage_counter; 
            if (pair_id < max_pair_id) begin
                pair_id <= pair_id + 1'b1;
            end
            if (pipeline_clear & stage_counter < max_stage) begin
                stage_counter <= stage_counter + 1'b1; 
                pair_id <= 1'b0; 
            end
            else if (pipeline_clear) begin
                stage_counter <= 0;
                pair_id <= 0;
                fft_done <= 1'b1; 
                fft_state <= IDLE;
            end
        end

        IO: begin
            fft_state <= IO; 
            stage_counter <= 0;
            pair_id <= 0;
            fft_done <= fft_done;
            if (input_done & output_done) begin
                fft_state <= IDLE;
                fft_done <= 0;
            end  
        end
        
        default: fft_state <= IDLE; 
    endcase
end
    
endmodule