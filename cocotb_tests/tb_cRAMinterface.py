import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb.binary import BinaryValue
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue

# from cocotb.
from copy import copy
import random
import coco_helpers

""" Module Definition

module interfaceRAM #(
    parameter N = 32,
    word_size = 16,
    address_width = $clog2(N)
) (
    input wire clk, reset, 
    input wire bank_select, wr_en,

    input wire [$clog2(N)-1: 0] wr_address1, wr_address2,
    input wire [$clog2(N)-1: 0] rd_address1, rd_address2, 

    input wire [2*word_size-1:0] comp1, comp2, //Computations to write
    output reg [2*word_size-1:0] samp1, samp2, //"samples" to read
    output reg o_valid, wr_complete
);

    localparam log2N = $clog2(N);

    reg b0_wr_en, b1_wr_en; 
    reg b0_select, b1_select;
    reg [address_width-1: 0] b0_address1, b0_address2, b1_address1, b1_address2; 
    wire [word_size*2-1: 0] b0_sample1, b0_sample2;
    wire [word_size*2-1: 0] b1_sample1, b1_sample2; 
    wire [word_size*2-1: 0] b0_comp1, b1_comp1;
    wire o_b0_valid, o_b1_valid;
    reg b0_read_en, b1_read_en; 


"""

input_list = ["clk", "reset", "bank_select", "wr_en",
        "wr_address1", "wr_address2",
        "rd_address1", "rd_address2",
        "comp1", "comp2"]

output_list = ["o_valid", "wr_complete", "samp1", "samp2"] #, "cRAM0", "cRAM1"

@cocotb.test()
async def check(dut):
    
    def test(input, output):

        if input["bank_select"].value == 0: 
            memory = dut.cRAM0
        elif input["bank_select"].value == 1:
            memory = dut.cRAM1

        memory = memory.memory1
        memory = list(memory)
        # print(memory)
        memory = copy(memory)
        memory.reverse()
        memory = [a.value for a in memory]
        #reverse for natural memory access, copy because of immutability concerns

        address1 = input["wr_address1"]
        address2 = input["wr_address2"]

        data1 = input["comp1"]
        data2 = input["comp2"]

        # print(memory)
        assert memory[address1] == data1
        assert memory[address2] == data2

    
    tester = coco_helpers.ModuleTester(dut, input_list, output_list)
    tester.test = test
    tester.make_input_valid_monitor("wr_en")
    tester.make_output_valid_monitor("wr_complete")
    tester.clock = Clock(dut.clk, 10, units="ns")
    tester.start_clock()
    await tester.reset_dut()
    tester.start()

    for bank in (0,1):
        for address1 in range(32):
            for address2 in range(32): 

                await RisingEdge(tester.dut.clk)
                if address1 == address2: 
                    tester.dut.wr_en.value = 0
                    continue

                data1, data2 = random.randint(0, 2**15), random.randint(0, 2**15)

                tester.dut.wr_address1.value = address1
                tester.dut.wr_address2.value = address2
                tester.dut.wr_en.value = 1
                tester.dut.comp1.value = data1
                tester.dut.comp2.value = data2
                tester.dut.bank_select.value = bank
                tester.dut.reset.value = 0





