@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
set "LOADER=%~dp0openFPGALoader\openFPGALoader.exe"
set "FS=%~1"
if "%FS%"=="" set "FS=%~dp0..\..\hdl\minimal_cpu.fs"
if not exist "%FS%" goto nofile
echo ============================================================
echo   Tang Nano 20K に かきこみ [おためし]
echo   ※ 電源を きると 消えます。何度でも ためせるよ
echo ============================================================
echo   ファイル: %FS%
echo.
"%LOADER%" -b tangnano20k "%FS%"
if errorlevel 1 goto fail
echo.
echo  *** おわり！ LED を 見てみよう ***
echo.
echo  何か キーを おすと この画面を とじます。
pause >nul
exit /b 0

:nofile
echo.
echo  [こまった] かきこむ ファイル .fs が 見つかりません
echo    さがした場所: %FS%
echo    .fs ファイルを この バッチファイルの 上に ドラッグしても いいよ
echo.
echo  何か キーを おすと この画面を とじます。
pause >nul
exit /b 1

:fail
echo.
echo  [しっぱい] かきこめませんでした。つぎを たしかめてね:
echo    1. USB ケーブルが ささっているか
echo    2. 0_setup_driver.bat を 1回 やったか
echo    3. 1_check_board.bat で ボードが 見えるか
echo  それでも ダメなら、この 黒い画面の 文字を AI に 見せて 相談しよう
echo.
echo  何か キーを おすと この画面を とじます。
pause >nul
exit /b 1
