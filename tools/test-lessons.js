// 新しい教材例と、ラボ側のリセット仕様を検証する。
'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const ASM = require('./tta8asm');
const TB = require('./tbasic');
const SIM = require('./tta8sim');
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'programs/basic/divide.bas'), 'utf8');
const lesson = fs.readFileSync(path.join(root, 'docs/guide/11_calculation.md'), 'utf8');
assert.strictEqual(lesson.match(/```basic\n([\s\S]*?)```/)[1].trim(), source.trim());
let cases = 0;
for (const n of [0, 1, 3, 17, 20, 127, 254, 255]) {
  for (const d of [0, 1, 2, 5, 127, 255]) {
    const src = source.replace('$N = 17 : $D = 5', `$N = ${n} : $D = ${d}`);
    const result = TB.build(src, ASM);
    assert.deepStrictEqual(result.errors, []);
    assert(result.size <= 256);
    const c = SIM.create();
    for (let i = 0; i < 10000; i++) SIM.step(c, result.rom);
    const get = x => c.ram[x.charCodeAt(0) - 65];
    assert.strictEqual(get('E'), d === 0 ? 1 : 0);
    assert.strictEqual(get('Q'), d === 0 ? 0 : Math.floor(n / d));
    assert.strictEqual(get('R'), d === 0 ? 0 : n % d);
    cases++;
  }
}
const c = SIM.create();
assert(c.ram.every(x => x === 0));
c.ram.fill(255); c.pc = 99; c.v = 22; c.a = 33; c.b = 44; c.led = 55;
SIM.reset(c);
assert(c.ram.every(x => x === 0));
for (const name of ['pc', 'v', 'a', 'b', 'led']) assert.strictEqual(c[name], 0);
// NAND だけで AND を作る教材コードも実行する。
const nandExample = [...lesson.matchAll(/```basic\n([\s\S]*?)```/g)][1][1];
const nand = TB.build(nandExample, ASM);
assert.deepStrictEqual(nand.errors, []);
for(let i = 0; i < 100; i++) SIM.step(c, nand.rom);
assert.strictEqual(c.led, 8);
console.log(`PASS: ${cases} division cases, lesson/source match, RAM reset, NAND lesson`);
