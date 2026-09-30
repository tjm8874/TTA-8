# 2026-09-30 教材・RAM初期化の検証

基点：73ee4816d3a4e61169830e7b79141155c8678083。

## 変更

- CPU本体でRAM全32バイトを同期リセット。空行・コメント除外で53行。
- 第8章にビット・配列・組み合わせ回路・クロック・非ブロッキング代入・PC更新を追加。SVG図解4点。
- 発展1は、わり算・繰り返し・NANDからの論理演算。割り算サンプルは81バイト。
- 発展2は、16bit化・アドレスインデックス・入出力インデックス・ページ化の設計案。これらの拡張回路は未実装。
- ラボのサンプル、Web説明書、PDF、ボード用ビットストリームを再生成。
- 動画台本と行数表示の生成コードを更新。公開済み動画・既存MP4は再生成していない。

## 確認済み

| 確認 | 結果 |
|---|---|
| `node tools/test.js` | 32成功、0失敗 |
| `node tools/test-lessons.js` | 除算48ケース（0除算・0・255など）、教材とソース一致、ラボのRAMリセット、NAND例が成功 |
| `sh tools/test-hdl.sh` | Verilogで初期化・RAM全32バイトへの書き込み・step停止・再リセット・再実行、17÷5の商3／余り2が成功 |
| `sim/tb_flasher.v` | 既存4モードの出力パターンを確認 |
| 合成・配置配線・パック | OSS CAD Suite 2026-09-29 darwin-arm64。27MHz制約で成功 |
| 配置配線の使用量 | LUT4 1,269 / 20,736、DFF 342 / 15,552 |

`sim/tb_flasher.v` は出力ログを観察するテストです。自己判定は `tb_reset.v` と `tb_divide.v` が担当します。
タイミング解析は実機の速度測定ではありません。

再生成した `hdl/minimal_cpu.fs` の SHA-256：

```text
ccaaef96bbdfd2a4700a8185183056e5bf8ebd218e242d60515f690ea267561e
```

## 再現手順

Node.jsで上記2つのJavaScriptテストを実行します。
OSS CAD Suiteの環境を読み込むか、PATHへiverilogとvvpを追加して `sh tools/test-hdl.sh` を実行します。
ボード用ビルドは `FPGA_Tool/Mac/4_build.sh` またはWindowsの `4_build.bat`。
ラボの再生成は `python3 debugger/build.py`。
説明書はMarkdownとPlaywrightを用意して `python3 tools/build_guide.py --pdf`。

## 未確認・公開範囲

- 今回生成したビットストリームの実機書き込みと、Windows上でのビルドは未実施。
- GitHubへのpush、公開ラボの更新、公開動画の差し替えは未実施。
- 16bit化・外部メモリ・入出力インデックス・ページ化は教材の設計案のみ。
