#!/bin/bash
# Mac 用 : ターミナルで  bash 1_check_board.sh  と 打つか、このファイルを ターミナルに ドラッグして Enter
cd "$(dirname "$0")"
if ! command -v openFPGALoader >/dev/null 2>&1; then
  echo "[こまった] openFPGALoader が ありません。先に 0_setup.sh を やってね"
  exit 1
fi
echo "--- USB に つながっている もの ---"
openFPGALoader --scan-usb
echo ""
echo "--- FPGA を さがす ---"
openFPGALoader -b tangnano20k --detect
if [ $? -eq 0 ]; then
  echo ""; echo " *** 「model GW2A(R)-18(C)」 と 出ていれば OK！ ***"
else
  echo ""
  echo " [しっぱい] USB ケーブルを たしかめて、1_check_board.sh を ためしてね"
  echo " それでも ダメなら、この 画面の 文字を AI に 見せて 相談しよう"
  exit 1
fi
