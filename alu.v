module alu8 (
    input  [7:0] A,
    input  [7:0] B,
    input  [3:0] sel,
    output [7:0] Result,
    output       Cout,
    output       Zero,
    output       Overflow 
  );

    wire [8:0] add_ext = {1'b0, A} + {1'b0, B};
    wire [8:0] sub_ext = {1'b0, A} - {1'b0, B};
    wire [15:0] mul_ext = A * B;

    assign Result =
        (sel == 4'b0000) ? add_ext[7:0] :
        (sel == 4'b0001) ? sub_ext[7:0] :
        (sel == 4'b0010) ? (A & B) :
        (sel == 4'b0011) ? (A | B):
        (sel == 4'b0100) ? (A ^ B):
        (sel == 4'b0101) ? ~(A | B):
        (sel == 4'b0110) ? ~(A & B):
        (sel == 4'b0111) ? ~(A ^ B):
        (sel == 4'b1000) ? ~A:
        (sel == 4'b1001) ? (A << 1):
        (sel == 4'b1010) ? (A >> 1):
        (sel == 4'b1011) ? {A[6:0], A[7]}:
        (sel == 4'b1100) ? {A[0], A[7:1]}:
        (sel == 4'b1101) ? mul_ext[7:0]:
        (sel == 4'b1110) ? {7'b0, (A > B)}:
        (sel == 4'b1111) ? {7'b0, (A == B)}:
        8'b0;

    assign Cout = (sel == 4'b0000) ? add_ext[8] :
                  (sel == 4'b0001) ? sub_ext[8] :
                  1'b0;

    assign Zero = (Result == 8'b0) ? 1'b1 : 1'b0;

    assign Overflow =
        (sel == 4'b0000) ? ((A[7] == B[7]) && (Result[7] != A[7])) :
        (sel == 4'b0001) ? ((A[7] != B[7]) && (Result[7] != A[7])) :
        1'b0;

endmodule
