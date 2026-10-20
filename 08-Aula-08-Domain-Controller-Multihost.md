# Aula 08 — Parte 2: Domain Controller com dois Hosts

**Enunciado clássico:**

```
Configure domain in a multi-homed environment:
 a) Master host  hostname "node1"  IP 192.168.6.11 (varia: 172.25.X.9)
 b) Slave  host  hostname "node2"  IP 192.168.6.12 (varia: 172.25.X.10)
 c) Servers ... port offset 100
 d) Servers ... port offset 300
 Note: All configuration must be done in host.xml.
```

**Antes de qualquer coisa:** leia TODAS as questões da Parte 2 e desenhe o ambiente
no rascunho (hosts, IPs, grupos, servidores, offsets, portas).

---

## 8.1 Preparar os dois base directories

```bash
cd /opt/eap
cp -r domain node1 && chown -R jboss node1
cp -r domain node2 && chown -R jboss node2
```

---

## 8.2 NODE1 — Domain Controller (master)

### `node1/configuration/host.xml`
```xml
<host xmlns="urn:jboss:domain:16.0" name="node1">
  <domain-controller>
      <local/>                       <!-- ele é o mestre -->
  </domain-controller>
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

  <servers>
      <!-- ou apague o bloco, ou mude os offsets para não conflitar -->
      <server name="server-one" group="main-server-group" auto-start="false">
          <socket-bindings port-offset="350"/>
      </server>
  </servers>
</host>
```

> **ARMADILHA N.º 1 DA PROVA:** `server-one` vem com **offset 0** e o `cluster_1`
> também será offset 0 → **conflito de porta** e o cluster não sobe.
> Soluções aceitas: apagar o `<servers>` **ou** jogar o offset para **350**
> **ou** deixar `auto-start="false"`. Os seus relatos usam as três (a terceira:
> *"eu só os deixei com auto-start = false e consegui 300"*).

### `node1/configuration/domain.xml`
- Ajustar as interfaces para o IP do node1 (se necessário).
- **Remover `<server-groups>` padrão** e criar os seus (via UI/CLI, abaixo).

### Subir
```bash
/opt/eap/bin/domain.sh -Djboss.domain.base.dir=/opt/eap/node1
```
Console: `http://192.168.6.11:9990`

### Criar os grupos e servidores do node1

`Runtime → Server Groups → Add`:

| Name | Profile | Socket Binding |
|---|---|---|
| `cluster` (ou `CServer-group` / `clustered`) | `ha` **ou** `full-ha` | `ha-sockets` **ou** `full-ha-sockets` |
| `message` (ou `MServer-group` / `mailbox`) | `full` | `full-sockets` |

`Runtime → <grupo> → Add` (servidores):

| Server | Grupo | Port Offset | Auto Start |
|---|---|---|---|
| `cluster_1` | cluster | **0** | ✔ |
| `message_1` | message | **100** | ✔ |

*(Na variação mais nova da prova: grupo `clustered` full-ha porta 8080 → `clustered_s1`;
grupo `mailbox` full → `mailbox_s1` porta 8280, etc. Sempre use os nomes do enunciado.)*

### Profile "Full JEE com cluster e SEM mensageria"

Se a prova pedir isso, existem dois caminhos:

```bash
# caminho 1: tirar a mensageria do full-ha
/opt/eap/bin/jboss-cli.sh --controller=192.168.6.11:9990 -c
/profile=full-ha/subsystem=messaging-activemq:remove()

# caminho 2: usar o profile ha (já é cluster sem mensageria)
# e criar o grupo com profile=ha, socket-binding-group=ha-sockets
```

---

## 8.3 NODE2 — Host Controller (slave)

### `node2/configuration/host.xml`
```xml
<host xmlns="urn:jboss:domain:16.0" name="node2">
  <domain-controller>
      <!--local/-->                                            <!-- comente/apague o <local/> -->
      <remote protocol="remote"
              host="192.168.6.11"                              <!-- IP do node1 -->
              port="${jboss.domain.master.port:9999}"
              security-realm="ManagementRealm"/>
  </domain-controller>
  <interfaces>
      <interface name="management">
          <inet-address value="${jboss.bind.address.management:192.168.6.12}"/>
      </interface>
      <interface name="public">
          <inet-address value="${jboss.bind.address:192.168.6.12}"/>
      </interface>
      <interface name="unsecure">
          <inet-address value="${jboss.bind.address.unsecure:192.168.6.12}"/>
      </interface>
  </interfaces>
  <!-- servers: mesmas regras de offset do node1 -->
</host>
```

> No EAP 6 a tag é `<remote host="..." port="9999" security-realm="ManagementRealm"/>`
> e às vezes você vê `${jboss.domain.master.address:IP}`. Mesma coisa.

### Usuários de aplicação iguais nos dois hosts
O slave precisa das **mesmas credenciais** de `application-users.properties` /
`application-roles.properties` do master (isso é obrigatório para JMS e para o
slave conectar no master quando o enunciado exige):
```bash
cd /opt/eap/bin
# gere no master
export JAVA_OPTS="-Djboss.server.config.user.dir=/opt/eap/node1/configuration"; ./add-user.sh
# copie para o node2
cp -a /opt/eap/node1/configuration/application-users.properties   /opt/eap/node2/configuration/
cp -a /opt/eap/node1/configuration/application-roles.properties   /opt/eap/node2/configuration/
```

### Subir
```bash
/opt/eap/bin/domain.sh -Djboss.domain.base.dir=/opt/eap/node2
```

### Servidores do node2

| Server | Grupo | Port Offset | Auto Start |
|---|---|---|---|
| `cluster_2` | cluster | **0** | ✔ |
| `message_2` | message | **100** | ✔ |

> No **domain mode os grupos são globais** — você cria os grupos uma vez (no node1)
> e no node2 só cria os **server-configs** apontando para esses mesmos grupos,
> escolhendo o host.

---

## 8.4 Comandos CLI equivalentes (node1)

```bash
# grupos
/domain/server-group=cluster:add(profile=ha,socket-binding-group=ha-sockets)
/domain/server-group=message:add(profile=full,socket-binding-group=full-sockets)

# servidores no node1
/host=node1/server-config=cluster_1:add(group=cluster,auto-start=true)
/host=node1/server-config=cluster_1/socket-bindings=default:add(port-offset=0)
/host=node1/server-config=message_1:add(group=message,auto-start=true)
/host=node1/server-config=message_1/socket-bindings=default:add(port-offset=100)

# servidores no node2 (executar via console do master, host=node2)
/host=node2/server-config=cluster_2:add(group=cluster,auto-start=true)
/host=node2/server-config=cluster_2/socket-bindings=default:add(port-offset=0)
/host=node2/server-config=message_2:add(group=message,auto-start=true)
/host=node2/server-config=message_2/socket-bindings=default:add(port-offset=100)
```

---

## 8.5 Validação

```bash
# console do master
http://192.168.6.11:9990  → Runtime → Hosts: node1 e node2 presentes
                            → Server Groups: cluster e message
                            → Start All Servers

ps -ef | grep "Server:"     # cluster_1, message_1, cluster_2, message_2 rodando

# portas por IP
ss -tlnp | grep 8080        # cluster_1 (node1) e cluster_2 (node2)
ss -tlnp | grep 8180        # message_1 (node1) e message_2 (node2)

# testes
curl http://192.168.6.11:8080/
curl http://192.168.6.12:8080/
```

## Checklist

- [ ] `node1` nome certo, interfaces no IP do master, `<local/>`
- [ ] `node2` nome certo, interfaces no IP do slave, `<remote host=master>`
- [ ] Servers padrão removidos ou com offset/auto-start ajustados (offset 350!)
- [ ] Grupos: cluster (ha/full-ha) e message (full)
- [ ] Servidores com offsets exatos (0 e 100, ou os pedidos)
- [ ] Todos os 4 servidores no ar
- [ ] Usuários `application-*` iguais nos dois hosts

## Exercício

Monte o ambiente de dois hosts do zero em até 30 minutos e valide com `ps` + `ss` +
console. Só depois siga para o cluster (Aula 09).
