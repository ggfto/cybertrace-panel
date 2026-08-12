/**
 * Conventional Commits — https://www.conventionalcommits.org/pt-br/
 *
 * Formato:  <tipo>(<escopo opcional>): <descricao>
 * Exemplos: feat(ip): adiciona consulta de ASN
 *           fix(cep): corrige timeout do ViaCEP
 *           feat!: remove a opcao 11 do menu   (BREAKING CHANGE -> major)
 */
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat', // nova funcionalidade      -> minor
        'fix', // correcao de bug          -> patch
        'perf', // performance              -> patch
        'refactor', // refatoracao              -> patch
        'docs', // documentacao             -> patch
        'build', // build/Docker/dependencias -> patch
        'ci', // pipelines                -> sem release
        'test', // testes                   -> sem release
        'style', // formatacao               -> sem release
        'chore', // tarefas gerais           -> sem release
        'revert', // reverte um commit
      ],
    ],
    'subject-case': [0],
    'header-max-length': [2, 'always', 100],
  },
};
