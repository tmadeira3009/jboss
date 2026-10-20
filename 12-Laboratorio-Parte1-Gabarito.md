# Laboratório Prático — PARTE 1 (gabarito completo)

**Meta:** executar a Parte 1 inteira em até **1h50**, sem consultar nada além deste roteiro.
Repeta **duas vezes** até conseguir sem parar.

> Substitua `<NOME>`, `<JNDI>`, IPs, usuário e senha pelos valores do **seu** enunciado.
> Os valores abaixo são os dos relatos de prova (simple / SimpleGroup / DS_NON_XA...).

---

## ETAPA 1 — Instalação (5 min)

```bash
java -jar jboss-eap-installer.jar
# → diretório EXATO pedido (ex.: /opt/eap) + criar usuário de gerenciamento

# validar
cd /opt/eap/bin && ./domain.sh          # sobe, confira :9990, pare com Ctrl+C
```

## ETAPA 2 — Novo domínio limpo (15 min)

```bash
cd /opt/eap
cp -r domain simple
chown -R $USER simple

vim simple/configuration/host.xml
  # name="simple"  e  APAGAR o bloco <servers>...</servers>

vim simple/configuration/domain.xml
  # APAGAR o bloco <server-groups>...</server-groups>

# subir
/opt/eap/bin/domain.sh -Djboss.domain.base.dir=/opt/eap/simple
```

Validação: `http://127.0.0.1:9990` → Host `simple`, **0** server groups, **0** servers.

**Criar o grupo** (Runtime → Server Groups → Add):
```
Name: SimpleGroup   Profile: default   Socket Binding: standard-sockets
```
```bash
/domain/server-group=SimpleGroup:add(profile=default,socket-binding-group=standard-sockets)
```

## ETAPA 3 — JVM do grupo (5 min)

```bash
/server-group=SimpleGroup/jvm=simple:add(heap-size=1326m,max-heap-size=1326m,\
   permgen-size=325m,max-permgen-size=325m,stack-size=128k)
```
*(use os números do seu enunciado — variações vistas: heap 1322m, stack 312k/265k)*

Validação:
```bash
/server-group=SimpleGroup/jvm=simple:read-resource
```

## ETAPA 4 — Servidor do grupo (5 min)

Runtime → SimpleGroup → Add: `Name=SimpleServer`, `Port Offset=0`, `Auto Start=✔`
```bash
/host=simple/server-config=SimpleServer:add(group=SimpleGroup,auto-start=true)
```
Validação: `ps -ef | grep SimpleServer`

## ETAPA 5 — Max connections + AJP (10 min)

```bash
# HTTP máx. 50 conexões
/profile=default/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=max-connections,value=50)

# AJP
/socket-binding-group=standard-sockets/socket-binding=ajp:add(port=8009)
/profile=default/subsystem=undertow/server=default-server/ajp-listener=ajp:add(socket-binding=ajp,scheme=http,enabled=true)
```

Validação:
```bash
/profile=default/subsystem=undertow/server=default-server/http-listener=default:read-attribute(name=max-connections)
/profile=default/subsystem=undertow/server=default-server:read-children-names(child-type=ajp-listener)
```

## ETAPA 6 — Driver JDBC (10 min)

```bash
# conferir JDBC4
jar -tf postgresql.jar | grep java.sql.Driver
# se não existir:
mkdir -p META-INF/services && echo org.postgresql.Driver > META-INF/services/java.sql.Driver
jar -uf postgresql.jar META-INF/services/java.sql.Driver
```
Deploy: `Runtime → Manage Deployments → Add → postgresql.jar → Assign → SimpleGroup → Enable`

*(Alternativa CLI: `module add --name=com.postgresql --resources=... --dependencies=javax.api,javax.transaction.api` +
`/subsystem=datasources/jdbc-driver=postgresql:add(...)`)*

## ETAPA 7 — Datasource Non-XA (20 min)

`Configuration → Profile: default → Datasources → Non-XA → Add`
```
Name: DS_NON_XA    JNDI: java:jboss/DS_NON_XA
Driver: postgresql
URL: jdbc:postgresql://localhost:5432/postgres    user/pass: postgres/postgres
Test Connection → Finish
```
Depois: **Disable** → configure → **Enable**:
```
Pool      → Min 5, Max 50            (ou o número do enunciado)
Connection→ Transaction Isolation: TRANSACTION_READ_COMMITTED
Validation→ Check Valid SQL: SELECT 1 | Background Validation: ✔ | Millis: 10000
Statements→ Track Statements: false | Prepared Statement Cache Size: 20
```

CLI-resumo:
```bash
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=min-pool-size,value=5)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=max-pool-size,value=50)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=transaction-isolation,value=TRANSACTION_READ_COMMITTED)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=check-valid-connection-sql,value="SELECT 1")
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=background-validation,value=10000)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=track-statements,value=false)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=prepared-statements-cache-size,value=20)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:enable()
```

## ETAPA 8 — Datasource XA (10 min)

```
XADDatasources → Add
Name: DS_XA   JNDI: java:jboss/DS_XA
Driver: postgresql  → Properties: ServerName=localhost, PortNumber=5432, DatabaseName=postgres
user/postgres pass/postgres → Test Connection → Enable
```

## ETAPA 9 — Remover o H2 (5 min) ⚠️ DOIS COMANDOS

```bash
/profile=default/subsystem=datasources/data-source=ExampleDS:remove()
/profile=default/subsystem=ee/service=default-bindings:undefine-attribute(name=datasource)
```

Validação:
```bash
/profile=default/subsystem=datasources:read-children-names(child-type=data-source)
```

## ETAPA 10 — Testar com dstest.war (5 min)

```
Runtime → Manage Deployments → dstest.war → Assign SimpleGroup → Enable
http://localhost:8080/dstest
  JNDI: java:jboss/DS_NON_XA     Table: jbtravel.airport
```

## ETAPA 11 — App como ROOT (15 min)

```bash
/profile=default/subsystem=undertow/server=default-server/host=default-host:write-attribute(name=enable-welcome-root,value=false)
/profile=default/subsystem=undertow/server=default-server/host=default-host:write-attribute(name=default-web-module,value=example.war)
# (alternativa: editar WEB-INF/jboss-web.xml com <context-root>/</context-root>)
```
Deploy `example.war` → `http://localhost:8080/` deve abrir a aplicação.

## ETAPA 12 — Security Domain RDBMS (20 min)

```
Profile: default → Security → Security Domains → Add
  Name: JBTravel   Cache Type: default
  → Authentication → Add: Code=Database, Flag=required
  → Module Options → Add:
      dsJndiName      = java:jboss/DS_NON_XA      (ou o XA, conforme enunciado)
      principalsQuery = select password from JBTravel.USER where username=?
      rolesQuery      = select null,'Roles' from JBTravel.USER where username=?
```

Preparar `example2.war`:
```bash
jar -xf example2.war
cat > WEB-INF/jboss-web.xml <<'EOF'
<jboss-web><security-domain>JBTravel</security-domain></jboss-web>
EOF
# web.xml: security-constraint (/*, role *) + login-config BASIC
jar -cf example2.war *
```
Deploy + **restart do servidor** + teste com usuário/senha do enunciado.

---

## CHECKLIST FINAL DA PARTE 1 (marque tudo)

- [ ] Domínio novo com o nome pedido, sem servers e sem server-groups
- [ ] Grupo criado com profile `default` + `standard-sockets`
- [ ] JVM: heap/permgen/stack nos valores pedidos
- [ ] Servidor criado com offset/auto-start pedidos
- [ ] max-connections = 50
- [ ] AJP listener ativo
- [ ] Driver JDBC ok
- [ ] DS Non-XA: todos os 7 parâmetros
- [ ] DS XA com 3 properties
- [ ] ExampleDS removido + default-bindings limpo
- [ ] dstest funcionando
- [ ] Aplicação na raiz (`:8080/`)
- [ ] Security Domain + app protegida autenticando

**⚠️ Não desligue o ambiente. Deixe tudo no ar — a Parte 2 começa em cima disso
(alguns enunciados mantêm a Parte 1 rodando no localhost).**
