# Fase 1 — Fundamentação técnica

**Status:** código integrado e revisão estática realizada; validação funcional pendente. Não aprovada para publicação.
**Última atualização documental:** 2026-11-16.

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

## Código integrado

Em 2026-11-16, os arquivos atuais da pasta local original do projeto Roblox foram copiados para `roblox/` neste repositório. A origem não possuía histórico Git próprio; portanto, esta integração é um snapshot e não uma importação de commits.

- `roblox/default.project.json`
- `roblox/src/shared/Config.luau`
- `roblox/src/server/Main.server.luau`
- `roblox/src/server/DataManager.luau`
- `roblox/src/client/Main.client.luau`

Os hashes SHA-256 dos cinco arquivos copiados foram comparados com a origem e coincidem. O arquivo Rojo foi parseado como JSON e seus três caminhos existem. Não foram feitas alterações aos scripts.

## Revisão estática reportada no código
- Session ID JobId + GUID.
- Saves condicionados à sessão atual.
- Saves locais serializados e revisão de dados.
- Lease periódico.
- Sessão invalidada e jogador expulso quando renovação não é confirmada.
- Dados inacessíveis a ações quando sessão inválida/além da margem do lease.
- Callbacks UpdateAsync sem yield ou efeitos externos.
- Roubo em memória sem yield entre remoção do slot e inserção no inventário.
- Cálculo econômico corrigido.

A existência desses mecanismos no código e a cópia byte a byte não comprovam que funcionem corretamente em Roblox.

## Riscos
- Sem transação atômica entre chaves de dois jogadores; roubo pode ficar inconsistente em crash entre gravações.
- Chamada DataStore pendurada não pode ser cancelada.
- Lease, throttling, resultados ambíguos, liberação e shutdown não foram validados em Roblox.
- Nenhum teste funcional de Studio/servidor publicado foi executado nesta integração.

## Testes e validações desta integração
- SHA-256 dos cinco arquivos de origem/destino: correspondentes.
- JSON de `roblox/default.project.json`: válido.
- Caminhos `src/shared`, `src/server` e `src/client`: presentes.
- `git diff --check`: resultado registrado no relatório desta integração.
- Build Rojo, análise Luau e Roblox Studio: **não executados**.
- Ver [docs/PLANO_DE_TESTES.md](../docs/PLANO_DE_TESTES.md) para os testes funcionais pendentes.

## Critérios de saída
- [x] Arquivos atuais revisados diretamente e snapshot integrado.
- [x] Hashes dos arquivos copiados e estrutura JSON/path verificados.
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
