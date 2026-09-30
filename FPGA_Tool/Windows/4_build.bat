@echo off
chcp 65001 >nul
setlocal
rem ============================================================
rem  4_build.bat : hdl フォルダの Verilog と program.hex から
rem                ボードに書きこむファイル minimal_cpu.fs を作る
rem  使うもの   : OSS CAD Suite (yosys / nextpnr-himbaechel / gowin_pack)
rem ============================================================
set "TOOL=%~dp0.."
set "SUITE=%TOOL%\oss-cad-suite"
set "HDL=%~dp0..\..\hdl"
set "URL=https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-09-29/oss-cad-suite-windows-x64-20260929.tgz"

echo ============================================================
echo   CPU を くみたてて minimal_cpu.fs を 作ります [ビルド]
echo ============================================================
echo.

if not exist "%SUITE%\environment.bat" goto nosuite
:build
if "%~1"=="" goto nohexarg
echo  program.hex を 入れかえます: %~1
copy /y "%~1" "%HDL%\program.hex" >nul
:nohexarg
call "%SUITE%\environment.bat" >nul
rem abc9.xaiger 1 : Windows 版 yosys-abc の XAIGER2 読みこみ不具合を さける
set PYTHONWARNINGS=ignore
cd /d "%HDL%"
if not exist build mkdir build
echo  [1/3] yosys : Verilog を 部品の つながりに 変かん中...
yosys -q -l build\yosys.log -p "scratchpad -set abc9.xaiger 1; read_verilog top_tangnano20k.v tta8.v; synth_gowin -top top_tangnano20k -json build\top.json"
if errorlevel 1 goto fail
echo  [2/3] nextpnr : FPGA の どこに おくか きめて 配線中...
nextpnr-himbaechel --freq 27 -q -l build\nextpnr.log --json build\top.json --write build\pnr.json --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=tangnano20k.cst
if errorlevel 1 goto fail
echo  [3/3] gowin_pack : 書きこみ用 ファイルに まとめ中...
gowin_pack -d GW2A-18C -o minimal_cpu.fs build\pnr.json
if errorlevel 1 goto fail
echo.
echo  *** できた！ hdl\minimal_cpu.fs ***
echo  つぎは 2_write_sram.bat で ボードに 書きこもう
echo.
echo  何か キーを おすと この画面を とじます。
pause >nul
exit /b 0

:nosuite
echo  ビルドには OSS CAD Suite という 道具が いります [約600MB]。
echo  まだ ないので、いまから ダウンロードして FPGA_Tool フォルダに 入れます。
echo  ※ 時間が かかります。インターネットに つながっているか たしかめてね
echo.
choice /c YN /m "ダウンロードしますか"
if errorlevel 2 exit /b 1
curl -L --fail -o "%TOOL%\oss-cad-suite.tgz" "%URL%"
if errorlevel 1 goto dlfail
echo  ひらいています... [数分 かかります]
tar -xzf "%TOOL%\oss-cad-suite.tgz" -C "%TOOL%"
if errorlevel 1 goto dlfail
del "%TOOL%\oss-cad-suite.tgz"
echo  じゅんび 完了！ ビルドを はじめます。
echo.
goto build

:dlfail
echo.
echo  [しっぱい] ダウンロードか 展開が うまく いきませんでした。
echo  この 黒い画面の 文字を AI に 見せて 相談しよう
echo.
echo  何か キーを おすと この画面を とじます。
pause >nul
exit /b 1

:fail
echo.
echo  [しっぱい] ビルドが とちゅうで 止まりました。
echo  くわしくは hdl\build\*.log を 見るか、この 画面の 文字を AI に 見せて 相談しよう
echo.
echo  何か キーを おすと この画面を とじます。
pause >nul
exit /b 1
