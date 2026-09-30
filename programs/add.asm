; ============================================================
;  はじめてのプログラム : 3 + 5 を計算して LED に出す
;  LED は 2進数で 8 = 001000 と光る
; ============================================================
START:  READ  IMM, 3
        WRITE ALU_A         ; ALU_A = 3
        READ  IMM, 5
        WRITE ALU_B         ; ALU_B = 5
        READ  ALU_ADD       ; V = 3 + 5
        WRITE OUT           ; LED に出す
        WRITE $A            ; 変数 $A にもしまう
STOP:   READ  IMM, STOP
        WRITE JMP           ; ここでずっと足ぶみ
