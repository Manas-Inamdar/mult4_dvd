`timescale 1ns/1ps

module mult_array (
    input        clk,
    input        rst_n,
    input  [3:0] a,
    input  [3:0] b,
    output [7:0] p
);
    reg [3:0] a_reg;
    reg [3:0] b_reg;
    reg [7:0] p_reg;

    wire [3:0] pp0;
    wire [3:0] pp1;
    wire [3:0] pp2;
    wire [3:0] pp3;
    wire [3:0] row0;
    wire [3:0] row1;
    wire [3:0] row2;
    wire [3:0] sum1;
    wire [3:0] sum2;
    wire [3:0] sum3;
    wire [4:0] carry1;
    wire [4:0] carry2;
    wire [4:0] carry3;
    wire [7:0] product_comb;

    // Four rows of four partial products: 4 x 4 = 16 AND operations.
    assign pp0[0] = a_reg[0] & b_reg[0];
    assign pp0[1] = a_reg[1] & b_reg[0];
    assign pp0[2] = a_reg[2] & b_reg[0];
    assign pp0[3] = a_reg[3] & b_reg[0];
    assign pp1[0] = a_reg[0] & b_reg[1];
    assign pp1[1] = a_reg[1] & b_reg[1];
    assign pp1[2] = a_reg[2] & b_reg[1];
    assign pp1[3] = a_reg[3] & b_reg[1];
    assign pp2[0] = a_reg[0] & b_reg[2];
    assign pp2[1] = a_reg[1] & b_reg[2];
    assign pp2[2] = a_reg[2] & b_reg[2];
    assign pp2[3] = a_reg[3] & b_reg[2];
    assign pp3[0] = a_reg[0] & b_reg[3];
    assign pp3[1] = a_reg[1] & b_reg[3];
    assign pp3[2] = a_reg[2] & b_reg[3];
    assign pp3[3] = a_reg[3] & b_reg[3];

    // Align the first row before the three four-bit adder rows.
    assign row0 = {1'b0, pp0[3], pp0[2], pp0[1]};

    assign carry1[0] = 1'b0;
    full_adder fa_row1_0 (pp1[0], row0[0], carry1[0], sum1[0], carry1[1]);
    full_adder fa_row1_1 (pp1[1], row0[1], carry1[1], sum1[1], carry1[2]);
    full_adder fa_row1_2 (pp1[2], row0[2], carry1[2], sum1[2], carry1[3]);
    full_adder fa_row1_3 (pp1[3], row0[3], carry1[3], sum1[3], carry1[4]);
    assign row1 = {carry1[4], sum1[3], sum1[2], sum1[1]};

    assign carry2[0] = 1'b0;
    full_adder fa_row2_0 (pp2[0], row1[0], carry2[0], sum2[0], carry2[1]);
    full_adder fa_row2_1 (pp2[1], row1[1], carry2[1], sum2[1], carry2[2]);
    full_adder fa_row2_2 (pp2[2], row1[2], carry2[2], sum2[2], carry2[3]);
    full_adder fa_row2_3 (pp2[3], row1[3], carry2[3], sum2[3], carry2[4]);
    assign row2 = {carry2[4], sum2[3], sum2[2], sum2[1]};

    assign carry3[0] = 1'b0;
    full_adder fa_row3_0 (pp3[0], row2[0], carry3[0], sum3[0], carry3[1]);
    full_adder fa_row3_1 (pp3[1], row2[1], carry3[1], sum3[1], carry3[2]);
    full_adder fa_row3_2 (pp3[2], row2[2], carry3[2], sum3[2], carry3[3]);
    full_adder fa_row3_3 (pp3[3], row2[3], carry3[3], sum3[3], carry3[4]);

    assign product_comb = {
        carry3[4], sum3[3], sum3[2], sum3[1], sum3[0],
        sum2[0], sum1[0], pp0[0]
    };
    assign p = p_reg;

    // Inputs are captured first; the registered product follows one edge later.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            p_reg <= 8'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            p_reg <= product_comb;
        end
    end
endmodule
