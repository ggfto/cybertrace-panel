# Cybertrace Panel v2.6.0

Painel de Investigação Digital com consultas a APIs públicas reais.

![Cybertrace Panel Demo](demo.png)

## Menu

```
[1]  Buscar IP            (rua, bairro, CEP, DDD, ISP, ASN, proxy/VPN)
[2]  Dados de Telefone    (DDD dinâmico + cidades via BrasilAPI)
[3]  Veículo              (preço FIPE por código)
[4]  CNPJ                 (BrasilAPI - Receita Federal)
[5]  CPF                  (validação de dígitos + UF)
[6]  Buscar Domínio       (DNS + MX + NS + TXT + WHOIS)
[7]  Buscar Nome          (Google Dorking - 10+ plataformas)
[8]  Redes Sociais        (24 plataformas + HTTP check)
[9] Consultar E-mail     (MX, NS, Gravatar, HIBP, Hunter.io)
[10] CEP                  (ViaCEP - rua, bairro, cidade)
[11] CPF Completo         (Selenium - requer Chrome, só Linux)
[12] Banco                (código/ISPB via BrasilAPI)        [NOVO]
[13] DDD + cidades        (BrasilAPI)                        [NOVO]
[14] Cotações             (Dólar, Euro, BTC - AwesomeAPI)    [NOVO]
[15] Rastrear encomenda   (Correios via Linketrack)          [NOVO]
[16] Feriados nacionais   (BrasilAPI)                        [NOVO]
[17] Certificado SSL      (expiração via openssl)            [NOVO]
[18] WHOIS via RDAP       (JSON - Verisign/registro.br)      [NOVO]
[19] Detector de hash     (identifica MD5/SHA1/SHA256/...)   [NOVO]
[20] Scanner de portas    (21, 22, 80, 443, 3306, 8080...)  [NOVO]
[21] Modo AUTO --target   (detecta o tipo e consulta)        [NOVO]
[22] Consulta em lote     (arquivo de alvos)                 [NOVO]
[23] Histórico            (log automático + exportação)      [NOVO]
[24] Atualizar painel     (git pull)                         [NOVO]
[25] Ferramentas Extras   (10 utilitários)
[0]  Sair
```

## Instalação

### Docker (não precisa instalar dependência nenhuma)

Imagens multi-arch (`linux/amd64` e `linux/arm64`) publicadas no GHCR a cada release:

```bash
# menu interativo
docker run --rm -it ghcr.io/ggfto/cybertrace-panel

# modo CLI
docker run --rm ghcr.io/ggfto/cybertrace-panel --ip 8.8.8.8

# com histórico persistente
docker run --rm -it -v cybertrace-data:/data ghcr.io/ggfto/cybertrace-panel
```

Ou via compose:

```bash
docker compose run --rm cybertrace
```

#### Tags disponíveis

Cada release publica as duas variantes em quatro tags: a versão exata, a minor,
a major e `latest`.

| Tag | Conteúdo |
|-----|----------|
| `latest`, `X`, `X.Y`, `X.Y.Z` | imagem enxuta (~250 MB) — opções 1-10 e 12-25 |
| `latest-full`, `X-full`, `X.Y-full`, `X.Y.Z-full` | \+ Chromium e Selenium (~1,3 GB) — inclui a opção 11 (CPF completo) |
| `latest-web`, `X-web`, `X.Y-web`, `X.Y.Z-web` | \+ [ttyd](https://github.com/tsl0922/ttyd): serve o painel no navegador |

```bash
docker run --rm -it ghcr.io/ggfto/cybertrace-panel:latest-full   # com a opção 11
docker run --rm -it ghcr.io/ggfto/cybertrace-panel:2             # fixa na major 2
```

A opção 24 (atualizar via `git pull`) não se aplica em container: atualize com
`docker pull`. O painel detecta isso e avisa.

### No navegador (imagem `-web`)

A variante `-web` embute o [ttyd](https://github.com/tsl0922/ttyd), que serve o
terminal por websocket: o painel aparece no navegador exatamente como é —
menu, cores e banner — inclusive no celular.

```bash
docker run --rm -p 7681:7681 \
  -e TTYD_CREDENTIAL=usuario:senha \
  ghcr.io/ggfto/cybertrace-panel:latest-web
# abra http://localhost:7681
```

> **Nunca exponha essa porta publicamente sem autenticação.** O ttyd roda em
> modo `--writable` (sem isso o menu não aceitaria teclado), e a opção 22
> (consulta em lote) lê arquivos arbitrários de dentro do container. Use o
> `TTYD_CREDENTIAL` e, para acesso externo, algo como o Cloudflare Access.

| Variável | Efeito |
|----------|--------|
| `TTYD_PORT` | porta interna (padrão `7681`) |
| `TTYD_CREDENTIAL` | `usuario:senha` para basic auth; vazio desliga |
| `TTYD_MAX_CLIENTS` | sessões simultâneas (padrão `5`, `0` = sem limite) |
| `TTYD_TITLE` | título da aba do navegador |

Para publicar via Cloudflare Tunnel há um stack pronto em
[`deploy/`](deploy/), inteiramente configurado por `.env` — veja
[`deploy/README.md`](deploy/README.md).

#### Variáveis de ambiente

| Variável | Efeito |
|----------|--------|
| `LINKETRACK_USER` / `LINKETRACK_TOKEN` | credenciais do rastreio de encomendas |
| `CYBERTRACE_HIST` | caminho do log de histórico (padrão `/data/.cybertrace_historico.log`) |

#### Construindo localmente

```bash
docker build --target runtime -t cybertrace .        # enxuta
docker build --target full    -t cybertrace:full .   # com Chromium
```

### Termux (recomendado)

```bash
pkg update && pkg upgrade -y
bash install.sh
bash cybertrace.sh
```

### Linux (Debian/Ubuntu)

```bash
sudo apt update
bash install.sh --linux
bash cybertrace.sh
```

### Manual

```bash
pkg install -y curl python3 git dnsutils openssl-tool qrencode
git clone https://github.com/ClubeDoTermux/cybertrace-panel.git
cd cybertrace-panel
bash cybertrace.sh
```

## Uso via terminal (sem menu)

```bash
bash cybertrace.sh --help
bash cybertrace.sh --ip 8.8.8.8
bash cybertrace.sh --cnpj 19131243000197
bash cybertrace.sh --cep 01310000
bash cybertrace.sh --cpf 52998224725
bash cybertrace.sh --dominio google.com
bash cybertrace.sh --email contato@exemplo.com
bash cybertrace.sh --telefone 5511999999999
bash cybertrace.sh --tempo "Sao+Paulo"
bash cybertrace.sh --redes clubbedotermux
bash cybertrace.sh --banco 341
bash cybertrace.sh --ddd 11
bash cybertrace.sh --fipe 001004-0
bash cybertrace.sh --cotacoes
bash cybertrace.sh --rastreio LU123456789BR
bash cybertrace.sh --feriados 2026
bash cybertrace.sh --ssl google.com
bash cybertrace.sh --rdap github.com
bash cybertrace.sh --portas 8.8.8.8
bash cybertrace.sh --target 52998224725
bash cybertrace.sh --historico
```

## Rastreio de encomenda

A API Linketrack é gratuita mas o modo demo (teste/teste) é limitado.
Para uso real, cadastre-se em https://linketrack.com e exporte as credenciais:

```bash
export LINKETRACK_USER=seu_usuario
export LINKETRACK_TOKEN=seu_token
bash cybertrace.sh --rastreio 000123456789BR
```

## CPF Completo (opção 11)

Requer Chrome/Chromium + dependências (não funciona no Termux):

```bash
pip install selenium webdriver-manager beautifulsoup4
python3 cpf_consulta.py SEU_CPF
```

Já vem pronto na imagem `-full`, sem instalar nada:

```bash
docker run --rm -it ghcr.io/ggfto/cybertrace-panel:latest-full
```

## APIs utilizadas

| API | Dados | Grátis |
|-----|-------|--------|
| [ip-api.com](http://ip-api.com) | Geolocalização de IP + proxy/VPN/hosting | ✅ |
| [Nominatim/OSM](https://nominatim.openstreetmap.org) | Reverse geocoding: rua, bairro, CEP | ✅ |
| [BrasilAPI](https://brasilapi.com.br) | CNPJ, FIPE, DDD, bancos, feriados | ✅ |
| [ViaCEP](https://viacep.com.br) | CEP (rua, bairro, cidade, DDD) | ✅ |
| [AwesomeAPI](https://economia.awesomeapi.com.br) | Cotações USD/EUR/BTC | ✅ |
| [Linketrack](https://linketrack.com) | Rastreio Correios | ✅ |
| [RDAP](https://rdap.org) | WHOIS em JSON (Verisign/.com) | ✅ |
| [wttr.in](https://wttr.in) | Previsão do tempo | ✅ |
| [TinyURL](https://tinyurl.com) | Encurtador de URL | ✅ |

## Novidades da v2.4

- 🟢 **Menu em loop** (sem recursão que crescia a pilha) — código mais limpo
- 🗺️ **DDD dinâmico**: tabela fixa de 130 linhas vira consulta à BrasilAPI com todas as cidades
- 🚗 **Veículo corrigido**: consulta por código FIPE (a antiga por placa não funcionava)
- 🏦 **Banco (ISPB)**: consulta nome/ISPB de qualquer banco brasileiro
- 💱 **Cotações em tempo real**: dólar, euro e bitcoin
- 📦 **Rastreio de encomendas** dos Correios (PAC/SEDEX)
- 🗓 **Feriados nacionais** de qualquer ano
- 🔐 **Certificado SSL**: data de expiração e emissor
- 📋 **WHOIS via RDAP**: JSON limpo, sem depender da ferramenta whois
- 🔑 **Detector de tipo de hash** (MD5, SHA1, SHA256, bcrypt, crypt...)
- 🖥 **Scanner de portas comuns** sem instalar nmap
- 🤖 **--target**: digite qualquer dado e a ferramenta decide a consulta
- 📦 **Consulta em lote**: processa arquivo inteiro de IPs/CEPs/CNPJs
- 🗂 **Histórico automático** de consultas em `.cybertrace_historico.log`
- 🔄 **git pull** integrado (opção 24 / --update)
- 💡 **Reverse geocode**: coordenadas → endereço completo (ferramentas extras [10])
- 📱 **Instalador dedicado** `install.sh` (Termux e Linux)
- 🌐 **Timeouts** em todos os comandos DNS/WHOIS — nada trava a consulta

## Contribuindo

Este projeto usa [Conventional Commits](https://www.conventionalcommits.org/pt-br/)
e release automática via [semantic-release](https://semantic-release.gitbook.io/).
Um commit `feat:` em `main` gera uma versão minor, publica a GitHub Release e
constrói as imagens amd64/arm64 sozinho. Detalhes em [CONTRIBUTING.md](CONTRIBUTING.md).

## Aviso

Ferramenta para fins educacionais e consultas públicas. Dados pessoais (CPF completo, dono de veículo, telefone) são protegidos pela LGPD e não estão disponíveis em APIs públicas gratuitas.