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
    wire [3:0] r0;
    wire [3:0] r1;
    wire [3:0] r2;
    wire [3:0] s1;
    wire [3:0] s2;
    wire [3:0] s3;
    wire [4:0] c1;
    wire [4:0] c2;
    wire [4:0] c3;
    wire [7:0] p_comb;

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

    assign r0 = {1'b0, pp0[3], pp0[2], pp0[1]};

    assign c1[0] = 1'b0;
    full_adder fa_row1_0 (pp1[0], r0[0], c1[0], s1[0], c1[1]);
    full_adder fa_row1_1 (pp1[1], r0[1], c1[1], s1[1], c1[2]);
    full_adder fa_row1_2 (pp1[2], r0[2], c1[2], s1[2], c1[3]);
    full_adder fa_row1_3 (pp1[3], r0[3], c1[3], s1[3], c1[4]);
    assign r1 = {c1[4], s1[3], s1[2], s1[1]};

    assign c2[0] = 1'b0;
    full_adder fa_row2_0 (pp2[0], r1[0], c2[0], s2[0], c2[1]);
    full_adder fa_row2_1 (pp2[1], r1[1], c2[1], s2[1], c2[2]);
    full_adder fa_row2_2 (pp2[2], r1[2], c2[2], s2[2], c2[3]);
    full_adder fa_row2_3 (pp2[3], r1[3], c2[3], s2[3], c2[4]);
    assign r2 = {c2[4], s2[3], s2[2], s2[1]};

    assign c3[0] = 1'b0;
    full_adder fa_row3_0 (pp3[0], r2[0], c3[0], s3[0], c3[1]);
    full_adder fa_row3_1 (pp3[1], r2[1], c3[1], s3[1], c3[2]);
    full_adder fa_row3_2 (pp3[2], r2[2], c3[2], s3[2], c3[3]);
    full_adder fa_row3_3 (pp3[3], r2[3], c3[3], s3[3], c3[4]);

    assign p_comb = {c3[4], s3[3], s3[2], s3[1], s3[0], s2[0], s1[0], pp0[0]};
    assign p = p_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            p_reg <= 8'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            p_reg <= p_comb;
        end
    end
endmodule
