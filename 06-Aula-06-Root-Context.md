# Aula 06 — Aplicação como ROOT (context-root)

**Enunciado:** *"Deploy the application `example.war` as the root (context `/`) of the
server. Disable the welcome page."*

Duas formas de resolver. **A prova aceita qualquer uma** (relato dos documentos:
*"o mesmo pode ser alcançado com `default-web-module` no domain.xml, que não exige
abrir a war"*).

---

## Opção A — Via configuração do servidor (sem mexer na .war) ✅ mais rápido

### Passo 1 — desligar a página de boas-vindas

**Console:**
`Configuration → Profile: default → Web/HTTP - Undertow → HTTP → default-server →
Hosts → default-host → Edit` → **Enable Welcome Root: false**

**CLI (EAP 7):**
```bash
/profile=default/subsystem=undertow/server=default-server/host=default-host:write-attribute(name=enable-welcome-root,value=false)
```

**CLI (EAP 6, subsystem web):**
```bash
/profile=default/subsystem=web/virtual-server=default-host:write-attribute(name=enable-welcome-root,value=false)
```

### Passo 2 — declarar a war como módulo padrão do host

**Console:** mesmo local → **Default Web Module** = `example.war`

**CLI (EAP 7):**
```bash
/profile=default/subsystem=undertow/server=default-server/host=default-host:write-attribute(name=default-web-module,value=example.war)
```

**XML (domain.xml)** — equivalente, dentro do profile:
```xml
<host name="default-host" enable-welcome-root="false" default-web-module="example.war">
    <!--<location name="/" handler="welcome-content"/>-->   <!-- comente esta linha -->
</host>
```

### Passo 3 — deploy + teste
```
Runtime → Manage Deployments → example.war → Assign → SimpleGroup → Enable
http://localhost:8080/            → deve mostrar a aplicação
http://localhost:8080/example     → também funciona (contexto original continua)
```

---

## Opção B — Mudando a própria aplicação (`jboss-web.xml`)

A prova dá a dica: *"you may need to open the war file"*.

```bash
cd /tmp
jar -xvf example.war
```

### Criar/editar `WEB-INF/jboss-web.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<jboss-web xmlns="http://www.jboss.org/xml/ns/javaee">
    <context-root>/</context-root>
</jboss-web>
```

### Empacotar de volta
```bash
jar -cvf example.war *
# ou, se o arquivo já existe e você só adicionou um:
jar -uf example.war WEB-INF/jboss-web.xml
```

### Desligar a welcome root (igual ao Passo 1 acima) — **obrigatório junto**

Sem desligar a welcome root, a página de boas-vindas continua capturando `/`.

---

## Variação: personalizar a página inicial (`welcome-file`)

Se a prova pedir "a página inicial da aplicação deve ser `index.jsp`", crie/edite
`WEB-INF/web.xml` dentro da war:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://java.sun.com/xml/ns/javaee" version="3.0">
  <display-name>minha-app</display-name>
  <welcome-file-list>
    <welcome-file>index.html</welcome-file>
    <welcome-file>index.jsp</welcome-file>
    <welcome-file>default.html</welcome-file>
  </welcome-file-list>
</web-app>
```

---

## Checklist

- [ ] `enable-welcome-root = false`
- [ ] `default-web-module` = `<app>.war` **OU** `<context-root>/</context-root>` na war
- [ ] Deploy atribuído ao server group e **Enabled**
- [ ] `http://<host>:8080/` mostra a aplicação (não a página de boas-vindas do EAP)

## Erros comuns

| Sintoma | Causa |
|---|---|
| `/` ainda mostra a página de boas-vindas | Esqueceu `enable-welcome-root=false` |
| `/` mostra 404 | `default-web-module` com nome errado (tem que ser o **runtime name** da war) |
| App só abre em `/example` | Só fez deploy, não configurou o root |

## Exercício

Publique `example.war` como raiz pelas **duas** opções (primeiro A, depois B) e
confirme que `http://localhost:8080/` carrega a aplicação nos dois casos.
