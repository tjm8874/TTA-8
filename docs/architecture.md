# TTA-8 仕様書 v1

教育用の最小CPU。命令は **READ** と **WRITE** の2つだけ。
計算・ジャンプ・入出力はすべて「決まったアドレスへの読み書き」で行う（Transport-Triggered Architecture）。

## 1. 決定事項

| 項目 | 決定 |
|---|---|
| ボード | Sipeed Tang Nano 20K (GW2AR-18) |
| HDL | Verilog（小中学生が読んで分かりやすいため。VHDL から変更） |
| 土台 | Gemini 相談の最初の案（7bit アドレス、READ/WRITE のみ）。拡張版（64KB 間接アクセス、ISA_VERSION、HDMI デバッガ、CPU 上の TinyBASIC）は v1 では採用しない |
| 追加 | IMM（即値）、ALU_SUB（引き算）、JZ は絶対番地ジャンプ |
| 名前 | 計算用の箱は ALU_A / ALU_B、変数は $A〜$Z・$0〜$5 |
| 言語 | TinyBASIC改。PC（ブラウザ）上でコンパイルして機械語にする |
| デバッガ | ブラウザ版：ブロック図＋値表示、ソース／アセンブラ対比、ステップ実行、ボード模擬表示 |

## 2. 命令

```
 7   6                 0
+---+-------------------+
|R/W|   アドレス (7bit)  |
+---+-------------------+
 0 = READ  addr : V ← [addr]
 1 = WRITE addr : [addr] ← V
```

- CPU の中にあるのは **V（8bit）** と **PC（8bit）** だけ。
- 1クロックで1命令（ステップ実行＝1命令）。
- `READ IMM` だけは2バイト命令：次の1バイトを V に入れ、PC は +2。

## 3. アドレスマップ v1

| アドレス | 名前 | READ | WRITE |
|---|---|---|---|
| 0x00 | ALU_A | ALU_A | ALU_A ← V |
| 0x01 | ALU_B | ALU_B | ALU_B ← V |
| 0x02 | ALU_ADD | ALU_A + ALU_B | — |
| 0x03 | ALU_NAND | ~(ALU_A & ALU_B) | — |
| 0x04 | ALU_SUB | ALU_A − ALU_B | — |
| 0x10 | JMP | — | PC ← V |
| 0x11 | JZ | — | ALU_A == 0 なら PC ← V |
| 0x12 | IMM | 次の1バイト（PC+2） | — |
| 0x20–0x39 | $A〜$Z | 変数 | 変数 |
| 0x3A–0x3F | $0〜$5 | 変数 | 変数 |
| 0x7E | IN | bit0 = S1, bit1 = S2（押すと1） | — |
| 0x7F | OUT | — | bit0–5 = LED（1で点灯、bit0 が右端） |

その他のアドレスは READ で 0、WRITE は無視。プログラム ROM は 256 バイト（別空間）。

> **ALU とは？**　Arithmetic Logic Unit（算術論理演算装置）のことで、CPU の中心で計算・演算を行う部分です。
> ALU_A と ALU_B に数を入れると、ALU_ADD（たし算）・ALU_SUB（ひき算）・ALU_NAND の答えがすぐに読み出せます。

変数は `$A`〜`$Z` と `$0`〜`$5` のちょうど32個で、RAM 32バイトと1対1に対応する。
アセンブラでも TinyBASIC改 でも同じ名前を使う。

## 4. チューリング完全であること

変数の読み書き・ALU_SUB（1を引く）・ALU_ADD（1を足す）・JZ（0なら分岐）・JMP があるので、
「数を+1/−1 して、0かどうかで分岐する」カウンタ機械（ミンスキー機械）を作れる。
カウンタ機械はチューリング完全なので、TTA-8 も（メモリが有限という点を除き）チューリング完全。
さらに ALU_ADD と ALU_NAND だけで、引き算・AND/OR/XOR・かけ算もすべて組み立てられる（ALU_SUB は便利のための追加）。

## 5. ボードとの対応（Tang Nano 20K）

| 信号 | ピン | 備考 |
|---|---|---|
| clk 27MHz | 4 | |
| S1 / S2 | 88 / 87 | 押すと 1（実機で確認済み、`BTN_ACTIVE_LOW = 0`）。「TANG NANO 20K」が読める向きで S2 が左上、S1 が左下 |
| LED bit0–5 | 20–15 | 0 で点灯（トップで反転）。USB を左に置いて bit0 = 右はし（基板印字 LED5）… bit5 = 左はし（印字 LED0）。cst で並びを逆にしている |

- CPU は 1000 命令/秒（`CPU_HZ`）。0.5秒 ≒ 500 命令。
- サブルーチンはスタックなし：戻り先を RAM に入れ、`READ R / WRITE JMP` で戻る。

## 6. サンプル：LED フラッシャー（programs/flasher.asm, 169 バイト）

| ボタン | 模様（0.5秒ごと） |
|---|---|
| なし | `_____○` / `______` |
| S1 | `_____○` → `____○_` → … → `○_____` |
| S2 | `○____○` → `_○__○_` → `__○○__` |
| S1+S2 | `○_○_○_` / `_○_○_○` |

ボタンは押している間だけ有効で、約0.5秒ごとに確認する。iverilog シミュレーションで全モードの動作を確認済み。

## 7. TinyBASIC改

文法は `docs/tinybasic.md`。PC 上のコンパイラ（tools/tbasic.js）で TTA-8 のアセンブリに翻訳する。
- 変数 `$A`〜`$Z`、`$0`〜`$5`／式 `+ - AND OR NAND`／`IF = / <> THEN`／`GOTO GOSUB RETURN`／`OUT POKE PEEK IN`／`WAIT n`（n × 0.01秒）／`END REM`
- BASIC 版フラッシャー（programs/basic/flasher.bas）は 170 バイト。iverilog で全モードの動作を確認済み。

## 8. フォルダ構成

```
hdl/       tta8.v (CPU), top_tangnano20k.v, tangnano20k.cst, minimal_cpu.fs (ビットストリーム)
FPGA_Tool/ Windows/ (openFPGALoader, Zadig, 0〜3_*.bat), Mac/ (0〜3_*.sh), README.md
tools/     tta8asm.js (アセンブラ), tbasic.js (BASIC コンパイラ), tta8sim.js (エミュレータ), test.js
programs/  flasher.asm, add.asm, count.asm / basic/ に .bas
debugger/  index.html (ブラウザ版デバッガ「TTA-8 ラボ」、「ボード用に保存」で program.hex を出力), src/lab.html, build.py
sim/       tb_flasher.v (iverilog)
docs/      architecture.md, tinybasic.md, guide/ (せつめい書 md + index.html + PDF), video/ (動画3本の台本・絵コンテ・素材 mp4)
tools/build_guide.py      せつめい書の Web / PDF をビルド
tools/video/              動画素材アニメ (anim.html, render.py)
README.md  GitHub トップ
```

## 9. 未決定・要確認

- ~~S1/S2 の論理、LED の物理的な並び~~ → 2026-09-29 実機で確認・対応済み
- ビルドはオープンソースツール（yosys + nextpnr-himbaechel + apicula）で `hdl/minimal_cpu.fs` を生成、書き込みは `FPGA_Tool/`（openFPGALoader、Windows は Zadig で WinUSB 化）
- 2026-09-29 実機確認：SRAM 書き込み・Flash 書き込み（`-f`）とも成功。電源を入れ直しても なし／S1／S2／S1+S2 の全モードが動作
- Gowin EDA で `$readmemh("program.hex")` のパスが通るか → 実機ビルドで確認
