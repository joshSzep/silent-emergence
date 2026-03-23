#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
website_dir="$script_dir/website"
pdf_script="$script_dir/generate-pdf.sh"
chapter_file="$script_dir/001.md"
cover_src="$script_dir/front-cover.png"
pdf_src="$script_dir/Silent Emergence.pdf"
output_html="$website_dir/index.html"

require_file() {
  local path="$1"
  local label="$2"

  if [[ ! -f "$path" ]]; then
    echo "Missing ${label}: $path" >&2
    exit 1
  fi
}

if [[ ! -x "$pdf_script" ]]; then
  echo "Missing executable PDF generator: $pdf_script" >&2
  exit 1
fi

require_file "$chapter_file" "first chapter source"
require_file "$cover_src" "front cover image"

rm -rf "$website_dir"
mkdir -p "$website_dir"

"$pdf_script"

require_file "$pdf_src" "generated PDF"

cp "$cover_src" "$website_dir/cover.png"
cp "$pdf_src" "$website_dir/"

CHAPTER_FILE="$chapter_file" OUTPUT_HTML="$output_html" python3 <<'PY'
from __future__ import annotations

import html
import os
import re
from pathlib import Path


chapter_path = Path(os.environ["CHAPTER_FILE"])
output_path = Path(os.environ["OUTPUT_HTML"])


def paragraphize(lines: list[str]) -> list[tuple[str, str]]:
    blocks: list[tuple[str, str]] = []
    current: list[str] = []

    def flush_paragraph() -> None:
        if current:
            blocks.append(("p", " ".join(piece.strip() for piece in current)))
            current.clear()

    for raw_line in lines:
        line = raw_line.rstrip()
        stripped = line.strip()

        if not stripped:
            flush_paragraph()
            continue

        if stripped == "---":
            flush_paragraph()
            blocks.append(("hr", ""))
            continue

        heading_match = re.match(r"^(#{1,6})\s+(.*)$", stripped)
        if heading_match:
            flush_paragraph()
            level = len(heading_match.group(1))
            text = heading_match.group(2).strip()
            blocks.append((f"h{level}", text))
            continue

        current.append(stripped)

    flush_paragraph()
    return blocks


def apply_inline_markdown(text: str) -> str:
    escaped = html.escape(text, quote=False)
    patterns = [
        (r"\*\*(.+?)\*\*", r"<strong>\1</strong>"),
        (r"__(.+?)__", r"<strong>\1</strong>"),
        (r"\*(.+?)\*", r"<em>\1</em>"),
        (r"_(.+?)_", r"<em>\1</em>"),
    ]

    rendered = escaped
    for pattern, replacement in patterns:
        rendered = re.sub(pattern, replacement, rendered)
    return rendered


raw_chapter = chapter_path.read_text(encoding="utf-8").strip().splitlines()
blocks = paragraphize(raw_chapter)

chapter_title = ""
chapter_body_parts: list[str] = []

for tag, content in blocks:
    if tag == "h1" and not chapter_title:
        chapter_title = apply_inline_markdown(content)
        continue

    if tag == "hr":
        chapter_body_parts.append("<hr>")
        continue

    chapter_body_parts.append(f"<{tag}>{apply_inline_markdown(content)}</{tag}>")

if not chapter_title:
    raise SystemExit(f"Expected a top-level heading in {chapter_path}")

chapter_html = "\n".join(chapter_body_parts)

description = (
    "A fog-drenched literary novel set in a near-future Los Angeles, where solitude, ambient AI, "
    "and quiet human fragility gather before the world changes."
)

blurb = (
    "In a muted Los Angeles morning, Alex wakes to absence: a wife still overseas in mourning, "
    "a city made frictionless by machines, and a future thinning into haze. Silent Emergence begins "
    "inside that suspended hour, where loneliness, memory, and the pressure of artificial presence "
    "turn stillness into a threshold."
)

framing = (
    "The city remains, but at a distance. Towers dissolve into weather. Interfaces speak too brightly. "
    "One person stands inside the blur, listening for whatever is still human beneath the soft machinery."
)

closing = "Some changes arrive with a siren. Others gather in the fog until you realize you are already inside them."

title_text = "Silent Emergence"
author_text = "Joshua Szepietowski"

document = f"""<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <meta name=\"description\" content=\"{html.escape(description, quote=True)}\">
  <meta property=\"og:title\" content=\"{title_text} | {author_text}\">
  <meta property=\"og:description\" content=\"{html.escape(description, quote=True)}\">
  <meta property=\"og:type\" content=\"website\">
  <meta property=\"og:image\" content=\"cover.png\">
  <meta name="theme-color" content="#587780">
  <style>
    :root {{
      --bg-top: #405660;
      --bg-mid: #243741;
      --bg-low: #131d23;
      --fog: rgba(205, 217, 217, 0.14);
      --fog-strong: rgba(230, 237, 236, 0.24);
      --veil: rgba(12, 20, 24, 0.5);
      --text: #f3f5ef;
      --muted: #c2ccc7;
      --soft: #96a6a7;
      --accent: #9abbbd;
      --accent-strong: #d6e6e6;
      --rule: rgba(214, 225, 223, 0.22);
      --shadow: rgba(5, 10, 13, 0.34);
      --reading-width: 40rem;
      --content-width: min(72rem, calc(100vw - 3rem));
    }}

    * {{
      box-sizing: border-box;
    }}

    html {{
      scroll-behavior: smooth;
      background:
        radial-gradient(circle at 50% 8%, rgba(223, 231, 230, 0.18), transparent 24%),
        radial-gradient(circle at 50% 24%, rgba(118, 152, 156, 0.16), transparent 36%),
        linear-gradient(180deg, var(--bg-top) 0%, var(--bg-mid) 38%, var(--bg-low) 100%);
      color: var(--text);
    }}

    body {{
      margin: 0;
      min-height: 100vh;
      font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif;
      line-height: 1.75;
      letter-spacing: 0.01em;
      background:
        radial-gradient(circle at 50% 10%, rgba(229, 235, 234, 0.14), transparent 18%),
        radial-gradient(circle at 20% 18%, rgba(150, 182, 186, 0.14), transparent 24%),
        radial-gradient(circle at 80% 24%, rgba(173, 197, 199, 0.09), transparent 28%),
        linear-gradient(180deg, rgba(255,255,255,0.06), rgba(255,255,255,0) 22%),
        linear-gradient(180deg, rgba(255,255,255,0.02), rgba(255,255,255,0) 18%),
        linear-gradient(180deg, var(--bg-top) 0%, var(--bg-mid) 38%, var(--bg-low) 100%);
      overflow-x: hidden;
    }}

    body::before,
    body::after {{
      content: \"\";
      position: fixed;
      inset: 0;
      pointer-events: none;
      z-index: -1;
    }}

    body::before {{
      background:
        radial-gradient(circle at 50% 16%, rgba(238, 242, 241, 0.22), transparent 16%),
        radial-gradient(circle at 50% 34%, rgba(153, 184, 187, 0.11), transparent 28%),
        linear-gradient(180deg, rgba(225, 234, 235, 0.13), transparent 24%, transparent 74%, rgba(8, 13, 16, 0.28));
      filter: blur(22px);
      opacity: 0.96;
      animation: drift 28s ease-in-out infinite alternate;
    }}

    body::after {{
      background:
        radial-gradient(circle at 50% 50%, transparent 38%, rgba(8, 13, 16, 0.36) 100%),
        linear-gradient(90deg, rgba(7, 11, 14, 0.22), transparent 16%, transparent 84%, rgba(7, 11, 14, 0.22));
    }}

    a {{
      color: inherit;
      text-decoration: none;
    }}

    img {{
      display: block;
      max-width: 100%;
      height: auto;
    }}

    main {{
      position: relative;
    }}

    .site-header {{
      position: sticky;
      top: 0;
      z-index: 10;
      backdrop-filter: blur(18px);
      -webkit-backdrop-filter: blur(18px);
      background: linear-gradient(180deg, rgba(18, 28, 33, 0.72), rgba(18, 28, 33, 0.42));
      border-bottom: 1px solid rgba(214, 225, 223, 0.12);
      animation: headerReveal 1000ms ease both;
    }}

    .site-header::after {{
      content: "";
      position: absolute;
      left: 0;
      right: 0;
      bottom: 0;
      height: 1px;
      background: linear-gradient(90deg, transparent, rgba(214, 225, 223, 0.22), transparent);
      opacity: 0.9;
      pointer-events: none;
    }}

    .header-inner {{
      width: var(--content-width);
      min-height: 4rem;
      margin: 0 auto;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
    }}

    .brand-block {{
      display: flex;
      flex-direction: column;
      justify-content: center;
      padding: 0.75rem 0;
    }}

    .brand-title {{
      font-family: Georgia, "Times New Roman", serif;
      font-size: 0.96rem;
      letter-spacing: 0.22em;
      text-transform: uppercase;
      color: #f4f6f0;
    }}

    .brand-subtitle {{
      margin-top: 0.15rem;
      font-size: 0.7rem;
      letter-spacing: 0.18em;
      text-transform: uppercase;
      color: var(--soft);
    }}

    .header-nav {{
      display: flex;
      align-items: center;
      flex-wrap: wrap;
      justify-content: flex-end;
      gap: 0.8rem 1.35rem;
      padding: 0.75rem 0;
    }}

    .header-link {{
      position: relative;
      display: inline-flex;
      align-items: center;
      color: var(--muted);
      font-size: 0.76rem;
      letter-spacing: 0.18em;
      text-transform: uppercase;
      transition: color 180ms ease, transform 180ms ease;
    }}

    .header-link::after {{
      content: "";
      position: absolute;
      left: 0;
      right: 0;
      bottom: -0.2rem;
      height: 1px;
      background: linear-gradient(90deg, transparent, rgba(214, 225, 223, 0.65), transparent);
      transform: scaleX(0.35);
      transform-origin: center;
      opacity: 0;
      transition: transform 220ms ease, opacity 220ms ease;
    }}

    .header-link:hover,
    .header-link:focus-visible {{
      color: var(--accent-strong);
      transform: translateY(-1px);
      outline: none;
    }}

    .header-link:hover::after,
    .header-link:focus-visible::after {{
      transform: scaleX(1);
      opacity: 1;
    }}

    .section {{
      width: var(--content-width);
      margin: 0 auto;
      padding: 0 0 6rem;
      position: relative;
    }}

    .section::before {{
      content: "";
      position: absolute;
      top: 0;
      left: 8%;
      right: 8%;
      height: 1px;
      background: linear-gradient(90deg, transparent, rgba(214, 225, 223, 0.18), transparent);
      opacity: 0.7;
      pointer-events: none;
    }}

    .hero.section::before {{
      display: none;
    }}

    .hero {{
      min-height: 100vh;
      display: grid;
      grid-template-columns: minmax(20rem, 31rem) minmax(18rem, 1fr);
      align-items: center;
      gap: clamp(2rem, 5vw, 6rem);
      padding-top: clamp(4rem, 8vw, 6rem);
      padding-bottom: clamp(5rem, 10vw, 8rem);
    }}

    .hero::after {{
      content: \"\";
      position: absolute;
      left: 0;
      right: 0;
      bottom: 0;
      height: 14rem;
      background: linear-gradient(180deg, rgba(24, 36, 43, 0), rgba(19, 29, 35, 0.92));
      pointer-events: none;
    }}

    .cover-wrap {{
      position: relative;
      justify-self: center;
      width: min(100%, 29rem);
    }}

    .cover-wrap::before {{
      content: \"\";
      position: absolute;
      inset: -14% -22% -20%;
      background:
        radial-gradient(circle at 50% 34%, rgba(241, 245, 244, 0.24), transparent 24%),
        radial-gradient(circle at 50% 66%, rgba(111, 146, 151, 0.28), transparent 48%);
      filter: blur(42px);
      opacity: 1;
      z-index: 0;
    }}

    .cover-wrap::after {{
      content: "";
      position: absolute;
      left: 10%;
      right: 10%;
      bottom: -9%;
      height: 18%;
      background: radial-gradient(circle at 50% 50%, rgba(195, 211, 212, 0.2), transparent 68%);
      filter: blur(26px);
      opacity: 0.8;
      z-index: 0;
    }}

    .cover-wrap img {{
      position: relative;
      z-index: 1;
      width: 100%;
      border-radius: 0.35rem;
      box-shadow: 0 1.8rem 5rem var(--shadow);
      animation: coverPulse 14s ease-in-out infinite;
    }}

    .hero-copy {{
      position: relative;
      z-index: 1;
      max-width: 38rem;
      animation: heroRise 1200ms ease 120ms both;
    }}

    .hero-copy::before {{
      content: "";
      position: absolute;
      top: -3rem;
      left: -2rem;
      width: 8rem;
      height: 8rem;
      background: radial-gradient(circle at 50% 50%, rgba(223, 232, 232, 0.12), transparent 70%);
      filter: blur(12px);
      pointer-events: none;
    }}

    .eyebrow {{
      margin: 0 0 1rem;
      color: var(--soft);
      font-size: 0.78rem;
      letter-spacing: 0.32em;
      text-transform: uppercase;
      animation: textDrift 10s ease-in-out infinite;
    }}

    h1,
    h2,
    h3 {{
      font-family: Georgia, \"Times New Roman\", serif;
      font-weight: 400;
      line-height: 1.08;
      letter-spacing: 0.06em;
      margin: 0;
    }}

    h1 {{
      font-size: clamp(3.6rem, 8vw, 6.9rem);
      max-width: 8ch;
      text-wrap: balance;
      color: #f8f8f3;
      text-shadow: 0 0.2rem 1.4rem rgba(10, 16, 20, 0.28);
    }}

    .author {{
      margin: 1.2rem 0 0;
      color: var(--muted);
      font-size: 1.02rem;
      letter-spacing: 0.28em;
      text-transform: uppercase;
    }}

    .blurb {{
      margin: 2rem 0 0;
      max-width: 34rem;
      color: var(--text);
      font-size: 1.14rem;
      line-height: 1.92;
    }}

    .actions {{
      display: flex;
      flex-wrap: wrap;
      gap: 1rem 1.5rem;
      margin-top: 2.5rem;
      align-items: center;
    }}

    .action-link {{
      display: inline-flex;
      align-items: center;
      gap: 0.65rem;
      color: var(--text);
      padding: 0.45rem 0 0.28rem;
      border-bottom: 1px solid rgba(214, 225, 223, 0.45);
      transition: border-color 180ms ease, color 180ms ease, transform 180ms ease, text-shadow 180ms ease;
      text-shadow: 0 0 0 rgba(0, 0, 0, 0);
    }}

    .action-link::after {{
      content: \"↘\";
      font-size: 0.9rem;
      color: var(--accent-strong);
      transition: transform 180ms ease;
    }}

    .action-link.secondary {{
      color: var(--muted);
      border-bottom-color: rgba(214, 225, 223, 0.2);
    }}

    .action-link:hover,
    .action-link:focus-visible {{
      color: var(--accent-strong);
      border-bottom-color: rgba(214, 225, 223, 0.78);
      transform: translateY(-1px);
      text-shadow: 0 0 1.2rem rgba(198, 215, 216, 0.22);
      outline: none;
    }}

    .action-link:hover::after,
    .action-link:focus-visible::after {{
      transform: translate(0.14rem, -0.05rem);
    }}

    .atmosphere,
    .closing {{
      text-align: center;
      padding-top: 3rem;
      padding-bottom: 7rem;
    }}

    .section-intro {{
      width: min(38rem, calc(100vw - 3rem));
      margin: 0 auto;
    }}

    .section-intro p,
    .closing p {{
      margin: 1.25rem 0 0;
      color: var(--muted);
      font-size: 1.12rem;
      line-height: 2;
    }}

    .section-title {{
      font-size: clamp(1.8rem, 3vw, 2.8rem);
      color: #f3f5ef;
    }}

    .chapter {{
      padding-top: 2rem;
      padding-bottom: 8rem;
    }}

    .chapter-header {{
      text-align: center;
      margin-bottom: 3.5rem;
    }}

    .chapter-header p {{
      margin: 0.9rem 0 0;
      color: var(--soft);
      letter-spacing: 0.18em;
      text-transform: uppercase;
      font-size: 0.78rem;
    }}

    .chapter-body {{
      width: min(var(--reading-width), calc(100vw - 2.5rem));
      margin: 0 auto;
      font-size: 1.08rem;
      color: var(--text);
    }}

    .chapter-body h2,
    .chapter-body h3 {{
      margin-top: 3.5rem;
      margin-bottom: 1.25rem;
      font-size: clamp(1.45rem, 2.5vw, 2rem);
      letter-spacing: 0.05em;
    }}

    .chapter-body p {{
      margin: 0 0 1.5rem;
      color: #eef1eb;
    }}

    .chapter-body strong {{
      font-weight: 600;
      color: #fbfcf8;
    }}

    .chapter-body em {{
      color: #dee6df;
    }}

    .chapter-body hr {{
      border: 0;
      border-top: 1px solid var(--rule);
      margin: 2.75rem auto;
      width: 6rem;
    }}

    .fade {{
      opacity: 0;
      transform: translateY(1.25rem);
      transition: opacity 900ms ease, transform 900ms ease;
    }}

    .fade.visible {{
      opacity: 1;
      transform: translateY(0);
    }}

    .closing {{
      padding-bottom: 5rem;
    }}

    .closing .action-link {{
      margin-top: 2rem;
    }}

    footer {{
      width: var(--content-width);
      margin: 0 auto;
      padding: 0 0 2rem;
      color: rgba(194, 204, 199, 0.8);
      font-size: 0.82rem;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      text-align: center;
    }}

    @keyframes drift {{
      from {{
        transform: translate3d(-1.5%, -1%, 0) scale(1.02);
      }}
      to {{
        transform: translate3d(1.5%, 1.2%, 0) scale(1.05);
      }}
    }}

    @keyframes headerReveal {{
      from {{
        opacity: 0;
        transform: translateY(-0.6rem);
      }}
      to {{
        opacity: 1;
        transform: translateY(0);
      }}
    }}

    @keyframes heroRise {{
      from {{
        opacity: 0;
        transform: translateY(1.2rem);
      }}
      to {{
        opacity: 1;
        transform: translateY(0);
      }}
    }}

    @keyframes coverPulse {{
      0%, 100% {{
        transform: translateY(0) scale(1);
      }}
      50% {{
        transform: translateY(-0.35rem) scale(1.008);
      }}
    }}

    @keyframes textDrift {{
      0%, 100% {{
        transform: translateY(0);
        opacity: 0.9;
      }}
      50% {{
        transform: translateY(-0.1rem);
        opacity: 1;
      }}
    }}

    @media (prefers-reduced-motion: reduce) {{
      html {{
        scroll-behavior: auto;
      }}

      body::before,
      .fade,
      .site-header,
      .cover-wrap img,
      .hero-copy,
      .eyebrow {{
        animation: none;
        transition: none;
        opacity: 1;
        transform: none;
      }}
    }}

    @media (max-width: 56rem) {{
      .header-inner {{
        min-height: auto;
        padding: 0.25rem 0 0.4rem;
        flex-direction: column;
        align-items: flex-start;
      }}

      .header-nav {{
        justify-content: flex-start;
      }}

      .hero {{
        grid-template-columns: 1fr;
        text-align: center;
      }}

      .hero-copy {{
        margin: 0 auto;
      }}

      h1,
      .blurb {{
        margin-left: auto;
        margin-right: auto;
      }}

      .actions {{
        justify-content: center;
      }}
    }}

    @media (max-width: 38rem) {{
      .section {{
        padding-bottom: 4.5rem;
      }}

      .site-header {{
        position: relative;
      }}

      .hero {{
        min-height: auto;
        padding-top: 2.8rem;
      }}

      .cover-wrap {{
        width: min(100%, 22rem);
      }}

      .blurb,
      .section-intro p,
      .chapter-body {{
        font-size: 1rem;
      }}
    }}
  </style>
</head>
<body>
  <header class="site-header">
    <div class="header-inner">
      <div class="brand-block">
        <a class="brand-title" href="#top">Silent Emergence</a>
        <span class="brand-subtitle">Joshua Szepietowski</span>
      </div>
      <nav class="header-nav" aria-label="Primary">
        <a class="header-link" href="#chapter-one">First Chapter</a>
        <a class="header-link" href="Silent%20Emergence.pdf" download>Download PDF</a>
      </nav>
    </div>
  </header>
  <main>
    <section class=\"section hero\" id=\"top\">
      <div class=\"cover-wrap fade visible\">
        <img src=\"cover.png\" alt=\"Cover art for Silent Emergence\">
      </div>
      <div class=\"hero-copy fade visible\">
        <p class=\"eyebrow\">A Novel</p>
        <h1>{title_text}</h1>
        <p class=\"author\">{author_text}</p>
        <p class=\"blurb\">{blurb}</p>
        <div class=\"actions\">
          <a class=\"action-link\" href=\"Silent%20Emergence.pdf\" download>Download the PDF</a>
          <a class=\"action-link secondary\" href=\"#chapter-one\">Read the first chapter</a>
        </div>
      </div>
    </section>

    <section class=\"section atmosphere fade\" aria-labelledby=\"atmosphere-title\">
      <div class=\"section-intro\">
        <h2 class=\"section-title\" id=\"atmosphere-title\">A Quiet Threshold</h2>
        <p>{framing}</p>
      </div>
    </section>

    <section class=\"section chapter fade\" id=\"chapter-one\" aria-labelledby=\"chapter-title\">
      <header class=\"chapter-header\">
        <p>First Chapter</p>
        <h2 class=\"section-title\" id=\"chapter-title\">{chapter_title}</h2>
      </header>
      <article class=\"chapter-body\">
{chapter_html}
      </article>
    </section>

    <section class=\"section closing fade\" aria-labelledby=\"closing-title\">
      <div class=\"section-intro\">
        <h2 class=\"section-title\" id=\"closing-title\">Continue Into the Silence</h2>
        <p>{closing}</p>
        <a class=\"action-link\" href=\"Silent%20Emergence.pdf\" download>Download the full novel</a>
      </div>
    </section>
  </main>
  <footer>Silent Emergence</footer>
  <script>
    (function () {{
      if (!('IntersectionObserver' in window)) {{
        return;
      }}

      var nodes = document.querySelectorAll('.fade');
      var observer = new IntersectionObserver(function (entries) {{
        entries.forEach(function (entry) {{
          if (entry.isIntersecting) {{
            entry.target.classList.add('visible');
            observer.unobserve(entry.target);
          }}
        }});
      }}, {{
        threshold: 0.12,
        rootMargin: '0px 0px -8% 0px'
      }});

      nodes.forEach(function (node) {{
        if (!node.classList.contains('visible')) {{
          observer.observe(node);
        }}
      }});
    }})();
  </script>
</body>
</html>
"""

output_path.write_text(document, encoding="utf-8")
PY

echo "Wrote $output_html"