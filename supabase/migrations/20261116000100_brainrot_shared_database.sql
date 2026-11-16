-- Brainrot Farm: banco compartilhado de desenvolvimento e integração.
-- Esta migration NÃO migra saves de jogadores do Roblox DataStore.
-- Aplicar primeiro em um projeto Supabase de desenvolvimento.

begin;

create table if not exists public.project_notes (
    id uuid primary key default gen_random_uuid(),
    slug text not null unique,
    title text not null,
    category text not null check (category in (
        'design', 'technical', 'economy', 'research', 'operations', 'other'
    )),
    content text not null,
    source_path text,
    tags text[] not null default '{}',
    status text not null default 'active'
        check (status in ('active', 'draft', 'archived')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.project_decisions (
    id uuid primary key default gen_random_uuid(),
    decision_key text not null unique,
    title text not null,
    context text not null,
    decision text not null,
    rationale text not null,
    status text not null default 'active'
        check (status in ('active', 'superseded', 'reverted')),
    source_path text,
    supersedes_id uuid references public.project_decisions(id) on delete set null,
    decided_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.test_runs (
    id uuid primary key default gen_random_uuid(),
    phase text not null,
    test_name text not null,
    environment text not null
        check (environment in ('static', 'local', 'studio', 'published_dev')),
    result text not null
        check (result in ('passed', 'failed', 'blocked', 'not_run')),
    evidence text,
    executed_by text,
    code_commit text,
    executed_at timestamptz,
    created_at timestamptz not null default now()
);

create table if not exists public.game_config (
    environment text not null
        check (environment in ('development', 'staging', 'production')),
    config_key text not null,
    config_value jsonb not null,
    description text,
    visible_to_game boolean not null default false,
    version integer not null default 1 check (version > 0),
    updated_at timestamptz not null default now(),
    primary key (environment, config_key)
);

create table if not exists public.game_events (
    id bigint generated always as identity primary key,
    event_name text not null check (char_length(event_name) between 1 and 64),
    environment text not null
        check (environment in ('development', 'staging', 'production')),
    place_id bigint,
    server_job_id text,
    payload jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

create index if not exists idx_project_notes_category_status
    on public.project_notes (category, status);

create index if not exists idx_project_decisions_status_date
    on public.project_decisions (status, decided_at desc);

create index if not exists idx_test_runs_phase_date
    on public.test_runs (phase, created_at desc);

create index if not exists idx_game_events_env_name_date
    on public.game_events (environment, event_name, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at = pg_catalog.now();
    return new;
end;
$$;

drop trigger if exists project_notes_set_updated_at on public.project_notes;
create trigger project_notes_set_updated_at
before update on public.project_notes
for each row execute function public.set_updated_at();

drop trigger if exists project_decisions_set_updated_at on public.project_decisions;
create trigger project_decisions_set_updated_at
before update on public.project_decisions
for each row execute function public.set_updated_at();

drop trigger if exists game_config_set_updated_at on public.game_config;
create trigger game_config_set_updated_at
before update on public.game_config
for each row execute function public.set_updated_at();

-- Todas as tabelas ficam fechadas para os papéis expostos pela Data API.
-- Agentes autenticados pelo MCP e Edge Functions com credencial de servidor
-- acessam os dados; clientes públicos do jogo não recebem acesso SQL direto.
alter table public.project_notes enable row level security;
alter table public.project_decisions enable row level security;
alter table public.test_runs enable row level security;
alter table public.game_config enable row level security;
alter table public.game_events enable row level security;

revoke all on table public.project_notes from anon, authenticated;
revoke all on table public.project_decisions from anon, authenticated;
revoke all on table public.test_runs from anon, authenticated;
revoke all on table public.game_config from anon, authenticated;
revoke all on table public.game_events from anon, authenticated;

grant all on table public.project_notes to service_role;
grant all on table public.project_decisions to service_role;
grant all on table public.test_runs to service_role;
grant all on table public.game_config to service_role;
grant all on table public.game_events to service_role;
grant usage, select on all sequences in schema public to service_role;

-- Espelho inicial dos valores já documentados. Eles NÃO são fonte de verdade
-- do gameplay enquanto a integração remota não for testada e aprovada.
-- visible_to_game=false impede que o gateway os publique ao jogo.
insert into public.game_config
    (environment, config_key, config_value, description, visible_to_game)
values
    ('development', 'economy.egg_price', '100'::jsonb,
     'Preço atual do ovo; espelho documental de Config.luau.', false),
    ('development', 'economy.sell_multiplier', '10'::jsonb,
     'Multiplicador de venda atual; espelho documental de Config.luau.', false),
    ('development', 'economy.rarity_probabilities',
     '{"Comum":0.60,"Rara":0.25,"Epica":0.10,"Lendaria":0.04,"Divina":0.01}'::jsonb,
     'Probabilidades atuais; espelho documental de Config.luau.', false),
    ('development', 'progression.starting_coins', '100'::jsonb,
     'Saldo inicial para novos jogadores, conforme a Fase 1.', false),
    ('development', 'progression.starting_creature', '"Gatomelo"'::jsonb,
     'Criatura inicial para novos jogadores, conforme a Fase 1.', false),
    ('development', 'base.slot_count', '6'::jsonb,
     'Quantidade atual de slots por base.', false),
    ('development', 'steal.victim_protection_seconds', '30'::jsonb,
     'Proteção atual após roubo bem-sucedido.', false),
    ('development', 'steal.thief_cooldown_seconds', '15'::jsonb,
     'Intervalo atual entre roubos do ladrão.', false),
    ('development', 'offline.max_seconds', '3600'::jsonb,
     'Limite atual de renda offline: uma hora.', false)
on conflict (environment, config_key) do nothing;

comment on table public.project_notes is
    'Notas curadas e não sensíveis compartilhadas entre agentes do Brainrot Farm.';
comment on table public.project_decisions is
    'Registro estruturado de decisões de produto, arquitetura e operação.';
comment on table public.test_runs is
    'Evidências de testes; não registrar como aprovado o que não foi executado.';
comment on table public.game_config is
    'Configuração por ambiente. Espelho inicial; não substitui Config.luau até migração aprovada.';
comment on table public.game_events is
    'Telemetria mínima do jogo; não armazenar chat, e-mail, nome real ou dados pessoais.';

commit;
