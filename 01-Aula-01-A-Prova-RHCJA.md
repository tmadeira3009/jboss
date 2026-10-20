# Aula 01 — A Prova RHCJA (EX248)

## O que é

A RHCJA (**Red Hat Certified JBoss Administrator**, prova **EX248** — *Red Hat Certified
Specialist in JBoss Enterprise Application Server Administration*) certifica que você sabe
administrar o Red Hat JBoss Enterprise Application Platform (EAP) em **modo domínio**.

Nomenclatura usada na Red Hat hoje: EX248. Nos materiais brasileiros ela é chamada de RHCJA.
O certificado RHCJD/EX249 é outra prova (desenvolvedor) — não confundir.

## Como funciona (o mais importante)

| Item | Detalhe |
|---|---|
| Tipo | **Prática** — nada de múltipla escolha |
| Duração | **4 horas** (a cair na próxima atualização, confirme na sua prova) |
| Nota para aprovação | **300 pontos** de um total de 300 |
| Correção | Automática, item a item, pelo sistema da Red Hat |
| Ambiente | Máquina virtual Linux já com o EAP instalado (às vezes você mesmo instala) |
| Internet | Geralmente **sem** acesso livre; a documentação e os materiais ficam num servidor local `materials.example.com` |
| Idioma | Enunciados em **inglês** (a prova brasileira tem enunciados em inglês; existe tradução em algumas versões) |
| Estrutura | **2 partes** independentes |
| Versão do EAP | A prova atual é baseada em **JBoss EAP 7.4** (Java 11). Enunciados legados com *permgen* vêm de EAP 6.x/Java 7 — saiba a diferença (Aula 04) |

> **Atenção à pontuação:** nos relatos de prova recente o aluno relatou *"consegui 300"*
> e *"fiz tudo e passei"*. Na prática, o sistema cobra cada item. Trate cada tarefa como
> obrigatória — não deixe NENHUMA de fora.

## As duas partes

### Parte 1 — "Simple Domain" (domínio único, localhost)
1. Instalação do EAP (quando cobra) e criação de usuário
2. Criação de um novo domínio base com nome exato (ex.: `simple`, `webserver`) + remoção de grupos e servidores padrão
3. Grupo de servidores (ex.: `SimpleGroup`) com profile `default`
4. Parâmetros de JVM do grupo (heap, permgen, stack) + servidor (offset, auto-start)
5. Max connections HTTP = 50 + habilitar connector AJP
6. DataSource Non-XA (PostgreSQL ou MySQL) + todos os parâmetros de pool/validação
7. DataSource XA + remoção do ExampleDS (H2)
8. Deploy de aplicação como ROOT (context-root)
9. Security Domain baseado em RDBMS

**Ao final da Parte 1: deixe o ambiente no ar** (o domínio continua rodando no localhost).

### Parte 2 — "Domain Controller" (dois hosts)
1. Novos domínios `node1` (master) e `node2` (slave) com IPs específicos
2. Grupos `cluster` (profile com cluster, sem JMS) e `message` (profile full, sem cluster)
3. Servidores com port offsets (0, 100, 300 conforme enunciado)
4. Cluster JGroups **somente TCP** (TCPPING + initial_hosts; remover/ignorar UDP)
5. Balanceamento de carga com Apache httpd + mod_cluster
6. JMS/ActiveMQ: connection factories, fila, tópico, segurança, usuário, teste

> **Objetivos oficiais da EX248 que seus relatos não citaram** (mas o exam pode cobrar —
> cobertos nas **Aulas 18 e 19**): logging (níveis/handlers), snapshots da configuração,
> JVM em nível de host/server, conexão **SSL/HTTPS**, security domain com **LDAP** e
> **segurança do cluster** (AUTH/criptografia). Veja a matriz de cobertura no índice.

## Estratégia de prova (o que faz passar)

1. **Leia TODAS as questões da parte antes de começar a executar.** Desenhe o ambiente
   no rascunho: quais hosts, quais grupos, quais servidores, quais IPs, quais offsets.
   (Dica literal dos seus documentos: *"é interessante ler primeiro todas as questões
   da segunda parte antes de começar a criar o ambiente"*).
2. **Copie exatamente os nomes** — nome de domínio, grupo, servidor, JNDI, porta, usuário.
   A correção é automática: `SimpleGroup` ≠ `simplegroup` ≠ `Simple-Group`.
3. **Use UI ou CLI, tanto faz.** A prova não exige um ou outro. O que vale é o resultado.
   Só que: CLI é mais rápido para tarefas repetitivas, UI é mais segura para descobrir caminhos.
4. **Valide cada item antes de passar ao próximo** (console em 9990, curl em 8080, log).
5. **Não pare o ambiente da Parte 1.** A correção pode verificar depois.
6. **Cronometre**: Parte 1 ≈ 1h50, Parte 2 ≈ 1h50, 20 min de folga para revisão.

## Conceitos-chave que você precisa ter na ponta da língua

- **Domain mode vs Standalone mode**
- **Host Controller / Process Controller / Server**
- **Profile** (`default`, `full`, `ha`, `full-ha`) e o que cada um oferece
- **Socket binding group** (`standard-sockets`, `full-sockets`, `full-ha-sockets`, `ha-sockets`)
- **Port offset** (por que `offset=0` conflita com `server-one`)
- **Subsystem** (undertow, datasources, security, messaging-activemq, jgroups, modcluster)
- **JNDI name** (o "endereço lógico" de datasource, security domain e connection factory)
- **Deploy** no domain: sempre atribuído a um **server group** (não a um servidor só)

## Exercício desta aula

1. Escreva num papel, de memória, os 9 itens da Parte 1 e os 6 da Parte 2.
2. Diga em voz alta: qual profile você usaria para "Full JEE com cluster e SEM mensageria"?
   *(Resposta no final do curso — Aula 08.)*
