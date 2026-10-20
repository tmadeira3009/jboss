# Aula 02 — Arquitetura do JBoss EAP (o que você precisa entender)

Toda a prova acontece em **Domain Mode**. Se você entender esta aula, metade da prova vira
cópia e cola do seu próprio rascunho.

## 1. Standalone x Domain

```
standalone mode: 1 JVM = 1 servidor        (configuração: standalone.xml)
domain mode:     N servidores controlados  (configuração: domain.xml + host.xml)
```

A prova quase sempre usa **domain mode**, porque ela cobra agrupamento de servidores,
cluster e distribuição de configuração.

## 2. Os processos de um domain mode

```
                    ┌─────────────────────────────┐
                    │      Domain Controller      │  ← dono do domain.xml
                    │  (Host Controller + gerência│     publica o console 9990
                    │   e os server-groups)       │
                    └──────────────┬──────────────┘
                                   │ (porta 9999/remote)
                    ┌──────────────┴──────────────┐
                    │       Host Controller        │  ← só tem host.xml
                    │      (escravo / slave)       │     aponta para o master
                    └──────────────┬──────────────┘
                          ┌────────┴────────┐
                     server-A           server-B   ← JVMs das aplicações
```

- **Process Controller** — processo pai, gerencia os Host Controllers.
- **Host Controller** — lê o `host.xml`; se for master, também publica o `domain.xml`.
- **Server** — a JVM de verdade onde roda a aplicação (é quem atende a porta 8080).

## 3. Os dois arquivos de configuração que a prova pede para você mexer

### `configuration/host.xml` — "quem é esta máquina"
```xml
<host xmlns="urn:jboss:domain:16.0" name="node1">     <!-- 1) NOME DO HOST -->

  <domain-controller>                                  <!-- master: <local/> -->
      <remote host="192.168.6.11" port="9999"          <!-- slave: <remote .../> -->
               security-realm="ManagementRealm"/>
  </domain-controller>

  <interfaces>
      <interface name="public">
          <inet-address value="${jboss.bind.address:192.168.6.11}"/>  <!-- 2) IP -->
      </interface>
      ...
  </interfaces>

  <servers>                                            <!-- 3) SERVIDORES -->
      <server name="server-one" group="main-server-group" auto-start="true">
          <socket-bindings port-offset="0"/>
      </server>
  </servers>
</host>
```

### `configuration/domain.xml` — "quais perfis, grupos e subsistemas existem"
```xml
<profiles>
  <profile name="default"> ... undertow, datasources, security ... </profile>
  <profile name="full">    ... + messaging-activemq ... </profile>
  <profile name="ha">      ... + jgroups (cluster) ... </profile>
  <profile name="full-ha"> ... tudo: cluster + mensageria ... </profile>
</profiles>

<socket-binding-groups>
  <socket-binding-group name="standard-sockets"> porta 8080, 9990, 8009(ajp) ... </socket-binding-group>
  <socket-binding-group name="full-sockets">    ... </socket-binding-group>
  <socket-binding-group name="full-ha-sockets"> ... + jgroups-tcp 7600 ... </socket-binding-group>
</socket-binding-groups>

<server-groups>
  <server-group name="SimpleGroup" profile="default">
      <jvm name="simple"> <heap size="1326m" max-size="1326m"/> </jvm>
      <socket-binding-group ref="standard-sockets"/>
  </server-group>
</server-groups>
```

## 4. Profiles — qual usar em cada questão da prova

| Profile | Cluster | Mensageria (JMS) | Uso na prova |
|---|---|---|---|
| `default` | não | não | Parte 1: "aplicações web Java EE sem mensageria e não clusterizadas" |
| `full` | não | **sim** | Grupo `message` / `mailbox` da Parte 2 |
| `ha` | **sim** | não | Grupo `cluster` quando pede cluster sem mensageria |
| `full-ha` | sim | sim | Quando pede Full JEE com cluster **e** mensageria |

> **Pegadinha clássica da prova:** pedem "Full JEE com cluster, **sem** mensageria".
> Solução: use `full-ha` e **remova o subsystem de mensageria**:
> ```
> /profile=full-ha/subsystem=messaging-activemq:remove()
> ```
> Ou use `ha` + `ha-sockets` (é o que os seus relatos indicam como mais simples).

## 5. Portas padrão que você vai usar

| Porta | O que é |
|---|---|
| 8080 | HTTP das aplicações (+ offset) |
| 9990 | Console de gerenciamento (HTTP management) |
| 9999 | Native management (domain controller) |
| 4447 / 8080 | Remoto EJB |
| 8009 | AJP (precisa ser habilitado na prova) |
| 7600 | JGroups TCPPING |
| 8008/8443 | HTTPS (não cai) |

**Port offset:** porta final = porta base + offset.
`server` com `offset=100` → HTTP em **8180**, console do servidor em **10090**.
É por isso que o relato da prova insiste: *"olhe o offset, principalmente os com offset 0"* —
`server-one` (offset 0) conflita com `cluster_1` (offset 0). Dica dos documentos:
**mova o `server-one` para offset 350** ou desative o auto-start dele.

## 6. Console (UI) x CLI — os dois caminhos

### Console de gerenciamento — `http://<ip>:9990`
- Abas principais: **Configuration** (configura) e **Runtime** (opera: start/stop/deploy).
- No domain, você escolhe o **Profile** (Configuration) e o **Host** (Runtime).
- Deploy: `Runtime → Domain: Manage Deployments → Add → Assign to <server-group> → Enable`.

### CLI (`jboss-cli.sh`) — mais rápido
```bash
# conectar no modo domínio
/opt/eap/bin/jboss-cli.sh -c --controller=127.0.0.1:9990
# ou a partir do bin
./jboss-cli.sh --connect --controller=192.168.6.11:9990
```
Prompt: `[domain@192.168.6.11:9990 /]`

Comandos genéricos:
```bash
# ver recursos
/profile=default/subsystem=undertow:read-resource(recursive=true)
# alterar atributo
/profile=default/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=max-connections,value=50)
# deploy
deploy /caminho/example.war --server-groups=SimpleGroup
# histórico (sua salvação)
history
```

**Regra prática:** o que é **1 tarefa** faça na **UI** (menos erro de digitação);
o que é **repetitivo ou exige XML** faça na **CLI**.

## 7. Como o deploy funciona no domain

1. `Runtime → Domain: Manage Deployments → Add` → envia o artefato ao **content repository**;
2. Atribui ao **server group** (nunca a um servidor isolado);
3. Marca **Enable**;
4. O arquivo aparece em `/opt/eap/<dominio>/data/content/` e é exposto em
   `http://<host>:8080/nome-da-war`.

## Exercício desta aula

Monte no papel o diagrama do ambiente da Parte 2:
- node1 (master, IP .11) com `cluster_1` (offset 0) e `message_1` (offset 100)
- node2 (slave, IP .12) com `cluster_2` (offset 0) e `message_2` (offset 100)
- marque as portas HTTP finais de cada servidor.

*(Respostas: cluster_1 → 8080, message_1 → 8180, cluster_2 → 8080, message_2 → 8180 —
cada um no seu IP.)*
