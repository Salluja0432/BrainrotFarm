# Economia — valores atuais conhecidos

**Status:** referência matemática do protótipo; não é balanceamento aprovado para lançamento.

## Parâmetros
- Preço do ovo: 100 moedas.
- Multiplicador de venda: 10 × renda por segundo.
- Renda passiva: soma das rendas das criaturas posicionadas.
- Chances totalizam 100%.

| Raridade | Probabilidade | Renda/s | Venda |
|---|---:|---:|---:|
| Comum | 60% | 1 | 10 |
| Rara | 25% | 5 | 50 |
| Épica | 10% | 20 | 200 |
| Lendária | 4% | 100 | 1.000 |
| Divina | 1% | 500 | 5.000 |

## Valor esperado correto
Renda média:
0,60×1 + 0,25×5 + 0,10×20 + 0,04×100 + 0,01×500 = **12,85 moedas/s**.

Venda média:
12,85×10 = **128,50 moedas**.

Resultado esperado ao comprar por 100 e vender:
128,50 − 100 = **+28,50 moedas por ovo**.

Retorno esperado relativo ao custo:
28,50/100 = **28,5%**.

Probabilidade de venda abaixo do preço:
Comum (60%) + Rara (25%) = **85%**.

Embora 85% das compras individuais resultem em venda abaixo do custo, a média é positiva por causa dos resultados Lendário e Divino. Repetir compra e venda tem valor esperado positivo e pode inflar a economia.

## Recuperação de custo via renda
Tempo teórico para recuperar 100 moedas usando a renda média:
100/12,85 ≈ **7,78 segundos**. É média probabilística, não garantia individual. Não considera roubo, limites offline, indisponibilidade, arredondamento ou mudanças futuras.

## Regras
- Não mudar preço, chances, rendas ou multiplicador sem decisão registrada.
- Simular progressão e cenários antes de balancear.
- Manter configuração centralizada.
- Distinguir valor efetivo de valor esperado.
- Ponderar pela probabilidade, nunca por média simples das categorias.
- Confirmar que as chances somam 100%.

## Valor inicial reportado
Inspeção estática de `roblox/src/shared/Config.luau` confirmou 100 moedas iniciais e Gatomelo para jogadores sem dados anteriores. A validação funcional desse fluxo no Roblox Studio com DataStore de desenvolvimento permanece pendente.
