# Laboratório Prático — PARTE 2 (gabarito completo)

**Meta:** executar a Parte 2 em até **1h50**. Repita **duas vezes**.
Use o rascunho: desenhe hosts, IPs, grupos, servidores, offsets **antes** de executar.

> IPs/nomes do relato: node1 = `192.168.6.11`, node2 = `192.168.6.12`.
> Substitua pelos do seu enunciado (variações: `172.25.6.9/.10`, `192.168.56.x`).

---

## ETAPA 1 — Ler tudo e rascunhar (10 min)

No papel:
```
node1 (master, .11)  → grupo cluster (offset 0) + grupo message (offset 100)
node2 (slave,  .12)  → cluster_2 (offset 0) + message_2 (offset 100)
port offset 100 → HTTP 8180   |   offset 0 → HTTP 8080
```

## ETAPA 2 — Base directories (5 min)

```bash
cd /opt/eap
cp -r domain node1 && cp -r domain node2
chown -R $USER node1 node2
```

## ETAPA 3 — node1 master (20 min)

`node1/configuration/host.xml`:
- `name="node1"`
- interfaces: management/public/unsecure → `192.168.6.11`
- `<domain-controller><local/></domain-controller>`
- **`<servers>`: apague ou mude o server-one para `port-offset="350"`** ⚠️

`node1/configuration/domain.xml`: apague os `<server-groups>` padrão.

```bash
/opt/eap/bin/domain.sh -Djboss.domain.base.dir=/opt/eap/node1
```

Console `http://192.168.6.11:9990`:

**Server Groups → Add**
| Name | Profile | Socket Binding |
|---|---|---|
| `cluster` | `ha` (ou `full-ha`, se pedir Full JEE) | `ha-sockets` |
| `message` | `full` | `full-sockets` |

**Servidores no node1**
| Name | Group | Offset | Auto-start |
|---|---|---|---|
| `cluster_1` | cluster | 0 | ✔ |
| `message_1` | message | 100 | ✔ |

*Se pedir "Full JEE com cluster sem mensageria":*
```bash
/profile=full-ha/subsystem=messaging-activemq:remove()
# e crie o grupo com profile=full-ha, socket-binding=full-ha-sockets
```

## ETAPA 4 — node2 slave (15 min)

`node2/configuration/host.xml`:
- `name="node2"`
- interfaces → `192.168.6.12`
- domain-controller:
```xml
<domain-controller>
    <remote protocol="remote" host="192.168.6.11"
            port="${jboss.domain.master.port:9999}" security-realm="ManagementRealm"/>
</domain-controller>
```
- `<servers>`: idem cuidado com offset (350 ou auto-start false)

```bash
# usuários de aplicação iguais nos dois hosts (necessário para JMS)
cp -a /opt/eap/node1/configuration/application-users.properties /opt/eap/node2/configuration/
cp -a /opt/eap/node1/configuration/application-roles.properties /opt/eap/node2/configuration/

/opt/eap/bin/domain.sh -Djboss.domain.base.dir=/opt/eap/node2
```

Console do master → host `node2` → Server Configurations:
| Name | Group | Offset | Auto-start |
|---|---|---|---|
| `cluster_2` | cluster | 0 | ✔ |
| `message_2` | message | 100 | ✔ |

**Start All Servers** e valide:
```bash
ps -ef | grep "Server:"     # 4 servidores
ss -tlnp | grep -E '8080|8180'
```

## ETAPA 5 — Cluster TCP (25 min)

```bash
/opt/eap/bin/jboss-cli.sh --controller=192.168.6.11:9990 -c

# stack tcpping
/profile=ha/subsystem=jgroups/stack="tcpping":add()
/profile=ha/subsystem=jgroups/stack="tcpping":add-protocol(type="TCPPING")
/profile=ha/subsystem=jgroups/stack="tcpping"/transport="TRANSPORT":add(socket-binding="jgroups-tcp",type="TCP")
/profile=ha/subsystem=jgroups/stack="tcpping"/protocol="TCPPING"/property="initial_hosts":add(value="192.168.6.11[7600],192.168.6.12[7600]")
/profile=ha/subsystem=jgroups/stack="tcpping"/protocol="TCPPING"/property="port_range":add(value="10")
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

# só TCP: apontar o canal ee e remover a udp
/profile=ha/subsystem=jgroups/channel=ee:write-attribute(name=stack,value=tcpping)
/profile=ha/subsystem=jgroups/stack=udp:remove()
```

Reinicie os servers do grupo cluster, faça deploy de `cluster_test.war` e valide:
```bash
grep -i "GMS\|view" /opt/eap/node1/servers/cluster_1/log/server.log
# http://192.168.6.11:8080/cluster_test/  e  http://192.168.6.12:8080/cluster_test/
```

## ETAPA 6 — Balanceamento Apache (25 min)

```bash
# módulos
sudo cp -f *.so /etc/httpd/modules/ && sudo chmod 755 /etc/httpd/modules/mod_*.so
grep proxy_bala /etc/httpd/conf/httpd.conf     # deve estar comentado
```

`/etc/httpd/conf.d/proxy.conf`:
```apache
Listen 192.168.6.11:80
LoadModule slotmem_module modules/mod_slotmem.so
LoadModule proxy_cluster_module modules/mod_proxy_cluster.so
LoadModule manager_module modules/mod_manager.so
LoadModule advertise_module modules/mod_advertise.so
ManagerBalancerName Mybalancer
<VirtualHost *:80>
  <Location /> Require all granted </Location>
  KeepAliveTimeout 60
  MaxKeepAliveRequests 0
  EnableMCPMReceive on
  ServerAdvertise off
  <Location /mod_cluster-manager>
      SetHandler mod_cluster-manager
      Require ip 192.168.6.11
  </Location>
</VirtualHost>
```
```bash
sudo httpd -t && sudo systemctl restart httpd
```

EAP (`Configuration → Profile: ha → Web → mod_cluster`):
```
Balancer: Mybalancer   Advertise: false   Connector: ajp   Proxy List: 192.168.6.11:6666
```
```bash
/profile=ha/subsystem=modcluster/proxy=default:write-attribute(name=proxies,value=[192.168.6.11:6666])
/profile=ha/subsystem=modcluster/proxy=default:write-attribute(name=balancer,value=Mybalancer)
/profile=ha/subsystem=modcluster/proxy=default:write-attribute(name=advertise,value=false)
```

**Teste:** `http://192.168.6.11/mod_cluster-manager` lista os 2 nós;
`http://192.168.6.11/cluster_test` alterna entre os nós.

## ETAPA 7 — JMS (25 min)

Grupo `message` (profile `full`).

1. **Socket binding remoto** (se usou connector netty/remote):
   ```bash
   /socket-binding-group=full-sockets/socket-binding=remote-connector:add(port=5445)
   ```
2. **Remova** as connection factories e destinations padrão (Console → Messaging → default → View).
3. **Add Connection Factories**
   ```
   InVmConnectionFactory    java:jboss/ConnectionFactory                       connector: in-vm
   RemoteConnectionFactory  java:jboss/exported/jms/RemoteConnectionFactory    connector: netty/remote-connector
   ```
4. **Add Queue** (+ Topic se pedir):
   ```
   Name: myQueue   JNDI: java:jboss/queues/myQueue   Durable: ✔(se pedir)  Selector: (vazio)
   ```
5. **Security Settings**
   - padrão `#`: desmarque **tudo** (desativar guest no default)
   - Add: Pattern = fila criada, Role = `guest`, **Send ✔**
6. **Usuário**:
   ```bash
   export JAVA_OPTS="-Djboss.server.config.user.dir=/opt/eap/node1/configuration"
   /opt/eap/bin/add-user.sh        # b → user/senha da questão → groups: guest → yes → yes
   # repita para node2 (troque o dir) ou copie os .properties
   ```
7. **Teste**: deploy `JMSTest.war` no grupo message →
   `http://<ip>:8180/JMSTest/run` →
   CF `java:jboss/ConnectionFactory`, fila `java:jboss/queues/myQueue`, 5 mensagens.

---

## CHECKLIST FINAL DA PARTE 2

- [ ] node1 master (IP certo) e node2 slave apontando para o master
- [ ] Offset dos servers padrão tratado (350 / auto-start false) — sem conflito
- [ ] Grupos `cluster` e `message` com profiles corretos
- [ ] 4 servidores no ar com offsets corretos
- [ ] Cluster TCP formado (2 membros no log) + cluster_test OK
- [ ] UDP removida (se exigido)
- [ ] Apache balanceando e `/mod_cluster-manager` com os 2 nós
- [ ] JMS: 2 factories, fila, segurança, usuário `guest`, JMSTest OK

## SIMULADO FINAL

Peça a um colega (ou você mesmo) para **trocar** nome de domínio, JNDIs, IPs, usuários,
tamanhos de heap e números de pool — e refaça as duas partes do zero cronometrado.
Se você concluir as duas partes em **3h30** com 100% do checklist, está pronto para a prova.
