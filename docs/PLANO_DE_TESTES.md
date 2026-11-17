# Plano de testes — Brainrot Farm

**Status geral:** integração estática do snapshot concluída; nenhum teste funcional Roblox foi executado nesta etapa.

## Registro obrigatório
Para cada execução, registrar data/hora, commit, ferramentas/versões, ambiente, passos, esperado, observado, logs e status. Status possíveis: não executado, passou, falhou ou bloqueado. Inspeção estática e build não são aprovação funcional.

## Validação de integração

| Verificação | Estado | Observação |
|---|---|---|
| Presença dos cinco arquivos-fonte | Passou | Origem e destinos confirmados. |
| Hashes SHA-256 | Passou | Os cinco destinos coincidem com a origem. |
| JSON de `roblox/default.project.json` | Passou | Parse estático executado. |
| Caminhos `$path` do Rojo | Passou | `src/shared`, `src/server`, `src/client` existem dentro de `roblox/`. |
| `git diff --check` | Passou | Executado após as alterações. |
| Build Rojo reproduzível e rastreável | **Pendente** | O histórico registra um build anterior concluído com `rojo --version` 7.7.1; não há log que vincule essa versão ao `.rbxlx` aberto. |
| Abrir o `.rbxlx` gerado no Roblox Studio | **Pendente** | Depende do build e do Studio. |
| Execução/validação funcional | **Pendente** | Nenhum cenário funcional executado. |

## Fase 1 — cenários funcionais obrigatórios

Todos os cenários abaixo permanecem pendentes até execução e registro de evidências.

| ID | Cenário | Resultado esperado | Ambiente |
|---|---|---|---|
| F1-01 | Primeiro acesso | Jogador novo recebe valores iniciais uma única vez | Studio + DataStore dev |
| F1-02 | Retorno | Progresso anterior carrega sem bônus inicial repetido | Studio + DataStore dev |
| F1-03 | Servidor cheio | Sétimo jogador não permanece sem base nem gera ações/renda | Teste com 7 jogadores |
| F1-04 | Falha de carregamento | Jogador não fica jogável em estado temporário | Ambiente dev/falha simulada |
| F1-05 | Falha de salvamento | Erro tratado; retry limitado; lock seguro | Ambiente dev |
| F1-06 | Sessões concorrentes | Segunda sessão não assume dados enquanto lock está ativo | Dois servidores dev |
| F1-07 | Roubo simultâneo | No máximo uma transferência para o mesmo slot | Dois clientes |
| F1-08 | Encerramento | Saves/liberação coordenados e reconexão possível | Servidor dev |
| F1-09 | Renda offline | Intervalo elegível creditado uma única vez | DataStore dev |
| F1-10 | Lease perdido | Ações mutáveis cessam após perda/insegurança do lock | Falha simulada |
| F1-11 | Personagem ausente/morto | Roubo/retirada recusado sem corromper estado | Dois clientes |
| F1-12 | Desconexão durante roubo | Nenhuma criatura duplicada; resultado recuperável/documentado | Dois clientes + falhas |

## Validação de dados — novos cenários

Os casos abaixo foram adicionados ao plano, mas ainda precisam de harness/teste controlado no ambiente Roblox:

| ID | Cenário | Resultado esperado |
|---|---|---|
| F1-13 | `coins` NaN, infinito ou negativo | Registro rejeitado sem sobrescrita |
| F1-14 | Inventário com buraco, chave extra ou criatura inválida | Registro rejeitado sem sobrescrita |
| F1-15 | Slot fora do intervalo ou valor inválido | Registro rejeitado; renda limitada aos seis slots |
| F1-16 | Saves legados sem `version` e com slots ausentes | Carregamento compatível; slots ausentes preenchidos vazios |
| F1-17 | Versão explícita desconhecida/futura | Carregamento bloqueado; registro preservado |
| F1-18 | Dados em memória inválidos antes do save | Save cancelado e sessão invalidada |
| F1-19 | Campo superior ou campo de sessão desconhecido | Registro rejeitado sem remover o campo do DataStore |

## Isolamento obrigatório
Executar testes somente em uma experiência Roblox separada e com um nome de DataStore exclusivo para desenvolvimento. Não habilitar Studio Access to API Services contra dados reais de jogadores. Veja [Configuração de Roblox Studio e Rojo](ROBLOX_STUDIO_E_ROJO.md).

## Economia
- Chances somam 100%.
- Renda esperada 12,85.
- Venda esperada 128,50.
- Lucro esperado 28,50 e retorno 28,5%.
- Probabilidade de venda abaixo do custo 85%.
- Simular séries longas para observar inflação.
- Verificar capacidade/tamanho de inventário quando o limite for definido.

## UX futura
Primeira sessão; desktop em resoluções distintas; celular; tablet/console; inventário cheio; base cheia; proteção e cooldown; mensagens de DataStore; seleção de item raro.

## Ferramentas e limitações
Na auditoria de 17/11/2026, Luau e Luau Analyzer não foram executados. A validação desta branch foi somente por revisão estática do diff; nenhum teste de Roblox Studio, DataStore ou build foi executado. O código alterado precisa ser compilado/analisado e testado na máquina com Roblox Studio antes de ser considerado aprovado.

## Gate de Fase 1
Aprovar somente após revisão dos arquivos atuais, build Rojo com versão registrada, casos de Studio e DataStore de desenvolvimento executados, concorrência/falhas avaliadas e riscos residuais documentados.
