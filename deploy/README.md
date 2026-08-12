# Deploy: painel no navegador via Cloudflare Tunnel

Stack de dois containers, sem nenhuma porta publicada no host:

```
navegador ──HTTPS──> Cloudflare ──tunnel──> cloudflared ──rede interna──> ttyd
                     (Access)                                             cybertrace.sh
```

Toda a configuração vem do `.env`. O compose não tem valor fixo de host,
porta, imagem ou nome de stack.

## Uso

```bash
cp .env.example .env
$EDITOR .env          # preencha ao menos TUNNEL_TOKEN
docker compose up -d
```

O compose falha imediatamente se `TUNNEL_TOKEN` estiver vazio, em vez de subir
um tunnel quebrado.

## O que o `.env` controla

| Variável | Efeito |
|----------|--------|
| `STACK_NAME` | prefixo dos containers, nome do projeto, da rede e do volume |
| `CYBERTRACE_IMAGE` / `CYBERTRACE_TAG` | imagem e versão (fixe em `X.Y.Z-web` para deploy reproduzível) |
| `APP_PORT` | porta interna do ttyd — não é publicada no host |
| `TTYD_CREDENTIAL` | basic auth `usuario:senha` |
| `TTYD_MAX_CLIENTS`, `TTYD_TITLE` | limites e aparência |
| `TUNNEL_TOKEN` | token do tunnel (**obrigatório**) |
| `APP_HOSTNAME` | hostname público — documentação, veja a ressalva abaixo |
| `CLOUDFLARED_TAG`, `TUNNEL_METRICS_PORT`, `RESTART_POLICY` | infraestrutura |
| `LINKETRACK_USER` / `LINKETRACK_TOKEN` | rastreio de encomendas |

Como `STACK_NAME` controla tudo, dá para rodar várias instâncias no mesmo host
sem colisão:

```bash
STACK_NAME=ct-lab docker compose up -d
```

## O ingress mora na Cloudflare, não aqui

Com tunnel por **token** (*remotely-managed*), o mapeamento hostname → serviço
fica no painel da Cloudflare, não no compose. O `APP_HOSTNAME` no `.env` é
documentação de para onde este stack responde; ele não configura nada sozinho.

Configure uma vez em **Zero Trust → Networks → Tunnels → seu tunnel → Public
hostname**:

| Campo | Valor |
|-------|-------|
| Subdomain / Domain | o que estiver em `APP_HOSTNAME` |
| Service type | `HTTP` |
| URL | `<STACK_NAME>-painel:<APP_PORT>` (ex.: `cybertrace-painel:7681`) |

O tunnel alcança o serviço pelo nome do container na rede do compose — por isso
nenhuma porta precisa ficar aberta no host.

Se quiser o ingress versionado junto do código, é preciso migrar para um tunnel
*locally-managed* (`config.yml` + credentials JSON). Aí o roteamento sai do
painel e entra no repositório, ao custo de gerenciar o arquivo de credenciais.

## Segurança

O ttyd roda em `--writable` — sem isso o menu não aceitaria teclado. Isso torna
o serviço uma superfície sensível: a opção 22 (consulta em lote) lê arquivos
arbitrários de dentro do container.

Duas camadas, e vale usar as duas:

1. **Cloudflare Access** na frente do hostname, restringindo por e-mail ou
   grupo. É o controle que impede alguém de chegar no ttyd.
2. **`TTYD_CREDENTIAL`** como defesa em profundidade, caso o Access seja
   removido ou mal configurado.

O token do tunnel é passado por **variável de ambiente**, nunca como argumento
de linha de comando — como argumento ele apareceria inteiro em
`docker inspect` e na lista de processos do host.

O `.env` é ignorado pelo git; apenas o `.env.example` é versionado.
