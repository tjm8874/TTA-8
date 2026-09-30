#!/bin/sh
# PATH に iverilog と vvp が必要。リポジトリのどこからでも実行できる。
set -eu
cd "$(dirname "$0")/../hdl"
mkdir -p build
for test in reset divide; do
  iverilog -g2012 -s "tb_$test" -o "build/test_$test" "../sim/tb_$test.v" tta8.v
  vvp "build/test_$test"
done
