`include "src/memory.sv"
`timescale 1us/1ns

module intcode(
    input logic clk,
    input logic reset,
    input logic write_program,
    input logic run_program,
    inout logic [63:0] data,
    output logic halt
);
    bit memory_write_enable;
    bit [63:0] memory_write;
    bit [63:0] memory_read;
    bit [7:0] memory_address;
    memory #(.AddressSize(8), .WordSize(64)) mem(
        .clk(clk),
        .write_enable(memory_write_enable),
        .data_in(memory_write),
        .data_out(memory_read),
        .address(memory_address)
    );
    initial $readmemh("input/input.hex", mem.memory);

    // register b00: arithmetic accumulator
    // register b01: general purpose
    // register b10: general purpose
    // register b11: instruction pointer
    bit [63:0] registers [4];

    bit [7:0] micro_instruction_pointer = '0;
    bit [7:0] micro_code [256];
    initial $readmemb("src/micro_code.bin", micro_code, 0, 255);

    enum logic [2:0] {
        RUNNING = 0,
        MEM_READ = 1,
        MEM_WRITE = 2,
        MEM_LOAD_INSTRUCTION = 3,
        HALT = 4
    } state = RUNNING;
    bit [1:0] mem_read_target;
    bit [63:0] data_output;

    integer i;

    always @ (posedge clk) begin
        bit [7:0] instruction;
        bit [1:0] target_register;
        bit [3:0] immediate_number;
        bit [1:0] operand_0;
        bit [1:0] operand_1;

        if (reset) begin
            for (i=0; i<4; i=i+1) registers[i] <= '0;
        end else if (run_program) begin
            case (state)
                RUNNING: begin
                    memory_write_enable <= 'b0;
                    $display("-------------\nInstruction %b", micro_code[micro_instruction_pointer]);
                    micro_instruction_pointer <= micro_instruction_pointer + 1;
                    instruction = micro_code[micro_instruction_pointer];
                    if (instruction[7]) begin
                        case(instruction[6:4])
                            'b000: begin
                                $display("add instruction");
                                registers[0] <= registers[0] + maths_operand(instruction[3:0]);
                            end
                            'b001: begin
                                $display("mul instruction");
                                registers[0] <= registers[0] * maths_operand(instruction[3:0]);
                            end
                            default: $display("Unknown maths instruction");
                        endcase
                    end else if (instruction[6]) begin
                        $display("load immediate instruction");
                        registers[instruction[5:4]] <= {60'b0, instruction[3:0]};
                    end else begin
                        case (instruction[5:4])
                            'b00: begin
                                $display("mv r%d <- r%d", instruction[3:2], instruction[1:0]);
                                registers[instruction[3:2]] <= registers[instruction[1:0]];
                            end
                            'b01: begin
                                $display("ld r%d <- %%r%d (*%d)", instruction[3:2], instruction[1:0], registers[instruction[1:0]]);
                                memory_address <= registers[instruction[1:0]];
                                mem_read_target <= instruction[3:2];
                                state <= MEM_READ;
                            end
                            'b10: begin
                                $display("st %%r%d (*%d) <- r%d (%d)",
                                    instruction[3:2],
                                    registers[instruction[3:2]],
                                    instruction[1:0],
                                    registers[instruction[1:0]]
                                );
                                memory_address <= registers[instruction[3:2]];
                                memory_write <= registers[instruction[1:0]];
                                state <= MEM_WRITE;
                            end
                            'b11: begin
                                case (instruction[3:2])
                                    'b11: begin
                                        case (instruction[1:0])
                                            'b10: begin
                                                $display("next");
                                                memory_address <= registers[3];
                                                state <= MEM_LOAD_INSTRUCTION;
                                            end
                                            'b11: begin
                                                $display("halt");
                                                state <= HALT;
                                                data_output <= registers[0];
                                            end
                                        endcase
                                    end
                                endcase
                            end
                        endcase
                    end
                end
                MEM_READ: begin
                    $display("memory read: %d -> r%d", memory_read, mem_read_target);
                    registers[mem_read_target] <= memory_read;
                    state <= RUNNING;
                end
                MEM_WRITE: begin
                    $display("writing memory");
                    memory_write_enable <= 'b1;
                    state <= RUNNING;
                end
                MEM_LOAD_INSTRUCTION: begin
                    $display("loading instruction");
                    case (memory_read)
                        1: begin
                            $display("\n\nExecuting 1: Add");
                            micro_instruction_pointer <= 1;
                        end
                        2: begin
                            $display("\n\nExecuting 2: Multiply");
                            micro_instruction_pointer <= 17;
                        end
                        99: begin
                            $display("\n\nExecuting 99: Halt");
                            micro_instruction_pointer <= 33;
                        end
                    endcase
                    state <= RUNNING;
                end
            endcase
        end
    end

    function [63:0] maths_operand;
        input [3:0] operand;
        if (operand[3] == 'b0) begin
            $display("maths operand immediate %d", operand[2:0]);
            maths_operand = {61'b0, operand[2:0]};
        end else begin
            $display("maths operand register %d", operand[1:0]);
            maths_operand = registers[operand[1:0]];
        end
    endfunction

    assign halt = state == HALT;
    assign data = state == HALT ? data_output : 'z;

    bit [63:0] dump_register_0;
    assign dump_register_0 = registers[0];
    initial begin
        $dumpvars(0, dump_register_0);
    end
    bit [63:0] dump_register_1;
    assign dump_register_1 = registers[1];
    initial begin
        $dumpvars(0, dump_register_1);
    end
    bit [63:0] dump_register_2;
    assign dump_register_2 = registers[2];
    initial begin
        $dumpvars(0, dump_register_2);
    end
    bit [63:0] dump_register_3;
    assign dump_register_3 = registers[3];
    initial begin
        $dumpvars(0, dump_register_3);
    end

endmodule // intcode
