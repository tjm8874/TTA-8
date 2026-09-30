# 7. アセンブリで 書いてみよう

BASIC は 便利ですが、CPU が ほんとうに やっているのは **READ と WRITE だけ** です。
その 命令を 直接 書く ことばを **アセンブリ** と いいます。
TTA-8 ラボの **アセンブリ** タブで 書けます。

## 書きかた

```asm
; セミコロンの あとは メモ
LABEL:  READ  名前          ; 名前の 部品から V へ
        WRITE 名前          ; V から 名前の 部品へ
        READ  IMM, 数       ; 数を そのまま V へ（2バイト 命令）
        READ  IMM, LABEL    ; LABEL の 番地を V へ（ジャンプ先に 使う）
```

| READ できる 名前 | WRITE できる 名前 |
|---|---|
| `ALU_A` `ALU_B` `ALU_ADD` `ALU_NAND` `ALU_SUB` `IN` `IMM` 変数 | `ALU_A` `ALU_B` `JMP` `JZ` `OUT` 変数 |

変数は `$A`〜`$Z`、`$0`〜`$5` です。

## ジャンプの しかた

ジャンプは「**行き先の 番地を V に 入れて、JMP に 書く**」の 2命令です。

```asm
        READ  IMM, LOOP     ; V = LOOP の 番地
        WRITE JMP           ; PC = V → LOOP へ ジャンプ！
```

**もし 0 なら ジャンプ** は、先に ALU_A に 調べたい 数を 入れておいて、JZ に 書きます。

```asm
        READ  $N
        WRITE ALU_A         ; ALU_A = $N
        READ  IMM, DONE
        WRITE JZ            ; ALU_A が 0 なら DONE へ。0 でなければ 次の 行へ
```

## れんしゅう：5 から 0 まで カウントダウン

```asm
; 5 から 0 まで 数えて LED に出す
        READ  IMM, 5
        WRITE $N            ; $N = 5
LOOP:   READ  $N
        WRITE OUT           ; LED に $N を出す
        WRITE ALU_A         ; ALU_A = $N
        READ  IMM, DONE
        WRITE JZ            ; ALU_A が 0 なら DONE へ
        READ  IMM, 1
        WRITE ALU_B         ; ALU_B = 1
        READ  ALU_SUB       ; V = $N - 1
        WRITE $N            ; $N = V
        READ  IMM, LOOP
        WRITE JMP           ; LOOP へ もどる
DONE:   READ  IMM, DONE
        WRITE JMP           ; ずっと 足ぶみ
```

TTA-8 ラボに 貼りつけて **くみたてる** → **かめ** の 速さで スタート。
LED が 5（`000101`）→ 4 → 3 → 2 → 1 → 0 と 変わって 止まれば 成功です。

> **ポイント**：`WRITE OUT` の あと、V の 中身は 変わらないので、
> そのまま `WRITE ALU_A` できます。V を じょうずに 使いまわすのが アセンブリの コツです。

## チャレンジ

1. 0 から 5 まで **数え上げる** ように 書きかえよう（ヒント：ALU_ADD と、5 を ひいて 0 か 調べる）
2. BASIC で 書いた `$C = $A + $B` が どんな アセンブリに なるか、TTA-8 ラボの アセンブリ タブで 見てみよう
3. `ALU_NAND` だけで `AND` を 作れるかな？（ヒント：NAND を 2回）

---
[← 6. TinyBASIC改 で プログラムを 書こう](06_basic.md)　|　[つぎへ → 8. CPU の 設計図を 読もう](08_verilog.md)
