; ==== TinyBASIC改 から つくった プログラム ====
; 10 REM ===== はじめての たし算 =====
L10:
; 20 $A = 3
L20:
        READ  IMM, 3
        WRITE $A
; 30 $B = 5
L30:
        READ  IMM, 5
        WRITE $B
; 40 $C = $A + $B
L40:
        READ  $A
        WRITE ALU_A
        READ  $B
        WRITE ALU_B
        READ  ALU_ADD
        WRITE $C
; 50 OUT $C
L50:
        READ  $C
        WRITE OUT
; 60 END
L60:
_H1:
        READ  IMM, _H1
        WRITE JMP             ; おわり (ここで足ぶみ)
; ---- プログラムのおわり ----
_END:
        READ  IMM, _END
        WRITE JMP             ; おわり (ここで足ぶみ)
