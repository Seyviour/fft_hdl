import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb.binary import BinaryValue, BinaryRepresentation
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue


import random
import coco_helpers

"""
MODULE DEFINITION

module BPU #(
    parameter N = 32, 
    word_size = 16,
    mult_latency = 2,
    address_width = $clog2(N)
) (
    input wire clk, reset, 
    input wire i_valid,

    input wire [address_width-1: 0] address1, address2, 
    input wire [word_size-1: 0] twiddle,  //Twiddle factor
    input wire [word_size*2-1: 0] sample1,  // A
    input wire [word_size*2-1: 0] sample2,  // B -> term to be multiplied by twiddle
    output wire [word_size*2-1: 0] comp1, // A + (B * Twiddle_factor)
    output wire [word_size*2-1: 0] comp2,  // A - (B * Twiddle_factor)
    output reg d_valid,
    output reg [address_width-1: 0] wr_address1, wr_address2
);
"""

def make_complex_number():
    r = random.randint(-1 *2**15, 2**15)
    i = random.randint(-1 *2**14, 2**14)
    r = BinaryValue(r, n_bits=16, binaryRepresentation=BinaryRepresentation.TWOS_COMPLEMENT)
    i = BinaryValue(i, n_bits=16, binaryRepresentation=BinaryRepresentation.TWOS_COMPLEMENT)
    




class Tester():
    def __init__(self, dut, input_list, output_list, input_valid, output_valid):
        self.dut = dut

        self.inputs = input_list
        self.outputs = output_list
        self.input_dict = {name: getattr(self.dut, name) for name in self.inputs}
        self.output_dict = {name: getattr(self.dut, name) for name in self.outputs}


        self.input_monitor = coco_helpers.DataValidMonitor(self.dut.clk, self.input_dict)
        self.output_monitor = coco_helpers.DataValidMonitor(self.dut.clk, self.output_dict)
        self.test = None
        self.previous_state = None
        self._checker = None

    def start(self):
        if self._checker is not None:
            raise RuntimeError ("Tester already started")
        self.input_monitor.start()
        self.output_monitor.start()

        try: 
            self._checker = cocotb.start_soon(self._check())
        except:
            raise RuntimeError ("Failed to start testbench")

    def stop(self):
        if self._checker is None:
            raise RuntimeError ("Tester never started")
        self.input_monitor.stop()
        self.output_monitor.stop()
        self._checker.kill()
        self._checker = None

    async def _check(self):
        while True:
            await RisingEdge(self.dut.clk)
            output = await self.output_monitor.values.get()
            input = await self.input_monitor.values.get()
            self.test(self.previous_state, input, output)
            self.previous_state = output



@cocotb.test()
async def test_butterfly_multiplications(dut):


    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut._log.info("Initialize and Reset")




