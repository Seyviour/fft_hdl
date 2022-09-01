import math
from random import randint
import cocotb
from cocotb.binary import BinaryRepresentation, BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb.binary import BinaryValue
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.types import Range, LogicArray

from typing import Dict, Any, List

class ComplexNumUtil:
    def __init__(self, n_real_bits, n_im_bits):
        self.n_real_bits = n_real_bits
        self.n_im_bits = n_im_bits
        self.real_range = Range(n_real_bits-1, 0)
        self.im_range = Range(n_im_bits-1, 0)
        self.real_range_int = (-2**(n_real_bits-1), 2**(n_real_bits-1)-1)
        self.im_range_int = (-2**(n_im_bits-1), 2**(n_im_bits-1)-1)

    def __repr__(self):
        return f"ComplexNumGen(real_range={self.real_range}, n_im_bits={self.im_range})"

    def create_random(self):
        r = randint(*self.real_range_int)
        im = randint(*self.im_range_int)
        return self.create_from(r, im)

    def create_from(self, r, im):
        r =  LogicArray(r, self.real_range)
        im = LogicArray(im, self.im_range)

        this_range = Range(self.n_im_bits+self.n_real_bits-1, 0)
        return LogicArray(r.binstr + im.binstr, this_range)

    def decode(self, val: LogicArray) -> tuple:
        r_str = val.binstr[0: self.n_real_bits]
        im_str = val.binstr[-self.n_im_bits:]

        r = LogicArray(r_str).signed_integer
        im = LogicArray(im_str).signed_integer

        return (r, im)

    def decode_complex(self, val: LogicArray) -> complex:
        tup = self.decode(val)
        return complex(*tup)

    @staticmethod
    def static_decode(val: LogicArray, n_real_bits, n_im_bits):
        r_str = val.binstr[0: n_real_bits]
        im_str = val.binstr[-n_im_bits:]

        r = LogicArray(r_str).signed_integer
        im = LogicArray(im_str).signed_integer

        return (r, im)





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
    
    async def run(self) -> None: 
        await cocotb.triggers.ClockCycles(self._clk, self._delay, rising=True)
        while True:
            await RisingEdge(self._clk)
            self.values.put_nowait(self._sample())
            # print(self.value)

    def _sample(self) -> Dict[str, Any]:

        a =  {name: handle.value for name, handle in self._data.items()}
        return a


class DataValidMonitor:
    """
    Reusable Monitor of one-way control flow (data/valid) streaming data interface
    Args
        clk: clock signal
        valid: control signal noting a transaction occured
        datas: named handles to be sampled when transaction occurs
    """

    def __init__(
        self, clk: SimHandleBase, datas: Dict[str, SimHandleBase], valid: SimHandleBase
    ):
        self.values = Queue[Dict[str, int]]()
        self._clk = clk
        self._datas = datas
        self._valid = valid
        self._coro = None

    def start(self) -> None:
        """Start monitor"""
        if self._coro is not None:
            raise RuntimeError("Monitor already started")
        self._coro = cocotb.start_soon(self._run())

    def stop(self) -> None:
        """Stop monitor"""
        if self._coro is None:
            raise RuntimeError("Monitor never started")
        self._coro.kill()
        self._coro = None

    async def _run(self) -> None:
        while True:
            await RisingEdge(self._clk)
            if self._valid.value.binstr != "1": 
                await RisingEdge(self._valid)
                continue
            self.values.put_nowait(self._sample())

    def _sample(self) -> Dict[str, Any]:
        """
        Samples the data signals and builds a transaction object
        Return value is what is stored in queue. Meant to be overriden by the user.
        """
        return {name: handle.value for name, handle in self._datas.items()}



class ModuleTester:

    def __init__(self, handle: SimHandleBase, input_list: List , output_list: List):
        self.dut = handle
        self.inputs = input_list
        self.outputs = output_list
        self._checker = None
        self.driver = None 

        try:
            self.input_dict = {name: getattr(self.dut, name) for name in self.inputs}
            self.output_dict = {name: getattr(self.dut, name) for name in self.outputs}
        except:
            raise Exception("Failed to initialise input or output dict")

        self.test = None
        self.previous_outputs = None
        self.previous_inputs = None
        self.clock = None


    async def _check(self):
        while True:
            await RisingEdge(self.dut.clk)
            curr_outputs = await self.output_monitor.values.get()
            curr_inputs = await self.input_monitor.values.get()
            self.test(curr_inputs, curr_outputs)

    def start(self):
        if self._checker is not None: 
            raise RuntimeError ("Tester already started")
        try:
            self.input_monitor.start()
            self.output_monitor.start()
        except:
            raise RuntimeError("Failed to start one or both I/O monitors")
        
        try: 
            self._checker = cocotb.start_soon(self._check())
        except:
            raise RuntimeError ("Failed to start testbench")

    def stop(self):
        if self._checker is None:
            raise RuntimeError("Tester never started")
        self.input_monitor.stop()
        self.output_monitor.stop()
        self._checker.kill()
        self._checker = None

    async def reset_dut(self):
        await FallingEdge(self.dut.clk)
        self.dut.reset.value = 1
        await FallingEdge(self.dut.clk)
        self.dut.reset.value = 0

    def start_clock(self):
        cocotb.start_soon(self.clock.start())

    def make_data_valid_monitor(self, signal_dict, valid_signal):
        monitor = DataValidMonitor(self.dut.clk, signal_dict, signal_dict[valid_signal])
        return monitor

    def make_input_valid_monitor(self, valid_signal):
        monitor = self.make_data_valid_monitor(self.input_dict, valid_signal)
        self.input_monitor = monitor
    
    def make_output_valid_monitor(self, valid_signal):
        monitor = self.make_data_valid_monitor(self.output_dict, valid_signal)
        self.output_monitor = monitor


    async def start_clock_and_reset(self):
        self.start_clock()
        await self.reset_dut()

    def start_driver(self):
        cocotb.start_soon(self.driver(self))

    





class Models:
    @staticmethod
    def cMultModel(A, B):
        A = ComplexNumUtil.static_decode(A, 16, 16)
        B = ComplexNumUtil.static_decode(B, 16, 16)
        
        A = complex(*A)
        B = complex(*B)

        C = A * B

        c_im = int(C.imag)>>16
        c_re = int(C.real)>>16

        return complex(c_re, c_im)
    
    @staticmethod
    def BPUModel(twiddle, sample1, sample2):
        temp = Models.cMultModel(twiddle, sample2)
        samp1 = ComplexNumUtil.static_decode(sample1, 16, 16)
        samp1 = complex(*samp1)

        comp1 = samp1 + temp
        comp2 = samp1 - temp

        return (comp1, comp2)


    @staticmethod
    def model_AGU(stage, pair_id, N=32):
        
        
        stage = LogicArray(stage)
        i = stage.integer

        pair_id = LogicArray(pair_id)
        j = pair_id.integer
        ja = j << 1
        jb = ja + 1
        ja = ((ja << i) | (ja >> (5 - i))) & 0x1f
        jb = ((jb << i) | (ja >> (5 - i))) & 0x1f


        TwAddr = ( ( 0xfffffff0 >> i ) & 0xf ) & j

        #straight from the horses mouth, lol

        return (ja, jb, TwAddr)

















if __name__ == "__main__":

    a = ComplexNumUtil(16,16)
    t = a.create_from(1,0)
    a.decode(t)
        


