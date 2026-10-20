#!/bin/bash
# Apaga os base dirs do laboratório para refazer do zero.
# Regra de ouro do curso: refaça a Parte 1 e a Parte 2 DUAS vezes sem consultar.
#
#   bash reset-lab.sh        # pede confirmação
#   bash reset-lab.sh -y     # não pergunta
set -euo pipefail

LAB_DIR="${LAB_DIR:-/opt/lab}"

if [ "${1:-}" != "-y" ]; then
  echo "Isto vai APAGAR: $LAB_DIR/simple $LAB_DIR/node1 $LAB_DIR/node2"
  read -r -p "Digite 'sim' para confirmar: " resp
  [ "$resp" = "sim" ] || { echo "Cancelado."; exit 0; }
fi

for n in simple node1 node2; do
  if [ -d "$LAB_DIR/$n" ]; then rm -rf "$LAB_DIR/$n"; echo "  ✓ removido $LAB_DIR/$n"; fi
done
echo "Laboratório zerado. Recrie com: bash criar-lab.sh [simple|tudo]"
