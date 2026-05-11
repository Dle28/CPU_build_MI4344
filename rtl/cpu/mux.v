`timescale 1ns/1ps

// Generic 2:1 mux.
module mux2 #(
    parameter WIDTH = 16
) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              sel,
    output [WIDTH-1:0] y
);

    assign y = sel ? b : a;

endmodule

// Generic 3:1 mux used by forwarding paths.
module mux3 #(
    parameter WIDTH = 16
) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [WIDTH-1:0] c,
    input  [1:0]       sel,
    output reg [WIDTH-1:0] y
);

    always @(*) begin
        case (sel)
            2'b00: y = a;
            2'b01: y = b;
            2'b10: y = c;
            default: y = a;
        endcase
    end

endmodule
