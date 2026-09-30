#!/bin/bash
# Mac 用 : ビルド (hdl の Verilog と program.hex から minimal_cpu.fs を作る)
#   bash 4_build.sh              … いまの hdl/program.hex で ビルド
#   bash 4_build.sh 自分の.hex   … program.hex を 入れかえてから ビルド
cd "$(dirname "$0")"
TOOL="$(cd .. && pwd)"; SUITE="$TOOL/oss-cad-suite"; HDL="$(cd ../../hdl && pwd)"
ARCH=$(uname -m); [ "$ARCH" = "arm64" ] || ARCH=x64
URL="https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-09-29/oss-cad-suite-darwin-$ARCH-20260929.tgz"
echo "=== CPU を くみたてて minimal_cpu.fs を 作ります [ビルド] ==="
if [ ! -f "$SUITE/environment" ]; then
  echo "ビルドには OSS CAD Suite という 道具が いります [約500MB]。"
  read -p "いまから ダウンロードしますか？ (y/n) " a; [ "$a" = "y" ] || exit 1
  curl -L --fail -o "$TOOL/oss-cad-suite.tgz" "$URL" && tar -xzf "$TOOL/oss-cad-suite.tgz" -C "$TOOL" && rm "$TOOL/oss-cad-suite.tgz" || { echo "[しっぱい] ダウンロードできませんでした"; exit 1; }
  # Mac の 安全機能で 止められないように (OSS CAD Suite の 説明どおり)
  [ -x "$SUITE/activate" ] && "$SUITE/activate"
fi
[ -n "$1" ] && cp "$1" "$HDL/program.hex" && echo "program.hex を 入れかえました: $1"
source "$SUITE/environment"
# abc9.xaiger 1 : 一部の yosys-abc で XAIGER2 読みこみが 落ちる 不具合を さける
export PYTHONWARNINGS=ignore
cd "$HDL" && mkdir -p build
echo "[1/3] yosys" && yosys -q -l build/yosys.log -p "scratchpad -set abc9.xaiger 1; read_verilog top_tangnano20k.v tta8.v; synth_gowin -top top_tangnano20k -json build/top.json" &&
echo "[2/3] nextpnr" && nextpnr-himbaechel -q -l build/nextpnr.log --json build/top.json --write build/pnr.json --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=tangnano20k.cst &&
echo "[3/3] gowin_pack" && gowin_pack -d GW2A-18C -o minimal_cpu.fs build/pnr.json
if [ $? -eq 0 ]; then
  echo ""; echo " *** できた！ hdl/minimal_cpu.fs  つぎは 2_write_sram.sh ***"
else
  echo ""; echo " [しっぱい] hdl/build/*.log を 見るか、この 画面の 文字を AI に 見せて 相談しよう"; exit 1
fi
