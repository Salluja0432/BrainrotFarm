# Registro de decisões — Brainrot Farm

## 2026-11-16 — Repositório privado
- **Decisão:** usar Salluja0432/BrainrotFarm com visibilidade privada.
- **Motivo:** centralizar código, documentação, histórico, testes e contexto para Codex/ChatGPT.
- **Consequência:** não tornar público sem autorização.

## 2026-11-16 — Código Roblox mantido em `roblox/`
- **Decisão:** manter `default.project.json` e a árvore `src/` do projeto Rojo sob `roblox/`.
- **Motivo:** separar a árvore de instâncias Roblox da documentação, configurações MCP e infraestrutura Supabase na raiz.
- **Consequência:** comandos Rojo e caminhos `$path` são executados/resolvidos a partir de `roblox/`; o código do jogo não passa a chamar Supabase.

## 2026-11-16 — Integração como snapshot da origem local
- **Decisão:** copiar os cinco arquivos atuais de `C:\Users\Archie\Downloads\BrainrotFarm` sem importar histórico Git.
- **Motivo:** a pasta de origem não possui repositório Git próprio; a branch `main` de BrainrotFarm-Control permanece a linha de histórico.
- **Consequência:** hashes SHA-256 foram comparados nesta integração; a cópia não representa commits anteriores e não prova validação funcional.

## 2026-11-16 — Documentação antes do código
- **Decisão:** criar documentação primeiro; não importar ZIP antigo como código atual.
- **Motivo:** a Fase 1 foi alterada localmente, mas os arquivos atuais não foram anexados para revisão.
- **Consequência:** decisão histórica. O snapshot atual foi integrado depois de revisão prévia aprovada; os testes Roblox continuam pendentes.

## 2026-11-16 — Economia de referência
- **Decisão:** renda esperada 12,85 moedas/s, venda esperada 128,50 e lucro esperado 28,50 por ovo.
- **Motivo:** correção do cálculo ponderado pelas probabilidades.
- **Consequência:** preço, chances, renda e multiplicador efetivos permanecem inalterados.

## 2026-11-16 — Fase 1 não aprovada para publicação
- **Decisão:** não declarar a Fase 1 pronta para produção até executar testes Roblox pendentes.
- **Motivo:** relatórios descrevem revisão estática, não teste funcional.
- **Consequência:** Fase 2 bloqueada até gate de testes e revisão do código.

## Modelo para novas decisões
### AAAA-MM-DD — Título
- **Decisão:**
- **Motivo:**
- **Alternativas:**
- **Consequências:**
- **Responsável/aprovação:**
