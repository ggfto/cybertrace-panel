#!/usr/bin/env bash
#
# bump-version.sh <versao>
#
# Propaga a versao decidida pelo semantic-release para os arquivos que a
# exibem. Chamado pelo @semantic-release/exec na etapa `prepare`.
#
set -euo pipefail

VERSAO="${1:-}"
if [[ -z "$VERSAO" ]]; then
    echo "uso: $0 <versao>" >&2
    exit 1
fi

if [[ ! "$VERSAO" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+].+)?$ ]]; then
    echo "[!] Versao invalida: $VERSAO" >&2
    exit 1
fi

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"

# Fonte unica da versao nos scripts shell.
for arquivo in cybertrace.sh install.sh; do
    sed -i -E "s/^CYBERTRACE_VERSION=\"[^\"]*\"/CYBERTRACE_VERSION=\"$VERSAO\"/" "$arquivo"
    echo "[OK] $arquivo -> $VERSAO"
done

# Titulo do README.
sed -i -E "s/^# Cybertrace Panel v.*/# Cybertrace Panel v$VERSAO/" README.md
echo "[OK] README.md -> $VERSAO"

# Falha cedo se algum sed nao pegou (evita release com versao fantasma).
for arquivo in cybertrace.sh install.sh; do
    grep -q "^CYBERTRACE_VERSION=\"$VERSAO\"$" "$arquivo" \
        || { echo "[!] falha ao atualizar $arquivo" >&2; exit 1; }
done
grep -q "^# Cybertrace Panel v$VERSAO$" README.md \
    || { echo "[!] falha ao atualizar README.md" >&2; exit 1; }
