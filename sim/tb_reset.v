// hdl で実行: iverilog -g2012 -s tb_reset -o build/reset ../sim/tb_reset.v tta8.v
//             vvp build/reset
`timescale 1ns/1ps
module tb_reset;
    reg clk = 0, reset = 1, step = 0;
    wire [5:0] led;
    integer i;
    tta8 cpu (.clk(clk), .reset(reset), .step(step), .btn(2'b00), .led(led));
    always #5 clk = ~clk;

    task tick(input enable);
        begin
            @(negedge clk); step = enable;
            @(posedge clk); #1;
        end
    endtask

    task check_zero;
        begin
            if (cpu.pc !== 0 || cpu.v !== 0 || cpu.alu_a !== 0 ||
                cpu.alu_b !== 0 || led !== 0) $fatal(1, "CPU reset failed");
            for (i = 0; i < 32; i = i + 1)
                if (cpu.ram[i] !== 0) $fatal(1, "RAM[%0d] was not reset", i);
        end
    endtask

    initial begin
        #1; // $readmemh のあとで、このテスト用プログラムを置く
        for (i = 0; i < 32; i = i + 1) begin
            cpu.rom[3*i] = 8'h12;       // READ IMM, i+1
            cpu.rom[3*i+1] = i+1;
            cpu.rom[3*i+2] = 8'ha0+i;   // WRITE RAM[i]
        end
        cpu.rom[96] = 8'h80; // WRITE ALU_A
        cpu.rom[97] = 8'h81; // WRITE ALU_B
        cpu.rom[98] = 8'hff; // WRITE OUT
        tick(0); check_zero; // step=0 でもリセットが効く
        reset = 0;
        repeat (67) tick(1); // RAMへ2命令ずつ×32個、そのあとWRITEを3命令
        for (i = 0; i < 32; i = i + 1)
            if (cpu.ram[i] !== i+1) $fatal(1, "RAM write failed: index=%0d got=%0d expected=%0d pc=%0d", i,cpu.ram[i],i+1,cpu.pc);
        if (cpu.alu_a !== 32 || cpu.alu_b !== 32 || led !== 32)
            $fatal(1, "Setup instructions failed");
        tick(0);
        if (cpu.pc !== 99 || cpu.ram[31] !== 32) $fatal(1, "step hold failed");
        reset = 1; tick(0); check_zero; // 書き込んだ値も全部消える
        reset = 0;
        tick(1); tick(1);
        if (cpu.ram[0] !== 1 || cpu.pc !== 3) $fatal(1, "Restart failed");
        $display("PASS: power-on reset, all 32 RAM bytes, step hold, reset priority, restart");
        $finish;
    end
endmodule
