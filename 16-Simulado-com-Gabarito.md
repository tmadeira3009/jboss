# Simulado com Gabarito

Duas partes: **I) Teórico** (fundamentos — responda no papel) e **II) Prático**
(enunciados no formato da prova — execute cronometrado).

---

## PARTE I — Simulado teórico (20 questões)

**1.** Qual arquivo define o **nome do host**, as **interfaces** e a relação com o domain controller?
a) `domain.xml`  b) `host.xml`  c) `standalone.xml`  d) `logging.properties`

**2.** Qual arquivo contém **profiles**, **server-groups** e **socket-binding-groups**?
a) `host.xml`  b) `domain.xml`  c) `host-slave.xml`  d) `jboss-modules.jar`

**3.** O profile indicado para "aplicações web Java EE **sem** mensageria e **não** clusterizadas" é:
a) full  b) ha  c) default  d) full-ha

**4.** "Full JEE **com** cluster e **sem** mensageria" — como você obtém isso?
a) profile `full`  b) profile `ha`  c) `full-ha` removendo `messaging-activemq`  d) b e c

**5.** Um servidor com `port-offset=100` expõe HTTP em:
a) 8180  b) 8080  c) 9990  d) 7600

**6.** Por que `server-one` (offset 0) pode impedir o cluster de subir?
a) Conflito de IP  b) Conflito de porta com `cluster_1`  c) Falta de memória  d) Profile errado

**7.** Para que serve o `enable-welcome-root=false`?
a) Desligar SSL  b) Permitir app na raiz `/`  c) Criar datasource  d) Habilitar AJP

**8.** O campo "background validation" de 10 segundos no console é preenchido com:
a) 10  b) 600  c) 10000  d) 1000000

**9.** Ao remover o `ExampleDS` (H2), qual é o segundo passo obrigatório?
a) Remover o driver  b) `undefine-attribute` do `subsystem=ee/default-bindings`  c) Reiniciar o Apache  d) Apagar o módulo h2

**10.** No login module `Database`, qual module-option aponta para o datasource?
a) `principalsQuery`  b) `rolesQuery`  c) `dsJndiName`  d) `hashAlgorithm`

**11.** Qual a diferença entre `<local/>` e `<remote .../>` em `domain-controller`?
a) É o mesmo  b) `<local/>` = este host é o mestre; `<remote/>` = aponta para o mestre  c) `<remote>` só existe no standalone  d) Nenhuma

**12.** Porta padrão do JGroups TCPPING:
a) 8080  b) 9990  c) 7600  d) 6666

**13.** Enunciado: "o profile não pode permitir nenhum outro cluster além de TCP". Ação correta:
a) Trocar `initial_hosts`  b) Remover a stack `udp`  c) Desativar o Apache  d) Usar profile `full`

**14.** No mod_cluster, o nome do balancer deve ser:
a) Qualquer um  b) Igual em Apache (`ManagerBalancerName`) e EAP  c) Sempre `cluster`  d) O nome do host

**15.** Para criar um usuário de **aplicação** no `add-user.sh` você escolhe:
a) opção `a`  b) opção `b`  c) `mgmt-users.properties`  d) opção `c`

**16.** Um cliente externo enviando JMS precisa de qual connector?
a) `in-vm`  b) `netty`/`remote-connector`  c) `ajp`  d) `http-listener`

**17.** Se a fila criada não recebe mensagens com o usuário novo, verifique primeiro:
a) Heap do servidor  b) Permissão `send` da role na Security Settings  c) Porta 8080  d) O Apache

**18.** Deploy no domain mode é atribuído a:
a) Um servidor específico  b) Um server group  c) Um host  d) Um profile

**19.** `track-statements=false` significa:
a) Não logar SQL  b) Não alertar conexão não fechada pelo desenvolvedor  c) Desligar pool  d) Desligar transação

**20.** Qual verificação confirma que o cluster formou?
a) `curl :8080`  b) Log com 2 membros GMS/view  c) `httpd -t`  d) `ping` no IP

---

### GABARITO TEÓRICO

| # | R | # | R | # | R | # | R |
|---|---|---|---|---|---|---|---|
| 1 | **b** | 6 | **b** | 11 | **b** | 16 | **b** |
| 2 | **b** | 7 | **b** | 12 | **c** | 17 | **b** |
| 3 | **c** | 8 | **c** | 13 | **b** | 18 | **b** |
| 4 | **d** | 9 | **b** | 14 | **b** | 19 | **b** |
| 5 | **a** | 10 | **c** | 15 | **b** | 20 | **b** |

**Meta: 18/20 ou mais.** Abaixo disso, refaça as Aulas 02, 04, 05, 08, 09, 11.

---

## PARTE II — Simulado prático (cronometrado: 3h30)

> **Instruções para o aplicador:** substitua entre `<...>` pelos valores que quiser
> (nomes, IPs, portas, senhas) e entregue **só o enunciado** ao aluno.

### BLOCO A — Parte 1 (1h50)

```
A1. Instale o EAP em <DIR> e crie o usuário de gerenciamento <USER>/<PASS>.

A2. Crie um novo domínio base com nome "<HOST>" em <DIR>, removendo todos os
    server-groups e servers existentes. Suba o domínio (bind localhost).

A3. Crie o server-group "<GROUP>" com profile "default" e socket-binding
    "standard-sockets".

A4. Configure a JVM do grupo: heap <HEAP> min/max, stack <STACK>.

A5. Crie o servidor "<SERVER>" no grupo, port offset <OFFSET>, auto-start true.

A6. No profile default: máximo de conexões HTTP = <N>; habilite o listener AJP.

A7. Configure o driver JDBC <DBDRIVER> e um datasource NON-XA:
    JNDI <JNDI_NONXA>, URL <URL>, user/pass <DBUSER>/<DBPASS>,
    min <MIN> / max <MAX>, TRANSACTION_READ_COMMITTED,
    valid SQL <VALIDSQL>, background validation <SEC>s,
    track-statements false, statement cache <CACHE>.

A8. Configure um datasource XA: JNDI <JNDI_XA>, classe XA <XACLASS>,
    ServerName/PortNumber/DatabaseName = <...>.

A9. Remova o datasource padrão H2 e seu binding padrão.

A10. Deploy <APP_ROOT>.war como aplicação RAIZ (context /) da porta 8080.

A11. Crie o security domain "<SECDOM>" (Database/required) usando o DS <JNDI_NONXA>,
     com principalsQuery "<QUERY1>" e rolesQuery "<QUERY2>". Publique <APP_SEC>.war
     e autentique com <APPUSER>/<APPPASS>.
```

**Gabarito do aplicador (itens corrigidos):** 12 verificações automáticas —
domínio limpo (2 blocos), grupo/profile, JVM, servidor/offset, max-connections,
AJP, DS non-XA (7 parâmetros), DS XA (3 properties), H2 removido (2 passos),
root context, security domain (3 module-options), autenticação OK.

### BLOCO B — Parte 2 (1h50)

```
B1. Crie os domínios <NODE1> (<IP1>) como master e <NODE2> (<IP2>) como slave
    (host.xml: interfaces, domain-controller remote para <IP1>).
    Trate os servers padrão para não conflitar de porta.

B2. Crie os server-groups <GCLUSTER> (profile com cluster, sem mensageria) e
    <GMESSAGE> (profile full).

B3. Servidores: <C1> e <C2> no grupo de cluster (offset 0);
                <M1> e <M2> no grupo de mensageria (offset <OFF2>).

B4. Configure cluster JGroups somente TCP (TCPPING com initial_hosts
    <IP1>[7600],<IP2>[7600]) e remova a stack UDP. Deploy <APP_CLUSTER>.war
    e confirme os 2 membros.

B5. Configure Apache httpd (<IP1>:80) com mod_cluster usando apenas o arquivo
    conf.d/proxy.conf, balancer <BAL>, ServerAdvertise off; configure o EAP
    apontando para o proxy. Comprove o balanceamento.

B6. No profile full: connection factory <CF1> (in-vm) e <CF2> (acesso remoto),
    fila <QUEUE> (JNDI <QUEUE_JNDI>), remova as factories/destinos padrão,
    remova as permissões default da role guest, crie o usuário <JMSUSER>/<JMSPASS>
    com role guest e libere SEND na fila criada. Deploy <APP_JMS>.war e envie
    5 mensagens com sucesso.
```

**Gabarito do aplicador (itens corrigidos):** 16 verificações —
host1/host2 nomes+IPs, remote apontando para o master, offsets sem conflito,
2 grupos com profiles certos, 4 servidores ativos, stack só TCP (udp removida),
initial_hosts correto, cluster formado (2 membros), Apache com 4 módulos+Listen,
balancer igual nos dois lados, 2 factories com JNDIs, fila, security settings,
usuário guest nos 2 hosts, permissão send, JMSTest enviando 5 mensagens.

---

## Correção e plano de recuperação

| Resultado no simulado | Ação |
|---|---|
| ≥ 90% dos itens | Faça 1 simulado completo extra cronometrado e vá para a prova |
| 70–89% | Refaça os laboratórios dos blocos com erro (2x) e refaça o simulado |
| < 70% | Volte às aulas teóricas do bloco com erro + 1 laboratório dirigido |

## Cronograma do dia do simulado

- 00:00–00:10 — ler tudo e rascunhar
- 00:10–01:50 — Bloco A (Parte 1)
- 01:50–02:00 — pausa + conferência do checklist A
- 02:00–03:40 — Bloco B (Parte 2)
- 03:40–03:50 — conferência final dos dois checklists
