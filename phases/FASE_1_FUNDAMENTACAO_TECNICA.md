# Fase 1 — Fundamentação técnica

**Status:** implementação relatada; validação funcional pendente. Não aprovada para publicação.  
**Última revisão relatada:** 2026-11-16.

## Escopo
- 100 moedas e Gatomelo para novos jogadores.
- Preservação de saves existentes.
- Controle das seis bases.
- Bloqueio de sessão único.
- UpdateAsync para aquisição, renovação e saves condicionados.
- Retry limitado e backoff com jitter.
- Invalidação de sessão em falha/resultado inesperado de renovação.
- Validação server-side de ações e roubo.
- Economia documentada e plano de testes.

## Arquivos relatados como modificados
- src/shared/Config.luau
- src/server/DataManager.luau
- src/server/Main.server.luau
- FASE-1-TECNICA.md

Os arquivos não foram sincronizados para este repositório.

## Revisão final relatada pelo Codex
- Session ID JobId + GUID.
- Saves condicionados à sessão atual.
- Saves locais serializados e revisão de dados.
- Lease periódico.
- Sessão invalidada e jogador expulso quando renovação não é confirmada.
- Dados inacessíveis a ações quando sessão inválida/além da margem do lease.
- Callbacks UpdateAsync sem yield ou efeitos externos.
- Roubo em memória sem yield entre remoção do slot e inserção no inventário.
- Cálculo econômico corrigido.

## Riscos
- Sem transação atômica entre chaves de dois jogadores; roubo pode ficar inconsistente em crash entre gravações.
- Chamada DataStore pendurada não pode ser cancelada.
- Lease, throttling, resultados ambíguos, liberação e shutdown não foram validados em Roblox.
- Revisão foi estática.

## Testes
Ver docs/PLANO_DE_TESTES.md. A revisão informou checks estáticos por PowerShell aprovados, incluindo fórmula econômica com tolerância. Não houve Luau/Rojo nem Roblox Studio.

## Critérios de saída
- [ ] Arquivos atuais revisados diretamente.
- [ ] Build Rojo com versão registrada.
- [ ] Análise/sintaxe Luau executada.
- [ ] Primeiro acesso e retorno aprovados em DataStore de desenvolvimento.
- [ ] Capacidade e liberação de base aprovadas.
- [ ] Falhas de carregamento/salvamento verificadas.
- [ ] Sessões concorrentes testadas em dois servidores.
- [ ] Roubo concorrente e desconexão testados.
- [ ] Shutdown e liberação testados.
- [ ] Renda offline sem duplicação comprovada.
- [ ] Riscos residuais documentados e aceitos.

Não iniciar Fase 2 enquanto critérios essenciais não forem atendidos.
