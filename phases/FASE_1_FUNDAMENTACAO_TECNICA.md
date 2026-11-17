# Fase 1 — Fundamentação técnica

**Status:** código integrado e revisão estática realizada; validação funcional pendente. Não aprovada para publicação.
**Última atualização documental:** 2026-11-17.

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

Os hashes SHA-256 dos cinco arquivos copiados foram comparados com a origem e coincidem. O arquivo Rojo foi parseado como JSON e seus três caminhos existem. Não foram feitas alterações aos scripts durante a integração original; esta branch propõe uma alteração localizada no `DataManager.luau`.

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

## Alteração proposta nesta branch — validação estrita
- Rejeitar NaN, infinitos e números negativos em saldo/timestamps/heartbeat.
- Exigir revisão inteira não negativa.
- Exigir inventário denso, sem chaves extras, contendo apenas criaturas de `Config`.
- Aceitar apenas slots válidos até `Config.MaxSlots`; preencher slots ausentes de saves legados com string vazia.
- Aceitar saves antigos sem `version` e normalizá-los para a versão atual no carregamento.
- Bloquear versões explícitas desconhecidas sem regravar o registro.
- Validar novamente os dados em memória antes de salvar.
- Cancelar transformações de `UpdateAsync` com retorno `nil` quando o registro é inválido ou pertence a outra sessão.
- Reconhecer uma liberação já persistida em tentativas repetidas após resposta ambígua, sem substituir lock de sessão posterior.
- Verificar resultados ainda ambíguos por uma leitura backend sem cache, exigindo evidência específica de aquisição, save ou liberação antes de confirmar sucesso.
- Repetir somente categorias reconhecidas de falhas transitórias de DataStore; confirmar os marcadores de erro reais em testes de desenvolvimento.
- Remover sessões invalidadas do cache em memória e ignorar respostas tardias de gravações iniciadas antes da invalidação.
- Calcular renda apenas pelos índices de slots configurados.

A alteração ainda não foi validada em Luau/Roblox Studio. Consulte [docs/PLANO_DE_TESTES.md](../docs/PLANO_DE_TESTES.md) para os casos pendentes.

## Riscos
- Sem transação atômica entre chaves DataStore de dois jogadores; roubo pode ficar inconsistente em crash entre gravações.
- Chamada DataStore pendurada não pode ser cancelada.
- Lease, throttling, resultados ambíguos, liberação e shutdown não foram validados em Roblox.
- Nenhum teste funcional de Studio/servidor publicado foi executado nesta integração.
- A alteração de validação precisa de teste controlado com saves legados representativos antes de adoção na branch principal.

## Testes e validações
- SHA-256 dos cinco arquivos de origem/destino: correspondentes na integração original.
- JSON de `roblox/default.project.json`: válido.
- Caminhos `src/shared`, `src/server` e `src/client`: presentes.
- Build Rojo, análise Luau, execução de Studio e DataStore: **não executados nesta branch**.
- Ver [docs/PLANO_DE_TESTES.md](../docs/PLANO_DE_TESTES.md) para o plano atualizado.

## Critérios de saída
- [x] Arquivos atuais revisados diretamente e snapshot integrado.
- [x] Hashes dos arquivos copiados e estrutura JSON/path verificados.
- [ ] Validação estrita de saves legados com fixtures representativas.
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
