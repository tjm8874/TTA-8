// LED フラッシャーのテスト: 1クロック = 1命令 = 1ms とみなす
`timescale 1ns/1ps
module tb_flasher;
    reg        clk = 0, reset = 1;
    reg  [1:0] btn = 0;
    wire [5:0] led;
    integer    t = 0;             // 命令の数 (= ミリ秒)

    tta8 cpu (.clk(clk), .reset(reset), .step(1'b1), .btn(btn), .led(led));

    always #5 clk = ~clk;
    always @(posedge clk) if (!reset) t <= t + 1;

    function [8*6-1:0] show(input [5:0] v);
        integer i;
        for (i = 0; i < 6; i = i + 1) show[8*i +: 8] = v[i] ? "O" : "_";
    endfunction

    reg [5:0] last = 6'h3f;
    always @(posedge clk) if (!reset && led !== last) begin
        $display("%6d ms  btn=%b  %s", t, btn, show(led));
        last <= led;
    end

    initial begin
        #20 reset = 0;
        repeat (2200) @(posedge clk);  btn = 2'b01;   // S1
        repeat (3600) @(posedge clk);  btn = 2'b10;   // S2
        repeat (2000) @(posedge clk);  btn = 2'b11;   // S1+S2
        repeat (2000) @(posedge clk);  btn = 2'b00;   // はなす
        repeat (1500) @(posedge clk);
        $finish;
    end
endmodule
