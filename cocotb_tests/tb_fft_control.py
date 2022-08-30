import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb.binary import BinaryValue
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue

import coco_helpers

""" Module Definition

    module fftDriver #(
        parameter N = 32,
        stage_width = $clog2($clog2(N)),
        pair_id_width = $clog2(N/2)
    ) (
        input wire clk, reset,
        input wire io_busy,
        input wire  input_valid, 
        input wire pipeline_clear,

        output reg [stage_width-1: 0] stage,
        output reg [pair_id_width-1: 0] pair_id,
        output reg valid, 
        output reg fft_done,
        output reg fft_busy
    );

"""




"""Test FFT Controller Module"""

"""
With the following inputs forced
    pipeline_clear = 1
    io_busy = 0
    input_valid = 1

The outputs should behave in the following way:

1. while stage != max_stage:
    if (pair_id == max_pair): 
        stage += 1
        pair_id = 0
"""



"""

2. when stage == max_stage & pair == max_pair,
        state should = IO
        valid should be 0;
        fft_done should be 1
        fft_busy should be 0

    These assertions should hold for one clock cycle, since the setup
    implies that the module should immediately return to it's COMPUTE state


"""



class fftControlTester:

    def __init__(self, handle: SimHandleBase):
        self.dut = handle
        self.inputs = ["reset", "io_busy", "input_valid", "pipeline_clear"]
        self.outputs = ["stage", "pair_id", "valid", "fft_done", "fft_busy"]
        self.input_dict = {name: getattr(self.dut, name) for name in self.inputs}
        self.output_dict = {name: getattr(self.dut, name) for name in self.outputs}
        
        self.test = None
        self.previous_state = None        
        self._checker = None

        self.input_monitor = coco_helpers.DataMonitor(self.dut.clk, self.input_dict)
        self.output_monitor = coco_helpers.DataMonitor(self.dut.clk, self.output_dict)


    
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
async def test_fft_control_as_two_level_counter(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut._log.info("Initialize and reset")
    
    def test(previous_state, input, current_state):
        max_stage = 4
        max_pair_id = 15

        if not previous_state:
            return

        if current_state["stage"] == previous_state["pair_id"] == 0:
            assert True

        elif (int(previous_state["pair_id"]) < max_pair_id):
            assert current_state["pair_id"] == previous_state["pair_id"] + 1
        else:
            assert current_state["pair_id"] == 0
            if (int(previous_state["stage"]) < max_stage):
                assert current_state["stage"] == previous_state["stage"] + 1
            else:
                assert current_state["stage"] == 0

    tester = fftControlTester(dut)
    
    await FallingEdge(dut.clk)
    dut.reset.value = 1
    await FallingEdge(dut.clk)
    dut.reset.value = 0
    dut.io_busy.value = 0
    dut.input_valid.value = 1
    dut.pipeline_clear.value = 1

    tester.test = test
    tester.start()

    for _ in range(1000):
        await RisingEdge(dut.clk)

