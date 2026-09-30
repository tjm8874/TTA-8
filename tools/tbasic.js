// ============================================================
//  TinyBASIC改 コンパイラ  (TinyBASIC改 -> TTA-8 アセンブリ)
//  ブラウザでも Node.js でも動く
//
//  使い方 (Node):  node tbasic.js prog.bas  -> prog.asm / prog.hex / prog.lst
//
//  文法 (くわしくは docs/tinybasic.md)
//    10 REM コメント
//    20 $A = 式              (LET $A = 式 でもよい)
//    30 OUT 式               LED に出す
//    40 POKE 番地, 式        番地に書く (番地は数だけ)
//    50 IF 式 = 式 THEN GOTO 行   (<> も使える。THEN のあとに文も書ける)
//    60 GOTO 行 / GOSUB 行 / RETURN
//    70 WAIT 式              式 x 0.01秒 待つ
//    80 END                  おわり
//    式 : 項 [ (+ | - | AND | OR | NAND) 項 ] ...
//    項 : 数(0-255, 0b.., 0x..) | $A-$Z $0-$5 | IN | PEEK(番地)
// ============================================================
(function (root) {
  'use strict';

  const VARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345'.split('').map(c => '$' + c);
  const TMP = '$3', WCNT = '$4', RET = '$5';        // コンパイラが使う変数
  const TOKEN = /\s*(\$[A-Za-z0-9]|0x[0-9A-Fa-f]+|0b[01]+|\d+|<>|[=+\-,():]|[A-Za-z_]+|\S)/y;

  function tokenize(s) {
    const out = [];
    TOKEN.lastIndex = 0;
    let m;
    while (TOKEN.lastIndex < s.length && (m = TOKEN.exec(s))) {
      if (m[1] === undefined) break;
      out.push(/^[A-Za-z_$]/.test(m[1]) ? m[1].toUpperCase() : m[1]);
    }
    return out;
  }

  function compile(src) {
    const errors = [];
    const lines = [];                               // {no, text, srcLine}
    src.split(/\r?\n/).forEach((raw, i) => {
      if (!raw.trim()) return;
      const m = raw.match(/^\s*(\d+)\s*(.*)$/);
      if (!m) { errors.push(`${i + 1}ぎょう目: 行番号 (10, 20 など) で はじめてね`); return; }
      const no = parseInt(m[1], 10);
      if (lines.length && no <= lines[lines.length - 1].no)
        errors.push(`${no}行: 行番号は 前の行 (${lines[lines.length - 1].no}) より大きくしてね`);
      lines.push({ no, text: m[2].trim(), srcLine: i + 1 });
    });
    const lineSet = new Set(lines.map(l => l.no));

    const asm = [];                                 // アセンブリの行
    const basicOf = [];                             // アセンブリの行番号(1-) -> BASIC 行番号
    let cur = null, uid = 0;
    const used = { tmp: false, wait: false, gosub: false };
    const userVars = new Set();
    const emit = (text, basic = cur) => { asm.push(text); basicOf[asm.length] = basic; };
    const ins = (op, arg, cmt) => emit(`        ${op.padEnd(6)}${cmt ? arg.padEnd(16) + '; ' + cmt : arg}`);
    const label = (l) => emit(`${l}:`);
    const newLabel = (k) => `_${k}${++uid}`;
    const err = (msg) => errors.push(`${cur}行: ${msg}`);

    // ---- 項と式 -------------------------------------------------
    function num(tok) {
      let n = null;
      if (/^0x/i.test(tok)) n = parseInt(tok.slice(2), 16);
      else if (/^0b/i.test(tok)) n = parseInt(tok.slice(2), 2);
      else if (/^\d+$/.test(tok)) n = parseInt(tok, 10);
      return n;
    }
    function parseTerm(ts) {
      const t = ts.shift();
      if (t === undefined) { err('式が とちゅうで おわっているよ'); return { k: 'num', v: 0 }; }
      const n = num(t);
      if (n !== null) {
        if (n > 255) err(`${t} は 大きすぎるよ (0〜255)`);
        return { k: 'num', v: n & 255 };
      }
      if (/^\$/.test(t)) {
        if (!VARS.includes(t)) err(`${t} という変数はないよ ($A〜$Z, $0〜$5)`);
        userVars.add(t);
        return { k: 'var', v: t };
      }
      if (t === 'IN') return { k: 'in' };
      if (t === 'PEEK') {
        if (ts.shift() !== '(') err('PEEK のあとは ( だよ');
        const a = num(ts.shift() || '');
        if (a === null || a > 127) err('PEEK の番地は 0〜127 の数だけ使えるよ');
        if (ts.shift() !== ')') err('PEEK の ) がないよ');
        return { k: 'peek', v: a || 0 };
      }
      err(`「${t}」は 式の中では使えないよ`);
      return { k: 'num', v: 0 };
    }
    const OPS = ['+', '-', 'AND', 'OR', 'NAND'];
    function parseExpr(ts) {
      const e = { first: parseTerm(ts), rest: [] };
      while (OPS.includes(ts[0])) e.rest.push({ op: ts.shift(), t: parseTerm(ts) });
      return e;
    }
    function loadV(t) {                              // 項を V に入れる
      switch (t.k) {
        case 'num':  ins('READ', `IMM, ${t.v}`); break;
        case 'var':  ins('READ', t.v); break;
        case 'in':   ins('READ', 'IN'); break;
        case 'peek': ins('READ', `0x${t.v.toString(16).toUpperCase()}`); break;
      }
    }
    function genExpr(e) {                            // 式の答えを V に入れる
      loadV(e.first);
      for (const { op, t } of e.rest) {
        ins('WRITE', 'ALU_A');
        if (op === 'OR') {                           // a OR b = NAND(~a, ~b)
          used.tmp = true;
          ins('READ', 'IMM, 255'); ins('WRITE', 'ALU_B');
          ins('READ', 'ALU_NAND', '~a (a の反対)'); ins('WRITE', TMP);
          loadV(t); ins('WRITE', 'ALU_A');
          ins('READ', 'ALU_NAND', '~b (b の反対)'); ins('WRITE', 'ALU_B');
          ins('READ', TMP); ins('WRITE', 'ALU_A');
          ins('READ', 'ALU_NAND', 'a OR b');
          continue;
        }
        loadV(t); ins('WRITE', 'ALU_B');
        if (op === '+') ins('READ', 'ALU_ADD');
        else if (op === '-') ins('READ', 'ALU_SUB');
        else if (op === 'NAND') ins('READ', 'ALU_NAND');
        else if (op === 'AND') {                     // a AND b = ~NAND(a, b)
          ins('READ', 'ALU_NAND'); ins('WRITE', 'ALU_A');
          ins('READ', 'IMM, 255'); ins('WRITE', 'ALU_B');
          ins('READ', 'ALU_NAND', 'a AND b');
        }
      }
    }
    const lineLabel = (n) => {
      if (!lineSet.has(n)) err(`${n}行 は ないよ`);
      return `L${n}`;
    };
    function parseLineNo(ts) {
      const n = num(ts.shift() || '');
      if (n === null) { err('行番号を書いてね'); return 'L0'; }
      return lineLabel(n);
    }

    // ---- 文 -----------------------------------------------------
    // ts = トークン列。IF は同じ行ののこりを全部 THEN の中身にする。
    function stmt(ts, restStmts) {
      const t = ts.shift();
      if (t === undefined) return;
      if (t === 'REM') return;
      if (t === 'LET') return stmt(ts, restStmts);
      if (/^\$/.test(t)) {
        if (!VARS.includes(t)) return err(`${t} という変数はないよ`);
        userVars.add(t);
        if (ts.shift() !== '=') return err(`${t} のあとは = だよ`);
        genExpr(parseExpr(ts)); ins('WRITE', t);
      } else if (t === 'OUT') {
        genExpr(parseExpr(ts)); ins('WRITE', 'OUT');
      } else if (t === 'POKE') {
        const a = num(ts.shift() || '');
        if (a === null || a > 127) return err('POKE の番地は 0〜127 の数だけ使えるよ');
        if (ts.shift() !== ',') return err('POKE 番地, 式 のように , で区切ってね');
        genExpr(parseExpr(ts)); ins('WRITE', `0x${a.toString(16).toUpperCase()}`);
      } else if (t === 'GOTO') {
        ins('READ', `IMM, ${parseLineNo(ts)}`); ins('WRITE', 'JMP');
      } else if (t === 'GOSUB') {
        used.gosub = true;
        const target = parseLineNo(ts), back = newLabel('R');
        ins('READ', `IMM, ${back}`); ins('WRITE', RET, 'もどる場所をおぼえる');
        ins('READ', `IMM, ${target}`); ins('WRITE', 'JMP');
        label(back);
      } else if (t === 'RETURN') {
        used.gosub = true;
        ins('READ', RET); ins('WRITE', 'JMP', 'おぼえた場所へもどる');
      } else if (t === 'WAIT') {
        used.wait = true;
        const lp = newLabel('W'), done = newLabel('E');
        genExpr(parseExpr(ts)); ins('WRITE', WCNT);
        label(lp);                                   // 1回 = 10命令 = 0.01秒
        ins('READ', WCNT); ins('WRITE', 'ALU_A');
        ins('READ', `IMM, ${done}`); ins('WRITE', 'JZ', '0 なら待ちおわり');
        ins('READ', 'IMM, 1'); ins('WRITE', 'ALU_B');
        ins('READ', 'ALU_SUB'); ins('WRITE', WCNT);
        ins('READ', `IMM, ${lp}`); ins('WRITE', 'JMP');
        label(done);
      } else if (t === 'END') {
        const here = newLabel('H');
        label(here); ins('READ', `IMM, ${here}`); ins('WRITE', 'JMP', 'おわり (ここで足ぶみ)');
      } else if (t === 'IF') {
        const cmp = ts.indexOf('=') >= 0 && (ts.indexOf('<>') < 0 || ts.indexOf('=') < ts.indexOf('<>')) ? '=' : '<>';
        const at = ts.indexOf(cmp);
        const th = ts.indexOf('THEN');
        if (at < 0) return err('IF には = か <> がいるよ');
        if (th < 0) return err('IF には THEN がいるよ');
        const left = parseExpr(ts.slice(0, at));
        const rightTs = ts.slice(at + 1, th);
        const right = parseTerm(rightTs);
        if (rightTs.length) err('IF の右がわは 数か変数 1つにしてね');
        const body = ts.slice(th + 1);
        // ALU_A = 左 - 右  (0 なら「おなじ」)
        genExpr(left); ins('WRITE', 'ALU_A');
        if (!(right.k === 'num' && right.v === 0)) {
          loadV(right); ins('WRITE', 'ALU_B');
          ins('READ', 'ALU_SUB'); ins('WRITE', 'ALU_A', 'ALU_A = 左 - 右');
        }
        let gotoN = null;
        if (body.length === 1 && num(body[0]) !== null) gotoN = lineLabel(num(body[0]));
        else if (body.length === 2 && body[0] === 'GOTO' && num(body[1]) !== null) gotoN = lineLabel(num(body[1]));
        if (gotoN && restStmts.length === 0) {
          if (cmp === '=') { ins('READ', `IMM, ${gotoN}`); ins('WRITE', 'JZ', 'おなじなら ジャンプ'); }
          else {
            const skip = newLabel('S');
            ins('READ', `IMM, ${skip}`); ins('WRITE', 'JZ', 'おなじなら とばす');
            ins('READ', `IMM, ${gotoN}`); ins('WRITE', 'JMP', 'ちがうから ジャンプ');
            label(skip);
          }
          return;
        }
        const skip = newLabel('S');
        if (cmp === '=') {
          const yes = newLabel('T');
          ins('READ', `IMM, ${yes}`); ins('WRITE', 'JZ', 'おなじなら THEN へ');
          ins('READ', `IMM, ${skip}`); ins('WRITE', 'JMP', 'ちがうから とばす');
          label(yes);
        } else {
          ins('READ', `IMM, ${skip}`); ins('WRITE', 'JZ', 'おなじなら とばす');
        }
        stmt(body, restStmts);
        while (restStmts.length) stmt(restStmts.shift(), restStmts);
        label(skip);
        return;
      } else {
        return err(`「${t}」は わからない命令だよ`);
      }
      if (ts.length) err(`「${ts.join(' ')}」が よけいだよ`);
    }

    emit('; ==== TinyBASIC改 から つくった プログラム ====', null);
    for (const ln of lines) {
      cur = ln.no;
      emit(`; ${ln.no} ${ln.text}`);
      label(`L${ln.no}`);
      // REM のあとは : があっても全部コメント
      const remAt = ln.text.search(/(^|:)\s*REM\b/i);
      const code = remAt >= 0 ? ln.text.slice(0, remAt) : ln.text;
      const parts = code.split(':').map(s => tokenize(s)).filter(p => p.length);
      while (parts.length) stmt(parts.shift(), parts);
    }
    cur = null;
    emit('; ---- プログラムのおわり ----', null);
    label('_END'); ins('READ', 'IMM, _END'); ins('WRITE', 'JMP', 'おわり (ここで足ぶみ)');

    // コンパイラ用の変数とぶつかっていないか
    const clash = (v, why) => { if (userVars.has(v)) errors.push(`${v} は ${why} ので、ほかの変数を使ってね`); };
    if (used.tmp) clash(TMP, 'OR の計算に使う');
    if (used.wait) clash(WCNT, 'WAIT が使う');
    if (used.gosub) clash(RET, 'GOSUB が使う');

    return { asm: asm.join('\n') + '\n', basicOf, lines, errors };
  }

  // BASIC -> 機械語 まで一気に (アセンブラが必要)
  function build(src, asmApi) {
    const c = compile(src);
    if (c.errors.length) return { errors: c.errors, compiled: c };
    const r = asmApi.assemble(c.asm);
    r.compiled = c;
    if (r.errors.length) r.errors = r.errors.map(e => 'アセンブラ: ' + e);
    return r;
  }

  const api = { compile, build };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.TBASIC = api;

  if (typeof require !== 'undefined' && typeof module !== 'undefined' && require.main === module) {
    const fs = require('fs'), path = require('path');
    const file = process.argv[2];
    if (!file) { console.log('usage: node tbasic.js prog.bas'); process.exit(1); }
    const r = build(fs.readFileSync(file, 'utf8'), require('./tta8asm.js'));
    if (r.errors.length) { r.errors.forEach(e => console.error('ERROR ' + e)); process.exit(1); }
    const base = file.replace(/\.bas$/i, '');
    fs.writeFileSync(base + '.asm', r.compiled.asm);
    fs.writeFileSync(base + '.hex', r.hex);
    fs.writeFileSync(base + '.lst', r.lst);
    console.log(`${path.basename(file)}: ${r.size} bytes -> ${path.basename(base)}.asm / .hex`);
  }
})(this);
