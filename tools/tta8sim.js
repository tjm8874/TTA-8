// ============================================================
//  TTA-8 エミュレータ (hdl/tta8.v と同じ動き)
//  ブラウザでも Node.js でも動く
// ============================================================
(function (root) {
  'use strict';
  function create() {
    return { pc: 0, v: 0, a: 0, b: 0, ram: new Uint8Array(32), led: 0, btn: 0 };
  }
  function reset(cpu) {
    cpu.pc = 0; cpu.v = 0; cpu.a = 0; cpu.b = 0; cpu.led = 0; cpu.ram.fill(0);
  }
  // 1命令すすめて、何がおきたかを返す
  function step(cpu, rom) {
    const inst = rom[cpu.pc], write = inst >> 7, ad = inst & 0x7f;
    const ev = { pc: cpu.pc, inst, write: !!write, addr: ad, a: cpu.a, b: cpu.b,
                 value: 0, jump: false, jz: null, ledBefore: cpu.led };
    let npc = (cpu.pc + 1) & 255;
    if (!write) {                                        // READ
      let r;
      switch (ad) {
        case 0x00: r = cpu.a; break;                     // ALU_A
        case 0x01: r = cpu.b; break;                     // ALU_B
        case 0x02: r = (cpu.a + cpu.b) & 255; break;     // ALU_ADD
        case 0x03: r = (~(cpu.a & cpu.b)) & 255; break;  // ALU_NAND
        case 0x04: r = (cpu.a - cpu.b) & 255; break;     // ALU_SUB
        case 0x12: r = rom[(cpu.pc + 1) & 255]; npc = (cpu.pc + 2) & 255; break;  // IMM
        case 0x7e: r = cpu.btn; break;                   // IN
        default:   r = (ad >> 5) === 1 ? cpu.ram[ad & 31] : 0;
      }
      cpu.v = r; ev.value = r;
    } else {                                             // WRITE
      const v = cpu.v; ev.value = v;
      switch (ad) {
        case 0x00: cpu.a = v; break;
        case 0x01: cpu.b = v; break;
        case 0x10: npc = v; ev.jump = true; break;       // JMP
        case 0x11: ev.jz = cpu.a === 0; if (ev.jz) { npc = v; ev.jump = true; } break;  // JZ
        case 0x7f: cpu.led = v & 63; break;              // OUT
        default:   if ((ad >> 5) === 1) cpu.ram[ad & 31] = v;
      }
    }
    cpu.pc = npc;
    return ev;
  }
  const api = { create, reset, step };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.TTA8SIM = api;
})(this);
