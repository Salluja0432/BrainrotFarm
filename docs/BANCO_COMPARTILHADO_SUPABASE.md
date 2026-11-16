# Banco compartilhado e integração Supabase

**Status:** infraestrutura especificada e arquivos versionados; projeto Supabase ainda não provisionado.

## Decisão arquitetural

Usar Supabase/PostgreSQL como base compartilhada de desenvolvimento e integração.
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

Conectar o aplicativo Supabase disponível no ChatGPT e autenticar na conta/projeto.
O acesso deve ser restrito ao projeto BrainrotFarm Dev. Usar consultas de leitura
para análise; exigir revisão antes de migrations, deletes ou alterações de dados.

### Codex

Instalar o plugin oficial do Supabase para agentes de código ou conectar o MCP
oficial. Escopar por project_ref. Preferir read-only para auditorias e habilitar
escrita apenas para aplicar migrations revisadas. Codex mantém as migrations no Git.

### Roblox

Scripts do servidor usam HttpService para HTTPS até a Edge Function
roblox-gateway. A autenticação é feita pelo header x-brainrot-server-key,
com valor obtido por HttpService:GetSecret("BRAINROTFARM_API_KEY").

Não utilizar a chave service_role no Roblox. Não fazer chamadas ao Supabase
diretamente a partir de LocalScripts. Não deixar segredos em ReplicatedStorage.

### Roblox Studio

Na primeira entrega, o acesso será pelo servidor do jogo em execução no Studio
e em servidores publicados de desenvolvimento. Um plugin de edição para Studio
que leia/escreva dados do projeto poderá ser criado posteriormente; ele não é
necessário para a conexão do jogo e deverá solicitar permissão HTTP ao usuário.

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

Começar com um projeto Supabase separado para desenvolvimento.
Staging e produção exigirão projetos e chaves separados, com deploy controlado.
A função atualmente fixa o ambiente como development.

## Critérios antes de usar no jogo

1. Migration aplicada em projeto de desenvolvimento.
2. RLS e privilégios revisados.
3. Edge Function implantada e segredo configurado.
4. Testes autenticados de GET config e POST events.
5. Teste negativo sem chave, com chave incorreta e payload inválido.
6. Segredo armazenado no Roblox Secrets Store e Local Secrets.
7. Teste de HttpService com dois servidores de desenvolvimento.
8. Aprovação explícita antes de publicar qualquer configuração ao jogo.

## Limite de escopo

A infraestrutura ainda não substitui DataStore e não realiza transações de roubo
entre jogadores. Não migrar persistência de usuários nesta etapa.
