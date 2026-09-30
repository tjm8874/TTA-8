// ============================================================
//  TTA-8 アセンブラ (ブラウザでも Node.js でも動く)
//
//  書き方:
//    ; コメント
//    LABEL:            ラベル
//    READ  名前        (名前 = ALU_A ALU_B ALU_ADD ALU_NAND ALU_SUB IN 変数)
//    WRITE 名前        (名前 = ALU_A ALU_B JMP JZ OUT 変数)
//    READ  IMM, 値     定数を V に入れる (値 = 数 / ラベル)
//    変数              $A-$Z, $0-$5 (RAM 0x20-0x3F, 全部で32個)
//    .equ  名前 値     名前に数をつける
//
//  使い方 (Node):  node tta8asm.js prog.asm  -> prog.hex / prog.lst
// ============================================================
(function (root) {
  'use strict';

  const PORTS = {
    ALU_A: 0x00, ALU_B: 0x01, ALU_ADD: 0x02, ALU_NAND: 0x03, ALU_SUB: 0x04,
    JMP: 0x10, JZ: 0x11, IMM: 0x12,
    IN: 0x7e, OUT: 0x7f,
  };
  // 変数: $A-$Z = 0x20-0x39, $0-$5 = 0x3A-0x3F
  'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345'.split('').forEach((c, i) => {
    PORTS['$' + c] = 0x20 + i;
  });

  function parseNum(s) {
    if (/^0x[0-9a-f]+$/i.test(s)) return parseInt(s, 16);
    if (/^0b[01]+$/i.test(s)) return parseInt(s.slice(2), 2);
    if (/^-?\d+$/.test(s)) return parseInt(s, 10);
    return null;
  }

  function assemble(src) {
    const syms = Object.assign({}, PORTS);
    const lines = src.split(/\r?\n/);
    const items = [];            // {line, op, arg, imm, addr}
    const errors = [];
    const labels = {};           // rom 番地 -> [ラベル名]
    let pc = 0;

    // ---- 1回目: ラベルと変数の場所を決める ----
    lines.forEach((raw, i) => {
      const line = raw.replace(/;.*$/, '').trim();
      const cm = raw.match(/;\s*(.*)$/);
      const comment = cm ? cm[1].trim() : '';
      if (!line) return;
      let rest = line;
      const m = rest.match(/^([A-Za-z_]\w*):\s*(.*)$/);
      if (m) {
        syms[m[1].toUpperCase()] = pc; rest = m[2];
        (labels[pc] = labels[pc] || []).push(m[1].toUpperCase());
      }
      if (!rest) return;
      const t = rest.split(/[\s,]+/).filter(Boolean);
      const op = t[0].toUpperCase();
      if (op === '.EQU') {
        syms[t[1].toUpperCase()] = t[2];   // あとで解決
      } else if (op === 'READ' || op === 'WRITE') {
        const arg = (t[1] || '').toUpperCase();
        const it = { line: i + 1, src: raw, op, arg, addr: pc, comment };
        if (op === 'READ' && arg === 'IMM') { it.imm = t[2]; pc += 2; }
        else pc += 1;
        items.push(it);
      } else {
        errors.push(`${i + 1}: わからない命令 "${t[0]}"`);
      }
    });

    function value(s, line) {
      if (s === undefined) { errors.push(`${line}: 値がない`); return 0; }
      let n = parseNum(s);
      if (n !== null) return n & 0xff;
      let v = syms[s.toUpperCase()];
      if (typeof v === 'string') v = value(v, line);
      if (v === undefined) { errors.push(`${line}: "${s}" が見つからない`); return 0; }
      return v & 0xff;
    }

    // ---- 2回目: 機械語にする ----
    const rom = new Array(256).fill(0);
    const map = [];              // rom 番地 -> ソース行
    for (const it of items) {
      const a = value(it.arg, it.line);
      if (a > 0x7f) errors.push(`${it.line}: アドレスが 0x7F をこえている`);
      const code = (it.op === 'WRITE' ? 0x80 : 0) | (a & 0x7f);
      rom[it.addr] = code; map[it.addr] = it.line; it.port = a & 0x7f;
      it.bytes = [code];
      if (it.imm !== undefined) {
        const v = value(it.imm, it.line);
        rom[it.addr + 1] = v; it.bytes.push(v); it.value = v;
      }
    }
    if (pc > 256) errors.push(`プログラムが 256 バイトをこえた (${pc})`);

    const hex2 = (n) => n.toString(16).toUpperCase().padStart(2, '0');
    const hex = rom.map(hex2).join('\n') + '\n';
    const lst = items.map(it =>
      `${hex2(it.addr)}: ${it.bytes.map(hex2).join(' ').padEnd(6)}  ${it.src.trim()}`
    ).join('\n') + `\n; size = ${pc} bytes\n`;

    return { rom, hex, lst, size: pc, symbols: syms, lineOf: map, items, labels, errors };
  }

  const api = { assemble, PORTS };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.TTA8ASM = api;

  // ---- Node から直接呼ばれたとき ----
  if (typeof require !== 'undefined' && typeof module !== 'undefined' && require.main === module) {
    const fs = require('fs'), path = require('path');
    const file = process.argv[2];
    if (!file) { console.log('usage: node tta8asm.js prog.asm'); process.exit(1); }
    const r = assemble(fs.readFileSync(file, 'utf8'));
    if (r.errors.length) { r.errors.forEach(e => console.error('ERROR ' + e)); process.exit(1); }
    const base = file.replace(/\.asm$/i, '');
    fs.writeFileSync(base + '.hex', r.hex);
    fs.writeFileSync(base + '.lst', r.lst);
    console.log(`${path.basename(file)}: ${r.size} bytes -> ${path.basename(base)}.hex`);
  }
})(this);
