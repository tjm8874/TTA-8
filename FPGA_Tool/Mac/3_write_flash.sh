#!/bin/bash
# Mac 用 : ターミナルで  bash 3_write_flash.sh  と 打つか、このファイルを ターミナルに ドラッグして Enter
cd "$(dirname "$0")"
if ! command -v openFPGALoader >/dev/null 2>&1; then
  echo "[こまった] openFPGALoader が ありません。先に 0_setup.sh を やってね"
  exit 1
fi
FS="${1:-../../hdl/minimal_cpu.fs}"
if [ ! -f "$FS" ]; then
  echo "[こまった] かきこむ ファイル .fs が 見つかりません: $FS"
  exit 1
fi
echo "=== Tang Nano 20K に かきこみ [ずっと] : 電源を きっても 消えません ==="
echo "  ファイル: $FS"
openFPGALoader -b tangnano20k -f "$FS"
if [ $? -eq 0 ]; then
  echo ""; echo " *** おわり！ LED を 見てみよう ***"
else
  echo ""
  echo " [しっぱい] USB ケーブルを たしかめて、1_check_board.sh を ためしてね"
  echo " それでも ダメなら、この 画面の 文字を AI に 見せて 相談しよう"
  exit 1
fi
