import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb.binary import BinaryValue
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from types import MethodType
# from cocotb.

import coco_helpers

from typing import Dict, Any, List


"""
MODULE DEFINITION
module fftInput #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N)
) (
    input wire clk, reset, en, 
    input wire in_valid, 
    input wire [word_size*2-1: 0] sample1, sample2, 
    output reg [word_size*2-1: 0] comp1, comp2,
    output reg [address_width-1: 0] addr1, addr2,
    output reg wr_en, busy
);
"""

inputs = ["clk", "reset", "en", "in_valid", "sample1", "sample2", "start"]
outputs = ["comp1", "comp2", "addr1", "addr2", "wr_en"]


@cocotb.test()
async def test_address_iteration(dut):

    tester = coco_helpers.ModuleTester(dut, inputs, outputs)
    tester.clock = Clock(dut.clk, 10, units="ns")
    tester.make_input_valid_monitor("start")
    tester.make_output_valid_monitor("wr_en")

    def test(self, input, output):
        pass

    tester.test = MethodType(test, tester)
    tester.start_clock()
    await tester.reset_dut()

    for x in range(0, 100, 2):
        await RisingEdge(tester.dut.clk)
        tester.dut.in_valid.value = 1
        tester.dut.en.value = 1
        tester.dut.sample1.value = x
        tester.dut.sample2.value = x + 1





