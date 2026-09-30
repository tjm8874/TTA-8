// TinyBASIC改 コンパイラのテスト:  node tools/test.js
'use strict';
const ASM = require('./tta8asm.js');
const TB = require('./tbasic.js');
const SIM = require('./tta8sim.js');

let pass = 0, fail = 0;
function ok(cond, name, extra) {
  if (cond) pass++; else { fail++; console.log('NG  ' + name + (extra ? '  ' + extra : '')); }
}
const VAR = (c) => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345'.indexOf(c);

// プログラムを動かす: _END に来るか limit 命令で止まる
function run(src, limit = 20000, btn = 0) {
  const r = TB.build(src, ASM);
  if (r.errors.length) return { errors: r.errors };
  const cpu = SIM.create(); cpu.btn = btn;
  const end = r.symbols._END;
  let n = 0;
  while (n < limit && cpu.pc !== end) { SIM.step(cpu, r.rom); n++; }
  return { cpu, steps: n, r, v: (c) => cpu.ram[VAR(c)] };
}

// ---- 式 ----
let t = run('10 $A = 200 + 100\n20 $B = 5 - 7\n30 $C = 12 AND 10\n40 $D = 12 OR 10\n50 $E = 12 NAND 10\n60 $F = 1 + 2 + 3 - 1');
ok(t.v('A') === 44, '200+100 = 44 (256 をこえる)', t.v('A'));
ok(t.v('B') === 254, '5-7 = 254', t.v('B'));
ok(t.v('C') === 8, '12 AND 10 = 8', t.v('C'));
ok(t.v('D') === 14, '12 OR 10 = 14', t.v('D'));
ok(t.v('E') === 247, '12 NAND 10 = 247', t.v('E'));
ok(t.v('F') === 5, '1+2+3-1 = 5', t.v('F'));

t = run('10 $A = 0x20 + 0b11\n20 $B = PEEK(32)\n30 POKE 34, 99\n40 LET $Z = $A + $B');
ok(t.v('A') === 35 && t.v('B') === 35, '16進・2進・PEEK');
ok(t.v('C') === 99, 'POKE で変数に書く');
ok(t.v('Z') === 70, 'LET');

// ---- OUT / IN ----
t = run('10 OUT 0b101010', 100);
ok(t.cpu.led === 42, 'OUT で LED');
t = run('10 $A = IN\n20 OUT IN', 100, 3);
ok(t.v('A') === 3 && t.cpu.led === 3, 'IN を読む');

// ---- IF ----
t = run('10 $A = 5\n20 IF $A = 5 THEN GOTO 50\n30 $B = 1\n50 $C = 1\n60 IF $A <> 5 THEN GOTO 80\n70 $D = 1\n80 END');
ok(t.v('B') === 0 && t.v('C') === 1 && t.v('D') === 1, 'IF = / <> と GOTO');
t = run('10 $A = 3\n20 IF $A = 3 THEN $B = 7 : $C = 8\n30 IF $A = 4 THEN $D = 9 : $E = 9\n40 IF $A <> 4 THEN $F = 1 : $G = 2\n50 IF $A <> 3 THEN $H = 5');
ok(t.v('B') === 7 && t.v('C') === 8, 'THEN のあとに 文 (真)');
ok(t.v('D') === 0 && t.v('E') === 0, 'THEN のあとに 文 (偽は : のあとも とばす)');
ok(t.v('F') === 1 && t.v('G') === 2 && t.v('H') === 0, 'IF <> THEN 文');
t = run('10 $A = 0\n20 IF $A = 0 THEN 40\n30 $B = 1\n40 IF $A + 2 = 2 THEN $C = 1');
ok(t.v('B') === 0 && t.v('C') === 1, 'THEN 行番号 / 左がわが式 / 右が 0');
t = run('10 $A = 1\n20 IF $A = 1 THEN IF $A <> 2 THEN $B = 5 : $C = 6\n30 $D = 1');
ok(t.v('B') === 5 && t.v('C') === 6 && t.v('D') === 1, 'IF の中の IF');

// ---- くりかえし ----
t = run('10 $I = 0 : $S = 0\n20 $S = $S + $I\n30 $I = $I + 1\n40 IF $I <> 11 THEN GOTO 20');
ok(t.v('S') === 55, '1〜10 のたし算 = 55', t.v('S'));
t = run('10 $A = 6 : $B = 7 : $C = 0\n20 IF $B = 0 THEN GOTO 60\n30 $C = $C + $A\n40 $B = $B - 1\n50 GOTO 20\n60 END');
ok(t.v('C') === 42, 'かけ算 6x7 = 42', t.v('C'));

// ---- GOSUB / RETURN ----
t = run('10 $A = 1\n20 GOSUB 100\n30 GOSUB 100\n40 END\n100 $A = $A + $A\n110 RETURN');
ok(t.v('A') === 4, 'GOSUB 2回', t.v('A'));

// ---- WAIT : 1 = 10命令 = 0.01秒 ----
const w0 = run('10 WAIT 0').steps, w1 = run('10 WAIT 1').steps, w50 = run('10 WAIT 50').steps;
ok(w1 - w0 === 10, 'WAIT 1 = 10命令', `${w1 - w0}`);
ok(w50 - w0 === 500, 'WAIT 50 = 500命令 (0.5秒)', `${w50 - w0}`);

// ---- END ----
t = run('10 $A = 1\n20 END\n30 $A = 2', 1000);
ok(t.v('A') === 1 && t.steps === 1000, 'END で止まる');

// ---- エラー ----
const e = (src) => TB.build(src, ASM).errors.join(' / ');
ok(/\$Q9|変数はない/.test(e('10 $a = 1\n20 $@ = 2')), '変な変数はエラー');
ok(/THEN/.test(e('10 IF 1 = 1 GOTO 10')), 'THEN がない');
ok(/99行 は ないよ/.test(e('10 GOTO 99')), 'ない行へ GOTO');
ok(/行番号/.test(e('PRINT 1')), '行番号がない');
ok(/大きくして/.test(e('20 END\n10 END')), '行番号の順番');
ok(/256|大きすぎる/.test(e('10 $A = 300')), '256 以上の数');
ok(/\$5/.test(e('10 $5 = 1\n20 GOSUB 30\n30 RETURN')), '$5 と GOSUB がぶつかる');
ok(/わからない命令/.test(e('10 PRINT 1')), 'わからない命令');
ok(e('10 REM : PRINT は コメント') === '', 'REM のあとは全部コメント');

console.log(`\n${pass} ok, ${fail} ng`);
process.exit(fail ? 1 : 0);
