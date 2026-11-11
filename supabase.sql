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


-- =====================================================================
-- CLASSEMENT (à exécuter une fois dans Supabase > SQL Editor)
-- Chaque sauvegarde calcule automatiquement le pseudo et la moyenne ; la vue "leaderboard"
-- n'expose que le pseudo et la moyenne (jamais le reste de la sauvegarde).
-- =====================================================================
alter table public.saves add column if not exists pseudo  text;
alter table public.saves add column if not exists moyenne numeric not null default 0;

create or replace function public.saves_fill() returns trigger language plpgsql as $$
declare k text; v numeric; tot numeric := 0;
begin
  foreach k in array array['force','speed','endurance','agility','precision','mental'] loop
    begin v := (new.data #>> array['stats', k])::numeric; exception when others then v := 0; end;
    tot := tot + least(greatest(coalesce(v, 0), 0), 100);
  end loop;
  new.moyenne := round(tot / 6, 2);
  new.pseudo  := left(coalesce(nullif(trim(new.data ->> 'name'), ''), 'Athlète'), 22);
  return new;
end $$;

drop trigger if exists saves_fill on public.saves;
create trigger saves_fill before insert or update on public.saves
  for each row execute function public.saves_fill();

update public.saves set data = data;   -- recalcule les sauvegardes déjà présentes

create or replace view public.leaderboard as
  select user_id, pseudo, moyenne, updated_at from public.saves;
grant select on public.leaderboard to authenticated;
