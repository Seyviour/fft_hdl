import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb.binary import BinaryValue, BinaryRepresentation
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from copy import copy

import random
import coco_helpers

"""
Module Definition
module cRAM #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N)
    
) (
    input wire clk,
    input wire [$clog2(N)-1:0] address1, address2,
    input wire wr_en, sel, read_en,  
    input wire [word_size*2-1: 0] in1, in2,
    output reg [word_size*2-1: 0] out1, out2,
    output reg o_valid
);
    
"""
input_list = ["clk", "address1", "address2", "wr_en", "sel", "read_en","in1", "in2",]
output_list = [ "out1", "out2", "o_valid", "memory1", "wr_complete"]
    
@cocotb.test(stage = 1)
async def test_write(dut): 
        
    def test(input, output):
        wr_address1, wr_address2 = input["address1"], input["address2"]
        wr_data1, wr_data2 = input["in1"], input["in2"]


        memory = copy(output["memory1"])
        memory.reverse() # TO MAKE INDEXING NATURAL ((N downto 0) => (0 upto N))
        memory_data1 = memory[wr_address1]
        memory_data2 = memory[wr_address2]

        # print(f"data1 -> Expected: {wr_data1} |||| Actual: {memory_data1}\n")
        # print(f"data2 -> Expected: {wr_data2} |||| Actual: {memory_data2}\n")
        
        assert wr_data1.value == memory_data1.value
        assert wr_data2.value == memory_data2.value

    tester = coco_helpers.ModuleTester(dut, input_list, output_list)
    tester.test = test
    tester.make_input_valid_monitor("wr_en")
    tester.make_output_valid_monitor("wr_complete")
    tester.clock = Clock(dut.clk, 10, units="ns")
    tester.start_clock()
    tester.start()
    # tester.start_driver()
            
    for address1 in range(32):
        for address2 in range(32):

            # Can't write to the same memory addresses at the same time
            await RisingEdge(tester.dut.clk)
            if address1 == address2:
                tester.dut.wr_en.value=0
                continue

            data1, data2 = random.randint(0, 2**15), random.randint(0, 2**15)

            tester.dut.address1.value = address1
            tester.dut.address2.value = address2
            tester.dut.wr_en.value=1
            tester.dut.sel.value=1
            tester.dut.in1.value = data1
            tester.dut.in2.value = data2

    await RisingEdge(dut.clk)



@cocotb.test(stage=2)
async def test_delayed_writes_and_reads(dut: SimHandleBase):

    d_range = (0, 2**32-1)
    write_data = [random.randint(*d_range)  for _ in range(32)]

    def test(input, output):
        a1 = input["address1"].integer
        a2 = input["address2"].integer

        o_data1 = output["out1"].integer
        o_data2 = output["out2"].integer

        dut._log.info(f"{(a1, a2)}\n")
        dut._log.info(f"{(write_data[a1], o_data1)}")
        dut._log.info(f"{(write_data[a2], o_data2)}")
        assert write_data[a1] == o_data1
        assert write_data[a2] == o_data2

    tester = coco_helpers.ModuleTester(dut, input_list, output_list)
    tester.test = test
    tester.make_input_valid_monitor("read_en")
    tester.make_output_valid_monitor("o_valid")
    tester.clock = Clock(dut.clk, 10, units="ns")
    tester.start_clock()
    tester.start()

    ## write_data
    for a in range(16):
        await RisingEdge(tester.dut.clk)
        a_1 = a * 2
        a_2 = a_1 + 1
        data1 = write_data[a_1] 
        data2 = write_data[a_2]
        tester.dut.address1.value = a_1
        tester.dut.address2.value = a_2
        tester.dut.wr_en.value=1
        tester.dut.sel.value=1
        tester.dut.in1.value = data1
        tester.dut.in2.value = data2

    ## verify_reads_sequential
    for a in range(16):
        await RisingEdge(dut.clk)
        dut.read_en.value = 1
        dut.wr_en.value = 0
        dut.sel.value = 1
        dut.address1.value = a*2
        dut.address2.value = a*2+1

    




    






