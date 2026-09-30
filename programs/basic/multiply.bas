10 REM ===== かけ算 6 x 7 (たし算のくりかえし) =====
20 $A = 6 : $B = 7 : $C = 0
30 IF $B = 0 THEN GOTO 70
40 $C = $C + $A
50 $B = $B - 1
60 GOTO 30
70 OUT $C
80 END
