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
    


@cocotb.test()
async def test_butterfly_operation(dut):

    complexUtil = coco_helpers.ComplexNumUtil(16, 16)

    input_list = ["clk", "reset", "i_valid", "address1", "address2",
                "twiddle", "sample1", "sample2"]
    
    output_list = ["comp1", "comp2", "d_valid", "wr_address1", "wr_address2"]

    tester = coco_helpers.ModuleTester(dut, input_list, output_list)

    tester.input_monitor = coco_helpers.DataValidMonitor(dut.clk,
                                                    tester.input_dict,
                                                    tester.input_dict["i_valid"]
                                                    )

    tester.output_monitor = coco_helpers.DataValidMonitor(
        dut.clk,
        tester.output_dict,
        tester.output_dict["d_valid"]
    )

    def test(input, output):
        twiddle = input["twiddle"]
        sample1 = input["sample1"]
        sample2 = input["sample2"]


        e_comp1, e_comp2 = coco_helpers.Models.BPUModel(twiddle, sample1, sample2)
        a_comp1 = complexUtil.decode_complex(output["comp1"])
        a_comp2 = complexUtil.decode_complex(output["comp2"])

        print(e_comp1, a_comp1)

        assert a_comp1 == e_comp1, "comp1 should be {e_comp1} not {a_comp2}"
        assert a_comp2 == e_comp2, "comp2 should be {e_comp2} not {a_comp2}"
        assert input["address1"] == output["wr_address1"]
        assert input["address2"] == output["wr_address2"]

    tester.test = test

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut._log.info("Initialize and Reset")

    await FallingEdge(dut.clk)
    dut.reset.value = 1
    await FallingEdge(dut.clk)
    dut.reset.value = 0
    tester.start()


    sample_range = (-2**13, 2 ** 13)
    for _ in range(100):
        await RisingEdge(dut.clk)
        dut.address1.value = random.randint(0, 16)
        dut.address2.value = random.randint(0, 16)

        re_s1, im_s1 = random.randint(*sample_range), random.randint(*sample_range)
        dut.sample1.value = complexUtil.create_from(re_s1, im_s1)
        dut.sample2.value = complexUtil.create_random()
        dut.twiddle.value = complexUtil.create_from(1,0)
        dut.i_valid.value = 1






    

    




