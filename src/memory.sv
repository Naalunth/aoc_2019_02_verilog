`timescale 1us/1ns

module memory(
    data_out,
    address,
    data_in, 
    write_enable,
    clk
);
    parameter AddressSize = 8;
    parameter WordSize = 64;

    output logic [WordSize-1:0] data_out;
    input logic [WordSize-1:0] data_in;
    input logic [AddressSize-1:0] address;
    input logic write_enable;
    input logic clk;
    
    bit [WordSize-1:0] memory [1 << AddressSize];

    always @(negedge clk) begin
        if (write_enable) begin
            memory[address] <= data_in;
        end
        data_out <= memory[address];
    end

    bit [63:0] dump_mem_0;
    assign dump_mem_0 = memory[0];
    initial begin
        $dumpvars(0, dump_mem_0);
    end
endmodule
