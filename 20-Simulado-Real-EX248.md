# Simulado Real — formato EX248 (prova RHCJA)

> **Como este simulado foi montado:** ele reproduce a **estrutura, os valores e o
> estilo das questões que caem na prova EX248**, a partir dos **retornos de prova**
> de alunos (relatos de tela, comandos e valores anotados durante a prova).
> Todo o texto é **original** — nada foi copiado literalmente de material da Red Hat;
> os valores (senhas, IPs, portas, nomes) são os mais repetidos nos relatos e **variam
> a cada prova**: na prova real, use **exatamente** os números que o enunciado der.

## Como usar

1. Leia **só a Parte 1**, cronometre e faça (sem aulas, sem internet, sem gabarito);
2. Depois a **Parte 2** (as duas partes somam 4 h — pode fazer em dias separados);
3. Corrija item a item com o **Gabarito** (cada item tem os pontos);
4. Errou? Volte na aula indicada em cada tarefa e refaça **só** a tarefa perdida.

## Ambiente (comum às duas partes)

| Item | Valor |
|---|---|
| Sistema | RHEL 8/9 (ou UBI 9), root, **sem internet** na prova |
| EAP | 7.4, instalado em `/opt/eap` |
| Banco | PostgreSQL em `localhost:5432`, base `postgres`, usuário/senha `postgres`/`postgres`, schema `jbtravel` com as tabelas `USER` e `airport` |
| Console | `http://localhost:9990` (Parte 1) · `http://192.168.6.11:9990` (Parte 2) |
| CLI | `/opt/eap/bin/jboss-cli.sh -c --controller=<ip>:9990` |

**Materiais** — deixe tudo em `/root/materials/` **antes** de começar (nos seus
materiais do curso JB248-RHJBEAP7 os arquivos estão assim):

| Arquivo | Onde achar |
|---|---|
| `jboss-eap-7.4.0.zip` | download Red Hat (sua conta) |
| `postgresql.jar` | `labs/lab12/postgresql-9.0-801-jdbc4.jar` |
| `JBTravel.sql` (schema do banco) | `labs/lab12/JBTravel.sql` → `psql -U postgres -f JBTravel.sql` |
| `example.war` · `example2.war` | `labs/chapter9/` |
| `dstest.war` | `labs/lab12/dstest.war` |
| `JMSTest.war` | `labs/lab17/JMSTest.war` |
| `cluster_test.war` | `labs/chapter12/cluster_test.war` |

> Sem os `.war` de teste você treina a configuração toda e valida com
> `read-resource` — os testes de aplicação ficam para quando tiver os arquivos.

## Cronômetro e pontuação

**Parte 1 — Simple · 150 pontos · 2 h**

| # | Tarefa | Pontos | Tempo |
|---|---|---|---|
| 1 | Instalação do EAP | 15 | 10 min |
| 2 | Simple domain (base dir limpo + grupo) | 30 | 20 min |
| 3 | JVM do grupo | 15 | 10 min |
| 4 | SimpleServer + Undertow (max-connections/AJP) | 20 | 15 min |
| 5 | Datasources (não-XA + XA + dstest) | 45 | 40 min |
| 6 | Root context (example.war na raiz) | 10 | 10 min |
| 7 | Security domain RDBMS | 15 | 15 min |

**Parte 2 — Domain · 150 pontos · 2 h**

| # | Tarefa | Pontos | Tempo |
|---|---|---|---|
| 1 | Domain com dois Host Controllers | 50 | 45 min |
| 2 | Cluster TCP (JGroups/TCPPING) | 35 | 25 min |
| 3 | JMS (ActiveMQ) | 40 | 35 min |
| 4 | Balanceamento Apache (mod_cluster) | 25 | 15 min |

---
---

# PARTE 1 — SIMPLE (150 pontos · 2 h)

> **Leia todas as 7 tarefas antes de começar** e anote no rascunho os valores que
> vai precisar (senhas, JNDIs, portas). A Parte 1 inteira roda em **localhost**.

## Tarefa 1 — Instalação do EAP **(15 pontos · ~10 min)**

1. Instale o EAP 7.4 em **`/opt/eap`** (o instalador está em `/root/materials/jboss-eap-7.4.0.zip`);
2. Garanta as bibliotecas nativas necessárias (JDK 11 e utilitários de descompactação);
3. Crie o usuário de gestão **`webmin`** com a senha **`secret1`**.

## Tarefa 2 — Controlador de domínio (Simple domain) **(30 pontos · ~20 min)**

1. Crie um novo *base directory* de domínio chamado **`simple`** em **`/opt/eap/simple`** (usando o `host.xml`);
2. Renomeie o host para **`simple`**; apague o bloco **`<servers>`** do `host.xml`
   e o bloco **`<server-groups>`** do `domain.xml` — **nenhum outro grupo ou
   servidor pode existir** neste domínio;
3. Inicie o controlador de domínio com o bind das interfaces em **127.0.0.1**;
4. Crie o grupo **`SimpleGroup`** com **profile `default`** (Java EE web, sem
   mensageria, sem cluster) e **socket-binding `standard-sockets`**.

## Tarefa 3 — Parâmetros de JVM do grupo **(15 pontos · ~10 min)**

Para o grupo `SimpleGroup` (JVM de nome `simple`):

| Parâmetro | Valor |
|---|---|
| Java Heap (mín e máx) | **1326 MB** |
| PermGen (mín e máx) | **325 MB** |
| Java Thread Stack | **128 KB** |

## Tarefa 4 — Servidor e Undertow **(20 pontos · ~15 min)**

1. Crie o servidor **`SimpleServer`** no grupo `SimpleGroup`, **port offset 0**,
   **auto-start = true** (nenhum outro servidor pode existir);
2. Máximo de conexões HTTP do listener = **50** (`max-connections`);
3. Ative o **connector AJP**: listener de nome **`ajp`** com socket-binding **`ajp`**.

## Tarefa 5 — Datasources (PostgreSQL) **(45 pontos · ~40 min)**

1. Deploy do driver **`postgresql.jar`** (runtime name `postgresql.jar`);
2. **DataSource não-XA:**

| Campo | Valor |
|---|---|
| Name / JNDI | `DS_NON_XA` / `java:jboss/DS_NON_XA` |
| Connection URL | `jdbc:postgresql://localhost:5432/postgres` |
| User / Pass | `postgres` / `postgres` |
| Transaction isolation | `TRANSACTION_READ_COMMITTED` |
| Pool | mínimo **5**, máximo **50** |
| Validation SQL | `SELECT 1` |
| Background validation | a cada **10 segundos** |
| Track statements | `false` |
| Statement cache size | **20** |

3. **DataSource XA:**

| Campo | Valor |
|---|---|
| Name / JNDI | `DS_XA` / `java:jboss/DS_XA` |
| xa-datasource-class | `org.postgresql.xa.PGXADataSource` |
| Propriedades | `ServerName=localhost`, `PortNumber=5432`, `DatabaseName=postgres` |
| User / Pass | `postgres` / `postgres` |

4. Remova o **`ExampleDS`** (H2) — inclusive a referência nos *default bindings*;
5. Deploy de **`dstest.war`** no grupo `SimpleGroup` e valide **os dois**
   datasources no formulário do aplicativo:
   JNDI `java:jboss/DS_NON_XA` e `java:jboss/DS_XA`, tabela **`jbtravel.airport`**.

## Tarefa 6 — Root context **(10 pontos · ~10 min)**

1. `example.war` deve atender em **`http://localhost:8080/`** (context root `/`);
2. Desligue a página de boas-vindas (welcome root);
3. Deploy da aplicação no grupo `SimpleGroup` e teste `/` e `/example`.

## Tarefa 7 — Security domain baseado em RDBMS **(15 pontos · ~15 min)**

1. Crie o security domain **`RDBMS`** (cache type: `default`) no profile `default`;
2. Authentication: código **`Database`**, flag **`required`**, com as module options:

| Module option | Valor |
|---|---|
| `dsJndiName` | `java:jboss/DS_NON_XA` (o pool **não-XA** da Tarefa 5) |
| `principalsQuery` | `select Password from JBTravel.USER where username=?` |
| `rolesQuery` | `select null, 'Roles' from JBTravel.USER where username=?` |

3. Ajuste `example2.war` para usar o security domain (`WEB-INF/jboss-web.xml` com
   `<security-domain>RDBMS</security-domain>` e `WEB-INF/web.xml` com `BASIC`
   em `/*`);
4. Deploy no grupo `SimpleGroup` e teste em `http://localhost:8080/example2`
   com o usuário **`mobius`** e a senha **`jboss`**.

**FIM DA PARTE 1 — deixe o ambiente no ar.**

---
---

# PARTE 2 — DOMAIN COM DOIS HOSTS (150 pontos · 2 h)

> **Leia as 4 tarefas inteiras antes de tocar em alguma coisa** e desenhe o
> ambiente no rascunho (IPs, grupos, offsets). Uma máquina só? Some os dois IPs
> em loopback **antes** de começar:
> `ip addr add 192.168.6.11/32 dev lo; ip addr add 192.168.6.12/32 dev lo`

## Tarefa 1 — Domain com dois Host Controllers **(50 pontos · ~45 min)**

**node1 (master)** — base dir `/opt/eap/node1`:

1. Host name **`node1`**; **todas** as interfaces apenas em **`192.168.6.11`**;
2. Nada além dos servidores novos pode estar em execução com offset 0/100 —
   trate os grupos/servidores padrão do domínio (remova ou ajuste offsets);
3. Grupo **`cluster`**: profile **`full-ha`** (full Java EE **com** cluster)
   **sem mensageria** — remova o subsystem `messaging-activemq` desse profile —,
   socket-binding **`full-ha-sockets`**;
   - servidor **`cluster_1`**: offset **0**, auto-start **true**;
4. Grupo **`message`**: profile **`full`** (mensageria, **sem** cluster),
   socket-binding **`full-sockets`**;
   - servidor **`message_1`**: offset **100**, auto-start **true**.

**node2 (slave)** — base dir `/opt/eap/node2`:

5. Host name **`node2`**; **todas** as interfaces apenas em **`192.168.6.12`**;
6. Domain controller **remoto** apontando para `192.168.6.11:9999` (`ManagementRealm`);
7. No master: servidor **`cluster_2`** no grupo `cluster` (offset **0**,
   auto-start **true**) e **`message_2`** no grupo `message` (offset **100**,
   auto-start **true**);
8. Suba os dois hosts — console do master em `http://192.168.6.11:9990` e os
   4 servidores no ar.

## Tarefa 2 — Cluster TCP **(35 pontos · ~25 min)**

1. O profile do grupo `cluster` deve usar **somente TCP** (nenhuma outra stack):
   configure a stack com o discovery **TCPPING** e
   `initial_hosts = 192.168.6.11[7600],192.168.6.12[7600]`, e faça o canal `ee`
   usar essa stack;
2. Remova a **stack `udp`**;
3. Deploy de **`cluster_test.war`** no grupo `cluster`; reinicie o cluster e valide:
   - os **2 membros** no log (`GMS: address=... cluster=web` nos dois servidores);
   - `http://192.168.6.11:8080/cluster_test/` e `http://192.168.6.12:8080/cluster_test/`.

## Tarefa 3 — JMS (ActiveMQ) **(40 pontos · ~35 min)**

No profile do grupo `message`:

1. Crie o socket binding de entrada **`remote-connector`**, porta **`5445`** (grupo `full-sockets`);
2. Connection factory de **acesso remoto**: nome **`MyRemote`**, JNDI
   **`java:jboss/exported/jms/MyRemote`**, connector **`remote-connector`**;
3. Fila: nome **`myQueue`**, JNDI **`java:jboss/queues/myQueue`**, **durable: não**;
4. Tópico: nome **`myTopic`**, JNDI **`java:jboss/topics/myTopic`**;
5. Remova **todas as demais** connection factories e destinos existentes;
6. Segurança:
   - desative **todo** o acesso da role **`guest`** no padrão **`#`** (todas as filas);
   - crie o usuário de aplicação **`jmsuser`** / **`Jms@2026`** com role **`guest`**
     **nos dois hosts**;
   - libere para a role `guest` **apenas SEND** na fila `myQueue`;
7. Deploy de **`JMSTest.war`** no grupo `message` e teste em
   `http://192.168.6.11:8180/JMSTest/run`: CF `java:jboss/exported/jms/MyRemote`,
   destino `java:jboss/queues/myQueue`, **5 mensagens**, usuário `jmsuser`.

## Tarefa 4 — Balanceamento Apache (mod_cluster) **(25 pontos · ~15 min)**

1. Instale o **Apache httpd** e os **módulos do mod_cluster** (pacotes do
   repositório ou `.so` dos materiais → `/etc/httpd/modules/`);
2. Garanta que `proxy_balancer` está **comentado** no `httpd.conf`;
3. Arquivo **único** em `/etc/httpd/conf.d/proxy.conf`:
   - `Listen 192.168.6.11:80` (aplicação) e `Listen 192.168.6.11:6666` (gestão mod_cluster);
   - os 4 módulos + `ManagerBalancerName mycluster`;
   - `VirtualHost *:6666` com `EnableMCPMReceive on`, `ServerAdvertise off` e
     `/mod_cluster-manager` restrito ao IP `192.168.6.11`;
   - `VirtualHost *:80` liberado para todos;
4. Lado EAP (profile do grupo `cluster`): balancer **`mycluster`**, advertise
   **`false`**, Proxy List **`192.168.6.11:6666`**;
5. Valide: `http://192.168.6.11:6666/mod_cluster-manager` lista os **2 nós** e
   `http://192.168.6.11/cluster_test/` responde **balanceado**.

---
---

# GABARITO

> **UI ou CLI?** A prova aceita os dois. Os blocos `CLI` abaixo são atalhos
> conferidos; onde os relatos usaram a UI, o caminho da UI está no passo a passo.
> **Nome do host importa:** como a Tarefa 2 renomeia o host para `simple`, os
> caminhos são `/host=simple/...` (se você não renomeou, é `/host=localhost/...`).

## PARTE 1

### Tarefa 1 — Instalação (15 pts)

```bash
dnf install -y java-11-openjdk unzip                 # b) nativas
cd /root/materials
unzip -q jboss-eap-7.4.0.zip -d /opt
mv /opt/jboss-eap* /opt/eap                          # a) em /opt/eap
/opt/eap/bin/add-user.sh -u webmin -p 'secret1'       # c) usuário de gestão
```

> ⚠️ **Variante installer:** algumas provas trazem `jboss-eap-installer.jar` —
> `java -jar jboss-eap-installer.jar`, aponte o diretório `/opt/eap` no wizard.
> Se a senha `secret1` for recusada pela política no modo interativo, o `-u/-p`
> (não-interativo) cria direto; na dúvida registre no rascunho e siga.

- [ ] `/opt/eap/bin/domain.sh` existe (8) · nativas instaladas (3) · `webmin` em `mgmt-users.properties` (4)

**Aula 03**

### Tarefa 2 — Simple domain (30 pts)

```bash
cd /opt/eap
cp -r domain simple
vim simple/configuration/host.xml     # name="simple"  + apagar <servers>...</servers>
vim simple/configuration/domain.xml   # apagar <server-groups>...</server-groups>

/opt/eap/bin/domain.sh -Djboss.domain.base.dir=/opt/eap/simple
```

Grupo (UI: `Runtime → Server Groups → Add`) ou CLI:

```bash
# (CLI conectada: ./jboss-cli.sh -c --controller=127.0.0.1:9990)
/domain/server-group=SimpleGroup:add(profile=default,socket-binding-group=standard-sockets)
```

> ⚠️ **Bind 127.0.0.1 é o default** — nada a mudar nas interfaces. Quem "configura
> de mais" no `host.xml` costuma quebrar o que já funciona.
> ⚠️ Depois de renomear, todo caminho usa **`/host=simple/`**.
> ⚠️ Não pode sobrar `<servers>` nem `<server-groups>` — confira com
> `grep -c '<server' /opt/eap/simple/configuration/host.xml` (deve dar 0).

- [ ] base dir `/opt/eap/simple` (8) · host renomeado (6) · `<servers>` apagado (6) · `<server-groups>` apagado (6) · `SimpleGroup` default/standard-sockets (7) · domínio subiu limpo (3)

**Aula 04**

### Tarefa 3 — JVM do grupo (15 pts)

```bash
# como a prova pergunta (EAP 6 / estilo prova):
/server-group=SimpleGroup/jvm=simple:add(heap-size=1326m,max-heap-size=1326m,permgen-size=325m,max-permgen-size=325m,stack-size=128k)
```

> ⚠️ **A armadilha nº 1 da Parte 1:** no EAP 7.4 (Java 8+) **`permgen-size` não
> existe** — PermGen virou Metaspace. Se a CLI recusar, configure o que ela
> deixar e registre na tela do examinador:
>
> ```bash
> /server-group=SimpleGroup/jvm=simple:add(heap-size=1326m,max-heap-size=1326m,stack-size=128k)
> /server-group=SimpleGroup/jvm=simple:write-attribute(name=jvm-options,value=["-XX:MetaspaceSize=325m","-XX:MaxMetaspaceSize=325m"])
> ```
>
> UI: `Runtime → SimpleGroup → JVM Configuration → Edit`.

- [ ] heap 1326m/1326m (6) · stack 128k (4) · PermGen tratado (tentou + anotou) (5)

**Aula 04 (§ Tarefa 3/3b)**

### Tarefa 4 — SimpleServer + Undertow (20 pts)

```bash
/host=simple/server-config=SimpleServer:add(group=SimpleGroup,auto-start=true)
/host=simple/server-config=SimpleServer/socket-bindings=default:add(port-offset=0)

/profile=default/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=max-connections,value=50)

/profile=default/subsystem=undertow/server=default-server/ajp-listener=ajp:add(socket-binding=ajp,scheme=http,enabled=true)
```

UI (relatos): `Runtime → SimpleGroup → Add` (SimpleServer, offset 0, auto-start ✔);
`Configuration → Profiles → default → Undertow → HTTP → default-server` (Max
connections 50) → `AJP Listener → Add` (`ajp` / socket binding `ajp`).

```bash
# validação:
/host=simple/server-config=SimpleServer:read-resource
/profile=default/subsystem=undertow/server=default-server/http-listener=default:read-attribute(name=max-connections)
/host=simple/server-config=SimpleServer:start()     # 8080 no ar
```

> ⚠️ `max-connections` é no **listener do profile**, não no servidor (armadilha clássica).

- [ ] `SimpleServer` no grupo + auto-start (7) · offset 0 (3) · max-connections=50 (5) · listener `ajp` (5)

**Aula 04**

### Tarefa 5 — Datasources (45 pts)

**a) Driver** — garanta o JDBC4 (`META-INF/services/java.sql.Driver` →
`org.postgresql.Driver`; se já existir, nada a fazer) e deploy pela UI:
`Runtime → Domain: Manage Deployments → Add → Upload → postgresql.jar`.

**b) Não-XA — caminho recomendado (UI, como na prova):**
`Configuration → Profile: default → Datasources → Non-XA → Add` → Name/JNDI →
driver/URL/usuário → **Test Connection** → **Finish** → selecione → **Disable** →
ajuste (tabela do enunciado) → **Enable**.

```bash
/profile=default/subsystem=datasources/data-source=DS_NON_XA:add(jndi-name=java:jboss/DS_NON_XA,driver-name=postgresql,connection-url=jdbc:postgresql://localhost:5432/postgres,user-name=postgres,password=postgres)

/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=min-pool-size,value=5)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=max-pool-size,value=50)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=transaction-isolation,value=TRANSACTION_READ_COMMITTED)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=check-valid-connection-sql,value="SELECT 1")
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=background-validation,value=10000)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=track-statements,value=false)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=prepared-statements-cache-size,value=20)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=share-prepared-statements,value=true)   # se "shared" for pedido
/profile=default/subsystem=datasources/data-source=DS_NON_XA:enable()
```

**c) XA — UI:** `XA Datasources → Add` → driver → **XA datasource class**:
`org.postgresql.xa.PGXADataSource` → propriedades `ServerName/localhost`,
`PortNumber/5432`, `DatabaseName/postgres` → usuário/senha → Test → Enable.

```bash
# CLI equivalente (driver precisa estar registrado com a classe XA — Aula 05 §5.1):
/profile=default/subsystem=datasources/xa-data-source=DS_XA:add(jndi-name=java:jboss/DS_XA,driver-name=postgresql)
/profile=default/subsystem=datasources/xa-data-source=DS_XA/xa-datasource-properties=ServerName:add(value=localhost)
/profile=default/subsystem=datasources/xa-data-source=DS_XA/xa-datasource-properties=PortNumber:add(value=5432)
/profile=default/subsystem=datasources/xa-data-source=DS_XA/xa-datasource-properties=DatabaseName:add(value=postgres)
/profile=default/subsystem=datasources/xa-data-source=DS_XA:write-attribute(name=user-name,value=postgres)
/profile=default/subsystem=datasources/xa-data-source=DS_XA:write-attribute(name=password,value=postgres)
/profile=default/subsystem=datasources/xa-data-source=DS_XA:test-connection()
/profile=default/subsystem=datasources/xa-data-source=DS_XA:enable()
```

**d) Remover o H2 (2 comandos — esquecer o 2º derruba ponto):**

```bash
/profile=default/subsystem=datasources/data-source=ExampleDS:remove()
/profile=default/subsystem=ee/service=default-bindings:undefine-attribute(name=datasource)
```

**e) dstest:** deploy no grupo `SimpleGroup` → `http://localhost:8080/dstest` →
JNDI `java:jboss/DS_NON_XA` → tabela `jbtravel.airport` → repita com `DS_XA`.

> ⚠️ **10 segundos = 10000 ms** (o campo é em milissegundos — erro clássico de
> colocar `10`).
> ⚠️ Pela UI não dá para editar com o DS ativo: **Disable → editar → Enable**.
> ⚠️ O atributo do cache é **`prepared-statements-cache-size`** e o de declarações
> é **`track-statements`** (com "s").

- [ ] driver (5) · não-XA criado (5) · 8 atributos do não-XA (10) · XA criado (7) · propriedades XA (6) · ExampleDS + default-bindings (4) · dstest validou os 2 (8)

**Aula 05 · Aula 06**

### Tarefa 6 — Root context (10 pts)

```bash
/profile=default/subsystem=undertow/server=default-server/host=default-host:write-attribute(name=enable-welcome-root,value=false)
/profile=default/subsystem=undertow/server=default-server/host=default-host:write-attribute(name=default-web-module,value=example.war)
```

Deploy de `example.war` (grupo `SimpleGroup`, **Enable**) → teste
`http://localhost:8080/` (app, **não** a página de boas-vindas) e
`http://localhost:8080/example`.

> ⚠️ `default-web-module` recebe o **runtime name** (`example.war`) — nome errado = 404.
> UI: `Configuration → Profile default → Undertow → Server → default-server → Hosts → default-host`.

- [ ] default-web-module (4) · welcome-root off (3) · deploy e testes OK (3)

**Aula 06**

### Tarefa 7 — Security domain RDBMS (15 pts)

```bash
/profile=default/subsystem=security/security-domain=RDBMS:add(cache-type=default)
/profile=default/subsystem=security/security-domain=RDBMS/authentication=classic:add(login-modules=[{"code"=>"Database","flag"=>"required","module-options"=>[("dsJndiName"=>"java:jboss/DS_NON_XA"),("principalsQuery"=>"select Password from JBTravel.USER where username=?"),("rolesQuery"=>"select null, 'Roles' from JBTravel.USER where username=?")]}])
```

**Aplicação** (descompacte, edite, recompacte):

```bash
mkdir -p /tmp/e2 && cd /tmp/e2 && jar xf /root/materials/example2.war
# crie WEB-INF/jboss-web.xml:
#   <jboss-web><security-domain>RDBMS</security-domain></jboss-web>
# no WEB-INF/web.xml adicione (ou crie):
```

```xml
<security-constraint>
  <web-resource-collection>
    <web-resource-name>All resources</web-resource-name>
    <url-pattern>/*</url-pattern>
  </web-resource-collection>
  <auth-constraint><role-name>*</role-name></auth-constraint>
</security-constraint>
<security-role><role-name>*</role-name></security-role>
<login-config>
  <auth-method>BASIC</auth-method>
  <realm-name>RDBMS</realm-name>
</login-config>
```

```bash
jar cf /root/materials/example2.war .
deploy /root/materials/example2.war --server-groups=SimpleGroup
/host=simple/server-config=SimpleServer:restart()    # mudou profile → reinicia
# teste: http://localhost:8080/example2  →  mobius / jboss
```

> ⚠️ No EAP 7 o parâmetro é **`login-modules=[{...}]`** — `classic:add(code=...)`
> **não existe**.
> ⚠️ Copie os SELECTs **exatamente** como no enunciado (schema, maiúsculas, `?` final).
> ⚠️ O `jboss-web.xml` usa o nome **`RDBMS`** (sem `java:/` — só use `java:/...`
> se o enunciado pedir um nome com esse prefixo).

- [ ] domain + authentication (5) · 3 module-options (4) · app configurada e publicada (4) · login `mobius` OK (2)

**Aula 07**

---

## PARTE 2

### Tarefa 1 — Dois Host Controllers (50 pts)

```bash
cd /opt/eap
cp -r domain node1
cp -r domain node2
```

**Edits no `node1/configuration/host.xml`:**

```xml
<host name="node1" ...>
  <interfaces>
    <interface name="management">
      <inet-address value="${jboss.bind.address.management:192.168.6.11}"/>
    </interface>
    <interface name="public">
      <inet-address value="${jboss.bind.address:192.168.6.11}"/>
    </interface>
    <interface name="unsecure">
      <inet-address value="${jboss.bind.address.unsecure:192.168.6.11}"/>
    </interface>
  </interfaces>
  <!-- apague o bloco <servers> inteiro -->
```

- `node1/configuration/domain.xml`: apague o bloco **`<server-groups>`**.

**Edits no `node2/configuration/host.xml`:** host `name="node2"`, as 3 interfaces
com **`192.168.6.12`** e:

```xml
<domain-controller>
  <!-- apague/comente o <local/> -->
  <remote protocol="remote"
          host="192.168.6.11"
          port="${jboss.domain.master.port:9999}"
          security-realm="ManagementRealm"/>
</domain-controller>
```

> ⚠️ **Offset 0 x offset 0:** os servidores padrão (`server-one` etc.) sobem com
> offset 0 e **conflitam** com `cluster_1`/`cluster_2` — por isso apagamos
> `<servers>`/`<server-groups>`. Se preferir manter, mude os offsets dos antigos
> (ex.: 350) e/ou desligue o auto-start deles.

**Suba os dois** (em terminais separados):

```bash
/opt/eap/bin/domain.sh -Djboss.domain.base.dir=/opt/eap/node1
/opt/eap/bin/domain.sh -Djboss.domain.base.dir=/opt/eap/node2
```

A partir daí, tudo pelo console do master (`http://192.168.6.11:9990`) ou pela CLI:

```bash
# ./jboss-cli.sh -c --controller=192.168.6.11:9990
/domain/server-group=cluster:add(profile=full-ha,socket-binding-group=full-ha-sockets)

# "full JEE com cluster e SEM JMS" → confira e remova a mensageria do full-ha:
/profile=full-ha/subsystem=messaging-activemq:read-resource   # existe? então:
/profile=full-ha/subsystem=messaging-activemq:remove()

/domain/server-group=message:add(profile=full,socket-binding-group=full-sockets)

/host=node1/server-config=cluster_1:add(group=cluster,auto-start=true)
/host=node1/server-config=cluster_1/socket-bindings=default:add(port-offset=0)
/host=node1/server-config=message_1:add(group=message,auto-start=true)
/host=node1/server-config=message_1/socket-bindings=default:add(port-offset=100)

# depois que o node2 registrar no master:
/host=node2/server-config=cluster_2:add(group=cluster,auto-start=true)
/host=node2/server-config=cluster_2/socket-bindings=default:add(port-offset=0)
/host=node2/server-config=message_2:add(group=message,auto-start=true)
/host=node2/server-config=message_2/socket-bindings=default:add(port-offset=100)
```

- [ ] `auto-start=true` **não** sobe servidor criado com o domínio já rodando —
  reinicie os dois HCs (mate os processos e rode os `domain.sh` de novo) **ou**
  dê `:start()` em cada um. Confira os 4 servidores em `Runtime → Domain: Overview`.
- [ ] Se o node2 acusar erro de autenticação ao conectar no master: usuários de
  gestão/gerência iguais nos dois hosts (Aula 08 — `add-user.sh` nos dois).

- [ ] node1: nome/IPs (8) · conflito de offset tratado (6) · grupo `cluster` full-ha **sem** messaging (8) · grupo `message` (5) · cluster_1/message_1 (6) · node2: nome/IP/remote (8) · cluster_2/message_2 (6) · 2 HCs + 4 servidores no ar (3)

**Aula 08**

### Tarefa 2 — Cluster TCP (35 pts)

**Caminho A — stack `tcp` nativa (mais rápido):**

```bash
# o discovery do stack tcp já é TCPPING — só troque os initial_hosts:
/profile=full-ha/subsystem=jgroups/stack=tcp/protocol=TCPPING/property=initial_hosts:write-attribute(name=value,value="192.168.6.11[7600],192.168.6.12[7600]")
/profile=full-ha/subsystem=jgroups/channel=ee:write-attribute(name=stack,value=tcp)
/profile=full-ha/subsystem=jgroups/stack=udp:remove()
```

**Caminho B — criar a stack `tcpping` (o que os relatos fizeram via UI+CLI):**

```bash
/profile=full-ha/subsystem=jgroups/stack="tcpping":add()
/profile=full-ha/subsystem=jgroups/stack="tcpping":add-protocol(type="TCPPING")
/profile=full-ha/subsystem=jgroups/stack="tcpping"/transport="TRANSPORT":add(socket-binding="jgroups-tcp",type="TCP")
/profile=full-ha/subsystem=jgroups/stack="tcpping"/protocol="TCPPING"/property="initial_hosts":add(value="192.168.6.11[7600],192.168.6.12[7600]")
/profile=full-ha/subsystem=jgroups/stack="tcpping"/protocol="TCPPING"/property="port_range":add(value="10")
# + demais protocolos (MERGE2, FD, VERIFY_SUSPECT, NAKACK, UNICAST2, STABLE, GMS,
#   UFC, MFC, FRAG2) — Aula 09 tem a lista completa — e por fim:
/profile=full-ha/subsystem=jgroups/channel=ee:write-attribute(name=stack,value=tcpping)
/profile=full-ha/subsystem=jgroups/stack=udp:remove()
```

> ⚠️ Atenção ao **profile**: aqui é **`full-ha`** (o do grupo `cluster`) — o mesmo
> trecho com `ha` serve quando o grupo usa profile `ha`.
> ⚠️ `initial_hosts` com **underline** e formato `IP[PORTA]` (sem espaço).
> Se o `:add` da stack der erro na CLI, faça as 3 primeiras linhas pela UI
> (`Configuration → Profiles → full-ha → JGroups → View`) e o resto na CLI.

**Deploy + teste:**

```bash
deploy /root/materials/cluster_test.war --server-groups=cluster
/host=node1/server-config=cluster_1:restart()
/host=node2/server-config=cluster_2:restart()
```

- [ ] Logs: `GMS: address=...` listando os **2 membros** nos dois servidores;
- [ ] `curl http://192.168.6.11:8080/cluster_test/` e `http://192.168.6.12:8080/cluster_test/` respondem;
- [ ] só existe stack TCP no profile (udp removida).

- [ ] TCPPING + initial_hosts (10) · canal `ee` na stack certa (6) · udp removida (5) · deploy + restart (4) · 2 membros no log (5) · URLs OK (5)

**Aula 09**

### Tarefa 3 — JMS (40 pts)

```bash
# 1) socket binding ANTES de tudo (a porta 5445 é o "remote-connector"):
/socket-binding-group=full-sockets/socket-binding=remote-connector:add(port=5445)

# 5) remova as factories/destinos padrão (confira os nomes):
/profile=full/subsystem=messaging-activemq:read-children-names(child-type=connection-factory)
/profile=full/subsystem=messaging-activemq/connection-factory=InVmConnectionFactory:remove()
/profile=full/subsystem=messaging-activemq/connection-factory=RemoteConnectionFactory:remove()
/profile=full/subsystem=messaging-activemq/external-queue=DLQ:remove()
/profile=full/subsystem=messaging-activemq/external-queue=ExpiryQueue:remove()

# 2) connection factory de acesso remoto:
/profile=full/subsystem=messaging-activemq/connection-factory=MyRemote:add(connector=[remote-connector],entries=["java:jboss/exported/jms/MyRemote"])

# 3) fila — durable NÃO:
/profile=full/subsystem=messaging-activemq/queue=myQueue:add(durable=false,entries=["java:jboss/queues/myQueue"])

# 4) tópico:
/profile=full/subsystem=messaging-activemq/topic=myTopic:add(entries=["java:jboss/topics/myTopic"])
```

**6) Segurança (UI primeiro — é o que a prova mostra):**

- `Configuration → Profile: full → Messaging → default → View → Security Settings`
  → padrão **`#`** → **Edit** → desmarque **tudo** (Send/Consume/Manage/Durable,
  inclusive a aba **Advanced**) → Save (desativa o guest no padrão);
- `Security Settings → Add` → Pattern **`java:jboss/queues/myQueue`**,
  Role **`guest`**, **Send ✔** → Save.

**Usuário nos dois hosts:**

```bash
cd /opt/eap/bin
export JAVA_OPTS="-Djboss.server.config.user.dir=/opt/eap/node1/configuration"
./add-user.sh     # b → jmsuser → Jms@2026 → groups: guest → yes → yes
export JAVA_OPTS="-Djboss.server.config.user.dir=/opt/eap/node2/configuration"
./add-user.sh     # repita (ou copie application-users/roles.properties do node1)
```

**7) Teste:**

```bash
deploy /root/materials/JMSTest.war --server-groups=message
# http://192.168.6.11:8180/JMSTest/run   (8080 + offset 100)
#   CF:  java:jboss/exported/jms/MyRemote
#   Dest: java:jboss/queues/myQueue   ·   5 mensagens   ·   usuário: jmsuser
```

> ⚠️ Ordem importa: socket binding **antes** da CF; guest desativado **antes**
> de liberar SEND na fila.
> ⚠️ `durable=false` — o `:add` padrão é `durable=true`.
> ⚠️ `8180` = porta do `message_1` (offset 100).
> ⚠️ Se o JMSTest também **consumir** as mensagens e o teste pedir leitura,
> adicione `consume` na mesma Security Setting (os relatos EAP 7 passaram só com SEND).

- [ ] socket binding 5445 (4) · CF `MyRemote` (6) · fila não-durable (4) · tópico (4) · remoções (5) · guest desativado no `#` (5) · usuário nos 2 hosts (4) · SEND na fila (4) · JMSTest enviou 5 (4)

**Aula 11**

### Tarefa 4 — Balanceamento Apache (25 pts)

```bash
dnf install -y httpd
# módulos: pacotes do repositório (mod_proxy_cluster) OU .so dos materiais →
sudo cp -f mod_*.so /etc/httpd/modules/ && sudo chmod 755 /etc/httpd/modules/mod_*.so
grep -n proxy_balancer /etc/httpd/conf/httpd.conf    # DEVE estar comentado
```

**Único arquivo** `/etc/httpd/conf.d/proxy.conf`:

```apache
Listen 192.168.6.11:80
Listen 192.168.6.11:6666

LoadModule slotmem_module modules/mod_slotmem.so
LoadModule proxy_cluster_module modules/mod_proxy_cluster.so
LoadModule manager_module modules/mod_manager.so
LoadModule advertise_module modules/mod_advertise.so

ManagerBalancerName mycluster

<VirtualHost *:80>
  <Location />
      Require all granted
  </Location>
  KeepAliveTimeout 60
  MaxKeepAliveRequests 0
</VirtualHost>

<VirtualHost *:6666>
  <Location />
      Require all granted
  </Location>
  EnableMCPMReceive on
  ServerAdvertise off
  <Location /mod_cluster-manager>
      SetHandler mod_cluster-manager
      Require ip 192.168.6.11
  </Location>
</VirtualHost>
```

```bash
sudo httpd -t && sudo systemctl enable --now httpd && sudo systemctl restart httpd
```

**Lado EAP** (profile do grupo `cluster` — aqui `full-ha`):

```bash
/profile=full-ha/subsystem=modcluster/proxy=default:write-attribute(name=proxies,value=[192.168.6.11:6666])
/profile=full-ha/subsystem=modcluster/proxy=default:write-attribute(name=balancer,value=mycluster)
/profile=full-ha/subsystem=modcluster/proxy=default:write-attribute(name=advertise,value=false)
```

**Testes:**

```bash
curl -s http://192.168.6.11:6666/mod_cluster-manager   # lista cluster_1 e cluster_2
for i in $(seq 8); do curl -s http://192.168.6.11/cluster_test/ >/dev/null; done   # deve alternar backends
```

> ⚠️ **`mycluster` igual dos dois lados** (`ManagerBalancerName` × `balancer`) —
> a divergência é a armadilha mais comum da tarefa.
> ⚠️ Se o manager vier vazio: confira `Listen ...:6666`, `proxies=[ip:6666]` e
> se o Apache subiu sem erro (`httpd -t`).
> ⚠️ RHEL: se o Apache logar *Permission denied* ao falar com o EAP:
> `setsebool -P httpd_can_network_connect 1` (+ `firewall-cmd --add-port=80/tcp --add-port=6666/tcp --permanent && firewall-cmd --reload`).
> ⚠️ Algumas coisas que o enunciado pede **já são default** (ex.: advertise em
> alguns templates) — confira antes de mudar e não quebre o que funciona.

- [ ] httpd + módulos (4) · proxy_balancer comentado (2) · proxy.conf com os Listen/módulos/vhosts (8) · EAP: balancer/advertise/proxies (6) · manager com 2 nós + balanceamento (5)

**Aula 10**

---

## Plano de 4 h

| Parte 1 | min | | Parte 2 | min |
|---|---|---|---|---|
| T1 instalação | 10 | | T1 dois hosts | 45 |
| T2 simple domain | 20 | | T2 cluster TCP | 25 |
| T3 JVM | 10 | | T3 JMS | 35 |
| T4 servidor/undertow | 15 | | T4 Apache | 15 |
| T5 datasources | 40 | | | |
| T6 root | 10 | | | |
| T7 security | 15 | | | |
| **Total** | **120** | | **Total** | **120** |

> Se estourar no T5, corte para 30 min — mas **não pule o T7**: é rápido e quase
> todo mundo perde ponto nele. Da mesma forma, na Parte 2 não gaste 1 h só no
> cluster: JMS + Apache juntos valem mais.

## Armadilhas deste simulado (confira antes de entregar)

| # | Armadilha | Correção |
|---|---|---|
| 1 | `permgen-size` não existe no EAP 7.4 | heap/stack + Metaspace via jvm-options; anote na tela |
| 2 | Procurar `max-connections` no servidor | é no **http-listener do profile** |
| 3 | Prazo de validação em "10" | 10 s = **10000 ms** |
| 4 | Esquecer o 2º passo do H2 | remover ExampleDS **+** `undefine-attribute` do default-bindings |
| 5 | `/host=localhost/...` com host renomeado | o caminho usa o nome real: **`/host=simple`** (Parte 2: `node1`/`node2`) |
| 6 | `classic:add(code=Database)` | parâmetro é **`login-modules=[{...}]`** |
| 7 | SELECT "melhorado" do principalsQuery | copie **byte a byte** do enunciado |
| 8 | Servidor criado mas não subiu | auto-start só age no boot — `:start()` ou reinicie os HCs |
| 9 | Conflito offset 0 na Parte 2 | limpe `<servers>`/`<server-groups>` (ou mude offsets) |
| 10 | `initial-hosts` / `initial-hosts` errado | é **`initial_hosts`** com underline, `IP[7600]` |
| 11 | Fila `durable=true` por default | enunciado pede **não** durable |
| 12 | CF remote sem socket binding | crie `remote-connector:5445` **antes** |
| 13 | Guest ainda ativo no padrão `#` | desmarque **tudo** (Advanced incluído) na UI |
| 14 | Usuário JMS em só um host | `add-user` (ou cópia dos `.properties`) nos **dois** |
| 15 | Balancer diferente Apache × EAP | **`mycluster`** dos dois lados |
| 16 | Apache sem escuta na 6666 | `Listen ...:6666` + `proxies=[192.168.6.11:6666]` |

**Refazer com apoio:** [Simulado curto (teórico+prático)](16-Simulado-com-Gabarito.md) ·
[Laboratório Parte 1](12-Laboratorio-Parte1-Gabarito.md) ·
[Laboratório Parte 2](13-Laboratorio-Parte2-Gabarito.md) ·
[Checklist do dia da prova](17-Checklist-Dia-da-Prova.md)
