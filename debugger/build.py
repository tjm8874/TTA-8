# TTA-8 ラボ をビルドする: src/lab.html + tools/tta8asm.js + programs/*.asm -> index.html
import json, pathlib
root = pathlib.Path(__file__).resolve().parent.parent
src = (root / 'debugger/src/lab.html').read_text(encoding='utf-8')
asm = '\n'.join((root / f'tools/{f}').read_text(encoding='utf-8') for f in ['tta8asm.js', 'tta8sim.js', 'tbasic.js'])
LIST = [  # key, 言語, 名前, ファイル
    ('flasher_bas', 'basic', 'LEDフラッシャー', 'basic/flasher.bas'),
    ('add_bas',     'basic', 'はじめての たし算', 'basic/add.bas'),
    ('count_bas',   'basic', '2進数カウンター', 'basic/count.bas'),
    ('mul_bas',     'basic', 'かけ算 6×7', 'basic/multiply.bas'),
    ('div_bas',     'basic', 'わり算 17÷5', 'basic/divide.bas'),
    ('flasher',     'asm',   'LEDフラッシャー', 'flasher.asm'),
    ('add',         'asm',   'はじめての たし算', 'add.asm'),
    ('count',       'asm',   '2進数カウンター', 'count.asm'),
]
samples = {k: {'lang': l, 'name': n, 'src': (root / 'programs' / f).read_text(encoding='utf-8')} for k, l, n, f in LIST}
body = src.replace('/*ASM*/', asm).replace('/*SAMPLES*/', json.dumps(samples, ensure_ascii=False))
i = body.index('</style>') + len('</style>')
full = ('<!doctype html>\n<html lang="ja">\n<head>\n<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
        + body[:i] + '\n</head>\n<body>\n' + body[i:] + '\n</body>\n</html>\n')
(root / 'debugger/index.html').write_text(full, encoding='utf-8')
import sys
if len(sys.argv) > 1:
    pathlib.Path(sys.argv[1]).write_text(body, encoding='utf-8')
print('ok', len(full))
