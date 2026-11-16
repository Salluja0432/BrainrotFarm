# DataStore, sessão e segurança multiplayer

## Objetivo
Proteger moedas, inventário, criaturas posicionadas e sessões contra duplicação, perda e sobrescrita concorrente.

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
DataStore não fornece transação atômica simples entre duas chaves independentes. Um roubo altera dados da vítima e do ladrão; crash entre gravações pode perder ou duplicar transferência persistida. É necessário projetar journal/transação recuperável ou reduzir operações cross-key. Não declarar roubo durável apenas porque a transferência em memória não faz yield.

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
