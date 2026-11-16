-- Supporting index for the self-referential decision history.
create index if not exists idx_project_decisions_supersedes_id
    on public.project_decisions (supersedes_id);