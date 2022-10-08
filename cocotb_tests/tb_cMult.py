import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb.binary import BinaryValue
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
# from cocotb.

import coco_helpers

from typing import Dict, Any, List

"""
module cMult #(
    parameter N = 32,
    word_size = 16
) (
    input wire reset,
    input wire clk,
    input wire [word_size*2-1:0] A, 
    input wire [word_size*2-1:0] B,
    output reg [word_size*2-1:0] C, 
    output wire o_valid
);
wire [word_size-1: 0] Ar = A[word_size*2-1: word_size];
wire [word_size-1: 0] Ai = A[word_size-1: 0];
wire [word_size-1: 0] Br = B[word_size*2-1: word_size];
wire [word_size-1: 0] Bi = B[word_size-1: 0];
wire [word_size-1: 0] Cr, Ci;

// signal declaration
reg [2*N-1: 0] RR; // product of the two real components -> Ar * Br
reg [2*N-1: 0] II; // product of the two complex components -> Ai * Bi
reg [2*N-1: 0] RI; // product of Real1 with complex2 -> Ar * Br
reg [2*N-1: 0] IR; // complex1 * real2 -> Ai * Br

reg [2*N-1: 0] R_sum; // sum of real components -> RR + II
reg [2*N-1: 0] I_sum; // sum of complex components -> RI + IR
"""


inputs = ["reset", "i_valid", "clk", "A", "B"]
outputs = ["C", "o_valid"]
complexUtil = coco_helpers.ComplexNumUtil(16,16)

@cocotb.test(stage=0, skip=True)
async def test_unit_multiplication(dut):
    """
    Test multiplications where one operand is real unity
    and the other varies arbitrarily
    """

    tester = coco_helpers.ModuleTester(dut, inputs, outputs)

    tester.input_monitor =  coco_helpers.DataValidMonitor(
                                        tester.dut.clk, 
                                        tester.input_dict, 
                                        tester.input_dict["i_valid"])

    tester.output_monitor = coco_helpers.DataValidMonitor(
                                        tester.dut.clk,
                                        tester.output_dict,
                                        tester.output_dict["o_valid"]
                                        )

    def test(input, output):
        A = input["A"]
        A = complexUtil.decode(A)
        B = input["B"]
        B = complexUtil.decode(B)
        product = complex(*A) * complex(*B)
        expected_real = int(product.real) >> 15
        expected_im = int(product.imag) >> 15
        expected = complex(expected_real, expected_im)
        # expected = complex(*B)
        
        C = output["C"]
        C = complexUtil.decode(C)
        actual = complex(*C)

        # print(actual, expected)
        diff = abs(abs(expected) - abs(actual))
        assert diff <=2, f"{A} * {B} should be {expected}, not {actual}"

    tester.test = test
    """RESET AND SETUP"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await FallingEdge(dut.clk)
    dut.reset.value = 1
    await FallingEdge(dut.clk)
    dut.reset.value = 0
    tester.start()

    for _ in range(10000):
        await FallingEdge(dut.clk)
        dut.i_valid.value = 1
        dut.A.value = complexUtil.create_from(1,0)
        dut.B.value = complexUtil.create_random()
    
    for _ in range(10000):
        await FallingEdge(dut.clk)
        dut.i_valid.value = 0
        dut.A.value = complexUtil.create_random()
        dut.B.value = complexUtil.create_from(1,0)


@cocotb.test(stage=1, skip=True)
async def test_zero_multiplication(dut):
    """
    Test multiplications where one operand is real unity
    and the other varies arbitrarily
    """

    tester = coco_helpers.ModuleTester(dut, inputs, outputs)

    tester.input_monitor =  coco_helpers.DataValidMonitor(
                                        tester.dut.clk, 
                                        tester.input_dict, 
                                        tester.input_dict["i_valid"])

    tester.output_monitor = coco_helpers.DataValidMonitor(
                                        tester.dut.clk,
                                        tester.output_dict,
                                        tester.output_dict["o_valid"]
                                        ) 

    
    def test(input, output):
        A = input["A"]
        A = complexUtil.decode(A)
        B = input["B"]
        B = complexUtil.decode(B)
        # product = complex(*A) * complex(*B)
        # expected_real = int(product.real) >> 16
        # expected_im = int(product.imag) >> 16
        expected = complex(0,0)
        
        C = output["C"]
        C = complexUtil.decode(C)
        actual = complex(*C)

        # print(actual, expected)
        diff = abs(abs(expected) - abs(actual))
        assert diff<=2, f"{A} * {B} should be {expected}, not {actual}"

    """RESET AND SETUP"""
    tester.test = test
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await FallingEdge(dut.clk)
    dut.reset.value = 1
    await FallingEdge(dut.clk)
    dut.reset.value = 0
    tester.start()


    for _ in range(10000):
        await FallingEdge(dut.clk)
        dut.i_valid.value = 1
        dut.A.value = complexUtil.create_from(0,0)
        dut.B.value = complexUtil.create_random()

    for _ in range(10000):
        await FallingEdge(dut.clk)
        dut.i_valid.value = 0
        dut.A.value = complexUtil.create_random()
        dut.B.value = complexUtil.create_from(0,0)



@cocotb.test(stage=2)
async def test_random_multiplication_arguments(dut):
    """
    Test multiplications where one operand is real unity
    and the other varies arbitrarily
    """

    tester = coco_helpers.ModuleTester(dut, inputs, outputs)

    tester.input_monitor =  coco_helpers.DataValidMonitor(
                                        tester.dut.clk, 
                                        tester.input_dict, 
                                        tester.input_dict["i_valid"])

    tester.output_monitor = coco_helpers.DataValidMonitor(
                                        tester.dut.clk,
                                        tester.output_dict,
                                        tester.output_dict["o_valid"]
                                        ) 

    
    def test(input, output):
        A = input["A"]
        A = complexUtil.decode(A)
        B = input["B"]
        B = complexUtil.decode(B)
        product = complex(*A) * complex(*B)
        expected_real = int(product.real) >> 15
        expected_im = int(product.imag) >> 15
        expected = complex(expected_real,expected_im)
        
        expected = coco_helpers.Models.cMultModel(input["A"], input["B"])

        C = output["C"]
        C = complexUtil.decode(C)
        actual = complex(*C)

        diff = abs(abs(expected) - abs(actual))
        assert diff <= 2, f"{A} * {B} should be {expected}, not {actual}"

    """RESET AND SETUP"""
    tester.test = test
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await FallingEdge(dut.clk)
    dut.reset.value = 1
    await FallingEdge(dut.clk)
    dut.reset.value = 0
    tester.start()


    for _ in range(100000):
        await FallingEdge(dut.clk)
        dut.i_valid.value = 1
        dut.A.value = complexUtil.create_random(15)
        dut.B.value = complexUtil.create_random(15)



    
