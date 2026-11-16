-- Brainrot Farm: conhecimento inicial compartilhado.
-- Registros curados e idempotentes; não contêm dados de jogadores.

insert into public.project_notes
    (slug, title, category, content, source_path, tags)
values
(
    'project-overview',
    'Visão geral do Brainrot Farm',
    'design',
    'Brainrot Farm é uma experiência Roblox original no gênero simulador de coleção e administração de bases. O loop atual combina compra de ovos, criaturas com raridades, renda passiva, venda, colocação em slots e roubo entre jogadores. A meta de produto é desenvolver retenção, progressão e identidade própria sem copiar personagens, assets, mapas ou identidade de outras experiências.',
    'docs/VISAO_E_PROPOSTA.md',
    array['gameplay','product','overview']
),
(
    'current-prototype-mechanics',
    'Mecânicas do protótipo atual',
    'technical',
    'O protótipo Luau possui compra de ovos, cinco raridades, inventário, seis slots por base, produção de moedas, venda, guardar criaturas, roubo com proteção da vítima por 30 segundos e cooldown do ladrão de 15 segundos, renda offline limitada a uma hora, HUD e DataStore. A presença descrita em documentação não substitui a inspeção do código local atualizado nem testes no Roblox Studio.',
    'docs/ESTADO_ATUAL_E_ARQUITETURA.md',
    array['prototype','luau','mechanics']
),
(
    'economy-baseline-corrected',
    'Linha de base econômica corrigida',
    'economy',
    'Valores atuais: ovo custa 100 moedas; multiplicador de venda é 10; probabilidades são Comum 60%, Rara 25%, Épica 10%, Lendária 4%, Divina 1%; rendas por segundo são 1, 5, 20, 100 e 500. Renda média esperada = 12,85 moedas/s. Valor médio de venda = 128,50 moedas. Lucro esperado por ovo comprado e vendido = 28,50 moedas (28,5% do preço). Probabilidade de prejuízo individual = 85%. O cálculo anterior de 143,50/43,50 estava incorreto. Não modificar valores reais sem decisão explícita.',
    'docs/ECONOMIA.md',
    array['economy','balance','corrected-math']
),
(
    'phase-one-status',
    'Estado e gate da Fase 1',
    'operations',
    'O Codex relatou implementação e revisão estática de inicialização, sessão DataStore, validação de ações e roubo. A auditoria não executou Luau, Rojo, Roblox Studio ou testes em servidores publicados de desenvolvimento. Portanto a Fase 1 ainda não está aprovada e a Fase 2 não deve começar até que os cenários funcionais, de concorrência, falhas de persistência, shutdown e renda offline sejam executados e registrados.',
    'phases/FASE_1_FUNDAMENTACAO_TECNICA.md',
    array['phase-1','testing','gate']
),
(
    'shared-database-architecture',
    'Responsabilidade do Supabase e do Roblox DataStore',
    'technical',
    'Supabase é o repositório de conhecimento estruturado, decisões, evidências de testes, configuração explicitamente publicada e telemetria mínima. GitHub mantém código, migrations e documentação versionada. Roblox DataStore continua fonte de verdade para moedas, inventário, criaturas, slots e progresso de jogadores. Não criar duas fontes graváveis para o mesmo estado de jogador.',
    'docs/BANCO_COMPARTILHADO_SUPABASE.md',
    array['supabase','datastore','architecture']
)
on conflict (slug) do nothing;

insert into public.project_decisions
    (decision_key, title, context, decision, rationale, status, source_path)
values
(
    'player-save-authority',
    'Roblox DataStore é a fonte de verdade do progresso do jogador',
    'A introdução do Supabase para compartilhar conhecimento entre agentes poderia levar a armazenar os mesmos dados de jogador em dois sistemas.',
    'Manter moedas, inventário, criaturas, slots e progresso dos jogadores no Roblox DataStore. Supabase não migra nem substitui esses saves nesta fase.',
    'Evita divergência entre duas fontes graváveis e reduz riscos de perda/duplicação enquanto a persistência atual ainda está sendo validada.',
    'active',
    'docs/BANCO_COMPARTILHADO_SUPABASE.md'
),
(
    'phase-one-release-gate',
    'Não iniciar a Fase 2 antes da validação funcional da Fase 1',
    'A implementação relatada foi revisada estaticamente, mas não executada no Roblox Studio nem em servidores de desenvolvimento publicados.',
    'Manter a Fase 1 aberta até executar e registrar os cenários críticos de DataStore, sessão, inicialização, roubo, concorrência e desligamento.',
    'Relatórios e verificações textuais não demonstram comportamento em runtime nem confiabilidade de persistência.',
    'active',
    'phases/FASE_1_FUNDAMENTACAO_TECNICA.md'
),
(
    'economy-baseline-lock',
    'Preservar os valores econômicos atuais até decisão de balanceamento',
    'A auditoria identificou erro na média anteriormente calculada, mas não há decisão de alterar preço, probabilidades, rendas ou multiplicador.',
    'Manter preço de ovo 100, multiplicador de venda 10, probabilidades e rendas atuais. Usar renda média 12,85/s, venda média 128,50 e lucro médio 28,50 como cálculos de referência.',
    'Corrige a matemática sem alterar o comportamento econômico efetivo durante a Fase 1.',
    'active',
    'docs/ECONOMIA.md'
),
(
    'development-supabase-isolation',
    'Supabase BrainrotFarm Dev é exclusivo para desenvolvimento',
    'O projeto Supabase foi criado para servir os agentes e testes de desenvolvimento; ainda não existe ambiente de produção para o jogo.',
    'Usar o projeto dhlomskkibsjnvsnvozy em São Paulo apenas para desenvolvimento. Criar projetos/segredos separados antes de staging ou produção.',
    'Reduz o risco de agentes modificarem dados reais e mantém a infraestrutura de desenvolvimento isolada.',
    'active',
    'docs/BANCO_COMPARTILHADO_SUPABASE.md'
)
on conflict (decision_key) do nothing;

commit;
