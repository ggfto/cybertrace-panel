#!/usr/bin/env bash
#
# Sobe o painel no navegador via ttyd. Toda a configuracao vem de variaveis
# de ambiente, para que o compose consiga controlar tudo pelo .env.
#
#   TTYD_PORT         porta interna (padrao 7681)
#   TTYD_MAX_CLIENTS  sessoes simultaneas (padrao 5, 0 = sem limite)
#   TTYD_CREDENTIAL   "usuario:senha" para basic auth (opcional)
#   TTYD_TITLE        titulo da aba do navegador
#
set -euo pipefail

PORTA="${TTYD_PORT:-7681}"
MAX="${TTYD_MAX_CLIENTS:-5}"
TITULO="${TTYD_TITLE:-Cybertrace Panel}"

ARGS=(
    --port "$PORTA"
    --interface 0.0.0.0
    --max-clients "$MAX"
    --client-option "titleFixed=$TITULO"
    --client-option "fontSize=14"
    # -W libera a entrada do teclado; sem isso o menu fica somente leitura.
    # E justamente por isso que este servico nao pode ficar exposto sem
    # autenticacao — ver o README.
    --writable
)

if [[ -n "${TTYD_CREDENTIAL:-}" ]]; then
    ARGS+=(--credential "$TTYD_CREDENTIAL")
    echo "[i] basic auth do ttyd ativa"
else
    echo "[!] ttyd sem basic auth — mantenha o acesso restrito (Cloudflare Access)"
fi

echo "[i] servindo o painel em 0.0.0.0:$PORTA"
exec ttyd "${ARGS[@]}" /app/cybertrace.sh
