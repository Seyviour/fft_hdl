module fftDriver #(
    parameter N = 32,
    stage_width = $clog2($clog2(N)),
    pair_id_width = $clog2(N/2)
) (
    input wire clk, reset,
    input wire io_busy, input_valid, 
    input wire pipeline_clear, 
    output reg [stage_width-1: 0] stage,
    output reg [pair_id_width-1: 0] pair_id,
    output reg valid, fft_done, fft_busy,
    output reg bank_select
);
    // initial begin
    //     $dumpfile("fftDriver.vcd");
    //     $dumpvars(0, fftDriver);
    // end


    localparam max_stage = $clog2(N)-1;
    localparam max_pair = N/2-1;
    
    localparam IO = 2'b00;
    localparam COMPUTE = 2'b01; 
   
    reg [1:0] fft_state;

    always @(posedge clk)
        if (reset) begin
            fft_state <= IO;
            stage <= 0;
            pair_id <= 0;
            valid <= 1'b0;
            fft_busy <= 1'b0;
            fft_done <= 1'b0;
            bank_select <= 1'b0;            
        end
        
        else begin case (fft_state)
            IO: begin 
                fft_state <= IO; 
                stage <= 0;
                pair_id <= 0;
                fft_busy <= 1'b0; 
                if (input_valid & !io_busy) begin 
                    fft_state <= COMPUTE;
                    bank_select <= ~bank_select; 
                    valid <= 1'b1;
                    fft_done <= 1'b0;
                    fft_busy <= 1'b1; 
                end 
            end

            COMPUTE: begin
                fft_state <= COMPUTE;
                fft_busy <= 1'b1;
                fft_done <=  1'b0;
                if (pair_id != max_pair) begin
                    pair_id <= pair_id + 1;
                end else if (pair_id == max_pair) begin
                    if (!pipeline_clear) begin
                        valid <= 1'b0; 
                    end else if (stage != max_stage) begin
                        valid <= 1'b1;
                        stage <= stage + 1'b1;
                        pair_id <= 0;
                        bank_select <= ~bank_select;
                    end else if (stage == max_stage & pipeline_clear) begin
                        valid <= 1'b0;
                        stage <= 0;
                        pair_id <= 0;
                        fft_state <= IO;
                        fft_done <= 1'b1; 
                        fft_busy <= 1'b0;
                        bank_select <= ~bank_select; 
                    end
                end
            end 
                
            default: fft_state <= IO;
        endcase
    end

endmodule