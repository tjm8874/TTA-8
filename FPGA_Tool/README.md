# FPGA_Tool : Tang Nano 20K に かきこむ 道具

できあがった CPU (`hdl/minimal_cpu.fs`) を Tang Nano 20K に かきこむための 道具です。

## Windows (`Windows` フォルダ)

| じゅんばん | ファイル | すること |
|---|---|---|
| 0 | `0_setup_driver.bat` | **はじめに 1回だけ**。Zadig で USB ドライバを WinUSB に する |
| 1 | `1_check_board.bat` | ボードが 見えるか しらべる |
| 2 | `2_write_sram.bat` | かきこみ **おためし** (電源を きると 消える) |
| 3 | `3_write_flash.bat` | かきこみ **ずっと** (電源を きっても のこる) |
| 4 | `4_build.bat` | **ビルド**。`hdl` の Verilog と `program.hex` から `minimal_cpu.fs` を 作る。`program.hex` を ドラッグ＆ドロップすると 入れかえてから ビルド。はじめてのときは OSS CAD Suite (約600MB) を ダウンロード |

- ダブルクリックで うごきます。
- ほかの `.fs` を かきこみたいときは、`.fs` ファイルを バッチファイルの 上に ドラッグ。

### うまく いかないとき
- Zadig に「不明な USB デバイス (デバイス記述子要求の失敗)」と 出るときは、ボードが 正しく つながっていません。
  - 充電専用ではない **データ通信できる USB ケーブル** に かえる
  - USB ハブ・ドック・モニターの USB ではなく、**パソコン本体の USB** に 直接 さす
  - USB-C ⇔ USB-C で ダメなら **USB-A ⇔ USB-C** の ケーブルを ためす
- 正しく つながると、Zadig の USB ID が `0403 6010` の デバイスが 2つ (Interface 0 と 1) 出ます。

### 大人の方へ
- Zadig で Interface 0 を WinUSB に 置き換えると、Gowin 公式の Programmer からは 認識しにくくなります。戻すときは デバイスマネージャーで 該当デバイスの ドライバを 削除して 再接続してください。
- `openFPGALoader` は OSS CAD Suite (2026-09-29, openFPGALoader v1.1.1) の Windows 版から 実行に必要な DLL と いっしょに 取り出したものです。ライセンスは `Windows/openFPGALoader/license/`。
- Zadig 2.9 : https://zadig.akeo.ie/ (https://github.com/pbatard/libwdi)

## Mac (`Mac` フォルダ)

ターミナルで つぎのように 打ちます (ファイルを ターミナルに ドラッグしても OK)。

```
bash 0_setup.sh        # はじめに 1回だけ (Homebrew で openFPGALoader を 入れる)
bash 1_check_board.sh  # ボードが 見えるか
bash 2_write_sram.sh   # かきこみ おためし
bash 3_write_flash.sh  # かきこみ ずっと
bash 4_build.sh [自分の.hex]  # ビルド (はじめては OSS CAD Suite を ダウンロード)
```

Mac では ドライバの 設定は いりません。
