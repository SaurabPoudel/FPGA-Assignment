module cu (
    input         clk,
    input         reset,
    input  [31:0] INSTRUCTION,

    output [2:0]  READREG1,
    output [2:0]  READREG2,
    output [2:0]  WRITEREG,
    output        WRITEENABLE,

    output [7:0]  IMMEDIATE,


    output [2:0]  ALUOP,

    output        MUX1_SEL,   
    output        MUX2_SEL,   


    output reg [31:0] PC
);


    assign IMMEDIATE   = INSTRUCTION[31:24];
    assign ALUOP       = INSTRUCTION[23:21];
    assign MUX2_SEL    = INSTRUCTION[20];
    assign MUX1_SEL    = INSTRUCTION[19];
    assign WRITEENABLE = INSTRUCTION[18];
    assign WRITEREG    = INSTRUCTION[17:15];
    assign READREG1    = INSTRUCTION[14:12];
    assign READREG2    = INSTRUCTION[11:9];

 
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 32'd0;
        else
            PC <= PC + 32'd4;
    end

endmodule
