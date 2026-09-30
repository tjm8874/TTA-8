; ============================================================
;  LED フラッシャー (Tang Nano 20K)
;    なにも押さない : 右はしの LED が点滅
;    S1             : 光が右から左へ流れる
;    S2             : 外側から内側へ
;    S1 + S2        : 交互に点滅
;  CPU は 1秒に 1000命令。1つの模様を約 0.5秒 見せる。
; ============================================================
; 変数  $M = いま押されているボタン
;       $L = 次に光らせる LED
;       $R = STEP から戻る場所
        .equ  WAITN 80      ; 待ち時間 (80回 x 6命令 = 約0.5秒)

; ---- ボタンを見て、どの模様にするか決める ------------------
MAIN:   READ  IN
        WRITE $M            ; $M = ボタン
        WRITE ALU_A         ; ALU_A = ボタン
        READ  IMM, IDLE
        WRITE JZ            ; 0 なら IDLE へ
        READ  IMM, 1
        WRITE ALU_B         ; ALU_B = 1
        READ  ALU_SUB
        WRITE ALU_A         ; ALU_A = ALU_A - 1
        READ  IMM, MODE1
        WRITE JZ            ; 1 (S1) なら MODE1 へ
        READ  ALU_SUB
        WRITE ALU_A         ; ALU_A = ALU_A - 1
        READ  IMM, MODE2
        WRITE JZ            ; 2 (S2) なら MODE2 へ
        READ  IMM, MODE3
        WRITE JMP           ; のこりは 3 (S1+S2)

; ---- なにも押していない : 000001 / 000000 --------------------
IDLE:   READ  IMM, 0b000001
        WRITE $L
        READ  IMM, I1
        WRITE $R
        READ  IMM, STEP
        WRITE JMP
I1:     READ  IMM, 0b000000
        WRITE $L
        READ  IMM, MAIN
        WRITE $R
        READ  IMM, STEP
        WRITE JMP

; ---- S1 : 右から左へ -----------------------------------------
MODE1:  READ  IMM, 0b000001
        WRITE $L
        READ  IMM, A1
        WRITE $R
        READ  IMM, STEP
        WRITE JMP
A1:     READ  IMM, 0b000010
        WRITE $L
        READ  IMM, A2
        WRITE $R
        READ  IMM, STEP
        WRITE JMP
A2:     READ  IMM, 0b000100
        WRITE $L
        READ  IMM, A3
        WRITE $R
        READ  IMM, STEP
        WRITE JMP
A3:     READ  IMM, 0b001000
        WRITE $L
        READ  IMM, A4
        WRITE $R
        READ  IMM, STEP
        WRITE JMP
A4:     READ  IMM, 0b010000
        WRITE $L
        READ  IMM, A5
        WRITE $R
        READ  IMM, STEP
        WRITE JMP
A5:     READ  IMM, 0b100000
        WRITE $L
        READ  IMM, MAIN
        WRITE $R
        READ  IMM, STEP
        WRITE JMP

; ---- S2 : 外側から内側へ -------------------------------------
MODE2:  READ  IMM, 0b100001
        WRITE $L
        READ  IMM, B1
        WRITE $R
        READ  IMM, STEP
        WRITE JMP
B1:     READ  IMM, 0b010010
        WRITE $L
        READ  IMM, B2
        WRITE $R
        READ  IMM, STEP
        WRITE JMP
B2:     READ  IMM, 0b001100
        WRITE $L
        READ  IMM, MAIN
        WRITE $R
        READ  IMM, STEP
        WRITE JMP

; ---- S1 + S2 : 交互に点滅 ------------------------------------
MODE3:  READ  IMM, 0b101010
        WRITE $L
        READ  IMM, C1
        WRITE $R
        READ  IMM, STEP
        WRITE JMP
C1:     READ  IMM, 0b010101
        WRITE $L
        READ  IMM, MAIN
        WRITE $R
        READ  IMM, STEP
        WRITE JMP

; ============================================================
;  STEP : L を光らせて 0.5秒 待つ。
;         ボタンが変わっていたら MAIN へ、同じなら R へ戻る。
; ============================================================
STEP:   READ  $L
        WRITE OUT           ; LED = $L
        READ  IMM, WAITN
        WRITE ALU_A         ; ALU_A = 待つ回数
        READ  IMM, 1
        WRITE ALU_B         ; ALU_B = 1
WLOOP:  READ  ALU_SUB
        WRITE ALU_A         ; ALU_A = ALU_A - 1
        READ  IMM, WDONE
        WRITE JZ            ; 0 になったら おわり
        READ  IMM, WLOOP
        WRITE JMP           ; まだなら くりかえし
WDONE:  READ  IN
        WRITE ALU_A         ; ALU_A = いまのボタン
        READ  $M
        WRITE ALU_B         ; ALU_B = さっきのボタン
        READ  ALU_SUB
        WRITE ALU_A         ; ALU_A = ALU_A - ALU_B
        READ  IMM, BACK
        WRITE JZ            ; 同じなら BACK へ
        READ  IMM, MAIN
        WRITE JMP           ; 変わったら MAIN へ
BACK:   READ  $R
        WRITE JMP           ; $R の場所へ戻る
