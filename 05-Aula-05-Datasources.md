# Aula 05 — Datasources (tarefas 6 e 7 da prova)

É a tarefa com **mais itens corrigidos** da Parte 1. Cada parâmetro vale ponto.

---

## 5.1 Instalar o driver JDBC

**Enunciado:** *"Configure JDBC driver `postgresql.jar` from `http://materials.example.com/postgresql.jar`"*
(versões novas da prova usam **MySQL**: `jdbc:mysql://localhost:3306/bookstoreDB`, user
`bookstoreDB`, senha `redhat`).

### Garantir o padrão JDBC4 (auto-descoberta do driver)

```bash
jar -xvf postgresql.jar
mkdir -p META-INF/services
echo "org.postgresql.Driver" > META-INF/services/java.sql.Driver
jar -cvf postgresql.jar *
```
Se o jar já tiver `META-INF/services/java.sql.Driver`, **não precisa fazer nada**.

### Opção A — Deploy do jar (mais simples, usada nos relatos)

`Runtime → Domain: Manage Deployments → Add → Upload → (se necessário ajuste o
Runtime Name para `postgresql.jar`) → Finish`

### Opção B — Módulo + registro do driver (via CLI)

```bash
# fora da conexão (comando de servidor)
module add --name=com.postgresql --resources=/opt/materials/postgresql.jar \
           --dependencies=javax.api,javax.transaction.api

# conectado na CLI
/subsystem=datasources/jdbc-driver=postgresql:add(driver-name=postgresql,driver-module-name=com.postgresql)
```

Para **XA** o driver precisa declarar a classe XA:
```bash
/profile=default/subsystem=datasources/jdbc-driver=postgresql:add(
    driver-name=postgresql,
    driver-module-name=com.postgresql,
    xa-datasource-class=org.postgresql.xa.PGXADataSource)
```
MySQL: `xa-datasource-class=com.mysql.jdbc.jdbc2.optional.MXADataSource`
(na prova nova: driver name `mysql`, URL `jdbc:mysql://localhost:3306/bookstoreDB`).

---

## 5.2 DataSource Non-XA

**Enunciado típico (varia a cada prova):**

```
Name: DS_NON_XA (ou NoTransaction / JBTravel)
JNDI: java:jboss/DS_NON_XA (ou java:jboss/datasources/bookstore)
URL:  jdbc:postgresql://localhost:5432/postgres
User/Pass: postgres/postgres
Minimum connections: 5
Maximum connections: 20 (ou 50, ou 7 — use o número do enunciado)
Transaction isolation: TRANSACTION_READ_COMMITTED
Validation SQL: SELECT 1
Background validation: a cada 10 segundos (10000 ms)
Track statements: false
Statement cache size: 20
```

### Via Console (caminho recomendado)

`Configuration → Profile: default → Connector → Datasources → Non-XA → Add`

1. **Add**: Name e JNDI Name (os da questão) → Next
2. **Connection Settings**: Driver Name (o do jar deployado), Connection URL,
   Username, Password → **Test Connection** → Finish
3. **Selecione o datasource → Disable** (não dá pra editar com ele ativo)
4. **Pool**: Min Pool Size = 5, Max Pool Size = 20/50
5. **Connection**: Transaction Isolation = `TRANSACTION_READ_COMMITTED`
6. **Validation**: Check Valid SQL = `SELECT 1` ✔ / Background Validation ✔ /
   Validation Millis = `10000`
7. **Statements**: Track Statements = `false`, Statement Cache Size = `20`, 
   ✔ *Use Shared Prepared Statements* (se pedido)
8. **Enable** novamente

> ⚠️ **Unidade de tempo:** a prova fala "a cada 10 segundos" e o campo é em
> **milissegundos** → `10000`. Erro clássico de colocar `10`.

### Via CLI (equivalente)

```bash
# criar
/profile=default/subsystem=datasources/data-source=DS_NON_XA:add(
   jndi-name=java:jboss/DS_NON_XA,
   driver-name=postgresql,
   connection-url=jdbc:postgresql://localhost:5432/postgres,
   user-name=postgres,password=postgres)

# parâmetros exigidos
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=min-pool-size,value=5)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=max-pool-size,value=20)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=transaction-isolation,value=TRANSACTION_READ_COMMITTED)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=valid-connection-checker-class-name,value=org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLValidConnectionChecker)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=check-valid-connection-sql,value="SELECT 1")
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=background-validation,value=10000)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=background-validation-millis,value=10000)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=track-statements,value=false)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:write-attribute(name=statement-cache-size,value=20)
/profile=default/subsystem=datasources/data-source=DS_NON_XA:enable()
```

**Valide tudo de uma vez:**
```bash
/profile=default/subsystem=datasources/data-source=DS_NON_XA:read-resource(recursive=true)
```

---

## 5.3 DataSource XA

**Enunciado:** usar `org.postgresql.xa.PGXADataSource`, serverName/localhost,
portNumber/5432, databaseName/postgres, user/senha postgres.
(Na prova MySQL: classe `MXADataSource`, ServerName localhost, DatabaseName `bookstore`.)

### Console
`Configuration → Profile: default → Datasources → XA Datasources → Add`
1. Name + JNDI Name (da questão) → Next
2. Driver (detectado) → Next
3. **Properties** → Add: `ServerName=localhost`, `PortNumber=5432`, `DatabaseName=postgres`
4. Username/Password → Next → **Test Connection** → Finish → **Enable**

### CLI
```bash
/profile=default/subsystem=datasources/xa-data-source=DS_XA:add(
   jndi-name=java:jboss/DS_XA, driver-name=postgresql)

/profile=default/subsystem=datasources/xa-data-source=DS_XA/xa-datasource-properties=ServerName:add(value=localhost)
/profile=default/subsystem=datasources/xa-data-source=DS_XA/xa-datasource-properties=PortNumber:add(value=5432)
/profile=default/subsystem=datasources/xa-data-source=DS_XA/xa-datasource-properties=DatabaseName:add(value=postgres)

/profile=default/subsystem=datasources/xa-data-source=DS_XA:write-attribute(name=user-name,value=postgres)
/profile=default/subsystem=datasources/xa-data-source=DS_XA:write-attribute(name=password,value=postgres)
/profile=default/subsystem=datasources/xa-data-source=DS_XA:test-connection()
/profile=default/subsystem=datasources/xa-data-source=DS_XA:enable()
```

---

## 5.4 Remover o ExampleDS (H2) — cobrado!

**Enunciado:** *"Remove the existing H2 datasource"* / *"remova a fonte de dados dos
drivers h2 já existentes"*.

São **dois** passos — esquecer o segundo reprova:

```bash
# 1) remover o datasource
/profile=default/subsystem=datasources/data-source=ExampleDS:remove()

# 2) desvincular do default-bindings do subsystem ee
/profile=default/subsystem=ee/service=default-bindings:undefine-attribute(name=datasource)
```

Via UI: `Datasources → ExampleDS → Remove` **e**
`Profile: default → Subsystem: EE → Default Bindings → DataSource → limpar o campo`.

**Valide:**
```bash
/profile=default/subsystem=datasources:read-children-names(child-type=data-source)
# não deve mais conter ExampleDS
```

---

## 5.5 Testar com o `dstest.war`

```bash
# deploy
http://localhost:9990 → Runtime → Manage Deployments → dstest.war →
   Assign to SimpleGroup → Enable

# uso
http://localhost:8080/dstest
JNDI Name of Datasource: java:jboss/DS_NON_XA   (ou o XA, um de cada vez)
Table Name to Query:     jbtravel.airport        (ou bookstore.CatalogItem na prova MySQL)
```

Erro típico no teste: colocar o JNDI errado (com/sem `java:jboss/`) ou a tabela errada.

---

## Checklist de correção automática desta tarefa

- [ ] Driver deployado/registrado
- [ ] DS Non-XA criada com nome e JNDI exatos
- [ ] Test Connection OK
- [ ] min/max pool
- [ ] TRANSACTION_READ_COMMITTED
- [ ] valid SQL `SELECT 1` + background validation 10000 ms
- [ ] track-statements = false
- [ ] statement-cache-size = 20
- [ ] DS XA criada com as 3 properties + user/senha
- [ ] ExampleDS (H2) removido **e** default-bindings limpo
- [ ] dstest funcionando

## Exercício

Configure Non-XA **e** XA com PostgreSQL, remova o H2, rode o dstest com cada um e
aponte na tela os 11 itens do checklist acima.
