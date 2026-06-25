`timescale 1ns/1ps
 
module alu8_tb;
 
    reg  [7:0] A, B;
    reg  [3:0] sel;
    wire [7:0] Result;
    wire       Cout, Zero, Overflow;
 
    alu8 uut (
        .A(A),
        .B(B),
        .sel(sel),
        .Result(Result),
        .Cout(Cout),
        .Zero(Zero),
        .Overflow(Overflow)
    );
 
    task show;
        input [127:0] opname; // string label
        begin
            $display("%-6s A=%3d(0x%02h) B=%3d(0x%02h) sel=%b -> Result=%3d(0x%02h) Cout=%b Zero=%b Ovf=%b",
                       opname, A, A, B, B, sel, Result, Result, Cout, Zero, Overflow);
        end
    endtask
 
    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu8_tb);
        $display("================ 8-bit ALU Testbench ================");
 
        A = 8'd45;  B = 8'd15;
 
        sel = 4'b0000; #10; show("ADD");
        sel = 4'b0001; #10; show("SUB");
        sel = 4'b0010; #10; show("AND");
        sel = 4'b0011; #10; show("OR");
        sel = 4'b0100; #10; show("XOR");
        sel = 4'b0101; #10; show("NOR");
        sel = 4'b0110; #10; show("NAND");
        sel = 4'b0111; #10; show("XNOR");
        sel = 4'b1000; #10; show("NOT");
        sel = 4'b1001; #10; show("SLL");
        sel = 4'b1010; #10; show("SRL");
        sel = 4'b1011; #10; show("ROL");
        sel = 4'b1100; #10; show("ROR");
        sel = 4'b1101; #10; show("MUL");
        sel = 4'b1110; #10; show("GT");
        sel = 4'b1111; #10; show("EQ");
 
        $display("-------------------------------------------------------");
        // Edge case: ADD with carry out
        A = 8'hFF; B = 8'h01; sel = 4'b0000; #10; show("ADD");
 
        // Edge case: SUB causing borrow (A < B)
        A = 8'd10; B = 8'd20; sel = 4'b0001; #10; show("SUB");
 
        // Edge case: Zero flag
        A = 8'd0; B = 8'd0; sel = 4'b0011; #10; show("OR(Z)");
 
        // Edge case: signed overflow on ADD (127 + 1 -> -128 in signed)
        A = 8'd127; B = 8'd1; sel = 4'b0000; #10; show("ADD(OVF)");
 
        // Edge case: signed overflow on SUB (-128 - 1 -> overflow)
        A = 8'h80; B = 8'h01; sel = 4'b0001; #10; show("SUB(OVF)");
 
        // Equality check
        A = 8'd99; B = 8'd99; sel = 4'b1111; #10; show("EQ(1)");
 
        $display("========================================================");
        $finish;
    end
 
endmodule
