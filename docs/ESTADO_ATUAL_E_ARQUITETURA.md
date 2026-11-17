# Estado atual e arquitetura conhecida

**Data de referência:** 2026-11-16.

## Escopo de evidência
O código-fonte Roblox atual foi integrado em `roblox/` a partir da pasta local original do projeto. A origem não tinha histórico Git próprio; os arquivos foram importados como snapshot.

A inspeção confirmou os arquivos e sua correspondência byte a byte com a origem. Na etapa de integração do snapshot, não foram feitos build Rojo, análise Luau ou testes funcionais no Studio. O histórico do projeto registra `rojo --version` como 7.7.1 e um build anterior concluído; a auditoria de 17/11/2026 não encontrou `rojo` nem `rokit` no `PATH`, nem log que vincule definitivamente a versão declarada à build aberta. Portanto, a integração e o build histórico não equivalem à validação funcional. Ver [docs/ROBLOX_STUDIO_E_ROJO.md](ROBLOX_STUDIO_E_ROJO.md).

## Estrutura atual
- `roblox/src/client/Main.client.luau` — HUD, botões e notificações.
- `roblox/src/server/Main.server.luau` — bases, ações, renda, prompts e ciclo de jogadores.
- `roblox/src/server/DataManager.luau` — carregamento, sessão, cache, salvamento e renda offline.
- `roblox/src/shared/Config.luau` — parâmetros, raridades, criaturas e métricas econômicas.
- `roblox/default.project.json` — mapeamento Rojo.
- `docs/ROBLOX_STUDIO_E_ROJO.md` — guia de configuração e uso.

## Mapeamento Rojo
- `ReplicatedStorage.Shared` ← `roblox/src/shared`
- `ServerScriptService.Server` ← `roblox/src/server`
- `StarterPlayer.StarterPlayerScripts.Client` ← `roblox/src/client`

## Tecnologias e dependências
Roblox Studio, Luau, Rojo, Git/GitHub e Codex. Nenhum gerenciador de dependências ou manifesto Rokit foi incluído no commit de integração. Há um `rokit.toml` local não rastreado que declara Rojo 7.7.1; o histórico também registra um build anterior com Rojo, mas a versão usada nessa build não está vinculada por log ao artefato aberto. Na auditoria de 17/11/2026, `rojo` e `rokit` não estavam disponíveis no `PATH` atual.

## Arquitetura de dados e Supabase
Roblox DataStore permanece a fonte de verdade para moedas, inventário, criaturas, slots e progresso dos jogadores. O código em `roblox/` não chama Supabase nem contém configuração de gateway. A infraestrutura Supabase do repositório permanece separada e inalterada.

## Fase 1 conforme revisão estática
O código presente contém:
- 100 moedas e Gatomelo para novos jogadores.
- Reserva de base durante carregamento.
- Session ID JobId + GUID e UpdateAsync para aquisição/saves condicionais.
- Saves serializados, revisão monotônica e retry limitado com backoff/jitter.
- Invalidação de sessão em falha/resultado inesperado.
- Validação server-side de jogador, personagem, dono, slot e distância.
- Economia documentada: renda esperada 12,85; venda 128,50; lucro 28,50.

Esses achados são de inspeção estática, não prova de funcionamento na plataforma.

## Testes informados nesta integração
- SHA-256 dos cinco arquivos copiados corresponde à origem.
- JSON de `roblox/default.project.json` parseado e caminhos verificados.
- `git diff --check` executado.
- Nenhuma execução de Rojo, Luau, Roblox Studio ou servidor publicado.
- Nenhum teste funcional em DataStore foi executado.

## Limites conhecidos
- Sem transação atômica entre chaves de dois jogadores; roubo pode falhar entre persistências.
- Chamada DataStore pendurada não pode ser cancelada pelo código.
- Throttling, renovação, resultados ambíguos, liberação de lock e shutdown precisam de teste na plataforma.

## Próximos passos de validação
1. Instalar/selecionar versão aprovada do Rojo no ambiente de desenvolvimento e registrar a versão.
2. Compilar o projeto de `roblox/` em artefato local ignorado pelo Git.
3. Abrir o artefato no Roblox Studio e verificar Explorer e Output.
4. Executar os cenários funcionais da Fase 1 com experiência e DataStore exclusivamente de desenvolvimento.
5. Manter Fase 2 bloqueada até o gate da Fase 1 ser atendido.
