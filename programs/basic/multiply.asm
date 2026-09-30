; ==== TinyBASIC改 から つくった プログラム ====
; 10 REM ===== かけ算 6 x 7 (たし算のくりかえし) =====
L10:
; 20 $A = 6 : $B = 7 : $C = 0
L20:
        READ  IMM, 6
        WRITE $A
        READ  IMM, 7
        WRITE $B
        READ  IMM, 0
        WRITE $C
; 30 IF $B = 0 THEN GOTO 70
L30:
        READ  $B
        WRITE ALU_A
        READ  IMM, L70
        WRITE JZ              ; おなじなら ジャンプ
; 40 $C = $C + $A
L40:
        READ  $C
        WRITE ALU_A
        READ  $A
        WRITE ALU_B
        READ  ALU_ADD
        WRITE $C
; 50 $B = $B - 1
L50:
        READ  $B
        WRITE ALU_A
        READ  IMM, 1
        WRITE ALU_B
        READ  ALU_SUB
        WRITE $B
; 60 GOTO 30
L60:
        READ  IMM, L30
        WRITE JMP
; 70 OUT $C
L70:
        READ  $C
        WRITE OUT
; 80 END
L80:
_H1:
        READ  IMM, _H1
        WRITE JMP             ; おわり (ここで足ぶみ)
; ---- プログラムのおわり ----
_END:
        READ  IMM, _END
        WRITE JMP             ; おわり (ここで足ぶみ)
