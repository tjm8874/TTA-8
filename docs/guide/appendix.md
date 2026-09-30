# ふろく

## A. こまったとき

| こまったこと | ためすこと |
|---|---|
| Zadig に「不明な USB デバイス」しか 出ない | 充電専用ケーブルかも。データ通信できる ケーブルに かえる／パソコン本体の USB に さす／USB-A ⇔ USB-C ケーブルを ためす |
| `1_check_board` で ボードが 見つからない | `0_setup_driver` を やったか 確認。Interface **0** を WinUSB に したか 確認 |
| 書きこめたのに LED が 動かない | もう一度 `2_write_sram` を ためす。USB を さしなおす |
| なにも おしてないのに LED が 交互に 点滅 | ボタンの 向きの 設定が 逆。`hdl/top_tangnano20k.v` の `BTN_ACTIVE_LOW` を 変える（Tang Nano 20K は 0 で 正しい） |
| 光る 向きが 左右 逆 | ボードの 向きを 確認（「TANG NANO 20K」が 読める 向き） |
| `4_build` の ダウンロードが 止まる | インターネット接続を 確認して もう一度。社内・学校の ネットワークでは 止められることも |
| TTA-8 ラボで「くみたて失敗」 | 下の 赤い 文字を 読む。わからなければ [9章](09_ai.md) の やりかたで AI に 聞く |
| Windows で 文字が 化ける | Windows 10 の 古い版では 起きることが あります。Windows Update を してみてください |

## B. 用語集

| ことば | 意味 |
|---|---|
| CPU | 命令を 1つずつ こなす 部品 |
| FPGA | 設計図を 書きこむと その回路に なる チップ |
| ビット（bit） | 0 か 1 が 入る 1マス |
| バイト | 8ビット。0〜255 |
| 2進数 / 16進数 | 0と1だけの 数 / 0〜9 と A〜F の 数（`0x` を つける） |
| レジスタ | CPU の 中の 小さな 箱。TTA-8 では V・PC・ALU_A・ALU_B など |
| PC（プログラムカウンター） | 実行する命令のバイト番地を おぼえる 箱 |
| ALU | 計算を する 係 |
| アドレス | 部品や メモリの 番号 |
| ROM / RAM | プログラムを しまう ところ / 変数を しまう ところ |
| バス | データの 通り道 |
| アセンブリ | CPU の 命令を そのまま 書く ことば |
| コンパイル | BASIC などを 機械語に 翻訳する こと |
| Verilog | 回路を 書く ことば |
| ビルド | Verilog と プログラムから 書きこみ用 ファイルを 作る こと |
| クロック | レジスタに値を保存するタイミングの基準になる信号 |
| インデックスレジスタ | アクセスする場所の番号を覚える箱（発展2の改造案） |
| ページ | 大きなプログラム空間を分けたまとまり（発展2では256バイト） |

## C. 大人の方へ（保護者・先生・開発者）

### 構成

| パス | 内容 |
|---|---|
| `hdl/tta8.v` | CPU 本体（コメント・空行除き 53 行） |
| `hdl/top_tangnano20k.v` | ボード用トップ（27MHz → 1kHz ステップ、ボタン同期、LED 反転） |
| `hdl/tangnano20k.cst` | ピン割り当て（LED は bit0 = pin 20 … bit5 = pin 15 に反転） |
| `hdl/program.hex` | ROM 初期値（256 行の 16 進） |
| `hdl/minimal_cpu.fs` | ビルド済みビットストリーム（LED フラッシャー） |
| `tools/` | `tta8asm.js`（アセンブラ）、`tbasic.js`（TinyBASIC改 コンパイラ）、`tta8sim.js`（エミュレータ）、`test.js` |
| `debugger/` | TTA-8 ラボ（`src/lab.html` を `build.py` で `index.html` に 1 ファイル化） |
| `FPGA_Tool/` | 書き込み・ビルド用スクリプト、openFPGALoader（Windows 版同梱）、Zadig |
| `sim/tb_flasher.v` | iverilog 用テストベンチ |
| `docs/architecture.md` / `docs/tinybasic.md` | 仕様書・文法書 |

### コマンドラインでのビルド

OSS CAD Suite（yosys / nextpnr-himbaechel / apicula）を使います。`FPGA_Tool/*/4_build` と同じ内容です。

```sh
cd hdl
yosys -p "scratchpad -set abc9.xaiger 1; read_verilog top_tangnano20k.v tta8.v; synth_gowin -top top_tangnano20k -json build/top.json"
nextpnr-himbaechel --freq 27 --json build/top.json --write build/pnr.json \
  --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=tangnano20k.cst
gowin_pack -d GW2A-18C -o minimal_cpu.fs build/pnr.json
openFPGALoader -b tangnano20k minimal_cpu.fs        # SRAM
openFPGALoader -b tangnano20k -f minimal_cpu.fs     # Flash
```

`scratchpad -set abc9.xaiger 1` は、Windows 版 OSS CAD Suite（2026-09-29）で ABC9 が XAIGER2 の読み込み時にアサーションで落ちる問題の回避策です（旧 XAIGER 経路を使う）。

2026-09-30の再ビルド（同梱フラッシャー、RAM初期化あり）では、LUT4 1,269 / 20,736、DFF 342 / 15,552。27MHzのタイミング制約を満たしています。これは配置配線ツールの結果で、実機測定値ではありません。回路やプログラムで使用量は変わります。

### プログラムのコンパイル（Node.js）

```sh
node tools/tbasic.js programs/basic/flasher.bas   # → .asm / .hex / .lst
node tools/tta8asm.js programs/flasher.asm        # → .hex / .lst
node tools/test.js                                # コンパイラのテスト
node tools/test-lessons.js                        # わり算48ケース・教材例・初期化
sh tools/test-hdl.sh                              # Verilogの初期化・わり算（iverilog/vvpが必要）
```

### Gowin 公式ツールを使う場合

Gowin EDA（Education 版）でも `hdl/*.v` と `hdl/tangnano20k.cst` からビルドできます。
ただし Zadig で WinUSB に置き換えた後は Gowin Programmer から認識しにくくなります。
戻すときはデバイスマネージャーで該当デバイスのドライバを削除して再接続してください。

### 動作確認

2026-09-29、実機（Tang Nano 20K）で SRAM・Flash 書き込みとも、
なし／S1／S2／S1+S2 の全モードの動作を確認しています（初版）。RAM初期化を追加した版は、別途実機での確認が必要です。

---
[← 発展2. CPU を大きくする](12_expansion.md)　|　[もくじ](README.md)
