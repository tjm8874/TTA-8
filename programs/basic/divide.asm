; ==== TinyBASIC改 から つくった プログラム ====
; 10 REM 17 / 5 : $Q = しょう, $R = あまり, $E = 0でわるエラー
L10:
; 20 $N = 17 : $D = 5 : $Q = 0 : $R = 0 : $E = 0
L20:
        READ  IMM, 17
        WRITE $N
        READ  IMM, 5
        WRITE $D
        READ  IMM, 0
        WRITE $Q
        READ  IMM, 0
        WRITE $R
        READ  IMM, 0
        WRITE $E
; 30 IF $D = 0 THEN $E = 1 : GOTO 120
L30:
        READ  $D
        WRITE ALU_A
        READ  IMM, _T2
        WRITE JZ              ; おなじなら THEN へ
        READ  IMM, _S1
        WRITE JMP             ; ちがうから とばす
_T2:
        READ  IMM, 1
        WRITE $E
        READ  IMM, L120
        WRITE JMP
_S1:
; 40 IF $N = 0 THEN GOTO 120
L40:
        READ  $N
        WRITE ALU_A
        READ  IMM, L120
        WRITE JZ              ; おなじなら ジャンプ
; 50 $N = $N - 1
L50:
        READ  $N
        WRITE ALU_A
        READ  IMM, 1
        WRITE ALU_B
        READ  ALU_SUB
        WRITE $N
; 60 $R = $R + 1
L60:
        READ  $R
        WRITE ALU_A
        READ  IMM, 1
        WRITE ALU_B
        READ  ALU_ADD
        WRITE $R
; 70 IF $R <> $D THEN GOTO 40
L70:
        READ  $R
        WRITE ALU_A
        READ  $D
        WRITE ALU_B
        READ  ALU_SUB
        WRITE ALU_A           ; ALU_A = 左 - 右
        READ  IMM, _S3
        WRITE JZ              ; おなじなら とばす
        READ  IMM, L40
        WRITE JMP             ; ちがうから ジャンプ
_S3:
; 80 $R = 0
L80:
        READ  IMM, 0
        WRITE $R
; 90 $Q = $Q + 1
L90:
        READ  $Q
        WRITE ALU_A
        READ  IMM, 1
        WRITE ALU_B
        READ  ALU_ADD
        WRITE $Q
; 100 GOTO 40
L100:
        READ  IMM, L40
        WRITE JMP
; 120 OUT $Q
L120:
        READ  $Q
        WRITE OUT
; 130 END
L130:
_H4:
        READ  IMM, _H4
        WRITE JMP             ; おわり (ここで足ぶみ)
; ---- プログラムのおわり ----
_END:
        READ  IMM, _END
        WRITE JMP             ; おわり (ここで足ぶみ)
