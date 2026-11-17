# Brainrot Farm

Projeto de experiência Roblox em desenvolvimento. Este repositório centraliza o código-fonte Roblox, documentação de produto, decisões técnicas, auditorias, testes e planejamento.

## Visão geral

Brainrot Farm é um conceito original de simulador de coleção e administração de bases com renda passiva, interação multiplayer e possibilidade de roubo de criaturas. A proposta combina padrões conhecidos do gênero com criaturas, identidade visual, progressão e eventos próprios — sem copiar personagens, assets ou identidade de outras experiências.

## Estado atual

- **Implementação:** código-fonte Roblox integrado em [`roblox/`](roblox/), estruturado como projeto Rojo e importado como snapshot da pasta original `BrainrotFarm`, sem histórico Git próprio.
- **Revisão estática:** os arquivos e o mapeamento Rojo foram inspecionados; isso não comprova comportamento em runtime.
- **Validação funcional da Fase 1:** pendente; o jogo ainda não foi validado funcionalmente no Roblox Studio.
- **Fase 2:** não iniciada.
- **Publicação:** não autorizada nem preparada.

## Documentação

- [Instruções para agentes](AGENTS.md)
- [Visão e proposta](docs/VISAO_E_PROPOSTA.md)
- [Game Design Document](docs/GDD.md)
- [Estado atual e arquitetura](docs/ESTADO_ATUAL_E_ARQUITETURA.md)
- [Auditoria técnica](docs/AUDITORIA_TECNICA.md)
- [Economia](docs/ECONOMIA.md)
- [DataStore e segurança](docs/DATASTORE_E_SEGURANCA.md)
- [Configuração de Roblox Studio e Rojo](docs/ROBLOX_STUDIO_E_ROJO.md)
- [Plano de testes](docs/PLANO_DE_TESTES.md)
- [Roadmap](docs/ROADMAP.md)
- [Monetização](docs/MONETIZACAO.md)
- [Pesquisa de tendências](docs/PESQUISA_DE_TENDENCIAS.md)
- [Registro de decisões](docs/DECISOES_DO_PROJETO.md)
- [Fase 1](phases/FASE_1_FUNDAMENTACAO_TECNICA.md)
- [Fase 2](phases/FASE_2_GAMEPLAY.md)

## Como trabalhar

1. Leia AGENTS.md antes de editar código ou documentação.
2. Consulte os documentos relevantes antes de propor mudanças.
3. Faça alterações pequenas e rastreáveis.
4. Registre testes realmente executados; não confunda inspeção estática com teste funcional.
5. Não inicie uma nova fase antes de atender aos critérios da fase anterior.
6. Nunca inclua tokens, credenciais, chaves, dados pessoais ou arquivos privados.

## Tecnologias

- Roblox Studio
- Luau
- Rojo
- Git/GitHub
- Codex como agente de implementação, sob revisão

## Status de validação

A presença do código em `roblox/` confirma a integração dos arquivos, não que o jogo funcione. A comparação SHA-256 e a validação estática do mapeamento Rojo foram executadas; build Rojo, análise Luau e testes funcionais no Studio continuam pendentes.

Repositório privado da conta Salluja0432. Não tornar público sem decisão explícita.

## Banco compartilhado

A fundação Supabase está versionada em [supabase/](supabase/):
- [Arquitetura e regras de integração](docs/BANCO_COMPARTILHADO_SUPABASE.md)
- [Conectar Codex ao Supabase](docs/CODEX_SUPABASE.md)
- [Migration inicial PostgreSQL](supabase/migrations/20261116000100_brainrot_shared_database.sql)
- [Edge Function para Roblox](supabase/functions/roblox-gateway/index.ts)
- [Instruções de configuração](supabase/README.md)

**Estado do ambiente (16/11/2026):** o projeto de desenvolvimento **Brainrot Farm Dev** está provisionado e ativo na região `sa-east-1` (São Paulo). As três migrations foram aplicadas, as cinco tabelas compartilhadas estão criadas e protegidas por RLS, e a Edge Function `roblox-gateway` está implantada e ativa.

- **Funcionando:** ChatGPT utiliza a integração Supabase conectada ao projeto. Codex CLI utiliza o MCP oficial do Supabase, com configuração local `read_only=true`. O Supabase é destinado ao conhecimento compartilhado dos agentes, decisões, configurações publicadas explicitamente e telemetria controlada.
- **Implantado, aguardando configuração segura:** o gateway ainda não pode autenticar chamadas Roblox porque o segredo `BRAINROTFARM_ROBLOX_API_KEY` não foi configurado. Ele deve permanecer sem acesso funcional até a configuração segura do segredo.
- **Ainda não integrado ao jogo:** Roblox Studio não está conectado ao gateway e os scripts Luau atuais não fazem requisições ao Supabase nem enviam dados de jogadores. Roblox DataStore continua sendo a fonte de verdade para moedas, inventário, criaturas e progresso dos jogadores.

## Codex ↔ Supabase

- No ambiente de desenvolvimento do responsável, o ChatGPT utiliza a integração Supabase conectada ao projeto de desenvolvimento.
- O Codex CLI usa o MCP oficial do Supabase; a configuração local em [`.codex/config.toml`](.codex/config.toml) limita a conexão ao projeto e usa `read_only=true`.
- Veja [docs/CODEX_SUPABASE.md](docs/CODEX_SUPABASE.md) para configuração inicial em outros ambientes e solução de problemas. A conexão verificada neste ambiente está ativa.
