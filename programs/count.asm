; ============================================================
;  LED で 2進数カウンター : 0, 1, 2, 3 ... と 0.5秒ごとにふえる
; ============================================================
        .equ  WAITN 80      ; 待ち時間 (約0.5秒)

START:  READ  IMM, 0
        WRITE $C            ; $C = 0
LOOP:   READ  $C
        WRITE OUT           ; LED = $C
        WRITE ALU_A         ; ALU_A = $C
        READ  IMM, 1
        WRITE ALU_B         ; ALU_B = 1
        READ  ALU_ADD
        WRITE $C            ; $C = $C + 1
        READ  IMM, WAITN
        WRITE ALU_A         ; ALU_A = 待つ回数
WAIT:   READ  ALU_SUB
        WRITE ALU_A         ; ALU_A = ALU_A - 1
        READ  IMM, LOOP
        WRITE JZ            ; 0 になったら LOOP へ
        READ  IMM, WAIT
        WRITE JMP           ; まだなら WAIT へ
