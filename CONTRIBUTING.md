# Como contribuir

## Conventional Commits (obrigatório)

As mensagens de commit definem **automaticamente** a próxima versão e o conteúdo
do CHANGELOG. O formato é validado pelo CI em todo pull request.

```
<tipo>(<escopo opcional>): <descrição no imperativo>

<corpo opcional>

<rodapé opcional>
```

### Tipos e o efeito na versão

| Tipo | Uso | Versão |
|------|-----|--------|
| `feat` | nova funcionalidade | **minor** (2.4.0 → 2.5.0) |
| `fix` | correção de bug | **patch** (2.4.0 → 2.4.1) |
| `perf` | melhoria de performance | patch |
| `refactor` | refatoração sem mudar comportamento | patch |
| `docs` | documentação | patch |
| `build` | Docker, dependências, empacotamento | patch |
| `ci` | pipelines do GitHub Actions | — |
| `test` | testes | — |
| `style` | formatação, espaços, cores | — |
| `chore` | tarefas gerais | — |
| `revert` | reverte um commit anterior | — |

### Mudança incompatível → major

Use `!` depois do tipo/escopo **ou** um rodapé `BREAKING CHANGE:`:

```
feat(cli)!: renomeia --veiculo para --fipe

BREAKING CHANGE: a flag --veiculo foi removida; use --fipe.
```

Isso gera 2.4.0 → **3.0.0**.

### Exemplos válidos

```
feat(ip): adiciona consulta de ASN e organização
fix(cep): corrige timeout na consulta ao ViaCEP
build(docker): reduz a imagem base para debian:bookworm-slim
docs(readme): documenta as variáveis do Linketrack
ci: constrói arm64 em runner nativo
```

### Validando antes de enviar

```bash
npm ci
echo "feat(ip): adiciona consulta de ASN" | npx commitlint --verbose
```

## Fluxo de release

Tudo é automático. Ao entrar um commit em `main`, o workflow `Release`:

1. roda o `semantic-release`, que analisa os commits desde a última tag;
2. calcula a nova versão e escreve o `CHANGELOG.md`;
3. propaga a versão para `cybertrace.sh`, `install.sh` e `README.md`
   (via `scripts/bump-version.sh`);
4. commita, cria a tag `vX.Y.Z` e publica a GitHub Release;
5. constrói as imagens `linux/amd64` e `linux/arm64` e publica no GHCR.

Se nenhum commit exigir release (só `chore`, `ci`, `test`, `style`),
nada é publicado e nenhuma imagem é construída.

### Simulando localmente

```bash
npm ci
GITHUB_TOKEN=$(gh auth token) npx semantic-release --dry-run --no-ci
```

## Rodando o CI localmente

```bash
bash -n cybertrace.sh                       # sintaxe
shellcheck -e SC2034,SC2059,SC1091 *.sh     # lint
docker build --target runtime -t cybertrace:dev .
docker run --rm cybertrace:dev --help
```
