-- Hall of Athlète : table des sauvegardes en ligne (à exécuter une fois dans Supabase > SQL Editor)
create table if not exists public.saves (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  data       jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.saves enable row level security;

-- chaque joueur ne peut lire et écrire que sa propre sauvegarde
create policy "lire sa sauvegarde"      on public.saves for select to authenticated using (auth.uid() = user_id);
create policy "creer sa sauvegarde"     on public.saves for insert to authenticated with check (auth.uid() = user_id);
create policy "modifier sa sauvegarde"  on public.saves for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
