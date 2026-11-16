# Estado atual e arquitetura conhecida

**Data de referência:** 2026-11-16.

## Escopo de evidência
O ZIP BrainrotFarm.zip foi inspecionado anteriormente. A auditoria inicial descreveu quatro scripts Luau, default.project.json e LEIA-ME.md. Depois, o Codex relatou alterações locais em arquivos do Windows. O conteúdo atualizado ainda não foi sincronizado para este repositório.

Assim:
- A estrutura abaixo descreve o protótipo inicial e os relatórios recebidos.
- As alterações da Fase 1 são relatadas pelo Codex, não verificadas diretamente aqui.
- Este repositório começa como documentação e ainda não contém o código-fonte atual.

## Estrutura inicial descrita
- src/client/Main.client.luau — HUD, botões e notificações.
- src/server/Main.server.luau — bases, ações, renda, prompts e ciclo de jogadores.
- src/server/DataManager.luau — carregamento, cache, salvamento e renda.
- src/shared/Config.luau — parâmetros, raridades e criaturas.
- default.project.json — mapeamento Rojo.
- LEIA-ME.md — setup, teste e publicação inicial.

## Mapeamento Rojo inicial
- ReplicatedStorage.Shared ← src/shared
- ServerScriptService.Server ← src/server
- StarterPlayer.StarterPlayerScripts.Client ← src/client

## Ferramentas
Roblox Studio, Luau, Rojo, Git/GitHub e Codex. Versões exatas de Rojo/Rokit/Luau ainda precisam ser registradas.

## Fase 1 conforme relatório do Codex
O Codex informou:
- Alteração de Config.luau, DataManager.luau e Main.server.luau.
- Criação de FASE-1-TECNICA.md.
- 100 moedas e Gatomelo inicial para novos jogadores.
- Reserva e validação de sessão JobId + GUID.
- UpdateAsync para aquisição e gravação condicionada à sessão.
- Saves locais serializados e revisão de dados.
- Invalidação da sessão e Kick em falha/resultado inesperado de renovação.
- Validação de jogador, personagem, proprietário, slot e distância.
- Economia documentada e corrigida.

Isso é relato de implementação, não validação independente.

## Testes informados
- Verificações estáticas por PowerShell.
- Conferência da fórmula econômica com tolerância a ponto flutuante.
- Checks textuais de referências antigas e métodos de persistência.
- Nenhuma execução de Luau, Rojo ou Roblox Studio.
- Nenhum teste funcional em servidor Roblox.

## Limites conhecidos
- Sem transação atômica entre chaves de dois jogadores; roubo pode falhar entre persistências.
- Chamada DataStore pendurada não pode ser cancelada pelo código.
- Throttling, renovação, resultados ambíguos, liberação de lock e shutdown precisam de teste na plataforma.

## Sincronização futura do código
1. Obter a pasta local atualizada da Fase 1.
2. Confirmar que contém os arquivos relatados.
3. Revisar .gitignore e remover dados sensíveis/gerados.
4. Comparar com o ZIP original.
5. Executar ferramentas disponíveis.
6. Adicionar o código em commit separado da documentação.
