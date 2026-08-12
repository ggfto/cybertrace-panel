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
# runtime: alvo padrao (imagem enxuta) — deve ser o ultimo estagio
# ------------------------------------------------------------
FROM base AS runtime
