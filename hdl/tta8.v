// ============================================================
//  TTA-8 : 命令が READ と WRITE の2つだけの 8bit CPU
// ============================================================
//  命令 (8bit)
//    bit7   : 0 = READ  (アドレスの値を V に読む)
//             1 = WRITE (V の値をアドレスに書く)
//    bit6-0 : アドレス (0x00 - 0x7F)
//
//  1クロック(step=1)で1命令を実行する。
//
//  ALU とは Arithmetic Logic Unit (算術論理演算装置) のこと。
//  CPU の中心で、たし算・ひき算などの計算(演算)をする部分。
//  ALU_A と ALU_B に数を入れると、答えがすぐに出てくる。
// ============================================================
module tta8 (
    input  wire       clk,
    input  wire       reset,
    input  wire       step,      // 1 のときだけ 1命令すすむ
    input  wire [1:0] btn,       // bit0 = S1, bit1 = S2 (押すと 1)
    output reg  [5:0] led        // 1 で点灯
);
    // ---- プログラム (ROM 256バイト) -------------------------
    reg [7:0] rom [0:255];
    initial $readmemh("program.hex", rom);

    // ---- CPU の中身 -----------------------------------------
    reg  [7:0] pc;               // いま何番目の命令か
    reg  [7:0] v;                // V : たった1つのレジスタ

    wire [7:0] inst  = rom[pc];
    wire       write = inst[7];
    wire [6:0] addr  = inst[6:0];

    // ---- まわりの部品 ---------------------------------------
    reg  [7:0] alu_a, alu_b;     // ALU に入れる数 (ALU_A, ALU_B)
    reg  [7:0] ram [0:31];       // 変数 $A-$Z, $0-$5 (0x20-0x3F)
    integer i;                  // リセットで RAM の箱を順に指定する番号
    wire       is_ram = (addr[6:5] == 2'b01);

    // ---- READ : アドレスごとに何が読めるか -------------------
    reg [7:0] rdata;
    always @* begin
        case (addr)
            7'h00:   rdata = alu_a;               // ALU_A
            7'h01:   rdata = alu_b;               // ALU_B
            7'h02:   rdata = alu_a + alu_b;       // ALU_ADD
            7'h03:   rdata = ~(alu_a & alu_b);    // ALU_NAND
            7'h04:   rdata = alu_a - alu_b;       // ALU_SUB
            7'h12:   rdata = rom[pc + 8'd1];      // IMM (次の1バイト)
            7'h7E:   rdata = {6'b0, btn};         // IN
            default: rdata = is_ram ? ram[addr[4:0]] : 8'h00;
        endcase
    end

    // ---- 1命令を実行する ------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            pc <= 0;  v <= 0;  alu_a <= 0;  alu_b <= 0;  led <= 0;
            for (i = 0; i < 32; i = i + 1) ram[i] <= 0;
        end else if (step) begin
            pc <= pc + 8'd1;                          // ふつうは次へ
            if (!write) begin                         // ===== READ
                v <= rdata;
                if (addr == 7'h12) pc <= pc + 8'd2;   // IMM は定数をとばす
            end else begin                            // ===== WRITE
                case (addr)
                    7'h00: alu_a <= v;                // ALU_A
                    7'h01: alu_b <= v;                // ALU_B
                    7'h10: pc <= v;                   // JMP
                    7'h11: if (alu_a == 0) pc <= v;   // JZ (ALU_A が 0 なら)
                    7'h7F: led <= v[5:0];             // OUT
                    default: if (is_ram) ram[addr[4:0]] <= v;
                endcase
            end
        end
    end
endmodule
