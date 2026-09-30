# 8. CPU の 設計図を 読もう

TTA-8 の 設計図は `hdl/tta8.v` に あります。
**Verilog（ベリログ）** という、回路を 書くための ことばで 書かれています。
コメントを のぞくと **51行**。いっしょに 読んでみましょう。

## ① 部品を 用意する

```verilog
reg [7:0] rom [0:255];            // プログラム 256バイト
initial $readmemh("program.hex", rom);

reg  [7:0] pc;                    // いま 何番目の 命令か
reg  [7:0] v;                     // V : たった1つのレジスタ
reg  [7:0] alu_a, alu_b;          // ALU に 入れる数
reg  [7:0] ram [0:31];            // 変数 $A-$Z, $0-$5
```

`reg [7:0]` は「8bit の 箱」という 意味です。
`program.hex` を ROM に 読みこんでいます。

## ② 命令を 分ける

```verilog
wire [7:0] inst  = rom[pc];       // いまの 命令
wire       write = inst[7];       // いちばん左の bit : 0=READ 1=WRITE
wire [6:0] addr  = inst[6:0];     // のこり 7bit : アドレス
```

[2章](02_tta8.md) の 命令の 形 そのままです。

## ③ READ したら 何が 読めるか

```verilog
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
```

**ALU は ここだけ** です。`+` `-` `&` `~` を 書くだけで、FPGA が 計算回路を 作ってくれます。

## ④ 1命令を 実行する

```verilog
pc <= pc + 8'd1;                          // ふつうは 次へ
if (!write) begin                         // ===== READ
    v <= rdata;
    if (addr == 7'h12) pc <= pc + 8'd2;   // IMM は 定数を とばす
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
```

- READ なら `v <= rdata`（部品 → V）
- WRITE なら `○○ <= v`（V → 部品）
- **JMP は「PC に 書く」だけ**。JZ は「A が 0 なら PC に 書く」だけ

CPU の 動きが、ほとんど そのまま 書いてあるのが わかりますね。

## ⑤ ボードと つなぐ（top_tangnano20k.v）

`hdl/top_tangnano20k.v` は、ボードと CPU を つなぐ ファイルです。

- ボードの 時計（**27MHz** ＝ 1秒に 2700万回）を 数えて、**1秒に 1000回** だけ CPU を 進める
- ボタンの 信号を 時計に そろえる
- LED は 0 で 光る 回路なので、反対（`~led`）に して つなぐ

どの ピンに つなぐかは `hdl/tangnano20k.cst` に 書いてあります。

## ⑥ チューリング完全って？

「**どんな 計算でも（時間と メモリさえ あれば）できる**」ことを **チューリング完全** と いいます。
スマホの CPU も スーパーコンピューターも チューリング完全です。

TTA-8 で できることを ならべると……

1. 変数に 1 を **たす**（ALU_ADD）
2. 変数から 1 を **ひく**（ALU_SUB）
3. 変数が **0 か どうかで ジャンプ** する（JZ）

じつは この 3つが あれば「**カウンター機械（ミンスキー機械）**」という 計算の しくみを 作れて、
それは チューリング完全だと 数学で 証明されています。
だから TTA-8 も（メモリが 256バイトまで という 点を のぞけば）**チューリング完全** です。

> かけ算も、わり算も、ぜんぶ「たす・ひく・0 で ジャンプ」の くみあわせで 作れます。
> [6章](06_basic.md) の かけ算 6 × 7 が その 例です。

---
[← 7. アセンブリで 書いてみよう](07_asm.md)　|　[つぎへ → 9. AI に こうやって たのもう](09_ai.md)
