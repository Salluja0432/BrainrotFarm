# Estado atual e arquitetura conhecida

**Data de referência:** 2026-11-17.

## Escopo de evidência
O código-fonte Roblox atual foi integrado em `roblox/` a partir da pasta local original do projeto. A origem não tinha histórico Git próprio; os arquivos foram importados como snapshot.

A inspeção confirmou os arquivos e sua correspondência byte a byte com a origem. Na etapa de integração do snapshot, não foram feitos build Rojo, análise Luau ou testes funcionais no Studio. O histórico do projeto registra `rojo --version` como 7.7.1 e um build anterior concluído; a auditoria de 17/11/2026 encontrou Rokit 1.2.0 e Rojo 7.7.1 instalados em `%USERPROFILE%\.rokit\bin`, diretório que não estava no `PATH`. O manifesto versionado `rokit.toml`, na raiz do repositório, fixa Rojo 7.7.1 para instalações reproduzíveis. Isso não vincula definitivamente a versão ao build histórico nem à build que estava aberta no Studio. Portanto, a integração e o build histórico não equivalem à validação funcional. Ver [docs/ROBLOX_STUDIO_E_ROJO.md](ROBLOX_STUDIO_E_ROJO.md).

## Estrutura atual
- `roblox/src/client/Main.client.luau` — HUD, botões e notificações.
- `roblox/src/server/Main.server.luau` — bases, ações, renda, prompts e ciclo de jogadores.
- `roblox/src/server/DataManager.luau` — carregamento, sessão, cache, salvamento e renda offline.
- `roblox/src/shared/Config.luau` — parâmetros, raridades, criaturas e métricas econômicas.
- `roblox/default.project.json` — mapeamento Rojo.
- `rokit.toml` — fixa Rojo 7.7.1 para instalação pelo Rokit.
- `docs/ROBLOX_STUDIO_E_ROJO.md` — guia de configuração e uso.

## Mapeamento Rojo
- `ReplicatedStorage.Shared` ← `roblox/src/shared`
- `ServerScriptService.Server` ← `roblox/src/server`
- `StarterPlayer.StarterPlayerScripts.Client` ← `roblox/src/client`

## Tecnologias e dependências
Roblox Studio, Luau, Rojo, Rokit, Git/GitHub e Codex. O manifesto `rokit.toml` está versionado na raiz e fixa `rojo-rbx/rojo@7.7.1`. Na auditoria de 17/11/2026, Rokit 1.2.0 e Rojo 7.7.1 estavam instalados em `%USERPROFILE%\.rokit\bin`, mas esse diretório não estava no `PATH`; por isso, os comandos não eram resolvidos diretamente pelo nome no terminal auditado. Na segunda máquina, é necessário instalar Rokit, executar `rokit install` na raiz do clone e confirmar `rojo --version` antes de gerar um build.

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
- Nenhuma execução de Rojo ou teste de Luau foi realizada como parte desta integração documental.
- Nenhum teste funcional em DataStore foi executado.
- Nenhum teste de build foi executado durante a preparação da transferência de 17/11/2026.

## Limites conhecidos
- Sem transação atômica entre chaves de dois jogadores; roubo pode falhar entre persistências.
- Chamada DataStore pendurada não pode ser cancelada pelo código.
- Throttling, renovação, resultados ambíguos, liberação de lock e shutdown precisam de teste na plataforma.

## Próximos passos de validação
1. Na segunda máquina, instalar Rokit e conferir que o comando está disponível no PowerShell.
2. Na raiz do clone, executar `rokit install` e confirmar `rojo --version` = 7.7.1.
3. Gerar um artefato local com `rojo build .\roblox\default.project.json -o .\build\BrainrotFarm.rbxlx`; não substituir os backups RBXLX da transferência.
4. Abrir o artefato gerado no Studio e verificar Explorer e Output.
5. Executar os cenários funcionais da Fase 1 com experiência e DataStore exclusivamente de desenvolvimento.
6. Manter Fase 2 bloqueada até o gate da Fase 1 ser atendido.
