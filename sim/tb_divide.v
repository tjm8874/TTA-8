// 発展1の配布済みHEXを、実際のVerilog CPUで実行する。
`timescale 1ns/1ps
module tb_divide;
    reg clk = 0, reset = 1;
    wire [5:0] led;
    tta8 cpu (.clk(clk), .reset(reset), .step(1'b1), .btn(2'b00), .led(led));
    always #5 clk = ~clk;
    initial begin
        #1;
        $readmemh("../programs/basic/divide.hex", cpu.rom);
        #19; reset = 0;
        repeat (10000) @(negedge clk);
        #1;
        if (cpu.ram[16] !== 3 || cpu.ram[17] !== 2 || cpu.ram[4] !== 0 || led !== 3)
            $fatal(1, "Division lesson failed: Q=%0d R=%0d E=%0d LED=%0d",
                   cpu.ram[16], cpu.ram[17], cpu.ram[4], led);
        $display("PASS: Verilog division lesson 17 / 5 = 3 remainder 2");
        $finish;
    end
endmodule
