#!/bin/sh
mkdir out
iverilog -g2005-sv -Wall -Isrc src/testbench.sv -o "out/intcode"
