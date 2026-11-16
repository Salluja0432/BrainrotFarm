# Brainrot Farm

Projeto de experiência Roblox em desenvolvimento. Este repositório centraliza a documentação de produto, decisões técnicas, auditorias, testes e planejamento. O código-fonte será incorporado quando a versão local atualizada da Fase 1 for conferida.

## Visão geral

Brainrot Farm é um conceito original de simulador de coleção e administração de bases com renda passiva, interação multiplayer e possibilidade de roubo de criaturas. A proposta combina padrões conhecidos do gênero com criaturas, identidade visual, progressão e eventos próprios — sem copiar personagens, assets ou identidade de outras experiências.

## Estado atual

- **Protótipo inicial:** projeto Luau organizado com Rojo, enviado originalmente como BrainrotFarm.zip.
- **Fase 1 — fundamentação técnica:** o Codex relatou implementação e revisão estática. A implementação ainda não foi validada em execução no Roblox Studio.
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

Este repositório começa como **documentação do projeto**. A presença de uma decisão ou descrição aqui não prova que a funcionalidade exista no código ou funcione no Roblox. Cada afirmação de implementação deve apontar para o código e evidência de teste.

Repositório privado da conta Salluja0432. Não tornar público sem decisão explícita.


## Banco compartilhado

A fundação Supabase está versionada em [supabase/](supabase/):
- [Arquitetura e regras de integração](docs/BANCO_COMPARTILHADO_SUPABASE.md)
- [Migration inicial PostgreSQL](supabase/migrations/20261116000100_brainrot_shared_database.sql)
- [Edge Function para Roblox](supabase/functions/roblox-gateway/index.ts)
- [Instruções de configuração](supabase/README.md)

**Estado:** especificação e arquivos criados no GitHub. O projeto Supabase ainda precisa ser criado/conectado, a migration aplicada e a Edge Function implantada. Não há banco remoto provisionado nesta etapa. O Roblox DataStore continua responsável pelos saves dos jogadores.


## Codex ↔ Supabase
- Configuração MCP restrita e somente leitura: [`.codex/config.toml`](.codex/config.toml)
- Passos de autenticação e verificação: [docs/CODEX_SUPABASE.md](docs/CODEX_SUPABASE.md)
- O Codex precisa confiar neste repositório e concluir OAuth localmente; o arquivo versionado não autentica a conta sozinho.
