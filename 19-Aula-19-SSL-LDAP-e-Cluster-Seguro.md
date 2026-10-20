# Aula 19 — SSL, LDAP e Cluster Seguro (tarefas oficiais restantes)

Esta aula fecha os **últimos 3 objetivos oficiais da EX248** que faltavam no curso:

| Objetivo oficial (EX248) | Onde |
|---|---|
| *Web connectors → Configure SSL encrypted connection* | **Parte A** |
| *Security → Connect to external security sources such as LDAP* (o DBMS está na Aula 07) | **Parte B** |
| *HA → Secure communications channels between clustered nodes* | **Parte C** |

> Todos os comandos foram conferidos no **Model Reference e na Configuration Guide do
> JBoss EAP 7.4**. A Parte B segue exatamente o formato do lab oficial `guess_ldap` da
> apostila JB248 (arquivo `guess_ldap-security-domain.cli`).

---

## Parte A — Conexão SSL criptografada (HTTPS)

**Enunciado-exemplo:** *"Configure the web connector to accept connections over an
encrypted SSL/TLS connection on port 8443."*

O caminho oficial no EAP 7.4 é **Elytron**: `key-store` → `key-manager` →
`server-ssl-context` → `https-listener` apontando para o ssl-context.

### A.1 Gerar o keystore

```bash
keytool -genkeypair -alias jboss -keyalg RSA -keysize 2048 -validity 365 \
  -keystore /opt/eap/domain/configuration/server.jks \
  -storepass changeit -keypass changeit \
  -dname "CN=localhost, OU=Curso, O=Example, L=Sao Paulo, SP=SP, C=BR"
```

> O keystore deve ficar no **directório de configuração** para que o
> `relative-to=jboss.server.config.dir` resolva. Em managed domain, esse diretório é
> `EAP_HOME/domain/configuration` **de cada host** — rode o `keytool` no node1 e copie o
> arquivo para o node2 (`scp server.jks node2:.../domain/configuration/`), ou repita lá.

### A.2 Configurar o Elytron (CLI, no profile pedido)

```bash
# 1) keystore (credential-reference = a senha do arquivo .jks)
/profile=default/subsystem=elytron/key-store=exampleKS:add(type=JKS,relative-to=jboss.server.config.dir,path=server.jks,credential-reference={clear-text="changeit"},required=true)

# 2) key-manager (credential-reference = a senha da chave privada)
/profile=default/subsystem=elytron/key-manager=exampleKM:add(key-store=exampleKS,credential-reference={clear-text="changeit"})

# 3) server-ssl-context (é nele que mora a política de TLS)
/profile=default/subsystem=elytron/server-ssl-context=exampleSSC:add(key-manager=exampleKM,protocols=["TLSv1.2","TLSv1.3"])

# 4) garantir que existe socket binding na 8443 (normalmente já existe)
/socket-binding-group=standard-sockets:read-children-names(child-type=socket-binding)
# se NÃO existir "https":
/socket-binding-group=standard-sockets/socket-binding=https:add(port=8443,interface=public)

# 5) criar o https-listener ligado ao ssl-context
/profile=default/subsystem=undertow/server=default-server/https-listener=https:add(socket-binding=https,ssl-context=exampleSSC)
```

### A.3 Validar

```bash
/profile=default/subsystem=undertow/server=default-server:read-children-names(child-type=https-listener)
/profile=default/subsystem=elytron/server-ssl-context=exampleSSC:read-resource

curl -k https://localhost:8443/
# -k: ignora o aviso de certificado auto-assinado (esperado neste teste)
```

### A.4 Variantes e armadilhas do exam

| Situação | O que fazer |
|---|---|
| A prova for no estilo **EAP 6** / pedir security-realm | O `https-listener` aceita o atributo **depreciado** `security-realm=...` apontando para um security-realm com keystore no `host.xml` — mas no EAP 7.4 o correto (e o que a doc ensina) é o `ssl-context` acima. **No exam de 7.4, use Elytron.** |
| SSL na **interface de gestão** (console/CLI em https) | Comando oficial da guide *How to Configure Server Security*: `security enable-ssl-management --interactive` (gera certificado auto-assinado guiado) |
| Keystore só num host | `relative-to=jboss.server.config.dir` resolve **por host** — os outros hosts vão dar erro de arranque. Copie o `.jks` para todos |
| `key-store` falha no boot | Ou o arquivo não existe no caminho resolvido, ou `clear-text` errado (é a senha do keystore) |
| Porta 8443 em uso / já declarada | Confira antes de `socket-binding=https:add()` — em domínio padrão ele já vem |
| Quer mudar o nível de detalhe TLS | `protocols=["TLSv1.2"]` etc. no `server-ssl-context`; ciphers/verificação de cliente também são atributos dele (`verify-client=REQUIRED` para mTLS) |

---

## Parte B — Security domain com LDAP (fonte externa de identidades)

**Enunciado-exemplo:** *"Configure a security domain that authenticates users against
the LDAP server at `ldap://ldap.example.com:389`."*

### B.1 Como o login module `Ldap` funciona (2 passos)

1. **Bind inicial** com um DN de serviço (`bindDN`/credencial, ou anônimo) que tem
   permissão de busca — localiza o DN do usuário com o filtro (`baseFilter`);
2. **Autenticação** — refaz o bind com o DN encontrado e a senha do usuário;
3. **Papéis** — busca no `rolesCtxDN` (árvore de grupos).

> O EAP 6/7 usa o subsystem **legacy** `security` (depreciado desde o 7.1, mas **funciona
> normalmente no 7.4** e é o que os materiais de prova usam). O substituto moderno é o
> Elytron (`ldap-realm`) — só caia nele se a prova pedir explicitamente.

### B.2 CLI — forma oficial (idêntica ao lab JB248 `guess_ldap`)

```bash
# 1) criar o security domain
/profile=default/subsystem=security/security-domain=LdapDomain:add(cache-type=default)

# 2) criar o authentication com o login module Ldap
/profile=default/subsystem=security/security-domain=LdapDomain/authentication=classic:add(login-modules=[{"code"=>"Ldap","flag"=>"required","module-options"=>[
  ("java.naming.factory.initial"=>"com.sun.jndi.ldap.LdapCtxFactory"),
  ("java.naming.provider.url"=>"ldap://ldap.example.com:389"),
  ("java.naming.security.authentication"=>"simple"),
  ("principalDNPrefix"=>"uid="),
  ("principalDNSuffix"=>", ou=people, dc=example, dc=com"),
  ("rolesCtxDN"=>"ou=Roles,dc=example,dc=com"),
  ("uidAttributeID"=>"member"),
  ("matchOnUserDN"=>"true"),
  ("roleAttributeID"=>"cn"),
  ("roleAttributeIsDN"=>"false")
])])
```

> ⚠️ **Sintaxe importante:** no EAP 7 o parâmetro do `authentication=classic:add` é
> `login-modules=[{...}]` (lista de objetos). **Não existe** `:add(code=...,flag=...)`
> direto no `authentication=classic` — a CLI recusa com erro de parâmetro inesperado.
> (`cache-type` no `security-domain:add` continua certo.)

### B.3 Variante com busca por filtro (bindDN + baseCtxDN + baseFilter)

Quando o enunciado/descrição da prova pede busca com filtro, o mesmo login module aceita:

```bash
/profile=default/subsystem=security/security-domain=LdapDomain/authentication=classic:add(login-modules=[{"code"=>"Ldap","flag"=>"required","module-options"=>[
  ("java.naming.factory.initial"=>"com.sun.jndi.ldap.LdapCtxFactory"),
  ("java.naming.provider.url"=>"ldap://ldap.example.com:389"),
  ("java.naming.security.authentication"=>"simple"),
  ("bindDN"=>"uid=ldapadmin,ou=People,dc=example,dc=com"),
  ("bindCredential"=>"senha-do-admin"),
  ("baseCtxDN"=>"ou=People,dc=example,dc=com"),
  ("baseFilter"=>"(uid={0})"),
  ("rolesCtxDN"=>"ou=Groups,dc=example,dc=com"),
  ("roleFilter"=>"(uniqueMember={1})"),
  ("roleAttributeID"=>"cn")
])])
```

Referência: Login Module Reference 7.4 — *Short name: `Ldap`* (classe completa
`org.jboss.security.auth.spi.LdapLoginModule`). Existe também o nome curto `LdapExtended`
(mesma família, mais opções) — se o enunciado citar `LdapExtended`, troque o `code`.

### B.4 Ligar a aplicação e testar

Mesma receita da Aula 07: `jboss-web.xml` com `<security-domain>LdapDomain</security-domain>`,
`web.xml` com `security-constraint`, deploy, **restart do servidor**, e teste com um
usuário que exista no LDAP.

```bash
# conferir
/profile=default/subsystem=security/security-domain=LdapDomain:read-resource(recursive=true)
```

| Erro | Causa / solução |
|---|---|
| `Unexpected parameter 'code'` | Você escreveu `classic:add(code=...)` — use `login-modules=[{...}]` |
| `CommunicationException` / timeout | URL/porta do LDAP errados; firewall; precisa de `ldap://` no `java.naming.provider.url` |
| Autentica mas sem papel | `rolesCtxDN`/`roleFilter` errados — role errada = 403 na app |
| `InvalidName`/filtro sem resultado | `baseFilter` com `{0}` errado ou `principalDNSuffix` com espaços fora do padrão |
| Funciona no standalone e não no domain | Esqueceu o prefixo `/profile=X/` |

---

## Parte C — Cluster seguro (JGroups)

**Enunciado-exemplo:** *"Secure the communication channels between the clustered
nodes"* → autenticar quem entra no cluster (**AUTH**) e/ou criptografar o tráfego
(**SYM_ENCRYPT** / **ASYM_ENCRYPT**).

### C.1 AUTH — autenticação de entrada no cluster

Regra de posição (Configuration Guide Red Hat, *Securing a Cluster*):

> **O protocolo AUTH deve ficar imediatamente antes do `pbcast.GMS`.**

Como a posição depende da stack que você criou na Aula 09, descubra o índice na hora:

```bash
# 1) ver os protocolos da stack na ordem (índice 0 = logo acima do transport)
/profile=ha/subsystem=jgroups/stack=tcpping:read-attribute(name=protocols)
# exemplo de resposta: ["TCPPING","MERGE2","FD","VERIFY_SUSPECT","pbcast.NAKACK",
#                       "UNICAST2","pbcast.STABLE","pbcast.GMS","UFC","MFC","FRAG2"]
#                                                    pbcast.GMS = índice 7 ↑

# 2) inserir o AUTH no índice do GMS (assim ele fica logo ANTES do GMS)
/profile=ha/subsystem=jgroups/stack=tcpping/protocol=AUTH:add(add-index=7)

# 3) token simples = segredo compartilhado (precisa ser IGUAL em todos os nós)
/profile=ha/subsystem=jgroups/stack=tcpping/protocol=AUTH/token=plain:add(shared-secret-reference={clear-text="segredo-do-cluster"})
```

Tipos de token aceitos pelo EAP 7.4: `plain` (segredo simples), `digest` e `cipher`
(model reference: `token=plain|digest|cipher`).

**Validar:**
```bash
/profile=ha/subsystem=jgroups/stack=tcpping:read-attribute(name=protocols)
# AUTH deve aparecer imediatamente antes de pbcast.GMS

# reinicie os servers do cluster e confira a view de 2 membros no log dos dois
/host=node1/server-config=cluster_1:restart()
/host=node1/server-config=cluster_2:restart()
```

### C.2 SYM_ENCRYPT / ASYM_ENCRYPT — criptografar os canais

**SYM_ENCRYPT** — mesma chave simétrica em todos os nós (não exige AUTH):
```bash
# posição típica: imediatamente ANTES do pbcast.NAKACK / pbcast.NAKACK2
# (mesma lógica: ache o índice do NAKACK com read-attribute(name=protocols))
/profile=ha/subsystem=jgroups/stack=tcpping/protocol=SYM_ENCRYPT:add(add-index=4,properties={secret_key="MDEyMzQ1Njc4OWFiY2RlZg=="})
```
- `secret_key` = chave AES em **base64**, idêntica nos dois nós (o exemplo acima é a
  chave de 16 bytes `0123456789abcdef`);
- variante com keystore: `properties={key_store_name="...",store_password="...",alias="..."}`.

**ASYM_ENCRYPT** — a chave é distribuída pelo coordenador (exige AUTH):
```bash
/profile=ha/subsystem=jgroups/stack=tcpping/protocol=ASYM_ENCRYPT:add(add-index=4,properties={asym_algorithm="RSA"})
```

Notas oficiais (Configuration Guide):
- *"Configuring AUTH is optional when using SYM_ENCRYPT"* — com SYM_ENCRYPT o AUTH é
  opcional; com ASYM_ENCRYPT ele é **obrigatório**;
- depois de mexer em JGroups: **restart dos servers do cluster** (não adianta só reload);
- os dois nós precisam da **mesma stack, mesmos protocolos e mesmo segredo** — stack
  diferente = cluster não forma (volte à Aula 09 e compare `read-attribute(name=protocols)`).

### C.3 Erros comuns — cluster seguro

| Erro | Sintoma | Correção |
|---|---|---|
| AUTH fora de posição | AUTH no fim da stack (após FRAG2) | `add-index` = índice do `pbcast.GMS` |
| Nó não entra no cluster | Log de AUTH rejeitado / view só com 1 membro | Segredo (`shared-secret-reference`) diferente entre os nós |
| ESQUECEU o restart | Config mudada mas cluster continua sem AUTH | `:restart()` nos servers do cluster |
| SYM_ENCRYPT sem chave igual | Nós não se entendem (erros de decrypt) | Mesmo `secret_key` base64 nos dois hosts |
| ASYM_ENCRYPT sem AUTH | Nó não consegue obter a chave | Adicione o AUTH antes |
| IP/porta errados (sempre) | Cluster não forma de jeito nenhum | `initial_hosts` = `IP[7600]` dos dois nós (Aula 09) |

---

## Checklist desta aula

- [ ] Keystore gerado e copiado para **todos** os hosts que servem HTTPS
- [ ] `key-store` → `key-manager` → `server-ssl-context` → `https-listener` criados no profile certo
- [ ] `curl -k https://...:8443/` responde
- [ ] Security domain LDAP no formato `login-modules=[{...}]` (não `add(code=...)`)
- [ ] `java.naming.provider.url`, `baseCtxDN`/`principalDNSuffix` e `rolesCtxDN` do enunciado
- [ ] AUTH inserido **imediatamente antes de pbcast.GMS** (`add-index`)
- [ ] Segredo AUTH idêntico nos dois nós; cluster re-formado (view de 2) após restart

## Exercício

1. **SSL:** gere o keystore, configure o `https-listener` no profile `default`, valide
   com `curl -k` e depois remova tudo (para praticar o caminho inverso com `:remove()`).
2. **LDAP:** crie o security domain `LdapDomain` no formato do lab oficial e confira com
   `read-resource(recursive=true)` que o login module `Ldap` está `required`.
3. **Cluster:** com a stack da Aula 09 no ar, adicione o AUTH com `add-index` correto,
   reinicie os dois servers e confirme no log que o cluster ainda forma com 2 membros.
   Depois troque o segredo de um dos nós, reinicie e **observe a falha** (é assim que o
   examinador valida que o AUTH está ativo).
