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

**Estado da implementação:** journal, reservas, aplicação idempotente e recuperação foram integrados na branch de trabalho; a análise estática com luau-lsp 1.70.1 + sourcemap Rojo 7.7.1 passou no [GitHub Actions](https://github.com/Salluja0432/BrainrotFarm/actions/runs/44214054498). Build RBXLX, abertura no Studio e testes funcionais continuam pendentes. `Config.StealingEnabled` permanece `false`, então o roubo segue desativado.

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
| F1-20 | Resposta perdida após liberação de sessão | Nova tentativa reconhece a liberação anterior sem alterar eventual lock de sessão nova |
| F1-21 | Resposta ambígua ao adquirir sessão | Leitura sem cache confirma somente o mesmo ID de sessão; caso contrário, entrada bloqueada |
| F1-22 | Resposta ambígua ao salvar | Leitura sem cache confirma somente revisão avançada e payload correspondente |
| F1-23 | Resposta ambígua ao liberar | Leitura sem cache confirma somente `lastReleasedSession` da sessão liberada |
| F1-24 | Classificação de erros DataStore | Throttling/erros transitórios recebem backoff; erros permanentes ou desconhecidos não são repetidos |
| F1-25 | Invalidação concorrente durante save pendente | Resposta tardia não reativa a sessão; referência local é liberada |

## Transferência recuperável — cenários adicionais

Os cenários abaixo derivam da especificação em [TRANSFERENCIA_RECUPERAVEL.md](TRANSFERENCIA_RECUPERAVEL.md). Permanecem pendentes; a especificação não significa que a mecânica já esteja corrigida.

| ID | Cenário | Resultado esperado | Ambiente |
|---|---|---|---|
| F1-26 | Roubo bem-sucedido | Uma ocorrência sai do slot da vítima e aparece uma vez no inventário do ladrão | Dois clientes + DataStore dev |
| F1-27 | Roubo simultâneo do mesmo slot | No máximo uma transferência é criada/confirmada | Dois clientes + DataStore dev |
| F1-28 | Mesmo jogador em duas transferências concorrentes | Apenas uma reserva pendente por perfil; a segunda operação é recusada | Dois clientes + DataStore dev |
| F1-29 | Falha depois de criar journal, antes das reservas | Nenhum perfil muda; journal órfão não concede propriedade | Falha injetada |
| F1-30 | Falha depois de reservar só um perfil | Journal pode ser abortado; reserva parcial é removida com segurança; nenhum item muda | Falha injetada |
| F1-31 | Falha após duas reservas, antes de COMMITTED | Nenhuma alteração de propriedade; recuperação aborta PREPARING | Falha injetada |
| F1-32 | Resposta ambígua ao gravar COMMITTED | Estado verificado sem cache; sem prova, os dois perfis permanecem bloqueados | Falha injetada |
| F1-33 | Falha depois de aplicar somente a origem | Vítima e ladrão permanecem bloqueados; recuperação entrega o item uma única vez | Falha injetada |
| F1-34 | Falha depois de aplicar somente o destino | Recuperação reconhece o lado aplicado e não adiciona outro exemplar | Falha injetada |
| F1-35 | Falha após APPLIED durante limpeza das reservas | Jogador com reserva restante só é liberado após limpeza; lado já liberado não é reaplicado | Falha injetada |
| F1-36 | Autosave durante preparação/aplicação | Snapshot antigo não apaga pendingTransfer nem restaura a criatura | Dois clientes + DataStore dev |
| F1-37 | Desconexão/saída durante transferência | Nenhum participante joga com estado pendente; recuperação termina ou mantém bloqueio seguro | Dois clientes + falha injetada |
| F1-38 | Recuperação concorrente em servidores diferentes | Um único recuperador adquire os bloqueios necessários; nenhum jogador entra antes da resolução | Dois servidores dev |
| F1-39 | Repetição de etapas e respostas tardias | Reexecutar qualquer etapa não duplica nem remove uma segunda criatura | Falha injetada |
| F1-40 | Retenção do journal concluído | Registros necessários à recuperação não são apagados prematuramente | DataStore dev |

**Gate específico:** o roubo só pode ser reativado quando todos os cenários acima passarem. Até lá, a revisão estática não equivale a aprovação funcional.

| F1-41 | Entrada com transferência pendente | Jogador não recebe ações, renda ou HUD utilizável antes da recuperação terminar | Studio + DataStore dev |
| F1-42 | Recuperador concorrente | Somente o detentor do lease do journal avança o estado da transferência | Dois servidores dev |
| F1-43 | Transição normal durante lease de recuperação | A transferência original não avança o journal enquanto outro recuperador possui o lease | Falha injetada + dois servidores |
| F1-44 | Erro inesperado no código de transferência | Ambos os participantes falham fechados; journal/reservas permitem recuperação posterior | Falha injetada |

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
Na validação automatizada de 18/11/2026, Rojo 7.7.1 gerou o sourcemap e luau-lsp 1.70.1 analisou Config, DataManager e Main sem diagnósticos ([execução CI](https://github.com/Salluja0432/BrainrotFarm/actions/runs/44214054498)). Isso é análise estática, não teste de execução. Nenhum build RBXLX, teste de Roblox Studio, DataStore ou cenário multiplayer foi executado ainda.

## Gate de Fase 1
Aprovar somente após revisão dos arquivos atuais, build Rojo com versão registrada, casos de Studio e DataStore de desenvolvimento executados, concorrência/falhas avaliadas e riscos residuais documentados.
