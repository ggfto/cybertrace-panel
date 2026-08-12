# Deploy: painel no navegador via Cloudflare Tunnel

Três containers, sem nenhuma porta publicada no host:

```
navegador ──HTTPS──> Cloudflare ──tunnel──> cloudflared ──rede interna──> ttyd
                     (Access)                    ▲                        cybertrace.sh
                                                 │ config.yml + creds.json
                                            tunnel-init (roda uma vez, sai 0)
                                                 │
                                            API da Cloudflare
```

Toda a configuração vem do `.env`. O compose não tem valor fixo de host, porta,
imagem ou nome de stack — e **não há nada a criar no painel da Cloudflare**.

## Uso

```bash
cp .env.example .env
$EDITOR .env
docker compose up -d
```

O compose falha imediatamente se faltar qualquer variável obrigatória, em vez de
subir um stack meio configurado.

Na primeira subida, o [`cf-tunnel-init`](https://github.com/ggfto/cf-tunnel-init)
cria o tunnel pela API, renderiza o ingress, escreve `config.yml` e `creds.json`
no volume e faz upsert do CNAME proxied. É idempotente: roda a cada `up` e
reconcilia o que estiver fora do lugar.

## O que o `.env` controla

| Variável | Efeito |
|----------|--------|
| `STACK_NAME` | prefixo dos containers, nome do projeto, da rede e dos volumes |
| `CYBERTRACE_IMAGE` / `CYBERTRACE_TAG` | imagem e versão (fixe em `X.Y.Z-web` para deploy reproduzível) |
| `APP_PORT` | porta interna do ttyd — não é publicada no host |
| `TTYD_CREDENTIAL` | basic auth `usuario:senha` |
| `TTYD_MAX_CLIENTS`, `TTYD_TITLE` | limites e aparência |
| `CF_API_TOKEN`, `CF_ACCOUNT_ID`, `CF_ZONE_ID` | credenciais da API (**obrigatórias**) |
| `APP_HOSTNAME` | hostname público — o CNAME é criado automaticamente |
| `TUNNEL_NAME` | um tunnel por stack; único na conta |
| `CF_TUNNEL_INIT_TAG`, `CLOUDFLARED_TAG`, `RESTART_POLICY` | infraestrutura |
| `LINKETRACK_USER` / `LINKETRACK_TOKEN` | rastreio de encomendas |

O `CF_SERVICE` do init é montado a partir de `STACK_NAME` e `APP_PORT`, então não
precisa ser configurado.

Como `STACK_NAME` controla tudo, dá para rodar várias instâncias no mesmo host:

```bash
STACK_NAME=ct-lab TUNNEL_NAME=ct-lab APP_HOSTNAME=ct-lab.gf2.in docker compose up -d
```

## O token da API

Precisa de dois escopos, em **My Profile → API Tokens → Create Token → Custom**:

| Permissão | Nível |
|-----------|-------|
| Cloudflare Tunnel : Edit | Account |
| DNS : Edit | Zone (a zona do `APP_HOSTNAME`) |

É um segredo mais poderoso que um token de tunnel — ele pode criar e apagar
tunnels na conta e editar DNS da zona. Em compensação, é o **único** segredo
durável: o volume `cf-runtime` pode ser destruído e é reconstruído da API no
próximo boot.

## Segurança

O ttyd roda em `--writable` — sem isso o menu não aceitaria teclado. Isso torna
o serviço uma superfície sensível: a opção 22 (consulta em lote) lê arquivos
arbitrários de dentro do container.

Duas camadas, e vale usar as duas:

1. **Cloudflare Access** na frente do hostname, restringindo por e-mail ou
   grupo. É o controle que impede alguém de chegar no ttyd.
2. **`TTYD_CREDENTIAL`** como defesa em profundidade, caso o Access seja
   removido ou mal configurado.

Nenhum token vai por linha de comando em lugar nenhum — como argumento ele
apareceria em `docker inspect` e na lista de processos do host.

O `.env` é ignorado pelo git; apenas o `.env.example` é versionado.
