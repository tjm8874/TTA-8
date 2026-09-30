# ============================================================
#  紹介動画の 図解アニメ素材を mp4 にする
#    tools/video/anim.html の シーンを 1コマずつ 描いて ffmpeg で つなぐ
#  必要: pip install playwright && playwright install chromium / ffmpeg
#  使い方: python tools/video/render.py              (ぜんぶ)
#          python tools/video/render.py title1,ending (えらんで)
# ============================================================
import json, pathlib, re, subprocess, sys
from playwright.sync_api import sync_playwright

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
OUT = ROOT / 'docs' / 'video' / 'assets'
FPS = 30
ALL = ['title1', 'title2', 'title3', 'cpu_loop', 'binary', 'readwrite', 'code51', 'patterns', 'flow', 'ending']

# code51 シーン用: tta8.v から コメントと空行を のぞいた 行
code = []
for l in (ROOT / 'hdl' / 'tta8.v').read_text(encoding='utf-8').splitlines():
    if re.match(r'^\s*(//|$)', l):
        continue
    code.append(re.sub(r'\s*//.*$', '', l).rstrip())
html = (HERE / 'anim.html').read_text(encoding='utf-8').replace('/*CODE*/[]', json.dumps(code, ensure_ascii=False))
built = HERE / '_anim_built.html'
built.write_text(html, encoding='utf-8')

scenes = sys.argv[1].split(',') if len(sys.argv) > 1 else ALL
OUT.mkdir(parents=True, exist_ok=True)
with sync_playwright() as p:
    b = p.chromium.launch()
    pg = b.new_page(viewport={'width': 1920, 'height': 1080})
    for sc in scenes:
        pg.goto('about:blank')
        pg.goto(built.as_uri() + '#' + sc)
        pg.wait_for_timeout(300)
        n = int(pg.evaluate('DUR') * FPS)
        ff = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'image2pipe', '-framerate', str(FPS), '-c:v', 'mjpeg', '-i', '-',
                               '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-movflags', '+faststart',
                               str(OUT / f'{sc}.mp4')], stdin=subprocess.PIPE)
        for i in range(n):
            pg.evaluate(f'render({i / FPS})')
            ff.stdin.write(pg.screenshot(type='jpeg', quality=92))
        ff.stdin.close(); ff.wait()
        print(f'{sc}: {n} frames')
    b.close()
built.unlink()
