# Aula 18 — Logging e Snapshots de Configuração

Esta aula cobre dois objetivos **oficiais** da EX248 que não aparecem nos seus relatos
de prova, mas fazem parte do escopo cobrado pelo exam (grupo *Monitoring and managing*):

- *"Create and restore configuration snapshots"* — criar e restaurar snapshots de configuração
- *"Configure logging"* — configurar o logging do EAP

> Todos os comandos abaixo foram conferidos no **Model Reference e na Configuration Guide
> do JBoss EAP 7.4**. Em domain mode, tudo que é de subsystem sempre leva o prefixo
> `/profile=<nome>/`.

---

## Parte A — Logging

### Conceitos em 30 segundos

| Conceito | O que é |
|---|---|
| **Nível** | `OFF, FATAL, ERROR, WARN, INFO, CONFIG, DEBUG, TRACE, ALL` (ordem crescente de detalhe) |
| **Root logger** | Logger raiz do profile — o nível dele vale para tudo que não tem logger próprio |
| **Handler** | Para onde o log vai: console (`console-handler`), arquivo (`periodic-rotating-file-handler`), etc. |
| **Logger category** | Categoria específica (por pacote Java) com nível/handlers próprios |

Em **domain mode** o logging é **por profile** — repita a configuração em cada profile
que o examinar pedir (ex.: `default` e `ha`).

### A.1 Subir o nível do root logger (ex.: DEBUG)

**Console:**
`Configuration → Profile: default → Logging → Root Logger → Edit → Level: DEBUG → Save`

**CLI:**
```bash
/profile=default/subsystem=logging/root-logger=ROOT:write-attribute(name=level,value=DEBUG)
```

**Valide:**
```bash
/profile=default/subsystem=logging/root-logger=ROOT:read-attribute(name=level)
# esperado: "DEBUG"
```

> **EAP 6:** o endereço é `root-logger=` **sem** nome:
> `/profile=default/subsystem=logging/root-logger=:write-attribute(name=level,value=DEBUG)`.

### A.2 Criar um handler de arquivo com rotação diária

**Enunciado-exemplo:** *"Configure the profile to also log to a file named `app.log`,
rotated daily, level INFO."*

```bash
# 1) criar o handler (suffix é OBRIGATÓRIO e define o período da rotação)
/profile=default/subsystem=logging/periodic-rotating-file-handler=APPLOG:add(file={path="app.log",relative-to="jboss.server.log.dir"},suffix=".yyyy-MM-dd",level=INFO)

# 2) ligar o handler ao root logger
/profile=default/subsystem=logging/root-logger=ROOT:add-handler(name=APPLOG)
```

**Valide:**
```bash
/profile=default/subsystem=logging/root-logger=ROOT:read-attribute(name=handlers)
/profile=default/subsystem=logging/periodic-rotating-file-handler=APPLOG:read-resource
```

Notas importantes:
- `file` é um **objeto**: `file={path="...",relative-to="..."}` — não existe `path=` solto
  no EAP 7.4.
- O arquivo aparece em `EAP_HOME/domain/servers/<nome-do-servidor>/log/app.log`.
- Se a prova pedir rotação **por tamanho**, use `size-rotating-file-handler` (mesma
  lógica, com `max-backup-index`/`rotate-size`).

### A.3 Logger category para um pacote específico

**Enunciado-exemplo:** *"Set logger `org.example` to DEBUG."*

```bash
/profile=default/subsystem=logging/logger=org.example:add(level=DEBUG,handlers=[CONSOLE])
```

Ou mexer num que já existe:
```bash
/profile=default/subsystem=logging/logger=org.jboss.as:write-attribute(name=level,value=DEBUG)
/profile=default/subsystem=logging/logger=org.jboss.as:add-handler(name=APPLOG)
```

**Valide:**
```bash
/profile=default/subsystem=logging:read-children-names(child-type=logger)
/profile=default/subsystem=logging/logger=org.example:read-resource
```

### A.4 Desligar a saída no console / só arquivo

```bash
# nível do handler de console
/profile=default/subsystem=logging/console-handler=CONSOLE:write-attribute(name=level,value=WARN)

# ou remover o console handler do root logger
/profile=default/subsystem=logging/root-logger=ROOT:remove-handler(name=CONSOLE)
```

### A.5 Onde olhar o log em domain mode

```bash
# cada servidor tem seu próprio log
tail -f /opt/eap/<dominio>/servers/<server>/log/server.log
```

A prova frequentemente pede *"verify in the server log"* — **sempre confira o log do
servidor certo** (cada server tem o seu).

### Erros comuns — logging

| Erro | Sintoma | Correção |
|---|---|---|
| Esquecer o `/profile=` | Erro de endereço ou configuração no DC | Todo subsystem em domain = `/profile=X/subsystem=...` |
| `suffix` ausente | CLI recusa o `add` do file handler | `suffix=".yyyy-MM-dd"` é obrigatório |
| `file` escrito como `path=` | `WFLYCTL0121` (unknown parameter) | Usar `file={path="...",relative-to="..."}` |
| Mudou o nível mas nada aparece | Está olhando o log de outro server / nível do handler mais alto que o do logger | Confira nível de logger **e** de handler |
| `root-logger=ROOT` num EAP 6 | Resource not found | EAP 6 usa `root-logger=` vazio |
| Config mudou mas log não reflete | Handler não ligado ao root logger | `add-handler(name=...)` e confira `handlers` |

---

## Parte B — Snapshots de configuração

### B.1 O que é

Snapshot = **cópia pontual do arquivo de configuração** (`domain.xml`, `host.xml` ou
`standalone.xml`) guardada num diretório de histórico. Antes mesmo de você pedir, o EAP
gera backups automáticos a cada mudança via management API — os snapshots são a versão
**sob demanda**: você tira quando quiser (por exemplo, **antes de uma tarefa arriscada**).

No managed domain existem **dois alvos**, em endereços diferentes:

| O que | Endereço no CLI | Arquivo copiado | Onde fica |
|---|---|---|---|
| Config do domínio | `/` (raiz) | `domain.xml` | `EAP_HOME/domain/configuration/domain_xml_history/snapshot/` |
| Config do host | `/host=<nome>` | `host.xml` | `EAP_HOME/domain/configuration/host_xml_history/snapshot/` |

### B.2 Criar, listar e apagar snapshots

```bash
# snapshot do domain.xml (sempre no Domain Controller)
:take-snapshot
# resposta: {"outcome"=>"success",
#  "result"=>"EAP_HOME/domain/configuration/domain_xml_history/snapshot/20261019-101500123domain.xml"}

# com nome/comentário próprios (mais fácil de achar depois)
:take-snapshot(name=antes-da-questao-7, comment="backup antes de mexer no undertow")

# snapshot do host.xml deste host
/host=master:take-snapshot

# listar
:list-snapshots
/host=master:list-snapshots

# apagar (o começo do nome basta, desde que seja único; 'all' apaga tudo)
:delete-snapshot(name=20261019-101500123domain.xml)
:host=master:delete-snapshot(name=antes-da-questao-7)
:delete-snapshot(name=all)
```

**Sempre copie o caminho completo que a CLI devolve** — você vai precisar dele para
restaurar.

### B.3 Restaurar um snapshot (atenção aqui)

> ⚠️ **Não existe operação `:restore-snapshot` no EAP 7.** O próprio Model Reference da
> 7.4 só tem `take-snapshot`, `list-snapshots` e `delete-snapshot`. Restaurar = **fazer o
> EAP subir usando o arquivo do snapshot** (é o procedimento documentado na Configuration
> Guide, seção *Configuration File Snapshots → Start the Server with a Snapshot*) — ou
> copiar o snapshot de volta por cima do arquivo de configuração.

**Standalone:**
```bash
./standalone.sh --server-config=standalone_xml_history/snapshot/<arquivo-do-snapshot>
```

**Managed domain (host.xml):** pare o Host Controller e suba apontando para o snapshot:
```bash
./domain.sh --host-config=host_xml_history/snapshot/<arquivo-do-snapshot>
```
(os caminhos são resolvidos a partir de `EAP_HOME/domain/configuration` — caminho absoluto
também funciona)

**Managed domain (domain.xml):** copie o snapshot de volta por cima do `domain.xml`
(há `--domain-config` no `domain.sh`, mas o caminho seguro e sempre disponível é o `cp`):
```bash
cp EAP_HOME/domain/configuration/domain_xml_history/snapshot/<arquivo> \
   EAP_HOME/domain/configuration/domain.xml
# depois reinicie o Domain Controller
```

**Receita de bolso (o que a prova pode pedir):**
1. `:take-snapshot` (guarda o caminho)
2. quebra a configuração de propósito (ou erra a tarefa)
3. restaura pelos passos acima
4. valida com `:read-resource` / `read-config-as-xml`

```bash
# ver a configuração atual em XML (útil para comparar com o snapshot)
:read-config-as-xml
```

### B.4 O snapshot NÃO cobre

- **Deployments** — war/ear não entram no snapshot (são salvos no content repository);
- **Arquivos fora do XML de configuração** (`*.properties`, keystores, módulos JDBC);
- Configuração feita **direto no arquivo** sem passar pela management API (por isso
  edite XML na mão só quando não houver alternativa — e faça snapshot antes).

### Erros comuns — snapshots

| Erro | Sintoma | Correção |
|---|---|---|
| Procurar `:restore-snapshot` | `Operation not found` | Restauração é por `--server-config`/`--host-config` ou `cp` |
| Tirar snapshot no host errado | Copiou `host.xml` de outro host | Snapshot de `host.xml` é **por host**: `/host=<nome>:take-snapshot` |
| Tirar `:take-snapshot` num slave | Pode até funcionar, mas o `domain.xml` correto é o do **DC** | Snapshot do domain = sempre no Domain Controller |
| Restaurar mas nada muda | Servidores continuam com a config em memória | Reinicie os servers (ou o HC) depois de restaurar |
| Achar que snapshot salva deployments | Deploy sumiu depois da restauração | Deploy de novo com `deploy ... --server-groups=...` |
| Deixar lixo acumulado | Vários snapshots parecidos | `:list-snapshots` + `:delete-snapshot(name=all)` na revisão |

---

## Checklist desta aula

- [ ] Root logger em DEBUG (quando pedido) e conferido com `read-attribute`
- [ ] File handler criado com `file={...}` **e** `suffix` e ligado ao root logger
- [ ] Logger category criado no profile pedido
- [ ] Sei onde fica o `server.log` de cada server do domain
- [ ] `:take-snapshot` / `:list-snapshots` / `:delete-snapshot` decorados
- [ ] Sei restaurar: `--server-config` (standalone), `--host-config` (host), `cp` (domain.xml)
- [ ] Snapshot tirado **antes** de mexer em configuração arriscada na prova

## Exercício

1. No seu ambiente da Parte 1: `:take-snapshot` → mude o root logger para `ERROR` →
   restaure o snapshot (domain.xml via `cp`) → reinicie o DC → confirme que o nível
   voltou ao original.
2. Crie o handler `APPLOG` com rotação diária, ligue no root logger, suba o nível para
   `DEBUG`, gere uma requisição em `curl localhost:8080` e confirme que a linha apareceu
   em `app.log`.
