# Imagem Docker de laboratório — RHCJA

Imagem pronta para **treino rápido**: Red Hat **UBI 9** (imagem oficial gratuita da
Red Hat, mesma base binária do RHEL 9) + **JBoss EAP 7.4** + JDK 11, já no
**domain mode**, com o host `simple` e **nenhum servidor/grupo criado** — exatamente
o estado da prova depois da Tarefa 2 da Parte 1.

> **Por que UBI 9 e não RHEL 10?** O EAP 7.4 só é certificado para **RHEL 8/9** —
> RHEL 10 não é suportado. E o próprio RHEL não pode ser distribuído no git
> (licença): o UBI é a imagem pública oficial Red Hat que resolve os dois casos.
> A prática real na prova é em RHEL nativo — aqui você treina a lógica e os
> comandos; o lab nativo (`lab/`, funciona em Windows também) é o mais fiel.

## Pré-requisitos

1. [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) instalado e rodando
2. O ZIP do **EAP 7.4** — baixe com **o seu login** Red Hat em
   <https://access.redhat.com/jbossnetwork/repo/list/product/eap/7.4.0>
   (`jboss-eap-7.4.0.zip`)

> O `.gitignore` bloqueia `*.zip`/`*.jar`: o instalador fica só na sua máquina.

## Build (2 comandos)

PowerShell, dentro da pasta `imagem/`:

```powershell
# 1) coloque o ZIP nesta pasta (exemplo: ele veio da pasta Downloads)
Copy-Item ..\..\Downloads\jboss-eap-7.4.0.zip .     # ajuste o caminho de origem

# 2) gere a imagem (~1,2 GB)
docker build -t rhcja-lab .
```

No WSL/Linux o mesmo é `bash build.sh`.

## Rodar

PowerShell:

```powershell
docker run -d --name rhcja-lab -p 8080:8080 -p 9990:9990 -p 9999:9999 rhcja-lab
```

No WSL/Linux: `bash run.sh` (mesma coisa).

| Onde | URL / porta |
|---|---|
| Console (admin) | <http://localhost:9990> — usuário `admin`, senha `Eap@2026` |
| CLI do host controller | `docker exec -it rhcja-lab bash` → `/opt/eap/bin/jboss-cli.sh -c --controller=localhost:9999` |
| Aplicação HTTP | <http://localhost:8080> (quando houver servidor no ar) |

## O que já vem pronto

- Host `simple` (renomeado de `localhost`), **sem** `<servers>` nem `<server-groups>` — o ponto de partida da Tarefa 2/3 da prova;
- Todas as interfaces em `0.0.0.0` (acessível de fora do container);
- Usuário de gestão `admin` / `Eap@2026`;
- `/opt/eap/domain` **intacto** como template (para recriar bases do zero);
- `python3` no image (os scripts do `lab/` funcionam dentro dele).

## Praticar

1. [Simulado Real (formato da prova)](../20-Simulado-Real-EX248.md) — enunciado no container, conferência com o gabarito;
2. [Laboratório Parte 1](../12-Laboratorio-Parte1-Gabarito.md) / [Parte 2](../13-Laboratorio-Parte2-Gabarito.md);
3. Sempre que quiser **estado zerado**: `docker rm -f rhcja-lab` e rode de novo (`run.sh`).

### Bônus (opcional): refazer a Tarefa 2 dentro do container

Com o lab montado (`criar-lab.sh` etc.), a Tarefa 2 (base dir limpo) também se
treina aqui — para isso o `lab/` é montado em `/lab` e o domínio inicial é parado:

```bash
docker rm -f rhcja-lab
docker run -d --name rhcja-lab -p 8080:8080 -p 9990:9990 -p 9999:9999 \
  --mount "type=bind,source=$(wslpath -w ../lab),target=/lab" rhcja-lab   # WSL
# no PowerShell troque o --mount por:
#   --mount "type=bind,source=$((Resolve-Path ..\lab),target=/lab"

docker exec -it rhcja-lab bash
export JBOSS_HOME=/opt/eap
pkill -f domain.sh; sleep 3                      # para o domínio que já sobe
LAB_DIR=/tmp/lab bash /lab/criar-lab.sh           # Tarefa 2 do zero (fonte: /opt/eap/domain)
/opt/eap/bin/domain.sh -Djboss.domain.base.dir=/tmp/lab/simple
```

## Limites honestos

- O container roda **um** host controller: a **Parte 2 da prova (2 hosts, cluster,
  JGroups, mod_cluster)** precisa de 2 processos/máquinas — use o
  [lab nativo](../lab/README.md) (tem versão `.ps1` para Windows) ou 2 VMs;
- O Apache HTTP + mod_cluster (Parte 2) não vem na imagem — instale em Linux
  (Aula 10) ou use WSL.

## Reset total

```powershell
docker rm -f rhcja-lab      # apaga o container (e todo estado alterado)
# e rode o docker run / run.sh de novo — a imagem continua lá
```
