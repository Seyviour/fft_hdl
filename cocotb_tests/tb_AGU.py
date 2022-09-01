import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb.binary import BinaryValue, BinaryRepresentation
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue


import random
import coco_helpers

"""Module Definition

module AGU #(
    parameter N = 32,
    stage_width = $clog2($clog2(N)),
    pair_id_width = $clog2(N/2),
    address_width = $clog2(N)
) (
    input wire clk, reset,
    input wire i_valid, 
    input wire [stage_width-1: 0] stage,
    input wire [pair_id_width - 1: 0] pair_id, 
    output reg [address_width -1 : 0] address1, address2, 
    output reg [address_width -1: 0] twiddle_address,
    output reg o_valid
);

"""

@cocotb.test()
async def test_butterfly_operation(dut):

    input_list = ["i_valid", "reset", "stage", "pair_id"]
    output_list = ["o_valid", "address1", "address2", "twiddle_address", "o_valid"]

    tester = coco_helpers.ModuleTester(dut, input_list, output_list)

    tester.output_monitor = coco_helpers.DataValidMonitor(
        dut.clk,
        tester.output_dict,
        tester.output_dict["o_valid"]
    )

    tester.input_monitor = coco_helpers.DataValidMonitor(
        dut.clk,
        tester.input_dict,
        tester.input_dict["i_valid"]
    )

    def test(input, output):
        stage, pair_id = input["stage"], input["pair_id"]

        e_address1, e_address2, e_tw_address = coco_helpers.Models.model_AGU(stage, pair_id)
        a_address1, a_address2, a_tw_address = output["address1"], output["address2"], output["twiddle_address"]

        assert e_address1 == a_address1, "address1 should be {e_address1}, not {a_address1}"
        assert e_address2 == a_address2, "address1 should be {e_address2}, not {a_address2}"
        assert e_tw_address == a_tw_address, "twiddle_address should be {e_tw_address}, not {a_tw_address}"

    tester.test = test

    dut._log.info("Initialize and Reset")
    tester.start_clock()
    tester.reset_dut()


    # async def dut_driver():
    for stage in range(5):
        for pair_id in range(16):
            await RisingEdge(dut.clk)
            dut.stage.value = stage
            dut.pair_id.value = pair_id
            dut.i_valid.value = 1




