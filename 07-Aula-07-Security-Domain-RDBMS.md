# Aula 07 — Security Domain baseado em RDBMS

**Enunciado clássico:**

```
Configure security for an application using the database:
 a) Configure the security domain using the datasource created above (Non-XA).
 b) Deploy example2.war with security domain "java:/jaas/JBTravel" (ou o nome da questão).
    Authenticate with user <user> / password <password>.
```

O EAP vai **buscar o usuário no banco** via datasource (login module `Database`).

---

## 7.1 Criar o Security Domain

### Console
`Configuration → Profile: default → Security → Security Domains → Add`

| Campo | Valor |
|---|---|
| Name | o nome SEM o prefixo `java:/` (ex.: o enunciado diz `java:/jaas/JBTravel` → crie `JBTravel`; diz `java:/RDBMS` → crie `RDBMS`) |
| Cache Type | `default` |

Depois: **View → Authentication → Add**

| Campo | Valor |
|---|---|
| Code | `Database` |
| Flag | `required` |

E **Module Options → Add** (3 opções):

| Name | Value |
|---|---|
| `dsJndiName` | `java:jboss/DS_XA` (o JNDI do datasource criado na Aula 05) |
| `principalsQuery` | `select password from JBTravel.USER where username=?` |
| `rolesQuery` | `select null, 'Roles' from JBTravel.USER where username=?` |

> Os SELECTs vêm **no enunciado da questão**. Copie letra por letra, incluindo o schema
> (`JBTravel.USER`, `bookstore.users`, etc.). Os nomes dos campos podem variar:
> `password`/`Password`, `username`/`PrincipalID` — **use os do enunciado**.

### CLI
```bash
# 1) criar o security domain
/profile=default/subsystem=security/security-domain=JBTravel:add(cache-type=default)

# 2) criar o authentication com o login module (forma oficial do lab JB248)
/profile=default/subsystem=security/security-domain=JBTravel/authentication=classic:add(login-modules=[{"code"=>"Database","flag"=>"required","module-options"=>[
  ("dsJndiName"=>"java:jboss/DS_XA"),
  ("principalsQuery"=>"select password from JBTravel.USER where username=?"),
  ("rolesQuery"=>"select null,'Roles' from JBTravel.USER where username=?")
])])
```
> ⚠️ No EAP 7 o parâmetro do `authentication=classic:add` é **`login-modules=[{...}]`**
> (lista de objetos). `:add(code=Database,...)` direto **não existe** e gera erro de
> parâmetro inesperado.

**Versão XML (domain.xml, dentro do profile):**
```xml
<security-domain name="JBTravel" cache-type="default">
    <authentication>
        <login-module name="db" code="Database" flag="required">
            <module-option name="dsJndiName" value="java:jboss/DS_XA"/>
            <module-option name="principalsQuery" value="select password from JBTravel.USER where username=?"/>
            <module-option name="rolesQuery" value="select null,'Roles' from JBTravel.USER where username=?"/>
        </login-module>
    </authentication>
</security-domain>
```

> **Atenção:** alguns enunciados pedem hash de senha. Nesse caso adicione:
> ```
> hashAlgorithm = SHA-256
> hashEncoding  = base64
> ```
> (variação `bksecurity` da prova nova: `select password from users where username=?`,
> `select role, 'Roles' from roles where username=?`).

---

## 7.2 Preparar a aplicação

```bash
cd /tmp
jar -xvf example2.war     # (ou example-solved.war / a war que a questão indicar)
```

### `WEB-INF/jboss-web.xml` — vincula a app ao security domain
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE jboss-web PUBLIC
    "-//JBoss//DTD Web Application 4.2//EN"
    "http://www.jboss.org/j2ee/dtd/jboss-web_4_2.dtd">
<jboss-web>
    <security-domain>JBTravel</security-domain>
</jboss-web>
```
> **Dica dos seus documentos:** se você criar o security domain **exatamente com o nome
> que pedem** (sem o `java:/`), muitas vezes nem precisa mexer nesse arquivo — mas
> mexer **nunca atrapalha**. Prefira sempre editar: é ponto garantido.

### `WEB-INF/web.xml` — define como autenticar e quais URLs proteger
```xml
<web-app>
  <security-constraint>
    <web-resource-collection>
      <web-resource-name>All resources</web-resource-name>
      <url-pattern>/*</url-pattern>
    </web-resource-collection>
    <auth-constraint>
      <role-name>*</role-name>
    </auth-constraint>
  </security-constraint>

  <security-role>
    <role-name>*</role-name>
  </security-role>

  <login-config>
    <auth-method>BASIC</auth-method>
    <realm-name>JBTravel</realm-name>
  </login-config>
</web-app>
```
Se a questão pedir proteger só um caminho, troque `/*` por `/secure/*` e a role
pelo nome pedido (ex.: `All`).

### Reempacotar e publicar
```bash
jar -cvf example2.war *
# deploy
Runtime → Manage Deployments → example2.war → Assign → SimpleGroup → Enable
```

---

## 7.3 Testar

```
http://localhost:8080/example2
usuário: <o da questão>   senha: <a da questão>
```

**Obrigatório: reiniciar/parar+subir o servidor depois de criar o security domain**
(UI: `Runtime → Domain: Overview → Stop/Start`; CLI: `/host=simple/server-config=SimpleServer:restart()`).

### Erros e diagnóstico

| Erro | Causa / solução |
|---|---|
| 403 sem pedir login | `web.xml` sem `<security-constraint>` ou role errada |
| Pede login e rejeita tudo | `dsJndiName` apontando para o DS errado; SELECT com schema errado |
| `NoSuchMethod`/classe não encontrada | Login module `Database` precisa do datasource ativo |
| 401 mesmo com usuário certo | Esqueceu de reiniciar o servidor |
| Usuário não existe no banco | Conferir se o INSERT do usuário foi feito na tabela certa |

---

## Checklist

- [ ] Security domain criado com o nome exato (sem `java:/`)
- [ ] Authentication: Code `Database`, Flag `required`
- [ ] `dsJndiName` = JNDI do DS usado
- [ ] `principalsQuery` e `rolesQuery` idênticos ao enunciado
- [ ] `jboss-web.xml` com `<security-domain>` 
- [ ] `web.xml` com `security-constraint` + `login-config`
- [ ] Deploy + restart + teste com as credenciais dadas

## Exercício

Crie o security domain, publique a app e autentique. Depois, **quebre de propósito**
(ponha o `dsJndiName` errado), veja o erro no log, e corrija — saber diagnosticar
é o que separa quem passa de quem trava na prova.
