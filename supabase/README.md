# Supabase — Brainrot Farm

## Papel desta infraestrutura

O Supabase é a base compartilhada para:
- notas estruturadas e decisões do projeto;
- evidências de testes;
- configurações de jogo que forem explicitamente publicadas;
- telemetria mínima de desenvolvimento.

O Roblox DataStore continua sendo a fonte de verdade para moedas, inventário,
criaturas e progresso dos jogadores nesta etapa. Esta integração não migra saves.

## Estrutura

- migrations/: schema SQL versionado no Git;
- functions/roblox-gateway/: API de servidor para o Roblox;
- config.toml: configuração local da Edge Function.

## Preparação

1. Crie/seleciona um projeto Supabase exclusivo de desenvolvimento chamado BrainrotFarm Dev.
2. Conecte o Supabase ao ChatGPT para operar o projeto após autenticação.
3. No computador de desenvolvimento, instale a Supabase CLI.
4. Faça login e vincule a pasta ao projeto usando o project ref correto.
5. Revise a migration antes de aplicá-la:
   supabase db push
6. Configure a função:
   supabase secrets set BRAINROTFARM_ROBLOX_API_KEY=<segredo-gerado-localmente>
7. Faça deploy:
   supabase functions deploy roblox-gateway

Não cole credenciais em conversas, issues, commits ou arquivos .env versionados.
Use um segredo aleatório de pelo menos 32 bytes e mantenha-o fora do Git.

## Codex

Instale o plugin de agentes do Supabase no ambiente Codex, seguindo a documentação
oficial. Alternativamente, configure o MCP oficial do Supabase com escopo para
este project ref. Comece com acesso read-only para inspeção; habilite escrita
somente quando estiver aplicando uma migration revisada.

Comando documentado pelo Supabase para plugin de agentes:
npx plugins add supabase-community/supabase-plugin

O MCP remoto aceita escopo por project_ref e modo read_only. Não conecte o agente
a todos os projetos da conta se ele só precisa trabalhar neste projeto.

## Roblox

A Edge Function possui duas rotas:
- GET /functions/v1/roblox-gateway/config
- POST /functions/v1/roblox-gateway/events

Ambas exigem o header x-brainrot-server-key.
O gateway só aceita o ambiente development nesta primeira versão.

No Roblox Creator Hub, cadastre o mesmo segredo com o nome
BRAINROTFARM_API_KEY no armazenamento de segredos da experiência.
Em testes locais, use Local Secrets em Experience Settings > Security.
A chamada deve ocorrer exclusivamente em Script do servidor usando HttpService.

Nunca coloque SUPABASE_SERVICE_ROLE_KEY, senha PostgreSQL ou a chave administrativa
do Supabase em scripts do Roblox, LocalScripts, ReplicatedStorage ou no Git.

## Segurança e limites

- RLS habilitada em todas as tabelas.
- anon e authenticated não recebem privilégios nas tabelas internas.
- O gateway valida um segredo próprio e usa a credencial administrativa apenas
  dentro da Edge Function.
- Eventos aceitos não incluem UserId, nome, chat, e-mail ou dados pessoais.
- Configurações começam com visible_to_game=false; só publicar após revisão.
- Desenvolvimento, staging e produção devem usar projetos/segredos separados.
- Não utilizar este banco como substituto do DataStore sem uma decisão arquitetural
  e migração testada.

## Limitações conhecidas

- A migration e a Edge Function estão versionadas, mas ainda não foram aplicadas
  nem implantadas em um projeto Supabase.
- A integração real ChatGPT/Codex depende de autenticação do usuário.
- A integração Roblox depende de URL, chave de desenvolvimento e configuração HTTP.
- O armazenamento de segredos Roblox não está disponível em execução local comum;
  configurar Local Secrets no Studio para testes.
- A presença destes arquivos não significa que o banco já esteja provisionado.
