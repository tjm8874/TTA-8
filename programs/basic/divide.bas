10 REM 17 / 5 : $Q = しょう, $R = あまり, $E = 0でわるエラー
20 $N = 17 : $D = 5 : $Q = 0 : $R = 0 : $E = 0
30 IF $D = 0 THEN $E = 1 : GOTO 120
40 IF $N = 0 THEN GOTO 120
50 $N = $N - 1
60 $R = $R + 1
70 IF $R <> $D THEN GOTO 40
80 $R = 0
90 $Q = $Q + 1
100 GOTO 40
120 OUT $Q
130 END
