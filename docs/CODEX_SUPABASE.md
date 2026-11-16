# Conectar Codex ao Supabase — Brainrot Farm

## Primeiro: instalar a Codex CLI no Windows

Ter acesso ao aplicativo Codex não significa que o comando `codex` esteja instalado no PowerShell. A CLI é uma ferramenta separada.

Instalador oficial para Windows (execute no PowerShell):

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 | iex"
```

Feche e abra novamente o PowerShell e verifique:

```powershell
codex --version
```

Alternativa oficial via npm, caso prefira usar Node.js:

```powershell
npm install -g @openai/codex
```

Se a instalação terminar mas o comando não for encontrado, feche e reabra o terminal. Se continuar, confira `npm config get prefix` e se a pasta global do npm está no PATH do Windows.

## Configuração segura do servidor Supabase

O repositório possui `.codex/config.toml`, com configuração MCP remota:
- Project ref fixo: `dhlomskkibsjnvsnvozy` (BrainrotFarm Dev).
- `read_only=true`: operações SQL do MCP ficam em modo somente leitura.
- `features=database,docs`: somente grupos de banco de dados e documentação.
- Aprovação de ferramentas: `prompt`.

O Codex carrega configurações MCP de projeto somente quando o repositório foi marcado como confiável.

### Opção A — usando o repositório clonado

1. Atualize/clonar o repositório privado BrainrotFarm.
2. Abra a raiz do repositório no Codex e marque-o como confiável.
3. No terminal nessa pasta, execute:

```powershell
codex mcp list
codex mcp login supabase
```

4. Conclua OAuth no navegador, autenticando na conta Supabase que contém a organização `trying`.
5. Reinicie a sessão do Codex. No TUI, `/mcp` mostra ferramentas MCP disponíveis.

### Opção B — adicionar à configuração do usuário

Se estiver trabalhando numa cópia local antiga do projeto que ainda não contém `.codex/config.toml`, registre o servidor no perfil local do Codex:

```powershell
codex mcp add supabase --url "https://mcp.supabase.com/mcp?project_ref=dhlomskkibsjnvsnvozy&read_only=true&features=database,docs"
codex mcp login supabase
codex mcp list
```

Essa opção escreve em `~/.codex/config.toml` e também permanece limitada ao projeto de desenvolvimento e em modo somente leitura.

Não é necessário usar as opções A e B ao mesmo tempo. Prefira a opção A quando a pasta aberta for o clone atualizado do repositório; use a B para a pasta local existente.

## Prompt de verificação

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
- `project_notes` tem cinco registros.
- `project_decisions` tem quatro registros.

## Segurança

- Não remova `read_only=true` nesta etapa.
- Não conecte MCP a Supabase de produção.
- Nunca cole tokens OAuth, senhas, service-role keys ou segredos em prompts/commits.
- Para liberar escrita futuramente, exija revisão específica e preserve migrations no GitHub.
