# Aula 09 — Cluster JGroups somente TCP

**Enunciado clássico:**

```
Configure TCP clustering:
 a) Use the appropriate profile for CServers — must be clustered and must NOT have
    messaging ability.
 b) Make these two servers into a cluster using TCP clustering.
 c) Deploy cluster_test.war and check the application output.
```

E a variação que derruba aluno: *"o profile **não pode permitir nenhum outro tipo de
cluster além do TCP**"* → você precisa **remover a stack UDP**.

---

## 9.1 Escolher o profile certo

| Se a prova pede | Profile | Socket Binding |
|---|---|---|
| Full JEE + cluster **com** mensageria | `full-ha` | `full-ha-sockets` |
| Full JEE + cluster **sem** mensageria | `ha` (ou `full-ha` com messaging removido) | `ha-sockets` |
| Só cluster de web (EAP 6) | `ha` | `ha-sockets` |

Remover a mensageria do `full-ha` (se for o caso):
```bash
/opt/eap/bin/jboss-cli.sh --controller=192.168.6.11:9990 -c
/profile=full-ha/subsystem=messaging-activemq:remove()
```

---

## 9.2 Trocar o padrão (UDP) por TCP e criar a stack TCPPING

**Console:**
`Configuration → Profile: ha (ou full-ha) → Core → JGroups → View`
- **Default Stack** = `tcp`
- (Se existir a stack `udp`, **delete-a** — é o que o enunciado "só TCP" exige.)

**XML (`domain.xml`, dentro do profile):**
```xml
<subsystem xmlns="urn:jboss:domain:jgroups:8.0" default-stack="tcp">
    <stack name="tcp">
        <transport type="TCP" socket-binding="jgroups-tcp"/>
        <protocol type="TCPPING">
            <property name="initial_hosts">192.168.6.11[7600],192.168.6.12[7600]</property>
            <property name="port_range">10</property>
            <property name="timeout">3000</property>
            <property name="num_initial_members">2</property>
        </protocol>
        <protocol type="MERGE2"/>
        <protocol type="FD_SOCK" socket-binding="jgroups-tcp-fd"/>
        <protocol type="FD"/>
        <protocol type="VERIFY_SUSPECT"/>
        <protocol type="BARRIER"/>
        <protocol type="pbcast.NAKACK"/>
        <protocol type="UNICAST2"/>
        <protocol type="pbcast.STABLE"/>
        <protocol type="pbcast.GMS"/>
        <protocol type="UFC"/>
        <protocol type="MFC"/>
        <protocol type="FRAG2"/>
        <protocol type="RSVP"/>
    </stack>
    <!-- stack "udp" removida -->
</subsystem>
```

**CLI — criar a stack e os protocolos:**
```bash
/profile=ha/subsystem=jgroups/stack="tcpping":add()
/profile=ha/subsystem=jgroups/stack="tcpping":add-protocol(type="TCPPING")
/profile=ha/subsystem=jgroups/stack="tcpping"/transport="TRANSPORT":add(socket-binding="jgroups-tcp",type="TCP")

/profile=ha/subsystem=jgroups/stack="tcpping"/protocol="TCPPING"/property="initial_hosts":add(value="192.168.6.11[7600],192.168.6.12[7600]")
/profile=ha/subsystem=jgroups/stack="tcpping"/protocol="TCPPING"/property="port_range":add(value="10")
/profile=ha/subsystem=jgroups/stack="tcpping"/protocol="TCPPING"/property="timeout":add(value="3000")
/profile=ha/subsystem=jgroups/stack="tcpping"/protocol="TCPPING"/property="num_initial_members":add(value="2")

/profile=ha/subsystem=jgroups/stack="tcpping":add-protocol(type="MERGE2")
/profile=ha/subsystem=jgroups/stack="tcpping":add-protocol(type="FD")
/profile=ha/subsystem=jgroups/stack="tcpping":add-protocol(type="VERIFY_SUSPECT")
/profile=ha/subsystem=jgroups/stack="tcpping":add-protocol(type="pbcast.NAKACK")
/profile=ha/subsystem=jgroups/stack="tcpping":add-protocol(type="UNICAST2")
/profile=ha/subsystem=jgroups/stack="tcpping":add-protocol(type="pbcast.STABLE")
/profile=ha/subsystem=jgroups/stack="tcpping":add-protocol(type="pbcast.GMS")
/profile=ha/subsystem=jgroups/stack="tcpping":add-protocol(type="UFC")
/profile=ha/subsystem=jgroups/stack="tcpping":add-protocol(type="MFC")
/profile=ha/subsystem=jgroups/stack="tcpping":add-protocol(type="FRAG2")

# declarar a stack como padrão do canal ee (usado pelo web cluster)
/profile=ha/subsystem=jgroups/channel=ee:write-attribute(name=stack,value=tcp)
```

> Se o `:add` da stack der erro, faça a criação das 3 primeiras linhas pela **UI**
> (Configuration → Profile → JGroups → View) e o restante pela CLI — é o que os seus
> documentos recomendam.

**Remover a stack udp (quando exigido):**
```bash
/profile=ha/subsystem=jgroups/stack=udp:remove()
```

---

## 9.3 Portas envolvidas

| Binding | Porta | Para quê |
|---|---|---|
| `jgroups-tcp` | 7600 | JGroups (TCPPING) |
| `jgroups-tcp-fd` | 7800 | Failure detection (FD_SOCK) |
| HTTP do servidor | 8080 + offset | Aplicação |

Confira o socket binding no `domain.xml` / em
`Configuration → Socket Bindings → standard-sockets (ou full-ha-sockets) → jgroups-tcp`.

---

## 9.4 Reiniciar tudo e publicar o teste

1. Pare os servidores de cluster e suba de novo (ou reinicie o domain inteiro):
   ```bash
   /host=node1/server-config=cluster_1:restart()
   /host=node1/server-config=cluster_2:restart()
   ```
2. `Runtime → Manage Deployments → Add → cluster_test.war → Assign → grupo cluster → Enable`
3. Verifique o **log dos dois servidores** por algo do tipo:
   ```
   GMS: address=node1:cluster_1/web, cluster=web, physical address=192.168.6.11:7700
   GMS: address=node2:cluster_2/web, cluster=web, physical address=192.168.6.12:7700
   ```
   Ou, no EAP 7: mensagens de `Infinispan`/`jgroups` formando o cluster e a mensagem
   de view view size = 2.
4. Teste as duas URLs:
   ```
   http://192.168.6.11:8080/cluster_test/
   http://192.168.6.12:8080/cluster_test/
   ```
   A aplicação deve mostrar os **nós do cluster** (o mesmo sessionid/ID de nó muda
   conforme o servidor que atendeu).

---

## Diagnóstico de cluster que não forma

| Sintoma | Verifique |
|---|---|
| Só 1 nó na view | `initial_hosts` com IPs/portas errados (tem que ser `IP[7600]` dos **dois** nós) |
| `BindException` | offset duplicado (server-one x cluster_1) — mude o offset |
| Nem sobe | `default-stack` apontando para stack inexistente (udp removida mas ainda referenciada) |
| Firewall bloqueia | `firewall-cmd --permanent --add-port=7600/tcp` e 7800/tcp, depois reload |
| Profile errado | Grupo de cluster apontando para profile sem JGroups |

**Verificação rápida via CLI:**
```bash
/profile=ha/subsystem=jgroups:read-attribute(name=default-stack)
/profile=ha/subsystem=jgroups:read-children-names(child-type=stack)
```

> **Se a prova pedir "secure communications"**: autenticação e criptografia dos canais
> JGroups (AUTH, SYM_ENCRYPT) têm regras de posição próprias — veja a **Aula 19, Parte C**.

## Checklist

- [ ] Grupo cluster usa profile com JGroups e **sem** mensageria (se pedido)
- [ ] `default-stack = tcp`
- [ ] Stack `tcpping` com `initial_hosts` dos dois IPs na porta 7600
- [ ] Stack `udp` removida (se o enunciado exigir "somente TCP")
- [ ] cluster_test.war no ar nos dois nós
- [ ] Log mostra os 2 membros formando o cluster

## Exercício

Forme o cluster TCP do zero, mate um dos nós (`kill`) e confirme que o outro continua
servindo a aplicação (failover) — é exatamente o que a prova verifica depois.
