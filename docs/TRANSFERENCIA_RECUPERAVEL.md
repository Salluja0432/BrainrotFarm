# Transferência recuperável entre jogadores

**Status:** implementação integrada na branch de trabalho; análise estática aprovada no CI; build Rojo 7.7.1 aberta no Studio e estrutura confirmada. Testes funcionais e de DataStore permanecem pendentes; não aprovada para produção.
**Branch de referência:** fix/phase1-strict-datastore-validation.

## 1. Decisão

O roubo atual altera dois perfis em memória e depende de salvamentos independentes. Isso não fornece durabilidade cross-player: uma gravação pode persistir enquanto a outra falha.

A proposta usa um registro durável por transferência e uma reserva persistida em cada perfil participante. O journal decide se a operação será cancelada ou concluída. Os perfis serão atualizados de forma idempotente e só voltarão a aceitar ações normais depois da reconciliação.

**Não existe transação atômica entre duas chaves DataStore.** Este protocolo é uma saga recuperável com bloqueios, decisão durável e operações idempotentes; não deve ser descrito como atomicidade de banco de dados.

## 2. Invariantes obrigatórios

1. Uma criatura nunca pode ser removida da vítima sem que a transferência tenha uma decisão durável COMMITTED.
2. Uma transferência COMMITTED nunca é revertida por timeout, desconexão ou retry; ela deve ser concluída.
3. Uma transferência PREPARING pode ser abortada, mas nenhuma alteração de propriedade pode ter sido aplicada nessa etapa.
4. Cada perfil pode participar de no máximo uma transferência pendente.
5. Um perfil com pendingTransfer nunca pode executar ações mutáveis, receber renda normal ou aceitar autosave de um snapshot antigo.
6. A aplicação em cada perfil é idempotente: a mesma transferência não pode remover duas criaturas nem adicionar duas criaturas.
7. Respostas ambíguas nunca são tratadas como sucesso ou falha sem verificação sem cache. Quando a verificação não for conclusiva, manter o bloqueio e falhar fechado.
8. Sessões e recuperação precisam provar posse dos bloqueios de perfil antes de gravar.
9. O servidor nunca libera o jogador para jogar enquanto sua transferência pendente não tiver sido resolvida.
10. Nenhuma rotina pode apagar o journal enquanto qualquer perfil ainda apontar para ele.

## 3. Estruturas persistentes propostas

### 3.1 Perfil do jogador

Adicionar ao formato validado do DataStore:

- pendingTransfer: nil ou ID da transferência reservada.
- lastAppliedTransferId: ID da última transferência aplicada neste perfil; substituído somente quando uma nova transferência for aplicada.

Esses campos precisam entrar na allowlist de validData, ser validados estritamente e ser preservados por dataPayload/autosave. O autosave deve recusar gravação se o perfil persistido tiver uma reserva que não corresponde ao snapshot atual.

No estado atual, as criaturas são strings de nomes e não têm atributos individuais. A transferência remove exatamente uma ocorrência do nome registrado no slot de origem e acrescenta uma ocorrência ao inventário do destinatário. Se o design futuramente adicionar atributos por criatura (nível, mutações, melhorias etc.), será necessário introduzir IDs únicos por criatura e uma migração de dados.

### 3.2 Registro de transferência

Um DataStore separado, com uma chave exclusiva por ID de transferência, armazena:

- id, schemaVersion e status;
- victimUserId e thiefUserId;
- slotIndex, creatureName e destinationInventoryCount (contagem esperada antes da inserção);
- createdAt;
- recoverySessionId e recoveryHeartbeat enquanto um recuperador detém o lease.

A confirmação de aplicação não é duplicada no journal: cada perfil guarda lastAppliedTransferId. Esse campo no próprio perfil é a evidência idempotente para saber se aquele lado já foi aplicado.

Não armazenar inventários completos no journal. Não usar MemoryStore como fonte de verdade permanente.

## 4. Máquina de estados

PREPARING
  -> COMMITTED
  -> APPLIED
  -> COMPLETED

PREPARING -> ABORTED

Regras:

- ABORTED só é permitido antes de COMMITTED.
- COMMITTED e APPLIED são estados monotônicos; nunca voltam a um estado anterior.
- A transição é feita com UpdateAsync condicional sobre o estado atual do journal.
- COMPLETED só é marcado depois de confirmar que os dois perfis não apontam mais para a transferência.
- Registros concluídos não são removidos na primeira implementação; retenção e limpeza segura serão tarefa separada.

## 5. Fluxo de uma transferência

### Etapa A — validar e congelar

1. Confirmar que vítima e ladrão estão no mesmo servidor, conectados e com sessões válidas.
2. Confirmar slot, dono da base, criatura, distância, cooldown e proteção.
3. Obter exclusão mútua das duas sessões em ordem determinística por UserId para evitar deadlock.
4. Enquanto a transferência estiver ativa, bloquear ações mutáveis, renda e salvamentos comuns nos dois perfis.
5. Aguardar qualquer autosave já em andamento terminar antes de adquirir os bloqueios da transferência.

### Etapa B — preparar e reservar

1. Criar o journal em PREPARING com um ID único.
2. Reservar o perfil da vítima por UpdateAsync, exigindo a sessão correta e pendingTransfer == nil; gravar o ID.
3. Reservar o perfil do ladrão da mesma forma.
4. Verificar ambos os resultados no backend. Uma reserva parcial nunca autoriza a transferência.
5. Se a preparação falhar, mudar o journal para ABORTED somente por transição condicional e remover apenas as reservas que correspondam a esse ID. Se uma resposta for ambígua, manter os jogadores bloqueados e iniciar recuperação; não adivinhar.

### Etapa C — decisão durável

1. Mudar o journal de PREPARING para COMMITTED via UpdateAsync, somente se as duas reservas tiverem sido confirmadas.
2. Em caso de resposta ambígua, ler o journal sem cache. Se não for possível provar o estado, falhar fechado e manter as reservas.
3. Depois de COMMITTED, qualquer retry ou recuperação deve concluir a transferência, nunca abortá-la.

### Etapa D — aplicar idempotentemente

1. Atualizar o perfil da vítima com UpdateAsync: exigir a reserva e a sessão corretas; se lastAppliedTransferId == id, não repetir; caso contrário, confirmar que o slot ainda contém a criatura esperada, esvaziá-lo e gravar lastAppliedTransferId = id.
2. Atualizar o perfil do ladrão: exigir a reserva e a sessão corretas; se lastAppliedTransferId == id, não repetir; caso contrário, acrescentar exatamente uma criatura ao inventário e gravar lastAppliedTransferId = id.
3. Verificar os dois perfis sem cache. Só depois de confirmar ambos, avançar o journal para APPLIED.
4. Atualizar os snapshots em memória a partir dos resultados persistidos; não reconstruir a memória com cópias anteriores à transação.

### Etapa E — liberar

1. Remover pendingTransfer de cada perfil com atualização condicional que exige o mesmo ID e journal APPLIED.
2. Verificar as duas remoções.
3. Marcar o journal COMPLETED.
4. Liberar os bloqueios locais e enviar atualizações aos clientes.

Se a etapa de liberação falhar parcialmente, o perfil já liberado pode continuar somente porque APPLIED prova que os dois lados foram persistidos. O outro perfil permanece bloqueado até sua reserva ser removida.

## 6. Recuperação após interrupção

A rotina de carregamento precisa detectar pendingTransfer antes de tornar o jogador jogável.

1. Ler o journal correspondente.
2. Obter um lease de recuperação exclusivo no journal.
3. Interpretar o estado antes de atuar:
   - PREPARING: nenhuma alteração de propriedade ocorreu. Abortar condicionalmente o journal e remover apenas a reserva deste perfil; o outro participante limpa a própria reserva quando entrar. Nenhum item é movido.
   - COMMITTED: adquirir o bloqueio do outro perfil, além da sessão já adquirida para o jogador que está entrando. Os dois perfis permanecem inacessíveis a sessões normais.
   - APPLIED ou COMPLETED: APPLIED prova que os dois lados já foram aplicados. Limpar somente a reserva ainda presente no perfil atual; não bloquear um participante cuja reserva já tenha sido removida.
4. Para COMMITTED, consultar lastAppliedTransferId em cada perfil e aplicar apenas o lado que ainda não foi aplicado.
5. Para APPLIED/COMPLETED, remover somente a reserva restante do perfil atual. Se o outro perfil ainda estiver pendente, ele fará a própria limpeza ao entrar.
6. Marcar COMPLETED quando uma leitura confirmar que ambos os perfis não têm pendingTransfer. Liberar leases de recuperação e permitir o carregamento normal somente depois de a reserva do participante atual ter sido removida.

Um servidor que encontre um perfil pendente não pode simplesmente carregar o inventário e deixá-lo jogar. Se o outro perfil ainda estiver bloqueado por uma sessão válida, a recuperação deve falhar fechado e a entrada deve ser tentada novamente depois que o bloqueio anterior for liberado ou expirar.

## 7. Integração necessária no código existente

- Main.server.luau: substituir a mutação direta em steal() por uma API de transferência no módulo de dados; bloquear também ações, renda e interações durante a reserva.
- DataManager.luau: validar/persistir os novos campos, serializar a operação contra autosave/saída, impedir snapshots antigos de sobrescrever reservas, implementar operações condicionais e recuperação.
- Config.luau: configurar nome separado do DataStore do journal, com isolamento obrigatório entre experiência dev e experiência publicada.
- onPlayerAdded: não liberar HUD, base ou ações até concluir recuperação.
- PlayerRemoving e BindToClose: esperar a transação ativa dentro de limites seguros; se não houver confirmação, deixar a reserva/journal recuperáveis e não liberar um perfil como se estivesse salvo.
- PLANO_DE_TESTES.md: acrescentar testes de interrupção após cada escrita, recuperação com um participante ausente, reservas parciais, respostas ambíguas, sessão concorrente e repetição idempotente.

## 8. Testes de aceitação obrigatórios

1. Roubo bem-sucedido: uma criatura sai da vítima e aparece uma vez no ladrão.
2. Duas tentativas simultâneas no mesmo slot: no máximo uma vence.
3. Duas transferências concorrentes envolvendo o mesmo jogador: no máximo uma reserva por perfil.
4. Falha depois de criar journal, antes de reservar qualquer perfil.
5. Falha depois de reservar somente a vítima.
6. Falha depois de reservar os dois perfis, antes de COMMITTED.
7. Resposta ambígua ao marcar COMMITTED.
8. Falha depois de aplicar somente a origem.
9. Falha depois de aplicar somente o destino.
10. Falha depois de aplicar ambos, antes de APPLIED.
11. Falha depois de APPLIED, durante a remoção das reservas.
12. Reinício e recuperação com jogadores entrando em ordem diferente e em servidores diferentes.
13. Autosave concorrente não apaga pendingTransfer nem restaura a criatura removida.
14. Nenhum participante executa compra, venda, posicionamento, renda ou outro roubo enquanto sua reserva está ativa.
15. Respostas tardias e retries não duplicam nem removem uma segunda criatura.
16. Transferência pendente não libera o jogador antes da recuperação.

Cada teste deve inspecionar o journal e os dois perfis no DataStore de desenvolvimento e registrar estado antes e depois. Não habilitar API Services contra dados reais.

## 9. Riscos e decisões ainda necessárias

- DataStore não oferece transação atômica multi-chave; o protocolo precisa passar pelos testes de interrupção e não deve prometer atomicidade.
- Chamadas DataStore podem sofrer throttling e respostas ambíguas. O número total de operações por transferência e o orçamento por servidor precisam ser medidos.
- A política de retenção/limpeza dos journals concluídos deve ser definida separadamente; a primeira versão mantém evidência concluída.
- O formato atual não identifica criaturas individualmente. Isso é suficiente somente enquanto criaturas não tiverem atributos individuais.
- A estratégia de recuperação precisa ser implementada antes de ativar o novo roubo. Um journal sem recuperação integrada é insuficiente.

## 10. Estado de implementação na branch de trabalho

- [x] Risco de gravações independentes identificado na revisão estática.
- [x] Especificação documentada e vinculada ao plano de testes.
- [x] Bloqueio local de ações durante transferência e carregamento/recuperação.
- [x] Serialização da transferência com autosave e saída do jogador.
- [x] Journal persistente, reservas de perfil e estados condicionais.
- [x] Aplicação idempotente de origem/destino com marcadores persistidos.
- [x] Recuperação de PREPARING, COMMITTED e APPLIED antes de liberar o jogador.
- [x] Lease persistente para serializar recuperadores concorrentes.
- [x] Snapshots normais não podem sobrescrever perfis com reserva pendente.
- [ ] Fixtures/harness de falhas.
- [x] Análise estática Luau com luau-lsp 1.70.1 + sourcemap Rojo 7.7.1 ([CI aprovado](https://github.com/Salluja0432/BrainrotFarm/actions/runs/44214054498)).
- [x] Build RBXLX gerado com Rojo 7.7.1 e aberto no Studio; estrutura confirmada no Explorer. Análise em execução e testes funcionais permanecem pendentes.
- [ ] Testes somente em experiência e DataStores de desenvolvimento isolados.
- [ ] Aprovar o roubo após evidência de todos os critérios de aceitação.

**Estado de segurança:** a implementação está integrada somente na branch de trabalho e a análise estática passou no CI, mas ainda falta build RBXLX e teste funcional no Roblox Studio. `Config.StealingEnabled` permanece `false`; o roubo continua desativado até os testes de aceitação passarem. A lista de itens marcados acima indica código presente, não comportamento comprovado.
