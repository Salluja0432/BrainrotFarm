# Supabase — Brainrot Farm

## Estado do ambiente

- Projeto: **BrainrotFarm Dev**
- Organização: `trying`
- Project ref: `dhlomskkibsjnvsnvozy`
- Região: São Paulo (`sa-east-1`)
- Plano: Free
- Estado verificado: `ACTIVE_HEALTHY`
- URL: https://dhlomskkibsjnvsnvozy.supabase.co
- Migration inicial e índice complementar aplicados com sucesso.
- Edge Function `roblox-gateway` implantada (versão 1, ACTIVE).

## Papel desta infraestrutura

O Supabase é a base compartilhada para:
- notas estruturadas e decisões do projeto;
- evidências de testes;
- configurações de jogo que forem explicitamente publicadas;
- telemetria mínima de desenvolvimento.

O Roblox DataStore continua sendo a fonte de verdade para moedas, inventário,
criaturas e progresso dos jogadores. Esta integração não migra saves.

## Estrutura criada

- `project_notes`: notas de projeto.
- `project_decisions`: decisões e histórico de substituição.
- `test_runs`: evidências dos testes.
- `game_config`: configuração por ambiente.
- `game_events`: telemetria mínima.

Todas as cinco tabelas têm RLS habilitada e privilégios revogados para
`anon` e `authenticated`. Acesso administrativo é feito por ferramentas
conectadas e pela Edge Function no servidor.

## Migrations

1. `20261116000100_brainrot_shared_database.sql`
2. `20261116000200_index_decision_supersedes.sql`
3. `20261116000300_seed_shared_project_knowledge.sql`

As três foram aplicadas ao projeto de desenvolvimento. O estado verificado contém cinco notas, quatro decisões e nove configurações iniciais. Mantenha futuras
alterações versionadas em `supabase/migrations/` e aplique-as somente após
revisão.

## Edge Function

Nome: `roblox-gateway`

Rotas:
- GET `/functions/v1/roblox-gateway/config`
- POST `/functions/v1/roblox-gateway/events`

A função foi implantada, mas **não está pronta para tráfego do Roblox**:
o segredo próprio `BRAINROTFARM_ROBLOX_API_KEY` ainda não foi configurado.
Sem esse segredo, todas as chamadas falham fechadas com HTTP 401. A função
usa `SUPABASE_SERVICE_ROLE_KEY` apenas no ambiente seguro do Supabase.

A ferramenta de conexão atual não expõe operação de gestão de Edge Function
Secrets. Configure o segredo no Dashboard do Supabase ou pela CLI local:

```bash
supabase secrets set BRAINROTFARM_ROBLOX_API_KEY=<segredo-aleatorio-forte>
```

Gere um segredo aleatório de pelo menos 32 bytes e não o envie no chat,
não o comite e não o coloque em código Luau. No Roblox Creator Hub, armazene
o mesmo valor como Secret `BRAINROTFARM_API_KEY`.

## ChatGPT e Codex

- ChatGPT: conexão Supabase autorizada; consultas reais ao banco foram executadas.
- Codex: configuração MCP oficial já versionada em `.codex/config.toml`, restrita
  ao project ref `dhlomskkibsjnvsnvozy`, com `read_only=true` e grupos `database,docs`.
  Falta o usuário confiar no repositório e concluir OAuth local com `codex mcp login supabase`.
- Guia: `docs/CODEX_SUPABASE.md`.
- O repositório GitHub continua sendo a fonte versionada de código, documentação
  e migrations. O banco guarda conhecimento consultável e estado estruturado.

## Roblox Studio

O Roblox poderá usar `HttpService` em Scripts do servidor, depois de configurar
o segredo no Creator Hub. Nunca use service-role key, senha PostgreSQL ou chave
administrativa em LocalScripts, ReplicatedStorage ou arquivos versionados.

## Segurança e limites

- Development usa projeto Supabase separado.
- Staging e production ainda não foram criados.
- `game_config.visible_to_game` permanece false por padrão; nenhum valor está
  publicado para o jogo pelo gateway.
- Eventos aceitos não incluem UserId, nomes, chat, e-mail ou dados pessoais.
- Não utilizar este banco como substituto do DataStore sem decisão arquitetural
  e migração testada.
- Não compartilhar credenciais em issues, commits, conversas ou arquivos .env.

## Verificações

- Projeto criado e estado ACTIVE_HEALTHY confirmado.
- Cinco tabelas verificadas por consulta ao catálogo PostgreSQL.
- Nove configurações iniciais confirmadas em development.
- Três migrations aplicadas com sucesso.
- Edge Function listada como ACTIVE.
- Advisors: RLS sem políticas é intencional nesta etapa, pois os papéis públicos
  não recebem grants; foi identificado e corrigido o índice ausente da FK
  `supersedes_id`. Índices recém-criados podem aparecer como ainda não usados
  até haver volume de consultas.
- Não foram executados testes de integração Roblox nem chamadas autenticadas
  ao gateway, pois o segredo ainda não foi configurado.
