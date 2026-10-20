#!/bin/bash
# Valida o laboratório (só leitura — não altera nada).
#   bash checar-lab.sh
#   LAB_DIR=$HOME/lab-eap JBOSS_HOME=/opt/eap bash checar-lab.sh
set -u

LAB_DIR="${LAB_DIR:-/opt/lab}"
JBOSS_HOME="${JBOSS_HOME:-/opt/eap}"
ok=0; falhas=0

v() { printf '  ✓ %s\n' "$1"; ok=$((ok+1)); }
x() { printf '  ✗ %s\n' "$1"; falhas=$((falhas+1)); }

echo "== Pré-requisitos =="
command -v java >/dev/null 2>&1 && v "Java instalado ($(java -version 2>&1 | head -1 | cut -d'"' -f2))" || x "Java não encontrado"
command -v python3 >/dev/null 2>&1 && v "python3 disponível" || x "python3 não encontrado (criar-lab.sh precisa dele)"
[ -d "$JBOSS_HOME/domain/configuration" ] && v "EAP em $JBOSS_HOME" || x "EAP não encontrado em $JBOSS_HOME (Aula 03)"

echo "== Base directories =="
achou=0
for n in simple node1 node2; do
  if [ -d "$LAB_DIR/$n" ]; then
    v "$LAB_DIR/$n existe"
    if [ ! -f "$LAB_DIR/$n/configuration/host.xml" ] || [ ! -f "$LAB_DIR/$n/configuration/domain.xml" ]; then
      x "$n: base incompleta (falta host.xml/domain.xml) — rode: bash criar-lab.sh"
    elif ! grep -q "<servers>" "$LAB_DIR/$n/configuration/host.xml" 2>/dev/null; then
      v "$n: domínio limpo (sem servers padrão)"
    else
      x "$n: ainda tem <servers> no host.xml"
    fi
    achou=1
  fi
done
[ "$achou" = 1 ] || x "nenhum base dir em $LAB_DIR — rode: bash criar-lab.sh"

echo "== Servidor no ar? =="
if pgrep -f "jboss.domain.base.dir" >/dev/null 2>&1 || pgrep -f "org.jboss.as" >/dev/null 2>&1; then
  v "processo do EAP/domínio rodando"
else
  printf '  -  nenhum servidor no ar (ok se você ainda não subiu)\n'
fi
curl -s -m 2 -o /dev/null http://127.0.0.1:9990 \
  && v "Management console responde em :9990" \
  || printf '  -  :9990 não responde (esperado se o domínio está parado)\n'
curl -s -m 2 -o /dev/null http://127.0.0.1:8080 \
  && v "Aplicações respondem em :8080" \
  || printf '  -  :8080 não responde (esperado se o domínio está parado)\n'

echo
echo "Resultado: $ok ok, $falhas problema(s)."
[ "$falhas" -eq 0 ]
