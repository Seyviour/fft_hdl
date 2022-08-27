# from queue import Queue
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb.binary import BinaryValue
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue

from typing import Dict, Any

class DataMonitor:
    """ Monitor inputs and outputs
    
    Args
        clk: clock signal
        data: data to monitor
        delay: number of clock cycles to wait before recording
    """

    def __init__(self, clk, data: Dict[str, SimHandleBase], delay= 0):
        self.values = Queue()
        self._clk = clk
        self._data = data
        self._coro = None
        self._delay = delay

    def start(self) -> None:
        """Start Monitor"""
        if self._coro is not None:
            raise RuntimeError("Monitor already started")
        self._coro = cocotb.start_soon(self.run())

    def stop(self) -> None:
        """Stop monitor"""
        if self._coro is None:
            raise RuntimeError("Monitor never started")
        self._coro.kill()
        self._coro = None
    
    async def _run(self) -> None: 
        await cocotb.triggers.ClockCycles(self._clk, self._delay, rising=True)
        while True:
            await RisingEdge(self._clk)
            self.values.put_nowait(self._sample())

    def _sample(self) -> Dict[str, Any]:

        return {name: handle.value for name, handle in self._data.items()}


"""
EXPECTED BEHAVIOUR:

1. en: when en is 0, address iteration should freeze, samples should not be read
    and wr_en should be set to 0

2. in_valid: if in_valid is 0 then the input we are receiving is incorrect.
    In this case, wr_en should be set to 0 and address iteration should freeze

3. reset: on reset, addresses should be set to 0, wr_en should be set to 0, done should be 0

4. addr1, addr2: when en and in_valid are 1, addr1 should each increase by 2 on every clock cycle

5. done: done should be set to 1 when addr2 is at it's maximum value

"""
class fftInputTester: 

    def __init__(self, input_handle: SimHandleBase):
        self.dut = input_handle
        self.max = 32
        self._sample = None
        self.previous_state = None
        # Yeah, yeah, I know it's actually a dict
        self._input_list = {
            "samp1": self.dut.sample1,
            "samp2": self.dut.sample2,
            "en": self.dut.en,
            "in_valid": self.dut.in_valid
        }
        self._output_list = {
            "comp2": self.dut.comp2,
            "comp1": self.dut.comp1,
            "addr1": self.dut.addr1,
            "addr2": self.dut.addr2,
            "wr_en": self.dut.wr_en,
            "done": self.dut.done
        }

        self.input_mon = DataMonitor(
            clk = self.dut.clk,
            data = self._input_list
         )

        self.output_mon = DataMonitor(
            clk = self.dut.clk,
            data = self._output_list, 
            delay=1
         )
    
    async def _sample(self, signals):
        await RisingEdge(self.clk)
        self._sample = {}


    async def _check(self):
        print("I ran")
        self.previous_state = None
        while True: 
            await RisingEdge(self.dut.clk)
            data_out = self.output_mon.values.get()
            data_in = self.input_mon.values.get()
            self._check_reset(data_in, data_out)
            self._check_en(data_in, data_out)
            self.previous_state = data_out

            

    def _check_reset(self, data_in, data_out):
        
        if (data_in["reset"].value == 1):
            assert data_out["done"].value == 0, "Failure: 'done' signal not 0 on reset"
            assert data_out["wr_en"].value == 0, "Failure: 'wr_en' 1 on reset (attempt to write invalid data)"
            assert data_out["addr1"] == 0, "Failure: address 1 not reset"
            assert data_out["addr2"] == 1, "Failure: address 2 not reset"

    def _check_en(self, data_in, data_out):
        if (data_in["en"].value == 0 or data_in["in_valid"].value == 0):
            if not self.previous_state:
                cocotb.log.debug("Previous state not yet recorded")
                return
            else:
                assert data_out["wr_en"].value == 0, "Attempt to write when not enabled"
                
                for k, v in self.previous_state:
                    if k != "wr_en": 
                        assert v.value == data_out[k].value
        
        elif (data_in["en"].value == 1 and data_in["in_valid"].value == 1):
            if not self.previous_state:
                cocotb.log.debug("Previous state not yet recorded")
                return
            else:
                if self.previous_state["addr2"].value == self.max:
                    assert data_out["valid"].value == 0
                    assert data_out["wr_en"].value == 0
                
                else:
                    assert data_out["addr1"].value == (self.previous_state["addr1"].value + 2)
                    assert data_out["addr2"].value == (self.previous_state["addr2"].value + 2)
                    assert data_out["comp1"].value == data_in["sample1"].value + data_in["sample2"].value
                    assert data_out["comp2"].value == data_in["sample1"].value - data_in["sample2"].value
    
    def start(self): 
        """Start monitors, model and checker corouting"""
        if self._checker is not None:
            raise RuntimeError("Monitor alreadys started")
        self.input_mon.start()
        self.output_mon.start()
        self._checker = cocotb.start_soon(self._check())

    def stop(self):
        if self._checker is None: 
            raise RuntimeError("Monitor never started")
        
        self.input_mon.stop()
        self.output_mon.stop()
        self._checker.kill()
        self._checker = None




@cocotb.test()
async def test_fft_input(dut):
    """Test FFT input module"""

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    tester = fftInputTester(dut)

    dut._log.info("Initialize and reset")

    await FallingEdge(dut.clk)
    dut.reset.value = 1
    await FallingEdge(dut.clk)
    dut.reset.value = 0

    

    for x in range(0, 35, 2):
        await FallingEdge(dut.clk)
        dut.en.value = 1
        dut.in_valid.value = 1
        dut.sample1.value = x
        dut.sample2.value = x + 1

    
    await RisingEdge(dut.clk)





    






# # -*- coding: utf-8 -*-
# import cocotb
# from cocotb.clock import Clock
# from cocotb.triggers import Timer
# from cocotb.regression import TestFactory

# @cocotb.test()
# async def run_test(dut):
#   PERIOD = 10
#   cocotb.fork(Clock(dut.clk, PERIOD, 'ns').start(start_high=False))

#   dut.reset = 0
#   dut.en = 0
#   dut.in_valid = 0
#   dut.sample1 = 0
#   dut.sample2 = 0
#   dut.comp1 = 0
#   dut.comp2 = 0
#   dut.addr1 = 0
#   dut.addr2 = 0
#   dut.wr_en = 0
#   dut.done = 0



