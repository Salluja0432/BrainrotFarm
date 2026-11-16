# Auditoria técnica — histórico consolidado

**Status:** resumo dos relatórios fornecidos; não substitui revisão independente do código atualizado.

## Protótipo inicial
Compra de ovos por 100 moedas; sorteio por raridade; seis slots; renda passiva; venda; guardar criatura; roubo; proteção de 30 segundos; cooldown de 15 segundos; DataStore e renda offline limitada a 3600 segundos; seis bases por servidor.

## Achados da auditoria inicial

### Persistência
- Desenho inicial usava GetAsync/SetAsync e cache local.
- Sem bloqueio robusto de sessão para mesmo jogador em servidores diferentes.
- Snapshot integral podia sobrescrever alterações concorrentes.
- Falhas de salvamento tinham tratamento limitado.
- Sem migração/validação robusta de esquema.
- BindToClose sem coordenação comprovada de todas as gravações.

### Segurança e lógica
- Roubo precisava validar personagem, proprietário, slot e distância no servidor.
- Argumentos de RemoteEvent são não confiáveis.
- Inventário sem limite.
- Ações sempre usavam primeiro item.
- Jogador sem base podia permanecer em servidor sem jogar normalmente.
- Proteção após roubo era memória local.

### Experiência
- HUD fixo e pouco responsivo.
- Sem tutorial, animação de ovo, áudio ou feedback visual de raridade.
- Sem inventário navegável ou seleção de item.
- Sem progressão de longo prazo.

## Revisões reportadas na Fase 1
- Session ID JobId + GUID.
- Aquisição, renovação e saves condicionados ao dono do lock por UpdateAsync.
- Saves locais serializados e revisão de dados.
- Backoff exponencial com jitter e tentativas limitadas.
- Falha fechada e Kick em renovação não confirmada.
- Reserva de base antes do carregamento.
- Verificações de roubo/retirada reforçadas.
- Fórmula econômica corrigida.

## Riscos conhecidos
1. Sem transação atômica entre chaves DataStore de dois jogadores; crash pode causar transferência perdida ou duplicada.
2. Chamadas nativas penduradas não podem ser canceladas.
3. Throttling, lease, resultados ambíguos, liberação de lock e shutdown não foram validados em servidores Roblox.
4. Nenhum teste funcional de Studio/servidor publicado foi executado.

## Economia
Renda esperada 12,85 moedas/s; venda esperada 128,50; lucro esperado 28,50. Cálculo anterior de 14,35/143,50/43,50 estava incorreto.

## Qualidade
- Revisões estáticas: reportadas como realizadas.
- Revisão independente de arquivos atuais: pendente.
- Análise Luau/Rojo: pendente.
- Testes Roblox Studio: pendentes.
- Testes de DataStore em experiência isolada: pendentes.
- Aprovação de publicação: não concedida.
