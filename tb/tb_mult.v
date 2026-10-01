`timescale 1ns/1ps

module tb_mult;
    reg clk;
    reg rst_n;
    reg [3:0] a;
    reg [3:0] b;
    wire [7:0] p;

    integer ai;
    integer bi;
    integer vectors_checked;
    integer errors;
    reg [7:0] expected;

    mult_array dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .p(p)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);

        rst_n = 1'b0;
        a = 4'b0;
        b = 4'b0;
        vectors_checked = 0;
        errors = 0;

        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        for (ai = 0; ai < 16; ai = ai + 1) begin
            for (bi = 0; bi < 16; bi = bi + 1) begin
                a = ai;
                b = bi;
                expected = ai * bi;
                @(posedge clk);
                @(posedge clk);
                #1;
                vectors_checked = vectors_checked + 1;
                if (p !== expected) begin
                    $display("MISMATCH: a=%0d b=%0d expected=%0d actual=%0d", ai, bi, expected, p);
                    errors = errors + 1;
                end
            end
        end

        if (errors == 0) begin
            $display("PASS: %0d vectors checked, %0d errors", vectors_checked, errors);
        end else begin
            $display("FAIL: %0d vectors checked, %0d errors", vectors_checked, errors);
        end
        $finish;
    end
endmodule
