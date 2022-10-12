import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb.binary import BinaryValue
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue

import numpy as np
import math
# from cocotb.

import coco_helpers

from typing import Dict, Any, List


"""
Module Definition
module FFT_TOP #(
    parameter N = 32,
    word_size = 16
) (
    input wire clk, reset, en,
    input wire input_valid, receiver_ready,
    input wire [word_size*2-1: 0] i_input_sample1, i_input_sample2,

    output wire output_valid,
    output wire [word_size*2-1: 0] o_output_sample1, o_output_sample2
);

"""

inputs = ["clk", "reset", "en", "input_valid", "receiver_ready", "i_input_sample1", "i_input_sample2"]
outputs = ["output_valid", "o_output_sample1", "o_output_sample2"]


@cocotb.test()
async def drive_fft(dut):

    fft_output = [0] * 32

    complex_helper = coco_helpers.ComplexNumUtil(16,16)

    tester = coco_helpers.ModuleTester(dut, inputs, outputs)
    tester.clock = Clock(dut.clk, 10, units="ns")
    tester.reset_dut()
    tester.make_input_valid_monitor("input_valid")
    tester.make_output_valid_monitor("output_valid")
    
    def test(input, output):
        pass

    tester.test = test
    tester.start_clock()
    await tester.reset_dut()


    for x in range(0, 32, 2):
        await RisingEdge(tester.dut.clk)

        tester.dut.input_valid.value = 1
        tester.dut.en.value = 1
        # tester.dut.i_input_sample1.value = complex_helper.create_from(int(math.cos(x) * 30), 0)
        # tester.dut.i_input_sample2.value = complex_helper.create_from(int(math.cos(x+1)*30), 0)

        tester.dut.i_input_sample1.value = complex_helper.create_from(x, x)
        tester.dut.i_input_sample2.value = complex_helper.create_from(x+1, x+1)


        tester.dut.receiver_ready.value = 1
    
    await RisingEdge(tester.dut.output_valid)
    x = 0
    await FallingEdge(tester.dut.clk)
    while tester.dut.output_valid == 1:
        a1 = x * 2
        a2 = a1 + 1
        out1 = tester.dut.o_output_sample1.value
        out2 = tester.dut.o_output_sample2.value

        out1 = complex_helper.decode_complex(out1)
        out2 = complex_helper.decode_complex(out2)

        fft_output[a1] = out1
        fft_output[a2] = out2
        x += 1
        await FallingEdge(tester.dut.clk)

    await RisingEdge(tester.dut.clk)

    # fft_output = [complex_helper.decode_complex(x) for x in fft_output]
    
    seq = [complex(x,x) for x in range(32)]
    comp = np.fft.fft([complex(x,x) for x in range(32)])

    # assert np.allclose(comp, fft_output, rtol=0.5, atol=0.5)

    with open("sample_output2", "w") as f:

        f.write(f"n \t\t SEQUENCE \t\t NUMPY_FFT \t\t HARDWARE_FFT\n")

        for idx in range(32):

            f.write(f"{idx} \t\t {seq[idx]} \t\t {comp[idx]:.2f} \t\t {fft_output[idx]}\n")

    
