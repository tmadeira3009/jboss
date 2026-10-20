# Laboratório pronto — comece por aqui

Esta pasta deixa o **ambiente de prática todo montado para você**: 3 comandos para
criar, validar e zerar o laboratório. Nada de copiar/colar XML à mão para começar —
os scripts fazem a parte repetitiva (criar os *base directories* limpos, no formato
da prova) e deixam para você a parte que **cai na prova**.

![Ambiente do laboratório](../imagens/diagrama-laboratorio.png)

## Pré-requisitos

1. EAP 7.4 instalado e `JBOSS_HOME` exportado (Aula 03)
2. `java` e `python3` no PATH (o script usa `python3` para limpar o XML)
3. Permissão de escrita no `/opt/lab` (use `sudo`) **ou** defina outro local (abaixo)

## Os 3 comandos

```bash
cd lab/

bash criar-lab.sh          # 1) cria /opt/lab/simple (Parte 1) — domínio limpo
bash checar-lab.sh         # 2) mostra o que está ✓ e ✗ (pré-requisitos, bases, portas)
bash reset-lab.sh          # 3) apaga tudo para refazer do zero (pede "sim")
```

Para praticar as **duas partes** da prova de uma vez:

```bash
bash criar-lab.sh tudo      # cria simple + node1 + node2
```

Sem `sudo` (lab no seu home):

```bash
LAB_DIR=$HOME/lab-eap bash criar-lab.sh
LAB_DIR=$HOME/lab-eap bash checar-lab.sh
```

EAP instalado em outro caminho:

```bash
JBOSS_HOME=/opt/jboss-eap-7.4 bash criar-lab.sh
```

## O que cada script faz

| Script | O que faz | O que ele **não** faz |
|---|---|---|
| `criar-lab.sh` | Copia `$JBOSS_HOME/domain` para `$LAB_DIR/<nome>`, **apaga** os `servers`/`server-groups` padrão e renomeia o host (igual à Tarefa 2 da prova) | Não cria grupos, servidores, datasources — isso é **você fazer** (é o que cai!) |
| `checar-lab.sh` | Confere Java, EAP, bases, processo e portas 9990/8080 (só leitura) | Não altera nada |
| `reset-lab.sh` | Apaga os 3 base dirs (confirme com `sim` ou use `-y`) | Não apaga o EAP nem o `/opt/lab` inteiro |

## Subir e praticar

```bash
# Parte 1 (Aulas 04–07)
$JBOSS_HOME/bin/domain.sh -Djboss.domain.base.dir=/opt/lab/simple

# Partes 1 e 2 (Aulas 08–11) — depois de criar node1/node2 pela Aula 08
$JBOSS_HOME/bin/domain.sh -Djboss.domain.base.dir=/opt/lab/node1
```

O `criar-lab.sh` imprime o comando exato ao terminar.

## Roteiro de prática (regra de ouro)

1. **Aula 04 → 07** seguindo o [Laboratório Parte 1](../12-Laboratorio-Parte1-Gabarito.md)
2. `bash checar-lab.sh` — tudo ✓?
3. `bash reset-lab.sh` e repita **sem olhar o gabarito** (meta: 2 vezes seguidas)
4. **Aula 08 → 11** seguindo o [Laboratório Parte 2](../13-Laboratorio-Parte2-Gabarito.md)
5. Reset de novo, refaça as 2 partes uma última vez **cronometrado** (meta: < 3h50)
6. Faça o [Simulado](../16-Simulado-com-Gabarito.md)

> Os scripts são **apoio** — na prova ninguém cria o domínio pra você. Depois que
> decorar o caminho, faça a Tarefa 2 manualmente (edits no `host.xml`/`domain.xml`)
> para treinar o que realmente é cobrado.
