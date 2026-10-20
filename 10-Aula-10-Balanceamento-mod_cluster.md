# Aula 10 — Balanceamento de carga (Apache httpd + mod_cluster)

**Enunciado clássico:**

```
Configure Apache load balancing:
 a) Use mod-jk or mod-cluster for the TCP cluster created above.
 b) Use the modules available from http://materials.example.com/modules
 c) Use <IP>:80 for the Apache httpd server.
 d) Do all configuration in HTTP_HOME/conf.d/proxy.conf
 e) Deploy the application and test that load is balanced across servers.
 f) Check session stickiness and fail-over.
```

> **Aviso dos seus documentos:** boa parte do que a prova pede de balanceamento
> **já é default**. *"É meio que uma pegadinha pedindo pra você fazer algo que já vem
> configurado por padrão."* Leia com calma: não quebre o que já funciona.

---

## 10.1 Instalar os módulos no Apache

```bash
# módulos fornecidos pela prova (ou copiados do próprio EAP)
wget http://materials.example.com/modules/mod_advertise.so
wget http://materials.example.com/modules/mod_manager.so
wget http://materials.example.com/modules/mod_proxy_cluster.so
wget http://materials.example.com/modules/mod_slotmem.so

sudo cp -f *.so /etc/httpd/modules/
sudo chmod 755 /etc/httpd/modules/mod_*.so
```

**EAP 6 (caminho alternativo citado nos seus documentos):**
```bash
sudo cp -f /opt/eap/modules/native/lib64/httpd/* /etc/httpd/modules/
```

Garanta que `mod_proxy_balancer` está **comentado** (evita conflito):
```bash
grep proxy_bala /etc/httpd/conf/httpd.conf
#LoadModule proxy_balancer_module modules/mod_proxy_balancer.so   ← deve estar comentado
```

---

## 10.2 Configurar o proxy (arquivo único permitido)

`/etc/httpd/conf.d/proxy.conf` (ou `modcluster.conf`, conforme a prova indicar):

```apache
LoadModule slotmem_module modules/mod_slotmem.so
LoadModule proxy_cluster_module modules/mod_proxy_cluster.so
LoadModule manager_module modules/mod_manager.so
LoadModule advertise_module modules/mod_advertise.so

ManagerBalancerName Mybalancer

<VirtualHost *:80>
  <Location />
      Require all granted          # (Apache 2.4; em 2.2: order deny,allow / allow from all)
  </Location>
  KeepAliveTimeout 60
  MaxKeepAliveRequests 0
  EnableMCPMReceive on
  ServerAdvertise off
  <Location /mod_cluster-manager>
      SetHandler mod_cluster-manager
      Require ip 192.168.6.11      # só o IP do próprio servidor conforme enunciado
  </Location>
</VirtualHost>
```

Pontos exigidos nos enunciados:
- **Listen no IP e porta 80**: `Listen 192.168.6.11:80` (coloque no início do arquivo)
- **ServerAdvertise = off**
- Redirecionar `http://<IP>/cluster_test` para o cluster → feito pelo próprio mod_cluster
  ao descobrir os backends

```bash
sudo httpd -t && sudo systemctl restart httpd
```

---

## 10.3 Configurar o lado do EAP (modcluster subsystem)

**Console:**
`Configuration → Profile: ha → Web → mod_cluster → View`
| Campo | Valor |
|---|---|
| Balancer | `Mybalancer` (tem que ser o mesmo nome do Apache) |
| Advertise | `false` |
| Connector | `ajp` (o listener AJP criado na Parte 1) |
| Proxy List | `<IP_DO_APACHE>:6666` (porta do mod_cluster, default 6666) |

**CLI:**
```bash
# outbound socket binding para o Apache
/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=proxy1:add(host=192.168.6.11,port=6666)
# ou via subsystem
/profile=ha/subsystem=modcluster/proxy=default:write-attribute(name=proxies,value=[192.168.6.11:6666])
/profile=ha/subsystem=modcluster/proxy=default:write-attribute(name=balancer,value=Mybalancer)
/profile=ha/subsystem=modcluster/proxy=default:write-attribute(name=advertise,value=false)
/profile=ha/subsystem=modcluster/proxy=default:write-attribute(name=connector,value=ajp)
```

**XML equivalente (domain.xml):**
```xml
<subsystem xmlns="urn:jboss:domain:modcluster:5.0">
  <mod-cluster-config advertise="false" connector="ajp" proxy-list="192.168.6.11:6666">
      <dynamic-load-provider history="10" decay="2">
          <load-metric type="cpu"/>
      </dynamic-load-provider>
  </mod-cluster-config>
</subsystem>
```

---

## 10.4 Testar o balanceamento

1. Suba os servidores do grupo cluster;
2. Abra o gerenciador: `http://192.168.6.11/mod_cluster-manager` —
   deve listar **os dois nós** no balancer `Mybalancer`;
3. Acesse repetidamente `http://192.168.6.11/cluster_test`:
   - **Balanceamento:** as respostas alternam entre `node1` e `node2`
     (a aplicação mostra qual nó atendeu);
   - **Session stickiness:** com a mesma sessão (cookie JSESSIONID), você continua
     caindo no **mesmo** nó;
   - **Failover:** mate um nó → a sessão migra para o outro (se a configuração de
     distribuída de sessão estiver ativa no profile ha/full-ha).

---

## Diagnóstico

| Sintoma | Causa |
|---|---|
| `mod_cluster-manager` vazio | Apache não recebeu advertise/connect: confira `proxy-list`, porta 6666, e que o **EAP não está com `advertise=true` apontando errado** |
| 503 Bad Gateway | Backends não registrados (servidores parados) ou connector errado (`ajp` x `http`) |
| Balancer name diferente | `ManagerBalancerName` ≠ `balancer` do subsystem |
| Não balanceia | Só 1 nó registrado — verifique se os 2 servidores do grupo cluster estão no ar |
| Sem permissão no manager | `Require ip` não bate com seu IP de acesso |

## Checklist

- [ ] 4 módulos `.so` copiados e com permissão de execução
- [ ] `proxy_balancer` comentado
- [ ] `Listen <IP>:80` + `ServerAdvertise off`
- [ ] `EnableMCPMReceive on`
- [ ] EAP: balancer igual, advertise false, proxy-list com IP do Apache
- [ ] `/mod_cluster-manager` mostra os 2 nós
- [ ] Teste de balanceamento + stickiness OK

## Exercício

Configure o balanceamento e comprove os 3 testes (balancear, stickiness, failover)
tirando print de cada um — na prova o sistema valida automaticamente, mas no treino
o print te obriga a provar que entendeu.
