# CURSO COMPLETO RHCJA (Prova EX248 - JBoss EAP Administration)

**Objetivo único deste curso: que todos os alunos passem na prova.**

A prova RHCJA / EX248 é **prática** (hands-on). Você não deculta questões teóricas: você
configura um servidor JBoss EAP de verdade e o sistema da Red Hat corrige automaticamente
cada tarefa. Por isso, este curso é 100% prático: cada aula termina com um laboratório
que reproduz exatamente o que cai na prova.

---

## De onde veio o conteúdo

Todo o conteúdo deste curso foi extraído dos seus documentos RHCJA:

| Documento | O que contribuiu |
|---|---|
| `Roteiro RHCJA.txt` | Roteiro completo da prova (Parte 1 e 2), passo a passo |
| `RHCJA_FINAL.txt` | Enunciados reais das questões + soluções no console UI |
| `RHCJA-VOLTA-DA_PROVA.txt` | Relato de quem fez a prova (o que realmente caiu) |
| `Rhcja_otimizado.txt` | Enunciados em inglês + soluções detalhadas com CLI |
| `Rhcja_final.txt` | Variações de comandos CLI e dicas de XML |
| `RHCJA_atualizado.docx` / `RHCJA_atual.docx` | Versão mais nova da prova (MySQL/bookstore, cluster mailbox) |
| `RHCJA.docx` (Certificação_Redhat) | Resumo enxuto das duas partes |
| Apostilas `JB248 Student Guide`, `JB348`, Pass Guarantee Paper | Base teórica oficial Red Hat (pasta Jboss) |

---

## Mapa do curso

### Fundamentos
1. `01-Aula-01-A-Prova-RHCJA.md` — formato, pontuação, cronograma, estratégia
2. `02-Aula-02-Arquitetura-do-JBoss-EAP.md` — domain mode, hosts, profiles, portas, console x CLI
3. `03-Aula-03-Instalacao-do-EAP.md` — instalação via JAR/ZIP, usuário, diretórios

### Parte 1 da prova — "Simple Domain"
4. `04-Aula-04-Simple-Domain.md` — domínio limpo, grupos, JVM, servidor, AJP, max-connections
5. `05-Aula-05-Datasources.md` — driver JDBC, Non-XA, XA, pool, validação, remoção do H2
6. `06-Aula-06-Root-Context.md` — aplicação como raiz (context-root / default-web-module)
7. `07-Aula-07-Security-Domain-RDBMS.md` — segurança baseada em banco de dados

### Parte 2 da prova — "Domain Controller"
8. `08-Aula-08-Domain-Controller-Multihost.md` — node1/node2, host.xml, offsets, grupos
9. `09-Aula-09-Cluster-JGroups-TCP.md` — cluster TCP, TCPPING, remoção do UDP
10. `10-Aula-10-Balanceamento-mod_cluster.md` — Apache httpd + mod_cluster
11. `11-Aula-11-JMS-ActiveMQ.md` — connection factories, filas, tópicos, segurança guest

### Prática e prova
12. `12-Laboratorio-Parte1-Gabarito.md` — roteiro integral da Parte 1 com comando a comando
13. `13-Laboratorio-Parte2-Gabarito.md` — roteiro integral da Parte 2 com comando a comando
14. `14-Cheatsheet-CLI.md` — todos os comandos CLI usados na prova
15. `15-Armadilhas-da-Prova.md` — as pegadinhas que fazem aluno reprovar
16. `16-Simulado-com-Gabarito.md` — simulado teórico + prático
17. `17-Checklist-Dia-da-Prova.md` — o que fazer hora a hora no dia

### Objetivos oficiais EX248 — lacunas fechadas
18. `18-Aula-18-Logging-e-Snapshots.md` — subsystem logging (handlers, níveis, categorias) + snapshots da configuração (`take-snapshot`/`list-snapshots`/restore)
19. `19-Aula-19-SSL-LDAP-e-Cluster-Seguro.md` — HTTPS com Elytron, security domain LDAP, AUTH + SYM_ENCRYPT no cluster

### Simulado da prova
20. `20-Simulado-Real-EX248.md` — simulado **no formato exato da prova** (Parte 1 e Parte 2,
    enunciados + gabarito, cronômetros, pontuação) montado a partir dos relatos de quem
    fez o EX248 — treine com ele no último dia.

---

## Matriz de cobertura — objetivos oficiais da EX248 → aula

| Objetivo oficial (Red Hat EX248) | Aula(s) |
|---|---|
| Perform key management tasks (users, groups, RBAC) | 02 |
| Manage server settings (JVM, portas, datasources, logging) | 04 (JVM host/server), 05, **18 (logging)** |
| Deploy applications and components | 06, 07, 12 |
| Configure subsystems: datasource, messaging, security, web, logging | 05, 07, 09, 10, 11, **18**, **19** |
| Configure JDBC datasource (Non-XA/XA) | 05 |
| Domain configuration (profiles, server-groups, host, sockets) | 02, 04, 08 |
| Configure messaging subsystem (ActiveMQ) | 11 |
| Configure a security domain (DBMS + LDAP) | 07, **19 (Parte B)** |
| Deploy applications (deploy/undeploy, server-groups) | 12, 13 |
| Configure JGroups (cluster TCP) | 09, **19 (Parte C)** |
| Configure mod_cluster + Apache | 10 |
| Web connectors / SSL encrypted connection | **19 (Parte A)** |
| Connect to external security sources (LDAP) | **19 (Parte B)** |
| HA: secure communications between nodes | **19 (Parte C)** |
| Diagnose/resolve app & server issues (logs, snapshots) | **18**, 15 |
| Snapshots da configuração | **18 (Parte B)** |

---

## Plano de estudo sugerido (5 dias, ~4h/dia)

| Dia | Conteúdo | Meta |
|---|---|---|
| 1 | Aulas 01, 02, 03 + instalar EAP na VM | Entender a arquitetura e ter o EAP no ar |
| 2 | Aula 04 + Laboratório Parte 1 (até AJP) | Domínio simples configurado |
| 3 | Aulas 05, 06, 07 + Laboratório Parte 1 completo | Parte 1 inteira rodando |
| 4 | Aulas 08, 09 + Laboratório Parte 2 (cluster) | Domínio multi-host e cluster TCP |
| 5 | Aulas 10, 11 + Laboratório Parte 2 completo + Simulado (16) | Simulado completo cronometrado |
| 6 | Aulas 18, 19 + repetição da Parte 1 sem consultar | Logging, snapshots, SSL, LDAP, cluster seguro |
| 7 | **Simulado Real (20)** — prova inteira cronometrada | Passar em 300/300 no simulado = passa na prova |

**Regra de ouro:** refaça a Parte 1 do zero **duas vezes** e a Parte 2 **duas vezes**.
Na prova o tempo é curto; só passa quem já decorou o caminho.

## Ambiente necessário para praticar

- 1 máquina RHEL/Rocky/CentOS 8+ com pelo menos 4 GB de RAM livres
  (**Windows 10/11 também funciona** — o [lab](lab/README.md) tem scripts PowerShell)
- Java 8 ou 11 instalado (`java -version`)
- Instaladores: `jboss-eap-7.x-installer.jar` e `jboss-eap-7.x.zip`
- PostgreSQL (Parte 1 clássica) **ou** MySQL (variação nova da prova)
- Apache httpd (Parte 2, balanceamento)
- Arquivos de teste: `example.war`, `dstest.war`, `cluster_test.war`, `JMSTest.war`

> **Monte o ambiente em 3 comandos** com o [guia do laboratório](lab/README.md)
> (passo a passo para Windows, WSL/Linux e [Docker](imagem/README.md), com
> solução de problemas).
