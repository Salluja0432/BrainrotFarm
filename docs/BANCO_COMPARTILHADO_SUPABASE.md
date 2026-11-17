# Banco compartilhado e integração Supabase

**Status (16/11/2026):** projeto de desenvolvimento provisionado e ativo; migrations e Edge Function implantadas. Configuração segura do segredo do gateway e integração com Roblox Studio permanecem pendentes.

## Decisão arquitetural

Usar Supabase/PostgreSQL como base compartilhada de desenvolvimento para conhecimento dos agentes, decisões, configurações publicadas explicitamente e telemetria controlada.
O GitHub continua sendo a fonte de verdade do código e dos documentos longos.
O Supabase guarda dados estruturados consultáveis pelos agentes e fornece uma API
controlada para o runtime Roblox.

### Fonte de verdade por domínio

| Domínio | Fonte de verdade |
| --- | --- |
| Código Luau, SQL e Edge Functions | GitHub |
| Documentação longa e decisões versionadas | GitHub |
| Notas operacionais, decisões estruturadas e evidências de teste | Supabase |
| Configuração remota explicitamente publicada | Supabase |
| Moedas, inventário, slots e progresso dos jogadores | Roblox DataStore |
| Eventos de telemetria de desenvolvimento | Supabase |

Não manter duas fontes de verdade graváveis para o mesmo dado de jogador.

## Atores e acesso

### ChatGPT

O aplicativo Supabase do ChatGPT está conectado ao projeto Brainrot Farm Dev.
Manter o acesso restrito ao projeto e usar consultas de leitura para análise;
exigir revisão antes de migrations, deletes ou alterações de dados.

### Codex

O Codex CLI está conectado pelo MCP oficial, escopado ao project_ref de desenvolvimento;
a configuração local usa `read_only=true`. Codex mantém as migrations no Git.

### Roblox

O desenho futuro prevê scripts do servidor usando HttpService para HTTPS até a
Edge Function `roblox-gateway`, autenticando pelo header `x-brainrot-server-key`
com segredo obtido por `HttpService:GetSecret`. **O código Luau atual ainda não
faz essas requisições e o Roblox Studio não está integrado ao gateway.**
O segredo `BRAINROTFARM_ROBLOX_API_KEY` ainda não foi configurado; portanto,
o gateway permanece sem acesso funcional para autenticar chamadas do Roblox até
que o segredo seja configurado de forma segura.

Não utilizar a chave service_role no Roblox. Não fazer chamadas ao Supabase
diretamente a partir de LocalScripts. Não deixar segredos em ReplicatedStorage.

### Roblox Studio

O Roblox Studio ainda não está integrado ao gateway. A futura integração será
feita pelo servidor do jogo em uma experiência isolada de desenvolvimento. Um
plugin de edição para Studio que leia/escreva dados do projeto poderá ser criado
posteriormente; ele não é necessário para a conexão do jogo e deverá solicitar
permissão HTTP ao usuário.

## Modelo de dados

- project_notes: notas curadas compartilhadas entre agentes.
- project_decisions: decisões com contexto, justificativa e substituição explícita.
- test_runs: resultado, ambiente, evidência, commit e executor de cada teste.
- game_config: configuração por ambiente; começa invisível ao jogo.
- game_events: telemetria mínima, sem identificadores pessoais.

Todas as tabelas têm RLS habilitada e privilégios retirados de anon/authenticated.
O acesso administrativo deve ocorrer por MCP autenticado e Edge Function protegida.

## API Roblox de desenvolvimento

### Buscar configuração publicada

GET /functions/v1/roblox-gateway/config

Resposta:
{
  "environment": "development",
  "config": {},
  "entries": 0
}

Somente linhas com visible_to_game=true serão retornadas.

### Registrar evento

POST /functions/v1/roblox-gateway/events

Corpo:
{
  "event_name": "egg_purchased",
  "place_id": 123456789,
  "server_job_id": "job-id",
  "payload": {
    "rarity": "Comum"
  }
}

Eventos permitidos estão em supabase/functions/roblox-gateway/index.ts.
Não enviar UserId, nome de jogador, chat, e-mail ou outros dados pessoais.

## Ambientes

O projeto Supabase separado para desenvolvimento já está criado e ativo.
Staging e produção exigirão projetos e chaves separados, com deploy controlado.
A função atualmente fixa o ambiente como development.

## Estado e critérios antes de usar no jogo

Concluídos em 16/11/2026:
1. Projeto separado de desenvolvimento criado e ativo.
2. Três migrations aplicadas e cinco tabelas compartilhadas criadas com RLS habilitada.
3. Edge Function `roblox-gateway` implantada e ativa.
4. Conexões MCP do ChatGPT e Codex CLI ao projeto de desenvolvimento; configuração local do Codex em modo somente leitura.

Pendentes antes de qualquer chamada autenticada do Roblox:
1. Configurar de forma segura o segredo `BRAINROTFARM_ROBLOX_API_KEY` no ambiente da Edge Function. Até lá, o gateway deve permanecer sem acesso funcional para autenticar chamadas Roblox.
2. Configurar o segredo correspondente no Roblox Secrets Store e Local Secrets, sem incluí-lo em arquivos versionados.
3. Integrar o Roblox Studio/servidor do jogo ao gateway; os scripts atuais não fazem requisições ao Supabase.
4. Executar testes autenticados de GET config e POST events e testes negativos sem chave, com chave incorreta e payload inválido.
5. Testar HttpService com dois servidores de desenvolvimento.
6. Obter aprovação explícita antes de publicar qualquer configuração ao jogo.

## Limite de escopo

A infraestrutura ainda não substitui DataStore e não realiza transações de roubo
entre jogadores. Não migrar persistência de usuários nesta etapa.


## Registro do provisionamento em 16/11/2026

- Projeto Supabase: `Brainrot Farm Dev`, ref `dhlomskkibsjnvsnvozy`, região `sa-east-1`, status `ACTIVE_HEALTHY`.
- Migrations aplicadas: banco inicial, índice da FK de decisões e seed de conhecimento.
- Contagens verificadas: cinco notas, quatro decisões, zero testes de jogo registrados e nove configurações de development.
- Edge Function `roblox-gateway`: implantada e ACTIVE, versão 1. O segredo `BRAINROTFARM_ROBLOX_API_KEY` ainda não está cadastrado; o gateway não está pronto para autenticar chamadas do Roblox e deve permanecer sem acesso funcional até a configuração segura do segredo.
- ChatGPT: ferramenta Supabase conectada e consultas SQL executadas.
- Codex CLI: conexão MCP com o projeto de desenvolvimento; configuração local em `.codex/config.toml`, restrita a este project ref e `read_only=true`.
- Roblox: Roblox Studio ainda não está integrado ao gateway. Os scripts Luau atuais não fazem requisições ao Supabase; Roblox DataStore continua a fonte de verdade dos dados dos jogadores.
