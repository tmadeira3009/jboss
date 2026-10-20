# Aula 04 — Parte 1: Simple Domain (tarefas 2 a 5 da prova)

Esta aula cobre: domínio limpo → grupo → JVM → servidor → AJP/max-connections.

## Tarefa 2 — Criar o domínio base e limpá-lo

**Enunciado:** *"Create a new domain base directory named `<NOME>` under `/opt/eap`
and remove all existing server groups and servers. Configure a profile for Java EE web
applications without messaging and non-clustered (default). Create a group named
`<GRUPO>` for that profile."*

### Passo 1 — criar o diretório do domínio

```bash
cd /opt/eap
cp -r domain simple          # nome EXATO pedido na questão (simple, webserver, ...)
chown -R jboss: simple       # se estiver rodando com outro usuário, ajuste
```

### Passo 2 — limpar o host.xml

```bash
vim /opt/eap/simple/configuration/host.xml
```
1. Troque o nome: `<host xmlns="urn:jboss:domain:16.0" name="simple">`
2. **Apague todo o bloco `<servers>...</servers>`** (server-one, server-two, server-three).

### Passo 3 — limpar o domain.xml

```bash
vim /opt/eap/simple/configuration/domain.xml
```
**Apague todo o bloco `<server-groups>...</server-groups>`** (main-server-group e other-server-group).

> ⚠️ Apagar só um dos dois **não basta**. A prova cobra os dois.
> E se você esquecer de apagar os `servers`, depois dá conflito de porta:
> `server-one` (offset 0) colide com o `cluster_1` (offset 0).

### Passo 4 — subir o domínio novo

```bash
/opt/eap/bin/domain.sh -Djboss.domain.base.dir=/opt/eap/simple
```

Bind padrão: management e public em **127.0.0.1** (é o default — se a prova não pedir
outro IP, não mexa).

Conferir no console: `http://127.0.0.1:9990`
- Host `simple` presente
- Zero server groups, zero servers

### Passo 5 — criar o grupo

**Console:** `Runtime → Server Groups → Add`
| Campo | Valor |
|---|---|
| Name | `SimpleGroup` (exatamente como pedir) |
| Profile | `default` (Java EE web, sem mensageria, sem cluster) |
| Socket Binding | `standard-sockets` |

**CLI (alternativa):**
```bash
/profile=default:read-resource   # só pra confirmar o profile
/domain/server-group=SimpleGroup:add(profile=default,socket-binding-group=standard-sockets)
```

---

## Tarefa 3 — Parâmetros de JVM do grupo

**Enunciado:** *heap fixo 1326 MB (min e max), permgen 325 MB (min e max),
Java thread stack 128 KB.*

### Via CLI
```bash
./jboss-cli.sh -c --controller=127.0.0.1:9990

/server-group=SimpleGroup/jvm=simple:add(heap-size=1326m,max-heap-size=1326m,permgen-size=325m,max-permgen-size=325m,stack-size=128k)
```

> **Sobre permgen:** o PermGen **não existe mais no Java 8+** (foi substituído por Metaspace).
> Se a CLI recusar `permgen-size`, a prova está numa versão mais nova do EAP — nesse caso
> configure o que ela deixar configurar (heap e stack) e anote na tela do examinador
> que permgen não é suportado. Nas versões EAP 6.x (Java 7) funciona normalmente.
> Variação dos seus documentos (prova nova): `heap 1322m / max 1322m / stack 312k`
> — **use os números EXATOS do seu enunciado**, eles mudam.

### Via UI
`Runtime → SimpleGroup → JVM Configuration → Edit` → Heap Size / Max Heap Size / Stack Size.

### Via XML (último recurso, domain.xml)
```xml
<server-group name="SimpleGroup" profile="default">
    <jvm name="simple">
        <heap size="1326m" max-size="1326m"/>
        <permgen size="325m" max-size="325m"/>
        <stack size="128k"/>
    </jvm>
    <socket-binding-group ref="standard-sockets"/>
</server-group>
```

### Validação
```bash
/server-group=SimpleGroup/jvm=simple:read-resource
```

---

## Tarefa 3b — JVM em nível de HOST e de SERVER (variação EAP 7)

No EAP 7 existem **três níveis** de JVM, em ordem de precedência (do mais específico
para o mais genérico):

1. **`/host=H/server-config=S/jvm=NAME`** — JVM de um servidor específico;
2. **`/host=H/jvm=NAME`** — JVM default de todo o host;
3. **`/domain/server-group=G/jvm=NAME`** — JVM do grupo (a da Tarefa 3).

Enunciados tipo *"configure the server-level JVM parameters"* ou *"set the JVM options
for the host"* caem nestes dois primeiros níveis — **não** no `server-group`.

### Via CLI
```bash
# nível de HOST (afeta os server-configs que referenciarem esta JVM)
/host=localhost/jvm=default:add(heap-size=2048m,max-heap-size=2048m,jvm-options=["-XX:-UseParallelGC"])

# nível de SERVER (precedência máxima para um servidor)
/host=localhost/server-config=SimpleServer/jvm=default:write-attribute(name=heap-size,value=1024m)
/host=localhost/server-config=SimpleServer/jvm=default:write-attribute(name=max-heap-size,value=2048m)
```

Atributos aceitos (model 7.4): `heap-size`, `max-heap-size`, `max-permgen-size`,
`stack-size`, `java-home`, `jvm-options` (lista), `debug-enabled`, `debug-port`,
`debug-agent`, `env`, `module-options` — **e é assim no host, no server-config e no
server-group** (mesma forma de `jvm`).

### ⚠️ Armadilha `max-permgen-size`
`permgen-size`/`max-permgen-size` **só existe em EAP 6 com Java 7**. No EAP 7.4
(Java 11) a CLI recusa — PermGen foi substituída por **Metaspace** (que não tem limite
fixo configurável). Se a prova for EAP 6.x (objetivo *"manage server settings with
JConsole/permgensize"* ainda existe no exam legado), os parâmetros funcionam.

### Validação
```bash
/host=localhost/jvm=default:read-resource
/host=localhost/server-config=SimpleServer/jvm=default:read-resource
```

---

## Tarefa 4 — Criar o servidor do grupo

**Enunciado:** *Create a server `<NOME>` in the group, port offset 0, auto-start = true.*

**Console:** `Runtime → <SimpleGroup> → Add`
| Campo | Valor |
|---|---|
| Name | `SimpleServer` (ou o nome pedido) |
| Port Offset | `0` |
| Auto Start | ✔ |

**CLI:**
```bash
/host=localhost/server-config=SimpleServer:add(group=SimpleGroup,auto-start=true)
/host=localhost/server-config=SimpleServer/socket-bindings=default:add(port-offset=0)
```

**Valide que subiu:**
```bash
/host=localhost/server-config=SimpleServer:read-resource
ps -ef | grep Server:SimpleServer
```

---

## Tarefa 5a — Máximo de conexões HTTP = 50

**Console:**
`Configuration → Profile: default → Web/HTTP - Undertow → HTTP → default-server → Edit`
→ **Max connections: 50** → Save

**CLI (EAP 7, undertow):**
```bash
/profile=default/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=max-connections,value=50)
```

**CLI (EAP 6, subsystem web):**
```bash
/profile=default/subsystem=web/connector=http:write-attribute(name=max-connections,value=50)
```

**Valide:**
```bash
/profile=default/subsystem=undertow/server=default-server/http-listener=default:read-attribute(name=max-connections)
```

---

## Tarefa 5b — Habilitar o conector AJP

**Console:**
`Configuration → Profile: default → Web/HTTP - Undertow → HTTP → default-server`
→ **AJP Listeners → Add**
| Campo | Valor |
|---|---|
| Name | `ajp` |
| Socket Binding | `ajp` |

**CLI (2 comandos — socket binding + listener):**
```bash
/socket-binding-group=standard-sockets/socket-binding=ajp:add(port=8009)
/profile=default/subsystem=undertow/server=default-server/ajp-listener=ajp:add(socket-binding=ajp,scheme=http,enabled=true)
```

**Valide:**
```bash
/profile=default/subsystem=undertow/server=default-server:read-children-names(child-type=ajp-listener)
# esperado: ["ajp"]
```

---

## Erros comuns desta etapa

| Erro | Sintoma | Correção |
|---|---|---|
| Esqueceu de apagar `server-groups` | `server-one` sobe e conflita | Apagar o bloco no domain.xml |
| Grupo com profile errado | Questão reprova silenciosamente | `default` = sem cluster e sem JMS |
| Não reiniciou depois de editar XML | Config não vale | Reinicie o `domain.sh` |
| AJP sem socket binding | CLI erro `socket-binding not found` | Criar o `socket-binding=ajp` antes |
| Offset 0 duplicado | Servidor não sobe (`BindException`) | Dar offset 350 no server-one |

## Exercício

Faça a Parte 1 até aqui do zero, **sem consultar material**, em até 25 minutos:
instalar/limpar domínio → grupo → JVM → servidor → max-connections → AJP.
Depois valide com os 4 comandos de `read-resource` acima.
