; ==== TinyBASIC改 から つくった プログラム ====
; 10 REM ===== LED フラッシャー (TinyBASIC改) =====
L10:
; 20 REM なにも押さない: 右はしが点滅 / S1: 右から左へ
L20:
; 30 REM S2: 外から内へ / S1+S2: 交互に点滅
L30:
; 100 $M = IN
L100:
        READ  IN
        WRITE $M
; 110 IF $M = 1 THEN GOTO 300
L110:
        READ  $M
        WRITE ALU_A
        READ  IMM, 1
        WRITE ALU_B
        READ  ALU_SUB
        WRITE ALU_A           ; ALU_A = 左 - 右
        READ  IMM, L300
        WRITE JZ              ; おなじなら ジャンプ
; 120 IF $M = 2 THEN GOTO 400
L120:
        READ  $M
        WRITE ALU_A
        READ  IMM, 2
        WRITE ALU_B
        READ  ALU_SUB
        WRITE ALU_A           ; ALU_A = 左 - 右
        READ  IMM, L400
        WRITE JZ              ; おなじなら ジャンプ
; 130 IF $M = 3 THEN GOTO 500
L130:
        READ  $M
        WRITE ALU_A
        READ  IMM, 3
        WRITE ALU_B
        READ  ALU_SUB
        WRITE ALU_A           ; ALU_A = 左 - 右
        READ  IMM, L500
        WRITE JZ              ; おなじなら ジャンプ
; 200 REM ----- なにも押していない -----
L200:
; 210 $L = 0b000001 : GOSUB 900
L210:
        READ  IMM, 1
        WRITE $L
        READ  IMM, _R1
        WRITE $5              ; もどる場所をおぼえる
        READ  IMM, L900
        WRITE JMP
_R1:
; 220 $L = 0b000000 : GOSUB 900
L220:
        READ  IMM, 0
        WRITE $L
        READ  IMM, _R2
        WRITE $5              ; もどる場所をおぼえる
        READ  IMM, L900
        WRITE JMP
_R2:
; 230 GOTO 100
L230:
        READ  IMM, L100
        WRITE JMP
; 300 REM ----- S1 : 右から左へ (2倍ずつ) -----
L300:
; 310 $L = 1
L310:
        READ  IMM, 1
        WRITE $L
; 320 GOSUB 900
L320:
        READ  IMM, _R3
        WRITE $5              ; もどる場所をおぼえる
        READ  IMM, L900
        WRITE JMP
_R3:
; 330 $L = $L + $L
L330:
        READ  $L
        WRITE ALU_A
        READ  $L
        WRITE ALU_B
        READ  ALU_ADD
        WRITE $L
; 340 IF $L <> 64 THEN GOTO 320
L340:
        READ  $L
        WRITE ALU_A
        READ  IMM, 64
        WRITE ALU_B
        READ  ALU_SUB
        WRITE ALU_A           ; ALU_A = 左 - 右
        READ  IMM, _S4
        WRITE JZ              ; おなじなら とばす
        READ  IMM, L320
        WRITE JMP             ; ちがうから ジャンプ
_S4:
; 350 GOTO 100
L350:
        READ  IMM, L100
        WRITE JMP
; 400 REM ----- S2 : 外から内へ -----
L400:
; 410 $L = 0b100001 : GOSUB 900
L410:
        READ  IMM, 33
        WRITE $L
        READ  IMM, _R5
        WRITE $5              ; もどる場所をおぼえる
        READ  IMM, L900
        WRITE JMP
_R5:
; 420 $L = 0b010010 : GOSUB 900
L420:
        READ  IMM, 18
        WRITE $L
        READ  IMM, _R6
        WRITE $5              ; もどる場所をおぼえる
        READ  IMM, L900
        WRITE JMP
_R6:
; 430 $L = 0b001100 : GOSUB 900
L430:
        READ  IMM, 12
        WRITE $L
        READ  IMM, _R7
        WRITE $5              ; もどる場所をおぼえる
        READ  IMM, L900
        WRITE JMP
_R7:
; 440 GOTO 100
L440:
        READ  IMM, L100
        WRITE JMP
; 500 REM ----- S1 + S2 : 交互に点滅 -----
L500:
; 510 $L = 0b101010 : GOSUB 900
L510:
        READ  IMM, 42
        WRITE $L
        READ  IMM, _R8
        WRITE $5              ; もどる場所をおぼえる
        READ  IMM, L900
        WRITE JMP
_R8:
; 520 $L = 0b010101 : GOSUB 900
L520:
        READ  IMM, 21
        WRITE $L
        READ  IMM, _R9
        WRITE $5              ; もどる場所をおぼえる
        READ  IMM, L900
        WRITE JMP
_R9:
; 530 GOTO 100
L530:
        READ  IMM, L100
        WRITE JMP
; 900 REM ----- $L を光らせて 0.5秒 待つ -----
L900:
; 910 OUT $L
L910:
        READ  $L
        WRITE OUT
; 920 WAIT 50
L920:
        READ  IMM, 50
        WRITE $4
_W10:
        READ  $4
        WRITE ALU_A
        READ  IMM, _E11
        WRITE JZ              ; 0 なら待ちおわり
        READ  IMM, 1
        WRITE ALU_B
        READ  ALU_SUB
        WRITE $4
        READ  IMM, _W10
        WRITE JMP
_E11:
; 930 IF IN <> $M THEN GOTO 100
L930:
        READ  IN
        WRITE ALU_A
        READ  $M
        WRITE ALU_B
        READ  ALU_SUB
        WRITE ALU_A           ; ALU_A = 左 - 右
        READ  IMM, _S12
        WRITE JZ              ; おなじなら とばす
        READ  IMM, L100
        WRITE JMP             ; ちがうから ジャンプ
_S12:
; 940 RETURN
L940:
        READ  $5
        WRITE JMP             ; おぼえた場所へもどる
; ---- プログラムのおわり ----
_END:
        READ  IMM, _END
        WRITE JMP             ; おわり (ここで足ぶみ)
