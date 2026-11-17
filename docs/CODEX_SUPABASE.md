# Conectar Codex ao Supabase — Brainrot Farm

## Estado da conexão

Na verificação de 17/11/2026, o Codex CLI estava conectado ao projeto de desenvolvimento Brainrot Farm Dev pelo MCP oficial do Supabase. A configuração local usa `read_only=true`, está escopada ao project ref do projeto e mantém os grupos `database,docs`. O ChatGPT utiliza a integração Supabase conectada ao mesmo projeto.

As instruções abaixo servem para configurar outro ambiente ou recuperar uma conexão. Elas não significam que a conexão verificada neste ambiente esteja pendente. Preserve o modo somente leitura.

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
- Project ref fixo: `dhlomskkibsjnvsnvozy` (Brainrot Farm Dev).
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


## Solução de problemas: documentos ausentes e ferramentas MCP

### Os documentos não aparecem na pasta local

O repositório GitHub `Salluja0432/BrainrotFarm` contém documentação, migrations,
integração Supabase e o snapshot do código Roblox sob `roblox/`. A pasta original
do protótipo Luau é distinta do clone Git e não deve ser presumida como clone do
repositório de documentação.

Verifique sem alterar nada:

```powershell
$downloadsPath = Join-Path $HOME 'Downloads'
$prototypePath = Join-Path $downloadsPath 'BrainrotFarm'
if (Test-Path -LiteralPath $prototypePath) {
    Set-Location $prototypePath
    Test-Path .git
    Test-Path .\AGENTS.md
    Test-Path .\docs\BANCO_COMPARTILHADO_SUPABASE.md
    git remote -v
} else {
    Write-Output 'A pasta original do protótipo não está neste local; ela é distinta do clone BrainrotFarm-Control.'
}
```

Se `.git` e os documentos retornarem `False`, **não execute `git pull` nessa
pasta**. Preserve o protótipo e clone o repositório de documentação em uma pasta
vizinha:

```powershell
$downloadsPath = Join-Path $HOME 'Downloads'
$repoPath = Join-Path $downloadsPath 'BrainrotFarm-Control'
if (-not (Test-Path $repoPath)) {
    Set-Location $downloadsPath
    git clone https://github.com/Salluja0432/BrainrotFarm.git BrainrotFarm-Control
}
Set-Location $repoPath
codex
```

O comando `codex`, executado com o diretório atual em `$repoPath`, abre a sessão
na raiz do clone. Se o clone já existir, o bloco não executa outro `git clone`.
O projeto contém documentação, configuração MCP e o snapshot integrado dos
scripts Luau em `roblox/`. A pasta original do protótipo permanece separada; não
a confunda com o clone Git `BrainrotFarm-Control`.

### O comando lista o servidor, mas a sessão não mostra ferramentas

`codex mcp list` confirma cadastro e estado de autenticação na configuração;
não prova, sozinho, que o servidor iniciou e anunciou ferramentas na sessão
atual do agente.

1. Feche completamente o Codex desktop e abra novamente.
2. Em Settings > MCP servers, confirme que `supabase` está habilitado e autenticado.
3. Abra uma sessão local com o clone `BrainrotFarm-Control`, não uma sessão remota/cloud.
4. No terminal, execute `codex` e dentro da TUI use `/mcp`.
5. Confira se `supabase` aparece conectado e se há ferramentas disponíveis.
6. Se continuar sem ferramentas, verifique a mensagem de inicialização/erro do
   servidor na tela MCP antes de alterar a configuração.

O Codex desktop e a CLI compartilham a configuração local MCP, mas o ChatGPT web
não lê arquivos locais `~/.codex`. Ferramentas MCP locais também não devem ser
presumidas disponíveis numa sessão cloud/remote.
