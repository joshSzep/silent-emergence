#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
manuscript_script="$script_dir/generate-manuscript.sh"
manuscript_file="$script_dir/MANUSCRIPT.md"
cover_file="$script_dir/front-cover.png"
output_file="$script_dir/Silent Emergence.pdf"

if [[ ! -x "$manuscript_script" ]]; then
  echo "Missing executable manuscript generator: $manuscript_script" >&2
  exit 1
fi

if [[ ! -f "$cover_file" ]]; then
  echo "Missing front cover image: $cover_file" >&2
  exit 1
fi

"$manuscript_script"

if [[ ! -f "$manuscript_file" ]]; then
  echo "Expected manuscript file was not created: $manuscript_file" >&2
  exit 1
fi

temp_body=$(mktemp)
temp_source=$(mktemp)
temp_header=$(mktemp)

cleanup() {
  rm -f "$temp_body" "$temp_source" "$temp_header"
}
trap cleanup EXIT

awk '
  body_started == 0 {
    if ($0 ~ /^## /) {
      body_started = 1
      print
    }
    next
  }

  {
    print
  }
' "$manuscript_file" > "$temp_body"

cat > "$temp_source" <<'EOF'
```{=latex}
\newgeometry{margin=0in}
\thispagestyle{empty}
\begin{titlepage}
\noindent\includegraphics[width=\paperwidth,height=\paperheight]{front-cover.png}
\end{titlepage}
\clearpage
\restoregeometry
\setcounter{page}{1}
```

EOF

cat "$temp_body" >> "$temp_source"

cat > "$temp_header" <<'EOF'
\usepackage{graphicx}
\usepackage{microtype}
\usepackage{mathpazo}
\usepackage{fancyhdr}
\usepackage{setspace}

\setstretch{1.08}
\setlength{\parindent}{1.25em}
\setlength{\parskip}{0.35em}
\setlength{\emergencystretch}{3em}
\widowpenalty=10000
\clubpenalty=10000
\raggedbottom

\pagestyle{fancy}
\fancyhf{}
\fancyhead[C]{\nouppercase{\leftmark}}
\fancyfoot[C]{\thepage}
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{0pt}

\fancypagestyle{plain}{
  \fancyhf{}
  \fancyhead[C]{\nouppercase{\leftmark}}
  \fancyfoot[C]{\thepage}
  \renewcommand{\headrulewidth}{0.4pt}
  \renewcommand{\footrulewidth}{0pt}
}
EOF

cd "$script_dir"

pandoc "$temp_source" \
  --standalone \
  --from=markdown+raw_tex \
  --pdf-engine=pdflatex \
  --include-in-header="$temp_header" \
  --output="$output_file" \
  --shift-heading-level-by=-1 \
  --top-level-division=chapter \
  -V documentclass=report \
  -V classoption=oneside \
  -V papersize=letter \
  -V geometry:margin=1.1in \
  -V fontsize=12pt

echo "Wrote $output_file"