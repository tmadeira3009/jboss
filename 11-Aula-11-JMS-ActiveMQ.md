# Aula 11 — JMS / ActiveMQ (Mensageria)

**Enunciado clássico:**

```
Configure JMS:
 a) Use the appropriate profile for MServers — messaging ability, NON clustered.
 b) Create a user "<USER>" with password "<PASS>" (they provide both).
 c) Connection factory "InVmConnectionFactory"  JNDI java:jboss/ConnectionFactory
 d) Connection factory "RemoteConnectionFactory" JNDI java:jboss/exported/jms/RemoteConnectionFactory
 e) Queue "myQueue" JNDI java:jboss/queues/myQueue
 f) Remove all other connection factories and destinations.
 g) Configure the queue with security (read/write permissions).
 h) Deploy JMSTest.war and verify connectivity (it prints the sent messages).
```

Variação mais nova da prova: connection factory `Custom` com connector `in-vm`
(**ou** `http-connector`/`netty` quando dizem que "clientes externos vão acessar"),
entries `java:/jms/CustomCF`, fila `TestQueue` JNDI `java:/jms/queue/JB248TestQueue`
**Durable ✔**, usuário `jmsguest` no `ApplicationRealm` com role `guest`.

---

## 11.1 O profile

Grupo `message` (ou `mailbox`) com **profile `full`** + `full-sockets`.
Profile `full` = Full JEE **com** mensageria **sem** cluster — é exatamente o que pedem.

Se o profile pedido tiver cluster sem mensageria, lembre-se do inverso:
remova `messaging-activemq` do profile de cluster (Aula 09).

---

## 11.2 Remover as factories e destinos padrão

**Console:** `Configuration → Profile: full → Messaging - ActiveMQ → default → View`
- **Connection Factories →** selecione os existentes → **Remove**
- **Queues →** remova as existentes (ex.: `java:/jbs/queue/ExpiryQueue`, `DLQ`)
- **Topics →** remova os existentes (se a prova pedir "remove all other destinations")

**CLI:**
```bash
/profile=full/subsystem=messaging-activemq/daemon-context=ON/server=...   # (varia)
# EAP 7 típico:
/profile=full/subsystem=messaging-activemq/external-queue=ExpiryQueue:remove()
/profile=full/subsystem=messaging-activemq/external-queue=DLQ:remove()
/profile=full/subsystem=messaging-activemq/connection-factory=InVmConnectionFactory:remove()
/profile=full/subsystem=messaging-activemq/connection-factory=RemoteConnectionFactory:remove()
```
> Confira os nomes reais com
> `/profile=full/subsystem=messaging-activemq:read-children-names(child-type=connection-factory)`
> antes de remover.

---

## 11.3 Criar as Connection Factories

**Console:** `... → Connection Factories → Add`

| | Factory 1 | Factory 2 |
|---|---|---|
| Name | `InVmConnectionFactory` | `RemoteConnectionFactory` |
| JNDI | `java:jboss/ConnectionFactory` | `java:jboss/exported/jms/RemoteConnectionFactory` |
| Connector | `in-vm` | `netty` (ou `http-connector`/`remote-connector`) |

**Atenção ao connector `netty`/remoto no EAP 7:** ele **não vem habilitado por padrão**.
Se a prova pedir acesso remoto, crie antes o socket binding:

```bash
/socket-binding-group=full-sockets/socket-binding=remote-connector:add(port=5445)
```
Console: `Configuration → Socket Bindings → full-sockets → Inbound → Add`
(Name: `remote-connector`, Port: `5445`, Group: `full-sockets`)

**Exemplo de XML (domain.xml, profile full):**
```xml
<jms-connection-factories>
   <connection-factory name="InVmConnectionFactory">
       <connectors><connector-ref connector-name="in-vm"/></connectors>
       <entries><entry name="java:jboss/ConnectionFactory"/></entries>
   </connection-factory>
   <connection-factory name="RemoteConnectionFactory">
       <connectors><connector-ref connector-name="netty"/></connectors>
       <entries>
           <entry name="java:jboss/exported/jms/RemoteConnectionFactory"/>
       </entries>
   </connection-factory>
</jms-connection-factories>
```

---

## 11.4 Criar Fila e Tópico

**Console:** `... → Queues/Topics`

| | Fila | Tópico |
|---|---|---|
| Add → | **Queue** | **Topic** |
| Name | `myQueue` (ou `TestQueue`) | o nome do enunciado |
| JNDI Name | `java:jboss/queues/myQueue` | `java:jboss/topics/<nome>` |
| Durable | ✔ se pedir "durable" (variação nova: **✔**) | — |
| Selector | vazio | vazio |

**CLI:**
```bash
/profile=full/subsystem=messaging-activemq/queue=myQueue:add(durable=true,entries=["java:jboss/queues/myQueue"])
/profile=full/subsystem=messaging-activemq/topic=meuTopico:add(entries=["java:jboss/topics/meuTopico"])
```

---

## 11.5 Segurança da mensageria

### a) Desativar o acesso para a role `guest` (se pedido)
**Console:** `Security Settings → (padrão `#` = todas as filas) → Edit`
→ desmarque **tudo** (Send/Consume/Manage/Durable...) incluindo a aba *Advanced*.

### b) Criar o usuário de aplicação com role `guest`

```bash
cd /opt/eap/bin
export JAVA_OPTS="-Djboss.server.config.user.dir=/opt/eap/node1/configuration"
./add-user.sh
```
Respostas:
```
(a): b                                  ← Application User
Username: <user da questão>             (ex.: JUNO, jmsguest)
Password: <senha da questão>
Groups: guest                           ← role EXATA
Is this correct? yes
Will this user be used for process-to-process?  yes
```

**Repita para o node2** (troque o `jboss.server.config.user.dir`) — ou copie os arquivos:
```bash
cp -a /opt/eap/node1/configuration/application-users.properties  /opt/eap/node2/configuration/
cp -a /opt/eap/node1/configuration/application-roles.properties  /opt/eap/node2/configuration/
```

### c) Liberar a fila criada para a role `guest` (só envio/SEND, se pedido)

**Console:** `Security Settings → Add`
| Campo | Valor |
|---|---|
| Pattern | `java:jboss/queues/myQueue` (ou o padrão indicado) |
| Role | `guest` |
| **Send** | ✔ |
| Consume/Manage/Durable | só se o enunciado pedir |

**CLI:**
```bash
/profile=full/subsystem=messaging-activemq/security-setting=JBQueue:add()
/profile=full/subsystem=messaging-activemq/security-setting=JBQueue/permission=queue:add(
    action=["send"],roles=["guest"],match="java:jboss/queues/myQueue")
```

---

## 11.6 Testar com o JMSTest.war

1. Deploy em `Runtime → Manage Deployments → JMSTest.war → Assign → grupo message → Enable`
2. Abra:
   ```
   http://<ip>:8180/JMSTest/run       # 8080 + offset 100
   ```
3. Preencha:
   ```
   Connection Factory JNDI: java:jboss/ConnectionFactory     (in-vm)
   Destination JNDI:       java:jboss/queues/myQueue
   Number of messages:     5
   ```
4. Repita com `java:jboss/exported/jms/RemoteConnectionFactory` para testar o acesso remoto.

**Sobre o "ERROR" no final:** nos seus relatos, o teste imprime as mensagens enviadas
com sucesso e **ainda mostra um erro na última linha** (porta diferente). *Não entre em
pânico*: confira se as mensagens foram realmente enviadas antes de considerar errado.

**Diagnóstico rápido:**
| Erro | Causa |
|---|---|
| `ClassNotFoundException`/JNDI não encontrado | Factory removida ou JNDI errado |
| `javax.security.auth.login.LoginFailedException` | Usuário sem role `guest` ou fila sem permissão `send` |
| Conexão recusada | Servidor do grupo message parado / porta errada (confira offset!) |
| Mensagem não chega | Fila JNDI errada no teste |

## Checklist

- [ ] Profile `full` no grupo de mensageria (não clusterizado)
- [ ] Factories padrão removidas, 2 novas criadas com JNDIs exatos
- [ ] Socket binding remoto criado se usou `netty`
- [ ] Fila (+ tópico se pedido) com nome/JNDI/durability exatos
- [ ] Security settings ajustados (guest desativado no default)
- [ ] Usuário criado com role `guest` nos **dois** hosts
- [ ] Permissão `send` liberada para a fila criada
- [ ] JMSTest enviando 5 mensagens com sucesso

## Exercício

Rode o teste de JMS do zero e depois **remova a permissão `send`** para ver o erro
LoginFailedException — saber reconhecer esse erro em 10 segundos economiza 20 minutos
na prova.
