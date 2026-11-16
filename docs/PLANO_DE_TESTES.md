# Plano de testes — Brainrot Farm

**Status geral:** cenários definidos; nenhum teste funcional Roblox foi reportado como executado.

## Registro obrigatório
Para cada execução, registrar data/hora, commit, ferramentas/versões, ambiente, passos, esperado, observado, logs e status. Status possíveis: não executado, passou, falhou ou bloqueado. Inspeção estática não é aprovação funcional.

## Fase 1 — cenários obrigatórios

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
O relatório do Codex informa que Rojo, Luau e Luau Analyzer não estavam instalados no ambiente usado para a auditoria. Isso pode diferir do PC do usuário. Registrar resultados reais.

## Gate de Fase 1
Aprovar somente após revisão dos arquivos atuais, análise/build disponíveis, casos de Studio e DataStore de desenvolvimento executados, concorrência/falhas avaliadas e riscos residuais documentados.
