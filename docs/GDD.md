# Game Design Document — Brainrot Farm

**Estado:** rascunho inicial. **Data:** 2026-11-16.

## 1. Conceito
Simulador multiplayer de coleção e fazenda com criaturas originais. Cada jogador tem uma base, inventário e moedas. Criaturas posicionadas produzem renda.

## 2. Mecânicas do protótipo inicial
- Seis bases por servidor e seis slots por base.
- Compra de ovo por 100 moedas.
- Sorteio por raridade.
- Colocação do primeiro item do inventário no primeiro slot livre.
- Renda passiva baseada nas criaturas posicionadas.
- Venda do primeiro item do inventário.
- Guardar criatura na própria base.
- Roubo de criatura em base de outro jogador.
- Proteção temporária após roubo e cooldown individual.
- Persistência de moedas, inventário e criaturas posicionadas.
- Renda offline limitada a uma hora conforme configuração inicial reportada.

## 3. Criaturas iniciais
- Comum: Gatomelo, Sapokito, Pinguim Chiclete.
- Rara: Dino Feijão, Vaquinha Pizza.
- Épica: Rato Foguete, Coruja Neon.
- Lendária: Tubarão Sorvete.
- Divina: Rei Bolinho.

Probabilidades e rendas constam em docs/ECONOMIA.md.

## 4. Roubo no protótipo
- Interação com slot alheio pode transferir criatura ao inventário do ladrão.
- Proteção da vítima: 30 segundos.
- Cooldown do ladrão: 15 segundos.
- Protótipo usa ProximityPrompt.
- Desconexão, sessão e persistência cross-player necessitam de testes na plataforma.

## 5. Progressão ainda não aprovada
Índice de coleção, melhorias de base, slots extras, fusão/evolução, novas regiões, missões, conquistas, eventos e rankings são possibilidades. Cada sistema precisa de especificação antes de implementação.

## 6. Experiência inicial
A revisão da Fase 1 relata que jogadores sem registro recebem 100 moedas e um Gatomelo. Isso precisa ser confirmado no código e no Studio. O tutorial deve explicar moedas, ovos, posicionamento, renda, guardar/vender e interação entre bases.

## 7. Interface
HUD inicial reportado: saldo, renda por segundo, criaturas posicionadas, resumo do inventário, botões de ovo/colocar/vender e notificações. É protótipo; precisa de redesign responsivo.

## 8. Monetização
Não implementada. Consulte docs/MONETIZACAO.md.

## 9. Perguntas em aberto
- Roubo permitido em bases offline?
- Qual contrajogo existe para a vítima?
- Quais limites de inventário?
- Como exibir probabilidades?
- Como tratar itens aleatórios pagos e elegibilidade?
- Qual conteúdo é essencial ou cosmético?
- O nome Brainrot Farm será mantido?
- Qual é o diferencial central?

## 10. Critério de qualidade
Código que compila não basta. Mecânicas precisam ser testadas na experiência real, em diferentes dispositivos e com múltiplos jogadores quando aplicável.
