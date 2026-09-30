; ==== TinyBASIC改 から つくった プログラム ====
; 10 REM ===== LED で 2進数カウンター =====
L10:
; 20 $C = 0
L20:
        READ  IMM, 0
        WRITE $C
; 30 OUT $C
L30:
        READ  $C
        WRITE OUT
; 40 WAIT 50
L40:
        READ  IMM, 50
        WRITE $4
_W1:
        READ  $4
        WRITE ALU_A
        READ  IMM, _E2
        WRITE JZ              ; 0 なら待ちおわり
        READ  IMM, 1
        WRITE ALU_B
        READ  ALU_SUB
        WRITE $4
        READ  IMM, _W1
        WRITE JMP
_E2:
; 50 $C = $C + 1
L50:
        READ  $C
        WRITE ALU_A
        READ  IMM, 1
        WRITE ALU_B
        READ  ALU_ADD
        WRITE $C
; 60 GOTO 30
L60:
        READ  IMM, L30
        WRITE JMP
; ---- プログラムのおわり ----
_END:
        READ  IMM, _END
        WRITE JMP             ; おわり (ここで足ぶみ)
