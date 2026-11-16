# Conectar Codex ao Supabase — Brainrot Farm

## Configuração já versionada

O repositório possui `.codex/config.toml`, que registra o servidor remoto Supabase MCP com:
- Project ref fixo: `dhlomskkibsjnvsnvozy` (BrainrotFarm Dev).
- `read_only=true`: consultas de banco são executadas em modo somente leitura.
- `features=database,docs`: só grupos de ferramentas de banco e documentação.
- Aprovação de ferramentas em `prompt`.

A configuração do projeto só é carregada pelo Codex depois de o usuário confiar no repositório. Ela não contém token, senha nem chave de API.

## Passos no Windows / PowerShell

1. Faça pull da versão mais recente de `main` no computador.
2. Abra no Codex a pasta raiz `BrainrotFarm` e marque-a como confiável quando o Codex solicitar.
3. No terminal integrado dessa pasta, execute:

```powershell
codex mcp list
codex mcp login supabase
```

4. O navegador abrirá o fluxo OAuth do Supabase. Entre na conta que contém a organização `trying` e autorize o acesso ao projeto solicitado.
5. Depois do login, execute:

```powershell
codex mcp list
```

6. Reinicie a sessão do Codex (ou o app/extensão) para recarregar as ferramentas MCP. No TUI, use `/mcp` para conferir os servidores ativos.

A documentação oficial do Codex diz que CLI, aplicativo desktop e extensão IDE compartilham a configuração MCP do mesmo host e que a autenticação OAuth é iniciada com `codex mcp login <server-name>`.

## Prompt de verificação para o Codex

Depois de conectar, peça:

```text
Leia AGENTS.md e docs/BANCO_COMPARTILHADO_SUPABASE.md.
Use o Supabase MCP conectado para identificar o projeto atual e listar as
tabelas do schema public. Faça somente consultas de leitura. Confirme o
project ref, o nome das cinco tabelas, e a quantidade de itens em
game_config para development. Não altere schema nem dados.
```

Resultados esperados:
- Project ref: `dhlomskkibsjnvsnvozy`.
- Tabelas: `game_config`, `game_events`, `project_decisions`,
  `project_notes`, `test_runs`.
- `game_config` tem nove linhas iniciais em development.

## Para habilitar escrita posteriormente

Não remova `read_only=true` ainda. Primeiro conclua a revisão do banco,
as verificações dos advisors e a conexão OAuth. Quando houver necessidade
real de escrita, uma mudança separada deverá habilitar apenas o acesso
necessário, manter aprovação explícita de operações e preservar migrations
versionadas no GitHub.

Nunca use MCP em produção. Nunca coloque secrets no repositório ou no prompt.
