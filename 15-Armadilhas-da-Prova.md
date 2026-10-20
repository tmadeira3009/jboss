# Armadilhas da Prova (o que faz aluno reprovar)

Lista montada a partir dos seus relatos de prova ("volta da prova", dicas do Felipe,
observações de quem conseguiu 300). Leia **duas vezes** antes da prova.

---

## 1. ARMADILHAS GERAIS

### 1.1 Copiar o nome errado (a correção é automática)
`SimpleGroup` / `simplegroup` / `SIMPLEGROUP` são 3 strings diferentes para o corretor.
**Regra:** nome de domínio, host, grupo, servidor, JNDI, profile e porta → copie **colando**.

### 1.2 Não ler a prova inteira antes de começar
Especialmente na Parte 2: sem o desenho do ambiente você acaba configurando IP errado,
offset errado e desperdiça tempo desfazendo. **10 minutos de rascunho economizam 40 de retrabalho.**

### 1.3 UI x CLI
A prova **não** exige um método. Mas:
- se você criar algo pela CLI, **valide pela UI** (e vice-versa);
- metade das questões é mais rápida na UI, a outra metade na CLI.

### 1.4 Esquecer de reiniciar/reload
Depois de editar `domain.xml`/`host.xml` na mão, **o EAP não recarrega sozinho**.
Depois de criar security domain, **pare e suba o servidor**.

---

## 2. PARTE 1

| # | Armadilha | Como evitar |
|---|---|---|
| 1 | Instalar no diretório errado (o instalador sugere outro) | Conferir o caminho no enunciado; `mv` se precisar |
| 2 | Apagar **só** os `servers` **ou só** os `server-groups` | São **dois** blocos em **dois** arquivos diferentes |
| 3 | Deixar `server-one` com offset 0 | Conflito de porta depois (Parte 2). Offset **350** ou auto-start false |
| 4 | Grupo com profile `full` quando pedem `default` | Releia: "sem mensageria e não clusterizado" = **default** |
| 5 | Validação de conexão em **minutos** | Campo é em **ms**: 10 segundos = `10000` |
| 6 | `track-statement` deixado em `true` | Questão cobra `false` explicitamente |
| 7 | Esquecer de **Disable → editar → Enable** no DS | No console não dá para editar DS ativo |
| 8 | Deixar o `ExampleDS` (H2) só removido do datasource | Precisa também **undefine-attribute** no `subsystem=ee` |
| 9 | AJP sem criar o socket binding `ajp` | CLI exige `/socket-binding-group=.../socket-binding=ajp:add(port=8009)` antes |
| 10 | Achar que "max-connections" é no servidor | É no **listener do profile** (undertow/http-listener) |
| 11 | Root context sem desligar a welcome root | `/` continua mostrando a página de boas-vindas |
| 12 | `default-web-module` com o nome errado | Tem que ser o **runtime name** da war (`example.war`) |
| 13 | Security domain com o prefixo `java:/` no Name | Crie **sem** o prefixo (`JBTravel`, `RDBMS`, `bksecurity`) |
| 14 | SELECT do principalsQuery errado | Copie do enunciado: schema, maiúsculas e `?` final |
| 15 | Deploy não atribuído a um **server group** | No domain, deploy é sempre por grupo |
| 16 | Testar o dstest com JNDI/tabela errados | `java:jboss/DS_...` exato + `jbtravel.airport` / `bookstore.CatalogItem` |

---

## 3. PARTE 2

| # | Armadilha | Como evitar |
|---|---|---|
| 1 | **Offset 0 duplicado** (`server-one` x `cluster_1`) | Offset 350 ou apagar/auto-start=false nos servers padrão |
| 2 | Bind das interfaces em 127.0.0.1 na Parte 2 | node1/node2 precisam dos **IPs reais** no `host.xml` |
| 3 | Slave ainda com `<local/>` no domain-controller | Trocar por `<remote host="IP_MESTRE" ...>` |
| 4 | `application-users.properties` diferente entre hosts | Copie os `.properties` de um host para o outro |
| 5 | Profile com mensageria no grupo de cluster | "Full JEE sem mensageria" → `ha` ou `full-ha` - messaging |
| 6 | Deixar a stack **UDP** existindo | Exigem **somente TCP**: `stack=udp:remove()` |
| 7 | `initial_hosts` com porta errada | `IP[7600]` dos **dois** nós — porta do `jgroups-tcp` |
| 8 | Não reiniciar os servers depois do JGroups | Cluster só forma depois do restart |
| 9 | Firewall bloqueando 7600/7800 | Abrir as portas JGroups nos dois hosts |
| 10 | **Mexer em configuração de balanceamento que já é default** | *"É pegadinha: muita coisa pedida já vem pronta"* — confira antes de alterar |
| 11 | `BalancerName` diferente no Apache e no EAP | `Mybalancer` dos dois lados |
| 12 | Connector errado no modcluster (`http` x `ajp`) | Use o AJP listener criado |
| 13 | Remover **demais** no JMS (apagar a factory que você mesmo precisa) | Remova as padrão, crie as novas, confira com `read-resource` |
| 14 | Conector `netty` inexistente no EAP 7 | Criar socket binding `remote-connector` antes |
| 15 | Usuário JMS criado num host só | Repetir no node2 / copiar properties |
| 16 | Fila sem permissão `send` para `guest` | Security Settings → Add com Pattern/Role/Send |
| 17 | Achar que o ERROR do fim do JMSTest é reprovação | Confirme se as mensagens foram enviadas (relato de prova) |
| 18 | Servidores padrão subindo e estourando memória | *"Sempre que subia com os servers default dava problema de memória stack"* — deixe auto-start=false |

---

## 4. SINAIS DE QUE ALGO ESTÁ ERRADO (confira sempre)

```bash
# servidor subiu?
ps -ef | grep "Server:"
# portas (confira offset!)
ss -tlnp | grep -E '8080|9990|9999|7600'
# log de erro
tail -50 /opt/eap/<dominio>/servers/<server>/log/server.log
# config realmente aplicada?
jboss-cli -c --controller=... --commands="/profile=default/subsystem=undertow:read-resource(recursive=true)"
```

Erros clássicos de log:
- `BindException: Address already in use` → offset duplicado
- `WFLYCTL0180: services are not started` → falhou alguma dependência (driver, socket)
- `JBAS014743: Failed to parse` → XML quebrado ao editar na mão (confira as tags que você apagou)
- `Connection refused` → host apontando para IP/porta errados

---

## 5. REGRAS DE sobrevivência na prova

1. **Não gaste mais de 10 minutos numa tarefa.** Pule, marque no rascunho e volte.
2. **Valide cada item** antes de seguir (read-resource / curl / log).
3. **Não reinicie o domain inteiro** sem necessidade — reinicie só o servidor afetado.
4. **Anote os valores da questão** (nomes, IPs, JNDIs, portas, senhas) no rascunho no
   primeiro minuto — você vai usá-los 30 vezes.
5. **Terminou?** Varra o checklist do laboratório item por item. Questão esquecida = ponto perdido.
6. **Ambiente da Parte 1 no ar** até o fim da prova.

---

## 6. ARMADILHAS DAS TAREFAS OFICIAIS RESTANTES (logging, snapshots, SSL, LDAP, cluster seguro)

| # | Armadilha | Como evitar |
|---|---|---|
| 1 | `permgen-size`/`max-permgen-size` recusado no EAP 7.4 | PermGen **só existe em EAP 6.x/Java 7**; no 7.4 a prova é **Metaspace** (heap/stack/`jvm-options` continuam válidos). Leia o enunciado: se caiu "JConsole/permgensize" é legado EAP 6 |
| 2 | Comando `authentication=classic:add(code=Database,...)` | **Não existe no EAP 7** — o parâmetro é `login-modules=[{code=...}]` (veja Aula 07/19) |
| 3 | `https-listener` com `security-realm=` no EAP 7.4 | Atributo depreciado — use `ssl-context` (Elytron: `key-store` → `key-manager` → `server-ssl-context`) |
| 4 | Keystore copiado só para um host | `relative-to=jboss.server.config.dir` é **por host** — copie o `.jks` para todos (domain: `domain/configuration/`) |
| 5 | Procurar `:restore-snapshot` no EAP 7 | **Não existe** — restaure com `--server-config=standalone_xml_history/snapshot/<arq>` / `--host-config=...` ou `cp` do snapshot de volta |
| 6 | Logging em domain sem `/profile=X/` | Todos os comandos de logging em managed domain são `/profile=default/subsystem=logging/...` |
| 7 | `periodic-rotating-file-handler` sem o objeto `file` ou sem `suffix` | `file={path=...,relative-to=...}` **e** `suffix=".yyyy-MM-dd"` são obrigatórios |
| 8 | Log procurado em `log/` da raiz do EAP | Em domain o log é `EAP_HOME/domain/servers/<server>/log/server.log` |
| 9 | AUTH no fim da stack (depois de FRAG2) | AUTH entra **imediatamente antes de `pbcast.GMS`** — descubra o índice com `read-attribute(name=protocols)` e use `add-index` |
| 10 | Segredos `shared-secret-reference` diferentes nos nós | Copie o mesmo valor para os dois hosts; sem isso o nó é rejeitado no cluster |
| 11 | SYM_ENCRYPT com chaves diferentes / ASYM_ENCRYPT sem AUTH | `secret_key` base64 idêntico; ASYM **exige** AUTH (sym, não) |
| 12 | Mudou JGroups e não reiniciou os servers | Só depois de `:restart()` nos servers do cluster a config vale |
