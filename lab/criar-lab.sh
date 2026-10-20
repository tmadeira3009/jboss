#!/bin/bash
# Cria os base directories do laboratório no estilo da prova (domain limpo).
#
# Uso:
#   bash criar-lab.sh              # cria só o "simple" (Parte 1)
#   bash criar-lab.sh tudo         # cria simple, node1 e node2 (Partes 1 e 2)
#   LAB_DIR=$HOME/lab-eap bash criar-lab.sh    # cria em outro local (sem sudo)
#
# Variáveis (opcionais):
#   LAB_DIR     onde criar os base dirs   (padrão: /opt/lab)
#   JBOSS_HOME  onde está o EAP instalado (padrão: /opt/eap)
set -euo pipefail

LAB_DIR="${LAB_DIR:-/opt/lab}"
JBOSS_HOME="${JBOSS_HOME:-/opt/eap}"
ALVO="${1:-simple}"

case "$ALVO" in
  simple|tudo) ;;
  *) echo "Uso: criar-lab.sh [simple|tudo]"; exit 1;;
esac

[ -d "$JBOSS_HOME/domain/configuration" ] || {
  echo "ERRO: EAP não encontrado em '$JBOSS_HOME'."
  echo "      Instale o EAP (Aula 03) e rode com JBOSS_HOME=/caminho/do/eap"
  exit 1; }

mkdir -p "$LAB_DIR" 2>/dev/null || {
  echo "ERRO: sem permissão para criar em '$LAB_DIR'."
  echo "      Rode com sudo, ou defina LAB_DIR=\$HOME/lab-eap"
  exit 1; }

criar() {
  local nome="$1" destino="$LAB_DIR/$1"
  rm -rf "$destino"
  cp -r "$JBOSS_HOME/domain" "$destino"
  python3 - "$destino" "$nome" <<'PY'
import re, sys, pathlib
dest, nome = sys.argv[1], sys.argv[2]
cfg = pathlib.Path(dest) / "configuration"
host, dom = cfg / "host.xml", cfg / "domain.xml"
if host.exists():
    t = host.read_text()
    t = re.sub(r"<servers>.*?</servers>", "", t, flags=re.S)          # apaga servers padrão
    t = re.sub(r'(<host\b[^>]*\bname=")[^"]*(")', rf'\g<1>{nome}\g<2>', t, count=1)
    host.write_text(t)
if dom.exists():
    t = dom.read_text()
    t = re.sub(r"<server-groups>.*?</server-groups>", "", t, flags=re.S)  # apaga grupos padrão
    dom.write_text(t)
print(f"  ✓ {dest}  (host name='{nome}', sem servers/server-groups)")
PY
  echo "    Sobe com: \$JBOSS_HOME/bin/domain.sh -Djboss.domain.base.dir=$destino"
}

echo "EAP:  $JBOSS_HOME"
echo "Lab:  $LAB_DIR"
criar simple
[ "$ALVO" = "tudo" ] && { criar node1; criar node2; }
echo "Pronto! Depois: bash checar-lab.sh"
