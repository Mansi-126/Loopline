--
//  supabase_schema.sql
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

-- Loopline schema. Run in the Supabase SQL editor.
-- Enable anonymous sign-ins: Dashboard → Auth → Providers → Anonymous.

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Player',
  emoji text not null default '🦊',
  created_at timestamptz not null default now()
);

create table public.solves (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  level_id text not null,
  kind text not null check (kind in ('campaign','daily')),
  time_seconds double precision not null check (time_seconds > 0),
  backtracks int not null default 0,
  hints_used int not null default 0,
  created_at timestamptz not null default now(),
  unique (user_id, level_id)          -- one entry per player per puzzle
);

-- Leaderboard view: joins names, LinkedIn-style ranking.
-- Rank is computed by: fastest time → fewest backtracks → fewest hints.
-- Includes created_at so the client can filter "today" vs "all time".
create or replace view public.daily_leaderboard as
  select
    s.user_id,
    s.level_id,
    p.display_name,
    p.emoji,
    s.time_seconds,
    s.backtracks,
    s.hints_used,
    s.created_at,
    rank() over (
      partition by s.level_id
      order by s.time_seconds asc, s.backtracks asc, s.hints_used asc
    )::int as rank
  from solves s
  join profiles p on p.id = s.user_id
  where s.kind = 'daily';

-- Row Level Security
alter table profiles enable row level security;
alter table solves enable row level security;

create policy "profiles readable by all"  on profiles for select using (true);
create policy "own profile writable"      on profiles for insert with check (auth.uid() = id);
create policy "own profile updatable"     on profiles for update using (auth.uid() = id);

create policy "solves readable by all"    on solves for select using (true);
create policy "own solves insertable"     on solves for insert with check (auth.uid() = user_id);
create policy "own solves updatable"      on solves for update using (auth.uid() = user_id);

create index solves_leaderboard_idx on solves (level_id, time_seconds, backtracks, hints_used);
