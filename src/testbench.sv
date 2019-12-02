`include "src/intcode.sv"
`timescale 1us/1ns

module testbench;
    logic clk = 'b0;
    logic reset = 'b0;
    logic write_program = 'b0;
    logic run_program = 'b0;
    logic [64] data;
    logic halt;
 
    // Instantiate the Unit Under Test (UUT)
    intcode UUT(
        .clk(clk),
        .reset(reset),
        .write_program(write_program),
        .run_program(run_program),
        .data(data),
        .halt(halt)
    );
     
    always #20 clk <= !clk;
         
    initial begin
        $dumpvars(0,testbench);

        run_program <= 1'b1;
        
        while (!halt) begin
            #1000;
        end
        
        run_program <= 1'b0;
        #100

        $display("Result: %d", data);

        $finish();
    end
     
endmodule
