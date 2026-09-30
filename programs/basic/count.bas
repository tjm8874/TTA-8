10 REM ===== LED で 2進数カウンター =====
20 $C = 0
30 OUT $C
40 WAIT 50
50 $C = $C + 1
60 GOTO 30
