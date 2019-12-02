#!/bin/sh
if ! [ -d out ]; then
    mkdir out
fi
iverilog -g2005-sv -Wall src/testbench.sv -o out/intcode
