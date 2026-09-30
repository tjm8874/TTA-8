@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
set "LOADER=%~dp0openFPGALoader\openFPGALoader.exe"
echo ============================================================
echo   ボードが つながっているか しらべます
echo ============================================================
echo.
echo --- USB に つながっている もの ---
"%LOADER%" --scan-usb
echo.
echo --- FPGA を さがす ---
"%LOADER%" -b tangnano20k --detect
if errorlevel 1 goto fail
echo.
echo  *** 「model GW2A[R]-18[C]」 と 出ていれば OK！ ***
echo.
echo  何か キーを おすと この画面を とじます。
pause >nul
exit /b 0

:fail
echo.
echo  [見つからない] USB ケーブルと、0_setup_driver.bat を たしかめてね
echo.
echo  何か キーを おすと この画面を とじます。
pause >nul
exit /b 1
