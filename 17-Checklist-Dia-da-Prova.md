# Checklist do Dia da Prova

## Na véspera

- [ ] VM/lab testado: EAP sobe, console 9990 responde
- [ ] Laboratórios Parte 1 e 2 feitos **2x** cada
- [ ] Aulas 18 e 19 praticados (logging, snapshots, SSL, LDAP, cluster seguro)
- [ ] Simulado ≥ 90%
- [ ] Rascunho em branco + caneta (se permitido)
- [ ] Documento de identidade e horário da prova conferidos
- [ ] Dormir bem — 4 horas de prova prática cansam

## Primeiros 10 minutos (antes de tocar no teclado)

- [ ] **Ler TODOS os enunciados** das duas partes
- [ ] Anotar no rascunho, de uma vez:
  - [ ] Diretório de instalação do EAP
  - [ ] Usuário / senha da questão
  - [ ] Nome do domínio base da Parte 1
  - [ ] Nome do grupo, do servidor, profile e socket-binding
  - [ ] Todos os valores de JVM (heap/permgen/stack)
  - [ ] Nome/JNDI dos dois datasources + todos os números (pool, cache, validação)
  - [ ] Nome do security domain + os 2 SELECTs + credenciais de teste
  - [ ] Se cair SSL: portas, alias do keystore, senhas; se cair LDAP: URL, baseDNs, filtros
  - [ ] Segredo AUTH/criptografia do cluster (se cobrado) e senhas de keystore
  - [ ] IPs e nomes dos hosts (node1/node2)
  - [ ] Grupos, servidores e offsets da Parte 2
  - [ ] Connection factories, fila, JNDIs, usuário/senha JMS
  - [ ] Nome do balancer, portas, aplicações de teste

## Parte 1 — conferência a cada etapa

- [ ] Instalação no diretório certo + usuário criado + `domain.sh` sobe
- [ ] Domínio novo criado com o **nome exato**
- [ ] `<servers>` apagado **e** `<server-groups>` apagado
- [ ] Domínio sobe em 127.0.0.1 e console mostra host sem grupos/servidores
- [ ] Grupo criado: profile `default` + `standard-sockets`
- [ ] JVM do grupo com os valores exatos (read-resource confirma)
- [ ] Servidor criado: offset e auto-start corretos; processo no `ps`
- [ ] max-connections = 50 (read-resource)
- [ ] AJP listener criado (read-children-names)
- [ ] Driver JDBC deployado
- [ ] DS Non-XA: 7 parâmetros certos + enabled
- [ ] DS XA: 3 properties + user/senha + enabled
- [ ] `ExampleDS` removido **e** default-bindings limpo
- [ ] `dstest` conecta e roda a query
- [ ] Aplicação na RAIZ (`:8080/` mostra a app)
- [ ] Security domain com 3 module-options + app autentica
- [ ] (se cobrado) Logging: nível/handler/logger alterado e conferido com `read-resource`
- [ ] (se cobrado) `take-snapshot` + `list-snapshots` executados (restore: via `--server-config`/`--host-config`)
- [ ] (se cobrado) HTTPS: keystore em todos os hosts + `https-listener` com `ssl-context` + `curl -k`
- [ ] (se cobrado) LDAP: security domain no formato `login-modules=[{...}]`
- [ ] **Ambiente da Parte 1 deixado no ar**

## Parte 2 — conferência

- [ ] node1: nome, IPs, `<local/>`
- [ ] node2: nome, IPs, `<remote host=IP_MESTRE>`
- [ ] Servers padrão tratados (offset 350 / auto-start false) — sem `BindException`
- [ ] Grupos criados com profiles corretos (cluster sem JMS, message full)
- [ ] 4 servidores no ar (ps/ss) nas portas esperadas
- [ ] Stack TCP criada com `initial_hosts` dos dois IPs na porta 7600
- [ ] Stack **udp removida** (se exigido)
- [ ] Log mostra **2 membros** no cluster
- [ ] (se cobrado) AUTH inserido **antes de `pbcast.GMS`** + mesmo segredo nos nós + restart (view de 2 mantida)
- [ ] (se cobrado) `SYM_ENCRYPT` com `secret_key` base64 idêntico nos dois nós
- [ ] `cluster_test` acessível nos dois IPs
- [ ] Apache: 4 módulos, `Listen <IP>:80`, `ServerAdvertise off`, arquivo certo
- [ ] EAP: balancer igual, advertise false, proxy-list certo
- [ ] `/mod_cluster-manager` lista os 2 nós e o balanceamento alterna
- [ ] JMS: factories novas criadas, padrões removidas
- [ ] Fila/tópico com nome/JNDI/durability exatos
- [ ] Security settings default limpos + `send` liberado para a fila
- [ ] Usuário criado com role `guest` **nos dois hosts**
- [ ] `JMSTest` envia 5 mensagens com sucesso

## Últimos 15 minutos

- [ ] Varredura linha a linha nos dois checklists acima
- [ ] Conferir nomes digitados (F3/find no console: `SimpleGroup`, JNDIs)
- [ ] Conferir se **tudo que foi pedido está Enabled/rodando**
- [ ] Conferir logs dos servidores por erro novo
- [ ] Confirmar que a Parte 1 continua no ar
- [ ] Salvar/encerrar conforme orientação do examinador

## Se travar

1. Respira. **Não reinicie tudo.**
2. Leia o enunciado de novo — 80% das travas são nome/porta errados.
3. Olhe o log (`server.log`) — ele diz a causa exata.
4. Valide com `read-resource` o que você acabou de configurar.
5. Passe para a próxima questão e volte (marque no rascunho).
6. Use a UI quando a CLI estiver te confundindo (e vice-versa).

---

**Boa prova!** Você já fez a Parte 1 duas vezes e a Parte 2 duas vezes —
no dia é só repetir o roteiro.
