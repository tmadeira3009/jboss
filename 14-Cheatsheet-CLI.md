# Cheatsheet — Todos os comandos CLI da prova

Copie para um `.sh` de estudo ou imprima. **Não leve para a prova** (a prova é sem
consultas externas, mas você pode ter seus rascunhos no papel).

## Conexão

```bash
# a partir do bin do EAP
./jboss-cli.sh -c --controller=127.0.0.1:9990
./jboss-cli.sh --connect --controller=192.168.6.11:9990

# executar um comando único (sem entrar no shell)
./jboss-cli.sh -c --controller=127.0.0.1:9990 --commands="/subsystem=datasources:read-resource"

# fora do domínio (comandos locais de servidor)
./jboss-cli.sh
module add --name=com.postgresql --resources=/path/postgresql.jar --dependencies=javax.api,javax.transaction.api
deploy /path/example.war --server-groups=SimpleGroup
undeploy example.war --server-groups=SimpleGroup
```

## Navegação / inspeção

```bash
/read-resource(recursive=true)
ls
whoami
history
/profile=default:read-resource(recursive=true)
/profile=default/subsystem=undertow:read-children-names(child-type=server)
/host=<nome>:read-children-names(child-type=server-config)   # no lab: /host=simple
/domain:read-children-names(child-type=server-group)
:completion                       # ajuda de autocompletar de caminho
```

## Domínio: grupos, servidores, JVM

```bash
/domain/server-group=SimpleGroup:add(profile=default,socket-binding-group=standard-sockets)
/domain/server-group=SimpleGroup:remove()
/domain/server-group=SimpleGroup/jvm=simple:add(heap-size=1326m,max-heap-size=1326m,stack-size=128k)
/domain/server-group=SimpleGroup/jvm=simple:write-attribute(name=heap-size,value=1024m)

/host=simple/server-config=SimpleServer:add(group=SimpleGroup,auto-start=true)
/host=simple/server-config=SimpleServer/socket-bindings=default:add(port-offset=0)
/host=simple/server-config=SimpleServer:write-attribute(name=auto-start,value=false)
/host=simple/server-config=SimpleServer:start()
/host=simple/server-config=SimpleServer:stop()
/host=simple/server-config=SimpleServer:restart()
/host=simple/server-config=SimpleServer:read-resource

# JVM em nível de HOST (define a JVM default de todos os server-configs do host)
/host=simple/jvm=default:add(heap-size=2048m,max-heap-size=2048m,jvm-options=["-XX:-UseParallelGC"])

# JVM em nível de SERVER (específico de um server-config; tem precedência)
/host=simple/server-config=SimpleServer/jvm=default:write-attribute(name=heap-size,value=1024m)
/host=simple/server-config=SimpleServer/jvm=default:write-attribute(name=max-heap-size,value=2048m)
```

## Undertow: conexões HTTP e AJP

```bash
/profile=default/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=max-connections,value=50)
/socket-binding-group=standard-sockets/socket-binding=ajp:add(port=8009)
/profile=default/subsystem=undertow/server=default-server/ajp-listener=ajp:add(socket-binding=ajp,scheme=http,enabled=true)
/profile=default/subsystem=undertow/server=default-server/host=default-host:write-attribute(name=enable-welcome-root,value=false)
/profile=default/subsystem=undertow/server=default-server/host=default-host:write-attribute(name=default-web-module,value=example.war)
/profile=default/subsystem=undertow/server=default-server/host=default-host/location=\/:remove

# EAP 6 (subsystem web)
/profile=default/subsystem=web/connector=http:write-attribute(name=max-connections,value=50)
/profile=default/subsystem=web/virtual-server=default-host:write-attribute(name=enable-welcome-root,value=false)
/profile=default/subsystem=web/virtual-server=default-host:write-attribute(name=default-web-module,value=example.war)
```

## Datasources

```bash
# driver
/subsystem=datasources/jdbc-driver=postgresql:add(driver-name=postgresql,driver-module-name=com.postgresql)
/profile=default/subsystem=datasources/jdbc-driver=postgresql:add(driver-name=postgresql,driver-module-name=org.postgresql,xa-datasource-class=org.postgresql.xa.PGXADataSource)

# non-xa
/profile=default/subsystem=datasources/data-source=DS_NON_XA:add(jndi-name=java:jboss/DS_NON_XA,driver-name=postgresql,connection-url=jdbc:postgresql://localhost:5432/postgres,user-name=postgres,password=postgres)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=min-pool-size,value=5)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=max-pool-size,value=50)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=transaction-isolation,value=TRANSACTION_READ_COMMITTED)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=check-valid-connection-sql,value="SELECT 1")
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=background-validation,value=10000)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=track-statements,value=false)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=prepared-statements-cache-size,value=20)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:enable()
/profile=default/subsystem=datasources/data-source=DS_NON_XA:disable()
/profile=default/subsystem=datasources/data-source=DS_NON_XA:test-connection()
/profile=default/subsystem=datasources/data-source=DS_NON_XA:read-resource(recursive=true)

# xa
/profile=default/subsystem=datasources/xa-data-source=DS_XA:add(jndi-name=java:jboss/DS_XA,driver-name=postgresql)
/profile=default/subsystem=datasources/xa-data-source=DS_XA/xa-datasource-properties=ServerName:add(value=localhost)
/profile=default/subsystem=datasources/xa-data-source=DS_XA/xa-datasource-properties=PortNumber:add(value=5432)
/profile=default/subsystem=datasources/xa-data-source=DS_XA/xa-datasource-properties=DatabaseName:add(value=postgres)
/profile=default/subsystem=datasources/xa-data-source=DS_XA:write-attribute(name=user-name,value=postgres)
/profile=default/subsystem=datasources/xa-data-source=DS_XA:write-attribute(name=password,value=postgres)
/profile=default/subsystem=datasources/xa-data-source=DS_XA:enable()
/profile=default/subsystem=datasources/xa-data-source=DS_XA:test-connection()

# remover H2 (DOIS comandos!)
/profile=default/subsystem=datasources/data-source=ExampleDS:remove()
/profile=default/subsystem=ee/service=default-bindings:undefine-attribute(name=datasource)
```

## Security Domain

```bash
/profile=default/subsystem=security/security-domain=JBTravel:add(cache-type=default)
/profile=default/subsystem=security/security-domain=JBTravel/authentication=classic:add(login-modules=[{"code"=>"Database","flag"=>"required","module-options"=>[("dsJndiName"=>"java:jboss/DS_NON_XA"),("principalsQuery"=>"select password from JBTravel.USER where username=?"),("rolesQuery"=>"select null,'Roles' from JBTravel.USER where username=?")]}])

# variante LDAP (fonte externa)
/profile=default/subsystem=security/security-domain=LdapDomain:add(cache-type=default)
/profile=default/subsystem=security/security-domain=LdapDomain/authentication=classic:add(login-modules=[{"code"=>"Ldap","flag"=>"required","module-options"=>[("java.naming.provider.url"=>"ldap://ldap.example.com:389"),("baseCtxDN"=>"ou=People,dc=example,dc=com"),("baseFilter"=>"(uid={0})"),("rolesCtxDN"=>"ou=Groups,dc=example,dc=com"),("roleFilter"=>"(uniqueMember={1})"),("roleAttributeID"=>"cn")]}])

/profile=default/subsystem=security/security-domain=JBTravel:remove()
```
> ⚠️ EAP 7: o parâmetro é `login-modules=[{...}]`. `classic:add(code=...)` não existe.

## Logging (subsystem logging)

```bash
# domain: SEMPRE com /profile=X/ (em standalone: /subsystem=logging/...)
/profile=default/subsystem=logging/root-logger=ROOT:write-attribute(name=level,value=DEBUG)
/profile=default/subsystem=logging/root-logger=ROOT:add-handler(name=CONSOLE)
/profile=default/subsystem=logging/root-logger=ROOT:remove-handler(name=FILE)

/profile=default/subsystem=logging/console-handler=CONSOLE:add(level=INFO,auto-flush=true)
/profile=default/subsystem=logging/periodic-rotating-file-handler=FILE:add(file={path="server.log",relative-to="jboss.server.log.dir"},suffix=".yyyy-MM-dd",level=INFO)

/profile=default/subsystem=logging/logger=org.example:add(level=DEBUG,handlers=[CONSOLE])
/profile=default/subsystem=logging/logger=org.example:remove()

/profile=default/subsystem=logging:read-resource(recursive=true)
# logs em: EAP_HOME/domain/servers/<server>/log/server.log
```

## Snapshots da configuração (XML)

```bash
take-snapshot(name="antes-da-questao",comment="backup")    # raiz do model: /take-snapshot(...)
list-snapshots
delete-snapshot(name="antes-da-questao")
delete-snapshot(all=true)

# RESTAURAR (não existe :restore-snapshot no EAP 7!)
# standalone:  ./standalone.sh --server-config=standalone_xml_history/snapshot/<arquivo>
# domain:      ./domain.sh --host-config=host_xml_history/snapshot/<arquivo>
# ou copiar o snapshot de volta: cp domain.xml.bak domain/configuration/domain.xml
```

## JGroups / Cluster

```bash
/profile=ha/subsystem=jgroups:read-attribute(name=default-stack)
/profile=ha/subsystem=jgroups:read-children-names(child-type=stack)
/profile=ha/subsystem=jgroups/stack="tcpping":add()
/profile=ha/subsystem=jgroups/stack="tcpping":add-protocol(type="TCPPING")
/profile=ha/subsystem=jgroups/stack="tcpping"/transport="TRANSPORT":add(socket-binding="jgroups-tcp",type="TCP")
/profile=ha/subsystem=jgroups/stack="tcpping"/protocol="TCPPING"/property="initial_hosts":add(value="192.168.6.11[7600],192.168.6.12[7600]")
/profile=ha/subsystem=jgroups/stack="tcpping"/protocol="TCPPING"/property="port_range":add(value=10)
/profile=ha/subsystem=jgroups/channel=ee:write-attribute(name=stack,value=tcpping)
/profile=ha/subsystem=jgroups/stack=udp:remove()
/profile=full-ha/subsystem=messaging-activemq:remove()      # full-ha sem mensageria

# cluster seguro (AUTH antes de pbcast.GMS; confera o índice com read-attribute name=protocols)
/profile=ha/subsystem=jgroups/stack=tcpping:read-attribute(name=protocols)
/profile=ha/subsystem=jgroups/stack=tcpping/protocol=AUTH:add(add-index=7)
/profile=ha/subsystem=jgroups/stack=tcpping/protocol=AUTH/token=plain:add(shared-secret-reference={clear-text="segredo"})
# criptografia dos canais (antes de pbcast.NAKACK; chave AES base64 igual nos nós)
/profile=ha/subsystem=jgroups/stack=tcpping/protocol=SYM_ENCRYPT:add(add-index=4,properties={secret_key="MDEyMzQ1Njc4OWFiY2RlZg=="})
```

## Messaging / JMS

```bash
/socket-binding-group=full-sockets/socket-binding=remote-connector:add(port=5445)
/profile=full/subsystem=messaging-activemq/connection-factory=InVmConnectionFactory:add(connector=[in-vm],entries=["java:jboss/ConnectionFactory"])
/profile=full/subsystem=messaging-activemq/connection-factory=RemoteConnectionFactory:add(connector=[remote-connector],entries=["java:jboss/exported/jms/RemoteConnectionFactory"])
/profile=full/subsystem=messaging-activemq/queue=myQueue:add(durable=true,entries=["java:jboss/queues/myQueue"])
/profile=full/subsystem=messaging-activemq/queue=ExpiryQueue:remove()
/profile=full/subsystem=messaging-activemq/security-setting=default:remove()
/profile=full/subsystem=messaging-activemq/security-setting=JBQueue:add()
/profile=full/subsystem=messaging-activemq/security-setting=JBQueue/permission=queue:add(action=["send"],roles=["guest"],match="java:jboss/queues/myQueue")
```

## mod_cluster (balanceamento)

```bash
/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=proxy1:add(host=192.168.6.11,port=6666)
/profile=ha/subsystem=modcluster/proxy=default:write-attribute(name=proxies,value=[192.168.6.11:6666])
/profile=ha/subsystem=modcluster/proxy=default:write-attribute(name=balancer,value=Mybalancer)
/profile=ha/subsystem=modcluster/proxy=default:write-attribute(name=advertise,value=false)
/profile=ha/subsystem=modcluster/proxy=default:write-attribute(name=connector,value=ajp)
```

## SSL / HTTPS (Elytron, EAP 7.4)

```bash
# keystore gerado: keytool -genkeypair -alias jboss -keyalg RSA -keystore <config-dir>/server.jks ...
/profile=default/subsystem=elytron/key-store=exampleKS:add(type=JKS,relative-to=jboss.server.config.dir,path=server.jks,credential-reference={clear-text="changeit"},required=true)
/profile=default/subsystem=elytron/key-manager=exampleKM:add(key-store=exampleKS,credential-reference={clear-text="changeit"})
/profile=default/subsystem=elytron/server-ssl-context=exampleSSC:add(key-manager=exampleKM,protocols=["TLSv1.2","TLSv1.3"])
/socket-binding-group=standard-sockets/socket-binding=https:add(port=8443,interface=public)
/profile=default/subsystem=undertow/server=default-server/https-listener=https:add(socket-binding=https,ssl-context=exampleSSC)

# SSL na interface de gestão (guia oficial)
security enable-ssl-management --interactive

# teste
curl -k https://localhost:8443/
```

## Deploy

```bash
deploy /tmp/example.war --server-groups=SimpleGroup
deploy /tmp/example.war --server-groups=SimpleGroup --disabled
deploy --name=example.war --runtime-name=example.war --server-groups=SimpleGroup
undeploy example.war --server-groups=SimpleGroup
:reload                          # (standalone) / para domain: restart dos servers
```

## Truques de CLI que salvam tempo

```bash
# pegar o caminho de um atributo que você não conhece
/profile=default/subsystem=datasources:read-resource-description(recursive=true)

# executar em lote (colar de uma vez)
batch
/subsystem=datasources/data-source=DS:write-attribute(name=min-pool-size,value=5)
/subsystem=datasources/data-source=DS:write-attribute(name=max-pool-size,value=50)
run-batch

# histórico e correção
Ctrl+A / Ctrl+E     # início/fim da linha
history             # lista comandos anteriores
!!                  # repete o último (em shells)
```

## Senhas de console sem digitar toda vez

```bash
./jboss-cli.sh -c --controller=127.0.0.1:9990 --user=admin --password=senha
```
