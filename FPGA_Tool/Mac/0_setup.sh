#!/bin/bash
# Mac 用 : はじめに 1回だけ。openFPGALoader を Homebrew で 入れます
echo "============================================================"
echo "  はじめに 1回だけ : openFPGALoader を 入れます"
echo "============================================================"
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew が ありません。https://brew.sh/ja/ の 手順で 先に 入れてね"
  echo "(わからなければ「Mac に Homebrew を 入れたい」と AI に 聞こう)"
  exit 1
fi
brew install openfpgaloader && echo "" && echo " *** じゅんび 完了！ つぎは 1_check_board.sh ***"
