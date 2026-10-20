#!/bin/bash
# Monta a imagem de laboratório: Red Hat UBI 9 + JBoss EAP 7.4 (domain mode).
#   1) Baixe o jboss-eap-7.4.0.zip (conta Red Hat gratuita) e coloque nesta pasta
#   2) bash build.sh
set -e
cd "$(dirname "$0")"

[ -f jboss-eap-7.4.0.zip ] || {
  echo "ERRO: jboss-eap-7.4.0.zip não está em $(pwd)"
  echo "      Baixe em: access.redhat.com → Customer Portal → JBoss EAP 7.4 → ZIP"
  echo "      (conta gratuita; o ZIP não é versionado no git por licença)"
  exit 1; }

command -v docker >/dev/null 2>&1 || {
  echo "ERRO: docker não encontrado. Instale o Docker (Docker Desktop ou engine)."
  exit 1; }

echo "Construindo a imagem 'rhcja-lab' (Red Hat UBI 9 + EAP 7.4)..."
docker build -t rhcja-lab .
echo
echo "OK. Suba o laboratório com: bash run.sh"
