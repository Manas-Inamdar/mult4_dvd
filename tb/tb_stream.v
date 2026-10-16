`timescale 1ns/1ps
module tb_stream;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst_n = 1;
    reg [3:0] a = 0, b = 0;
    wire [7:0] p;
    reg [7:0] previous = 0;
    integer i;
    mult_array dut (.clk(clk), .rst_n(rst_n), .a(a), .b(b), .p(p));
    initial begin
        rst_n = 0;
        #2;
        if (p !== 0) $fatal(1, "Initial async reset failed");
        repeat (2) @(negedge clk);
        rst_n = 1;
        for (i = 0; i < 256; i = i + 1) begin
            @(negedge clk);
            a = i / 16;
            b = i % 16;
            @(posedge clk);
            #2;
            if (p !== previous)
                $fatal(1, "Pipeline mismatch: vector=%0d expected=%0d got=%0d", i, previous, p);
            previous = a * b;
        end
        @(negedge clk);
        a = 0; b = 0;
        @(posedge clk);
        #2;
        if (p !== previous) $fatal(1, "Pipeline drain failed");
        // Assert between clock edges while the output is nonzero.
        #1 rst_n = 0;
        #2;
        if (p !== 0) $fatal(1, "Mid-stream asynchronous reset failed");
        @(negedge clk);
        rst_n = 1;
        a = 7; b = 9;
        @(posedge clk);
        #2;
        if (p !== 0) $fatal(1, "Output changed before second capture edge");
        @(posedge clk);
        #2;
        if (p !== 63) $fatal(1, "Post-reset 7x9 failed");
        $display("PASS: 256 streaming vectors, pipeline drain, asynchronous reset, and two-edge 7x9 latency");
        $finish;
    end
endmodule
