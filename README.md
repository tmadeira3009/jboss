# Curso RHCJA — Preparação para a Prova EX248

![Capa do curso RHCJA](imagens/capa-rhcja.png)

Curso **100% prático** de administração do Red Hat JBoss Enterprise Application
Platform (EAP), organizado para a prova **EX248 / RHCJA**: 20 aulas, laboratórios
com gabarito, cheatsheet de CLI, armadilhas, simulado e checklist para o dia da prova.

Tudo em **português**, com comandos testados contra o **Model Reference do JBoss
EAP 7.4** e labs oficiais Red Hat (JB248).

## Sobre a prova

| Item | Detalhe |
|---|---|
| Código | **EX248** — Red Hat Certified Specialist in EAP Administration |
| Formato | **Prática** (hands-on), 2 partes, correção automática |
| Duração | 4 horas |
| Nota | **300/300** para aprovação — cada tarefa conta |
| Ambiente | RHEL + JBoss EAP **7.4**, sem internet (docs locais) |

## Como usar este repositório

1. **Ler direto no GitHub** — comece pelo [Índice do Curso](00-INDICE-do-Curso.md);
   cada aula é um arquivo `.md` autocontido.
2. **Site local (recomendado)** — material com busca, menu, modo escuro e checkboxes
   clicáveis (MkDocs Material):
   ```bash
   git clone https://github.com/tmadeira3009/jboss.git
   cd jboss
   bash iniciar-site.sh        # abre http://127.0.0.1:8000
   bash iniciar-site.sh build  # gera HTML estático na pasta site/
   ```
   (Requer Python 3.9+ com `pip install mkdocs-material`, ou o venv citado no script.)
3. **Estudar na ordem** — siga o plano de 6 dias do índice.

## Laboratório pronto (para os alunos)

A pasta [`lab/`](lab/README.md) deixa o ambiente de prática **montado em 3 comandos**:

```bash
cd lab/
bash criar-lab.sh      # cria os base directories limpos (simple/node1/node2)
bash checar-lab.sh     # valida tudo com ✓/✗
bash reset-lab.sh      # zera para refazer do zero (regra: 2x sem consultar)
```

![Ambiente do laboratório](imagens/diagrama-laboratorio.png)

Guia completo: **[lab/README.md](lab/README.md)** — o que cada script faz, como
subir o domínio e o roteiro de prática cronometrado.

## Roteiro de estudo (6 dias, ~4h/dia)

| Dia | Conteúdo | Meta |
|---|---|---|
| 1 | Aulas 01–03 + instalar o EAP na VM | Arquitetura clara + EAP no ar |
| 2 | Aula 04 + Laboratório Parte 1 (até AJP) | Domínio simples configurado |
| 3 | Aulas 05–07 + Laboratório Parte 1 completo | Parte 1 inteira rodando |
| 4 | Aulas 08–09 + Laboratório Parte 2 (cluster) | Domínio multi-host + cluster TCP |
| 5 | Aulas 10–11 + Laboratório Parte 2 completo + Simulado | Simulado cronometrado |
| 6 | Aulas 18–19 + refazer Parte 1 sem consultar | Logging, snapshots, SSL, LDAP, cluster seguro |

**Regra de ouro:** refaça o Laboratório da Parte 1 **duas vezes** e o da Parte 2
**duas vezes**, sem consultar material. Na prova só passa quem decorou o caminho.

## Mapa do curso

### Fundamentos
| Aula | Arquivo |
|---|---|
| 01 | [A Prova RHCJA (EX248)](01-Aula-01-A-Prova-RHCJA.md) |
| 02 | [Arquitetura do JBoss EAP](02-Aula-02-Arquitetura-do-JBoss-EAP.md) |
| 03 | [Instalação do EAP (GUI, silenciosa, serviço)](03-Aula-03-Instalacao-do-EAP.md) |

### Parte 1 da prova — "Simple Domain"
| Aula | Arquivo |
|---|---|
| 04 | [Simple Domain (grupo, JVM, servidor, AJP)](04-Aula-04-Simple-Domain.md) |
| 05 | [Datasources (Non-XA, XA, pool, H2)](05-Aula-05-Datasources.md) |
| 06 | [Root Context (app na raiz)](06-Aula-06-Root-Context.md) |
| 07 | [Security Domain RDBMS](07-Aula-07-Security-Domain-RDBMS.md) |

### Parte 2 da prova — "Domain Controller"
| Aula | Arquivo |
|---|---|
| 08 | [Domain Controller Multihost (node1/node2)](08-Aula-08-Domain-Controller-Multihost.md) |
| 09 | [Cluster JGroups TCP](09-Aula-09-Cluster-JGroups-TCP.md) |
| 10 | [Balanceamento mod_cluster](10-Aula-10-Balanceamento-mod_cluster.md) |
| 11 | [JMS / ActiveMQ](11-Aula-11-JMS-ActiveMQ.md) |

### Prática e prova
| Arquivo | Para quê |
|---|---|
| [12 — Laboratório Parte 1 (gabarito)](12-Laboratorio-Parte1-Gabarito.md) | Roteiro comando a comando da Parte 1 |
| [13 — Laboratório Parte 2 (gabarito)](13-Laboratorio-Parte2-Gabarito.md) | Roteiro comando a comando da Parte 2 |
| [14 — Cheatsheet CLI](14-Cheatsheet-CLI.md) | Todos os comandos da prova em um lugar só |
| [15 — Armadilhas da Prova](15-Armadilhas-da-Prova.md) | O que faz aluno reprovar |
| [16 — Simulado com Gabarito](16-Simulado-com-Gabarito.md) | Simulado teórico + prático cronometrado |
| [17 — Checklist do Dia da Prova](17-Checklist-Dia-da-Prova.md) | O que fazer hora a hora |

### Objetivos oficiais EX248 (lacunas fechadas)
| Aula | Arquivo |
|---|---|
| 18 | [Logging e Snapshots](18-Aula-18-Logging-e-Snapshots.md) |
| 19 | [SSL, LDAP e Cluster Seguro](19-Aula-19-SSL-LDAP-e-Cluster-Seguro.md) |

> A tabela completa **objetivo oficial da EX248 → aula** está no
> [Índice do Curso](00-INDICE-do-Curso.md).

## Estrutura do repositório

```
jboss/
├── README.md                    ← você está aqui
├── 00-INDICE-do-Curso.md        ← mapa, matriz de cobertura e plano de estudo
├── 01..11  Aulas da prova       ← fundamentos + Parte 1 + Parte 2
├── 12..13  Laboratórios         ← gabaritos comando a comando
├── 14..17  Material de apoio    ← cheatsheet, armadilhas, simulado, checklist
├── 18..19  Objetivos oficiais   ← logging/snapshots e SSL/LDAP/cluster seguro
├── index.md                     ← página inicial do site
├── mkdocs.yml                   ← config do site (MkDocs Material)
├── iniciar-site.sh              ← sobe o site local com busca e modo escuro
├── imagens/                     ← capa, diagrama do lab e telas do instalador (Aula 03)
└── lab/                         ← laboratório pronto (criar / checar / resetar)
```

## Fontes

- Relatos e enunciados reais de prova (documentos pessoais do autor)
- Red Hat: Model Reference e Configuration Guide do **JBoss EAP 7.4**
- Apostila oficial **JB248** Student Guide (labs incluídos)
- [antvale/rhcja-certification](https://github.com/antvale/rhcja-certification) —
  guia de instalação EAP 7.4 (usado na Aula 03)
