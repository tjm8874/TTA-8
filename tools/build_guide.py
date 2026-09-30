# ============================================================
#  せつめい書をビルドする
#    docs/guide/*.md  ->  docs/guide/index.html (Web 版, 1ページ)
#                     ->  docs/guide/TTA-8_guide.pdf (PDF 版, --pdf のとき)
#  必要: pip install markdown   (PDF は pip install playwright も)
#  使い方: python tools/build_guide.py [--pdf]
# ============================================================
import html, pathlib, re, sys
import markdown
from markdown.extensions.toc import TocExtension, slugify_unicode

ROOT = pathlib.Path(__file__).resolve().parent.parent
G = ROOT / 'docs' / 'guide'
CHAPTERS = ['README', '01_cpu', '02_tta8', '03_setup', '04_run', '05_lab', '06_basic',
            '07_asm', '08_verilog', '09_ai', '10_next', '11_calculation', '12_expansion', 'appendix']
TITLE = 'TTA-8 せつめい書'


def convert(name):
    src = (G / f'{name}.md').read_text(encoding='utf-8')
    # 章の最後のナビ (--- のあとの ← / つぎへ の行) は 1ページ版ではいらない
    src = re.sub(r'\n---\n\[[^\n]*\]\([^\n]*\)[^\n]*\s*$', '\n', src)
    md = markdown.Markdown(extensions=['tables', 'fenced_code',
                                       TocExtension(slugify=slugify_unicode, toc_depth='2-3')])
    body = md.convert(src)
    # 章どうしのリンク: 02_tta8.md#xx -> #xx, 02_tta8.md -> #ch-02_tta8
    body = re.sub(r'href="([0-9a-z_]+|README)\.md#([^"]+)"', r'href="#\2"', body)
    body = re.sub(r'href="([0-9a-z_]+|README)\.md"', lambda m: f'href="#ch-{m.group(1)}"', body)
    body = body.replace('href="../tinybasic.md"', 'href="../tinybasic.md"')
    body = body.replace('<li>[ ] ', '<li>☐ ').replace('<li>[x] ', '<li>☑ ')
    h1 = re.search(r'<h1[^>]*>(.*?)</h1>', body)
    return h1.group(1) if h1 else name, body


CSS = r'''
:root { --bg:#E9EEFB; --panel:#fff; --panel-2:#F4F6FD; --line:#D5DAEE; --ink:#3E4466; --ink-soft:#7C82A3;
  --top:#855CD6; --accent:#E64D8C; --code:#F4F6FD; --f:"M PLUS Rounded 1c","Hiragino Maru Gothic ProN","Yu Gothic","Noto Sans CJK JP",system-ui,sans-serif; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --bg:#1B1D2C; --panel:#262940; --panel-2:#2E3150; --line:#3D4166; --ink:#ECEEFB; --ink-soft:#A6ABCD; --top:#6B45BF; --code:#1F2236; } }
* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
section.ch, h2, h3 { scroll-margin-top: 80px; }
body { margin:0; background:var(--bg); color:var(--ink); font-family:var(--f); line-height:1.85; font-size:16px; }
header.top { background:var(--top); color:#fff; padding:14px 20px; display:flex; align-items:center; gap:12px; position:sticky; top:0; z-index:5; }
header.top b { font-size:20px; letter-spacing:.02em; }
header.top span { opacity:.85; font-size:13px; }
.wrap { display:grid; grid-template-columns: 260px minmax(0,1fr); gap:24px; max-width:1180px; margin:0 auto; padding:24px 16px 80px; }
nav.toc { position:sticky; top:76px; align-self:start; background:var(--panel); border:1px solid var(--line); border-radius:16px; padding:14px 10px; max-height:calc(100vh - 100px); overflow:auto; }
nav.toc a { display:block; padding:6px 10px; border-radius:10px; color:var(--ink); text-decoration:none; font-weight:700; font-size:14px; }
nav.toc a:hover { background:var(--panel-2); }
main section.ch { background:var(--panel); border:1px solid var(--line); border-radius:20px; padding:24px 32px; margin-bottom:24px; }
h1 { font-size:28px; margin:0 0 12px; padding-bottom:10px; border-bottom:4px solid var(--top); }
h2 { font-size:22px; margin:32px 0 10px; padding-left:12px; border-left:8px solid var(--accent); }
h3 { font-size:18px; margin:24px 0 8px; }
a { color:#4C97FF; }
img { max-width:100%; height:auto; border-radius:12px; }
table { border-collapse:collapse; width:100%; margin:12px 0; font-size:15px; display:block; overflow-x:auto; }
th, td { border:1px solid var(--line); padding:6px 10px; vertical-align:top; }
th { background:var(--panel-2); }
code { font-family: ui-monospace, Menlo, Consolas, "Noto Sans Mono CJK JP", monospace; background:var(--code); padding:1px 5px; border-radius:6px; font-size:.92em; }
pre { background:var(--code); border:1px solid var(--line); border-radius:12px; padding:12px 16px; overflow-x:auto; line-height:1.55; }
pre code { background:none; padding:0; }
blockquote { margin:14px 0; padding:10px 16px; background:var(--panel-2); border-left:6px solid #FFBF00; border-radius:10px; }
blockquote p { margin:0; }
hr { border:none; border-top:1px dashed var(--line); margin:24px 0; }
.cover { text-align:center; }
@media (max-width: 820px) { .wrap { grid-template-columns: 1fr; } nav.toc { position:static; max-height:none; } main section.ch { padding:18px 16px; } }
@media print {
  body { background:#fff; font-size:11pt; line-height:1.65; } header.top, nav.toc { display:none; }
  .wrap { display:block; padding:0; max-width:none; }
  main section.ch { border:none; border-radius:0; padding:0; margin:0; break-before:page; }
  main section.ch:first-child { break-before:auto; }
  pre, table, img, blockquote { break-inside:avoid; } h2, h3 { break-after:avoid; }
  pre { white-space:pre-wrap; overflow-wrap:anywhere; }
  table { display:table; table-layout:auto; break-inside:avoid; }
  th, td { overflow-wrap:anywhere; }
  tr { break-inside:avoid; }
  a { color:inherit; text-decoration:none; }
}
@page { size:A4; margin:16mm 14mm; }
'''


def build():
    secs, toc = [], []
    for n in CHAPTERS:
        title, body = convert(n)
        label = 'はじめに・もくじ' if n == 'README' else re.sub('<[^>]+>', '', title)
        toc.append(f'<a href="#ch-{n}">{label}</a>')
        secs.append(f'<section class="ch" id="ch-{n}">{body}</section>')
    page = f'''<!doctype html>
<html lang="ja"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{TITLE}</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=M+PLUS+Rounded+1c:wght@400;700;800&display=swap">
<style>{CSS}</style></head>
<body>
<header class="top"><b>TTA-8</b><span>READ と WRITE だけの 8bit CPU ― せつめい書</span></header>
<div class="wrap"><nav class="toc">{''.join(toc)}</nav><main>{''.join(secs)}</main></div>
</body></html>
'''
    out = G / 'index.html'
    out.write_text(page, encoding='utf-8')
    print('web :', out)
    return out


def pdf(html_path):
    from playwright.sync_api import sync_playwright
    out = G / 'TTA-8_guide.pdf'
    with sync_playwright() as p:
        b = p.chromium.launch()
        pg = b.new_page()
        pg.goto(html_path.as_uri(), wait_until='networkidle')
        pg.emulate_media(media='print')
        pg.pdf(path=str(out), format='A4', print_background=True,
               display_header_footer=True, header_template='<span></span>',
               footer_template='<div style="width:100%;text-align:center;font-size:9px;color:#888">'
                               '<span class="pageNumber"></span> / <span class="totalPages"></span></div>',
               margin={'top': '16mm', 'bottom': '16mm', 'left': '14mm', 'right': '14mm'})
        b.close()
    print('pdf :', out)


if __name__ == '__main__':
    h = build()
    if '--pdf' in sys.argv:
        pdf(h)
