#!/bin/bash
# Sobe (ou para) o container do laboratório.
#   bash run.sh          # cria/atualiza o container rhcja-lab
#   bash run.sh parar    # remove o container (o dado dentro dele é perdido)
set -e

NAME=rhcja-lab
IMG=rhcja-lab

if [ "${1:-}" = "parar" ]; then
  docker rm -f "$NAME" 2>/dev/null && echo "Container '$NAME' removido." || echo "Nada para parar."
  exit 0
fi

command -v docker >/dev/null 2>&1 || { echo "ERRO: docker não encontrado."; exit 1; }
docker image inspect "$IMG" >/dev/null 2>&1 || {
  echo "Imagem não existe ainda — rode antes: bash build.sh"; exit 1; }

docker rm -f "$NAME" 2>/dev/null || true
docker run -d --name "$NAME" \
  -p 8080:8080 -p 9990:9990 -p 9999:9999 -p 8009:8009 \
  "$IMG" >/dev/null

echo "Laboratório no ar!"
echo "  Console:  http://localhost:9990   (admin / Eap@2026)"
echo "  Apps:     http://localhost:8080"
echo "  Logs:     docker logs -f $NAME"
echo "  Reset:    bash run.sh parar && bash build.sh && bash run.sh"
