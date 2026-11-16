# Instruções para agentes — Brainrot Farm

Estas regras se aplicam ao Codex e a outros agentes que alterem este repositório.

## Antes de trabalhar
1. Leia este arquivo e o README.
2. Leia a documentação específica da tarefa, especialmente estado atual, arquitetura, segurança, economia, plano de testes e roadmap.
3. Inspecione o código real e o estado do Git. Não presuma que relatórios antigos descrevem os arquivos atuais.
4. Identifique branch, alterações locais não commitadas e arquivos afetados.
5. Preserve alterações do usuário. Nunca descarte trabalho ou force-push sem autorização explícita.

## Regras de desenvolvimento
- O projeto usa Luau para Roblox Studio e Rojo para mapeamento.
- Não introduza dependências externas sem necessidade justificada.
- Prefira soluções simples e compatíveis com a arquitetura existente.
- Não reescreva módulos inteiros quando uma mudança localizada for suficiente.
- Economia, inventário, propriedade de base e transações devem permanecer sob autoridade do servidor.
- Trate dados recebidos do cliente como não confiáveis.
- Não faça yield nem efeitos externos dentro de callbacks de UpdateAsync.
- Não afirme que DataStore é transacional entre chaves: não há atomicidade entre dados de dois jogadores em um roubo.
- Não adicione Gamepasses, Developer Products, evolução, fusão, eventos ou novos sistemas durante a Fase 1.
- Não altere preço de ovo, chances, rendas ou multiplicador sem decisão registrada.
- Não copie personagens, marcas, sons, mapas, assets ou identidade protegidos.
- Nunca inclua secrets, tokens, cookies, chaves, dados de jogadores ou arquivos privados.

## Documentação
- Mantenha a documentação em português brasileiro, exceto nomes técnicos e APIs.
- Atualize documentos afetados junto com mudanças de comportamento.
- Registre decisões em docs/DECISOES_DO_PROJETO.md.
- Registre o estado de cada fase em phases/.
- Diferencie implementado no código, verificado estaticamente, testado localmente, testado no Studio e validado em servidor publicado de desenvolvimento.
- Nunca marque como aprovado um teste não executado.
- Registre comandos, ambiente, versões, resultado e limitações.

## Processo
1. Planeje mudanças de impacto amplo.
2. Implemente em etapas pequenas.
3. Execute os testes disponíveis.
4. Revise o diff completo.
5. Atualize documentação e checklists.
6. Informe arquivos, testes executados, pendências e riscos residuais.

## Fases e gates
- Não iniciar Fase 2 antes de os critérios essenciais da Fase 1 serem atendidos.
- Não publicar nem alterar configurações de produção sem autorização explícita.
- Use experiência Roblox separada e DataStore exclusivo de desenvolvimento.
- Nunca teste dados experimentais sobre dados reais de jogadores.

## Economia de referência
Consulte docs/ECONOMIA.md. O cálculo correto é renda esperada de 12,85 moedas/s, venda esperada de 128,50 e lucro esperado de 28,50 moedas por ovo comprado e vendido. Não reutilize o cálculo incorreto de 143,50/43,50.

## Relatório obrigatório
Ao concluir, informe resumo, arquivos alterados/criados, testes e resultados, testes não executados, limitações, riscos e decisões que dependem do responsável.
