# Estado atual e arquitetura conhecida

**Data de referência:** 2026-11-16.

## Escopo de evidência
O código-fonte Roblox atual foi integrado em `roblox/` a partir de `C:\Users\Archie\Downloads\BrainrotFarm`. A origem não tinha histórico Git próprio; os arquivos foram importados como snapshot.

A inspeção confirmou os arquivos e sua correspondência byte a byte com a origem. O projeto Rojo foi validado estruturalmente, mas build Rojo, análise Luau e execução no Roblox Studio ainda não foram realizados. Portanto, integração de código não equivale a validação funcional.

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
Roblox Studio, Luau, Rojo, Git/GitHub e Codex. Nenhum gerenciador de dependências ou manifesto Rojo foi importado. Rojo CLI, Rokit, Luau e Luau Analyzer não estavam disponíveis no ambiente desta integração; versões exatas ainda precisam ser registradas quando instaladas no ambiente de desenvolvimento.

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
