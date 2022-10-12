import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb.binary import BinaryValue
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
# from cocotb.

import coco_helpers

from typing import Dict, Any, List

"""Module DEFINITION
module twiddleROM #(
    parameter
    N = 32,
    word_size = 16,
    memory_file_real = "/home/saviour/study/fft_hdl/helper/out.real",
    memory_file_im = "/home/saviour/study/fft_hdl/helper/out.im"
) (
    input wire clk,
    input wire [$clog2(N)-1: 0] read_address,
    output reg [word_size*2-1: 0] twiddle
    // output reg [word_size-1: 0] twiddle_im
);



reg [word_size-1:0] twiddle_real_ROM [N-1:0];
reg [word_size-1:0] twiddle_im_ROM [N-1:0];



"""

@cocotb.test()
async def test_twiddle_generation(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    for x in range(100):
        await RisingEdge(dut.clk)
        dut.read_address.value = x % 32


