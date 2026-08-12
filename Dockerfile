# syntax=docker/dockerfile:1

# ============================================================
# Cybertrace Panel — imagem multi-arch (linux/amd64, linux/arm64)
#
#   docker build -t cybertrace .                 -> imagem enxuta (padrao)
#   docker build --target full -t cybertrace .   -> + Chromium/Selenium (opcao 11)
# ============================================================

# ------------------------------------------------------------
# base: dependencias comuns a todas as variantes
# ------------------------------------------------------------
FROM debian:bookworm-slim AS base

# ARG e nao ENV: nao deve vazar para o runtime do usuario final.
ARG DEBIAN_FRONTEND=noninteractive

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color \
    CYBERTRACE_DOCKER=1 \
    CYBERTRACE_HIST=/data/.cybertrace_historico.log

# curl/dig/openssl/qrencode/whois/ping sao chamados diretamente pelo cybertrace.sh;
# python3 e usado apenas como parser de JSON (stdlib, sem pip).
# git fica de fora de proposito: a opcao 24 (git pull) nao se aplica a container
# — a atualizacao e feita com `docker pull` — e ele traria ~80MB de perl junto.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        dnsutils \
        iputils-ping \
        openssl \
        python3 \
        qrencode \
        tzdata \
        whois \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 10001 --shell /bin/bash cybertrace \
    && mkdir -p /data \
    && chown cybertrace:cybertrace /data

WORKDIR /app

COPY --chown=cybertrace:cybertrace cybertrace.sh ip_consulta.py cpf_consulta.py ./
# Normaliza CRLF: um contexto de build vindo de checkout Windows quebraria o shebang.
RUN sed -i 's/\r$//' cybertrace.sh ip_consulta.py cpf_consulta.py \
    && chmod +x cybertrace.sh

USER cybertrace

# /data ja existe e e gravavel. Nao ha VOLUME declarado de proposito: isso criaria
# um volume anonimo a cada `docker run`. Para persistir o historico, monte:
#   docker run -v cybertrace-data:/data ...
# Sem argumentos abre o menu interativo (precisa de `docker run -it`);
# com argumentos vira CLI: `docker run --rm cybertrace --ip 8.8.8.8`
ENTRYPOINT ["/app/cybertrace.sh"]
CMD []

# ------------------------------------------------------------
# full: adiciona Chromium + Selenium para a opcao 11 (CPF completo)
# ------------------------------------------------------------
FROM base AS full

ARG DEBIAN_FRONTEND=noninteractive
USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        chromium \
        chromium-driver \
        fonts-liberation \
        python3-bs4 \
        python3-selenium \
    && rm -rf /var/lib/apt/lists/*

ENV CHROME_BIN=/usr/bin/chromium \
    CHROMEDRIVER_PATH=/usr/bin/chromedriver

USER cybertrace

# ------------------------------------------------------------
# web: full + ttyd, serve o painel no navegador
#
# O ttyd nao existe nos repos do Debian, entao baixamos o binario estatico
# oficial e conferimos o checksum publicado no SHA256SUMS do release.
# ------------------------------------------------------------
FROM full AS web

ARG DEBIAN_FRONTEND=noninteractive
ARG TTYD_VERSION=1.7.7
ARG TARGETARCH
USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "$TARGETARCH" in \
        amd64) arq=x86_64; sha=8a217c968aba172e0dbf3f34447218dc015bc4d5e59bf51db2f2cd12b7be4f55 ;; \
        arm64) arq=aarch64; sha=b38acadd89d1d396a0f5649aa52c539edbad07f4bc7348b27b4f4b7219dd4165 ;; \
        *) echo "arquitetura sem binario de ttyd: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /usr/local/bin/ttyd \
        "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${arq}"; \
    echo "${sha}  /usr/local/bin/ttyd" | sha256sum -c -; \
    chmod +x /usr/local/bin/ttyd; \
    ttyd --version

COPY --chown=root:root docker/web-entrypoint.sh /usr/local/bin/web-entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/web-entrypoint.sh \
    && chmod +x /usr/local/bin/web-entrypoint.sh

ENV TTYD_PORT=7681 \
    TTYD_MAX_CLIENTS=5

EXPOSE 7681
USER cybertrace

ENTRYPOINT ["/usr/local/bin/web-entrypoint.sh"]
CMD []

# ------------------------------------------------------------
# runtime: alvo padrao (imagem enxuta) — deve ser o ultimo estagio
# ------------------------------------------------------------
FROM base AS runtime
