# DataStore, sessão e segurança multiplayer

## Objetivo
Proteger moedas, inventário, criaturas posicionadas e sessões contra duplicação, perda e sobrescrita concorrente.

## Contrato de validação de dados — Fase 1

O `DataManager.validData` aplica validação estrutural antes de adquirir uma sessão e novamente antes de persistir o snapshot em memória.

- Números de saldo, timestamps e heartbeat precisam ser finitos e não negativos. `revision`, índices de listas e índices de slots precisam ser inteiros válidos.
- Inventário precisa ser uma lista densa, indexada a partir de 1, sem chaves extras ou buracos; cada elemento deve corresponder a uma criatura registrada em `Config`.
- `placed` aceita apenas índices entre 1 e `Config.MaxSlots`; cada slot presente precisa estar vazio ou conter uma criatura registrada. Slots ausentes em saves legados são preenchidos com string vazia durante o carregamento.
- `version` ausente é o formato legado atualmente suportado. `Config.DataVersion` é a versão corrente. Qualquer versão explícita diferente da corrente é bloqueada até existir migração específica.
- Em saves legados, `revision`, `lastSeen` e `lastOfflineClaim` podem estar ausentes; a lógica de carregamento existente fornece os valores de compatibilidade.
- Sessão persistida, quando presente, exige ID não vazio e heartbeat finito e não negativo; campos extras dentro da sessão são rejeitados.
- Campos de nível superior são limitados aos campos conhecidos do formato atual/legado. Campos desconhecidos são bloqueados, não descartados silenciosamente. `shieldUntil` é aceito como campo transitório legado e reiniciado em zero ao carregar.
- Registros inválidos ou com versão não suportada não são substituídos por dados iniciais. A transformação de `UpdateAsync` retorna `nil` para cancelar a gravação, preservando o valor existente.
- Uma tentativa repetida de liberação reconhece `lastReleasedSession` quando a liberação anterior já foi confirmada no backend, mesmo que a resposta ao servidor tenha sido perdida; ela retorna o registro atual sem alterar um lock eventualmente adquirido por outra sessão.
- A repetição é limitada a marcadores documentados de falhas transitórias de throttling/serviço interno/rejeição temporária; erros permanentes ou não reconhecidos param sem consumir todas as tentativas. A lista de marcadores precisa ser confirmada com mensagens reais do ambiente de desenvolvimento.
- Depois que uma operação falha, o módulo faz uma leitura única com `DataStoreGetOptions.UseCache = false`. Aquisição é reconhecida somente se o registro confirmar o mesmo ID de sessão; autosave exige sessão, revisão avançada e payload idêntico; liberação exige `lastReleasedSession` correspondente. Se a leitura não provar o resultado, o módulo continua falhando fechado.
- O snapshot em memória é validado antes de ser enviado ao DataStore. Se estiver inválido, a sessão é invalidada e o salvamento é cancelado.
- `markLost` remove a sessão invalidada do cache em memória. Uma resposta de DataStore que chegue depois não pode atualizar nem reativar uma sessão que já foi invalidada por outra rotina.
- A renda percorre somente os seis índices permitidos, nunca valores adicionais fora da base.

Não foi criado limite numérico de itens no inventário nesta etapa. O limite de produto precisa ser decidido separadamente; o registro completo também deve respeitar o limite de tamanho de objeto do DataStore.

## Estado reportado na Fase 1
O Codex informou:
- Session ID JobId + GUID.
- Aquisição e salvamento via UpdateAsync.
- Verificação de dono do lock em callbacks.
- Renovação de lease.
- Saves locais serializados e revisão de dados.
- Retry limitado com backoff exponencial e jitter.
- Falha fechada/Kick em falha ou resultado inesperado da renovação.
- Renda offline creditada na aquisição da sessão.

É necessário conferir o código e testar no Roblox. O relatório não prova comportamento em produção.

## Requisitos de sessão
1. Identificador único por sessão.
2. Aquisição condicional e exclusão de dono simultâneo.
3. Renovação periódica do lease com margem.
4. Toda gravação confirma que a sessão ainda é dona.
5. Sessão é invalidada se não puder provar posse do lock.
6. Depois de invalidada, nenhuma ação mutável é aceita.
7. Liberação remove o lock somente se pertence à sessão atual.
8. Resultado ambíguo tratado conservadoramente.
9. Callback UpdateAsync sem yield ou efeitos externos.
10. Shutdown coordena saves e liberação dentro dos limites da plataforma.

## Limite cross-player

DataStore não fornece transação atômica entre duas chaves independentes. O roubo atual ainda altera os dois perfis em memória e depende de saves independentes; portanto, continua vulnerável a perda/duplicação persistida e não está aprovado para produção.

A implementação do protocolo foi integrada a `Main.server.luau`, `DataManager.luau` e `Config.luau) na branch de trabalho. O desenho, a máquina de estados e os critérios estão em [TRANSFERENCIA_RECUPERAVEL.md](TRANSFERENCIA_RECUPERAVEL.md).

**Estado:** código integrado, mas ainda não compilado/analisado nem testado no Roblox. `Config.StealingEnabled` permanece `false`, portanto o roubo está desativado. O risco cross-player só poderá ser considerado aprovado depois de build, análise Luau e testes de interrupção nos DataStores de desenvolvimento. Não declarar atomicidade multi-chave: o protocolo é recuperável e idempotente, não uma transação atômica.

## Segurança
- Servidor é autoridade para moedas, inventário, renda, slots e propriedade.
- Validar tipo, formato e limites de argumentos de RemoteEvent.
- Não confiar em preços, raridades, nomes, timestamps ou saldo enviados pelo cliente.
- Verificar jogador conectado, personagem vivo, HumanoidRootPart e distância.
- Verificar plot, slot, dono e estado antes da operação.
- Revalidar imediatamente antes da transferência.
- Impedir transferências concorrentes do mesmo item.
- Aplicar rate limits adequados por ação.
- Limpar cache/cooldowns/reservas ao sair.
- Não permitir jogador sem base em estado jogável.
- Registrar erros sem coletar dados desnecessários.

## Testes
Usar experiência de desenvolvimento separada, DataStoreName exclusivo e nunca habilitar API Services do Studio contra dados reais.
