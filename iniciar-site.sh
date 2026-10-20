#!/bin/bash
# Site do curso (MkDocs Material).
#   bash iniciar-site.sh        → site no ar com auto-refresh: http://127.0.0.1:8000
#   bash iniciar-site.sh build   → gera HTML estático na pasta site/
set -e
cd "$(dirname "$0")"
mkdir -p docs
cp -f ./*.md docs/
cp -rf imagens docs/ 2>/dev/null || true
MK="$HOME/.mkdocs-venv/bin/mkdocs"
if [ "$1" = "build" ]; then
  rm -rf site
  "$MK" build --quiet
  echo "OK → $(pwd)/site/index.html"
else
  exec "$MK" serve -a 127.0.0.1:8000
fi
