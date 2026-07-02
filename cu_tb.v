`timescale 1ns/1ps

module cu_tb;

    reg         clk;
    reg         reset;
    reg  [31:0] INSTRUCTION;

    wire [2:0]  READREG1;
    wire [2:0]  READREG2;
    wire [2:0]  WRITEREG;
    wire        WRITEENABLE;
    wire [7:0]  IMMEDIATE;
    wire [2:0]  ALUOP;
    wire        MUX1_SEL;
    wire        MUX2_SEL;
    wire [31:0] PC;

    // Instantiate Control Unit
    cu uut (
        .clk(clk),
        .reset(reset),
        .INSTRUCTION(INSTRUCTION),
        .READREG1(READREG1),
        .READREG2(READREG2),
        .WRITEREG(WRITEREG),
        .WRITEENABLE(WRITEENABLE),
        .IMMEDIATE(IMMEDIATE),
        .ALUOP(ALUOP),
        .MUX1_SEL(MUX1_SEL),
        .MUX2_SEL(MUX2_SEL),
        .PC(PC)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    // Display task
    task show;
        input [127:0] label;
        begin
            $display("%-12s | PC=%0d | ALUOP=%b MUX2=%b MUX1=%b WE=%b | WREG=%0d RREG1=%0d RREG2=%0d | IMM=%0d(0x%02h)",
                     label, PC, ALUOP, MUX2_SEL, MUX1_SEL, WRITEENABLE,
                     WRITEREG, READREG1, READREG2, IMMEDIATE, IMMEDIATE);
        end
    endtask

    // ---------------------------------------------------------------
    // Instruction builder (helper)
    //   imm[7:0], aluop[2:0], mux2, mux1, we, wreg[2:0],
    //   rreg1[2:0], rreg2[2:0], reserved[8:0]
    // ---------------------------------------------------------------
    function [31:0] build_instr;
        input [7:0]  imm;
        input [2:0]  aluop;
        input        mux2;
        input        mux1;
        input        we;
        input [2:0]  wreg;
        input [2:0]  rreg1;
        input [2:0]  rreg2;
        begin
            build_instr = {imm, aluop, mux2, mux1, we, wreg, rreg1, rreg2, 9'b0};
        end
    endfunction

    initial begin
        $dumpfile("cu.vcd");
        $dumpvars(0, cu_tb);
        $display("================== Control Unit Testbench ==================");
        $display("LABEL        | PC   | ALUOP MUX2 MUX1 WE  | WREG RREG1 RREG2 | IMM");
        $display("-------------------------------------------------------------");

        clk = 0;
        reset = 1;
        INSTRUCTION = 32'd0;

        // ---- Reset ----
        #10;
        show("RESET");

        reset = 0;

        // ---- Test 1: ADD R1, R2, R3  (R1 = R2 + R3) ----
        //   imm=0, aluop=000(ADD), mux2=0, mux1=0, we=1,
        //   wreg=1, rreg1=2, rreg2=3
        INSTRUCTION = build_instr(8'd0, 3'b000, 1'b0, 1'b0, 1'b1, 3'd1, 3'd2, 3'd3);
        @(posedge clk); #1;
        show("ADD R1,R2,R3");

        // ---- Test 2: SUB R4, R5, R6  (R4 = R5 - R6) ----
        //   aluop=001(SUB), mux1=1 (2's comp), we=1
        INSTRUCTION = build_instr(8'd0, 3'b001, 1'b0, 1'b1, 1'b1, 3'd4, 3'd5, 3'd6);
        @(posedge clk); #1;
        show("SUB R4,R5,R6");

        // ---- Test 3: AND R0, R1, R2 ----
        //   aluop=010(AND), we=1
        INSTRUCTION = build_instr(8'd0, 3'b010, 1'b0, 1'b0, 1'b1, 3'd0, 3'd1, 3'd2);
        @(posedge clk); #1;
        show("AND R0,R1,R2");

        // ---- Test 4: ADDI R7, R0, #42  (R7 = R0 + 42) ----
        //   imm=42, aluop=000(ADD), mux2=1 (use immediate), we=1
        INSTRUCTION = build_instr(8'd42, 3'b000, 1'b1, 1'b0, 1'b1, 3'd7, 3'd0, 3'd0);
        @(posedge clk); #1;
        show("ADDI R7,R0,42");

        // ---- Test 5: OR R3, R4, R5 ----
        //   aluop=011(OR), we=1
        INSTRUCTION = build_instr(8'd0, 3'b011, 1'b0, 1'b0, 1'b1, 3'd3, 3'd4, 3'd5);
        @(posedge clk); #1;
        show("OR R3,R4,R5");

        // ---- Test 6: XOR R2, R6, R7 ----
        //   aluop=100(XOR), we=1
        INSTRUCTION = build_instr(8'd0, 3'b100, 1'b0, 1'b0, 1'b1, 3'd2, 3'd6, 3'd7);
        @(posedge clk); #1;
        show("XOR R2,R6,R7");

        // ---- Test 7: NOP (no write, all zero) ----
        INSTRUCTION = build_instr(8'd0, 3'b000, 1'b0, 1'b0, 1'b0, 3'd0, 3'd0, 3'd0);
        @(posedge clk); #1;
        show("NOP");

        // ---- Test 8: LOAD IMMEDIATE R5 = 255 ----
        //   imm=255, aluop=000(ADD), mux2=1, we=1, rreg1=0 (R0=0 base)
        INSTRUCTION = build_instr(8'd255, 3'b000, 1'b1, 1'b0, 1'b1, 3'd5, 3'd0, 3'd0);
        @(posedge clk); #1;
        show("LDI R5,255");

        // ---- Verify PC increments ----
        $display("-------------------------------------------------------------");
        $display("Final PC = %0d (expected: %0d after 8 clock edges)", PC, 8*4);

        $display("================== Testbench Complete ==================");
        $finish;
    end

endmodule
