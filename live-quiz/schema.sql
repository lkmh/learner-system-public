-- Run this once in the Supabase SQL editor for your project (Dashboard > SQL Editor > New query).
-- This is the full, current schema. If you already ran an earlier version of
-- this file, see the "incremental migration" block at the bottom instead —
-- running the `create table if not exists` statements again is harmless,
-- but re-running `create policy` will error on duplicates.

create extension if not exists pgcrypto;

create table if not exists live_quiz_sessions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  -- lobby -> question -> results -> ... -> ended        (mode = 'lockstep', host-paced)
  -- lobby -> active -> review -> ... -> ended            (mode = 'timed', self-paced within a time limit)
  status text not null default 'lobby' check (status in ('lobby', 'question', 'results', 'active', 'review', 'ended')),
  question_index integer not null default -1,
  host_id uuid references auth.users(id) default auth.uid(),
  question_source text not null default 'live-quiz-demo.yaml',
  question_section text,
  question_label text,
  mode text not null default 'lockstep' check (mode in ('lockstep', 'timed')),
  duration_minutes integer,
  started_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists live_quiz_participants (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references live_quiz_sessions(id) on delete cascade,
  client_id uuid not null,
  name text not null,
  joined_at timestamptz not null default now(),
  unique (session_id, client_id)
);

create table if not exists live_quiz_answers (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references live_quiz_sessions(id) on delete cascade,
  participant_id uuid not null references live_quiz_participants(id) on delete cascade,
  question_index integer not null,
  option_index integer not null,
  answered_at timestamptz not null default now(),
  unique (session_id, participant_id, question_index)
);

alter table live_quiz_sessions enable row level security;
alter table live_quiz_participants enable row level security;
alter table live_quiz_answers enable row level security;

-- Sessions: only a signed-in host can create/advance one, and only the host
-- that created it (host_id = auth.uid()) can advance it — this is what stops
-- a random visitor from hijacking someone else's live class. "Signed in"
-- means a real Supabase email+password account that only you know the
-- password to (create it once in Dashboard > Authentication > Users > Add
-- user) — not Anonymous Auth, so nobody else can even create a session, let
-- alone touch yours. See README.md's "Security model" section for the full
-- setup (also: turn OFF Anonymous sign-ins and turn OFF "Allow new users to
-- sign up" under Authentication > Sign In / Providers > Email).
create policy "Signed-in hosts can create a session"
  on live_quiz_sessions for insert
  to authenticated
  with check (host_id = auth.uid());

create policy "Only the owning host can advance their session"
  on live_quiz_sessions for update
  to authenticated
  using (host_id = auth.uid());

-- Reads are scoped to the last 24 hours across all three tables — long
-- enough for a live class plus its review, short enough that a scraper with
-- just the public key can't harvest your full multi-class history of names
-- and answers. Nothing in host.html/join.html ever needs to read older data.
create policy "Anyone can read recent sessions"
  on live_quiz_sessions for select
  to public
  using (created_at > now() - interval '24 hours');

-- Participants/answers stay insert-open (no sign-in) — that's what lets
-- learners join and answer with nothing but the join code, and it's low
-- stakes if someone spams fake rows into their own class's tally. `to
-- public` (not just `to anon`) so this keeps working even if the same
-- browser also has a host's auth session active (e.g. a presenter testing
-- their own join link).
create policy "Anyone can join a session" on live_quiz_participants for insert to public with check (true);
create policy "Anyone can read recent participants" on live_quiz_participants for select to public
  using (session_id in (select id from live_quiz_sessions where created_at > now() - interval '24 hours'));
-- Needed for the join upsert's ON CONFLICT DO UPDATE path (re-joining with
-- the same name after a refresh) — without this, rejoining fails RLS.
create policy "Anyone can update their own join row" on live_quiz_participants for update to public
  using (session_id in (select id from live_quiz_sessions where created_at > now() - interval '24 hours'))
  with check (session_id in (select id from live_quiz_sessions where created_at > now() - interval '24 hours'));

create policy "Anyone can submit an answer" on live_quiz_answers for insert to public with check (true);
create policy "Anyone can read recent answers" on live_quiz_answers for select to public
  using (session_id in (select id from live_quiz_sessions where created_at > now() - interval '24 hours'));

-- Turn on Realtime (Postgres Changes) for these three tables.
alter publication supabase_realtime add table live_quiz_sessions;
alter publication supabase_realtime add table live_quiz_participants;
alter publication supabase_realtime add table live_quiz_answers;


-- ============================================================
-- Incremental migration — run this instead if your database already has
-- the original (pre-security, pre-multi-session) version of this schema.
-- ============================================================
--
-- alter table live_quiz_sessions
--   add column if not exists host_id uuid references auth.users(id) default auth.uid(),
--   add column if not exists question_source text not null default 'live-quiz-demo.yaml',
--   add column if not exists question_section text,
--   add column if not exists question_label text;
--
-- drop policy if exists "Anyone can create a session" on live_quiz_sessions;
-- drop policy if exists "Anyone can advance a session" on live_quiz_sessions;
-- drop policy if exists "Anyone can read sessions" on live_quiz_sessions;
--
-- create policy "Signed-in hosts can create a session"
--   on live_quiz_sessions for insert to authenticated with check (host_id = auth.uid());
-- create policy "Anyone can read sessions"
--   on live_quiz_sessions for select to public using (true);
-- create policy "Only the owning host can advance their session"
--   on live_quiz_sessions for update to authenticated using (host_id = auth.uid());
--
-- drop policy if exists "Anyone can join a session" on live_quiz_participants;
-- drop policy if exists "Anyone can read participants" on live_quiz_participants;
-- create policy "Anyone can join a session" on live_quiz_participants for insert to public with check (true);
-- create policy "Anyone can read participants" on live_quiz_participants for select to public using (true);
--
-- drop policy if exists "Anyone can submit an answer" on live_quiz_answers;
-- drop policy if exists "Anyone can read answers" on live_quiz_answers;
-- create policy "Anyone can submit an answer" on live_quiz_answers for insert to public with check (true);
-- create policy "Anyone can read answers" on live_quiz_answers for select to public using (true);


-- ============================================================
-- Second migration — adds the "timed / self-paced" quiz mode (as opposed to
-- the original host-paced, one-question-at-a-time mode). Run this if your
-- database already has the security + multi-session migration above.
-- ============================================================
--
-- alter table live_quiz_sessions
--   add column if not exists mode text not null default 'lockstep' check (mode in ('lockstep', 'timed')),
--   add column if not exists duration_minutes integer,
--   add column if not exists started_at timestamptz,
--   add column if not exists ends_at timestamptz;
--
-- -- Widen the status check constraint to allow 'active' and 'review', whatever
-- -- its auto-generated name actually is:
-- do $$
-- declare
--   con record;
-- begin
--   for con in
--     select pgc.conname
--     from pg_constraint pgc
--     join pg_class rel on rel.oid = pgc.conrelid
--     where rel.relname = 'live_quiz_sessions'
--       and pgc.contype = 'c'
--       and pg_get_constraintdef(pgc.oid) like '%status%'
--   loop
--     execute format('alter table live_quiz_sessions drop constraint %I', con.conname);
--   end loop;
-- end $$;
--
-- alter table live_quiz_sessions add constraint live_quiz_sessions_status_check
--   check (status in ('lobby', 'question', 'results', 'active', 'review', 'ended'));
--
-- -- Bug fix: rejoining with the same name (the upsert's ON CONFLICT DO UPDATE
-- -- path) was never covered by an UPDATE policy, so it silently failed RLS.
-- create policy "Anyone can update their own join row" on live_quiz_participants for update to public using (true) with check (true);


-- ============================================================
-- Third migration — real password-gated host login (instead of Anonymous
-- Auth) + time-scoped reads, ahead of making this repo public. Run this if
-- your database already has the first two migrations above.
-- ============================================================
--
-- -- Reads scoped to the last 24h, so a scraper with just the public key
-- -- can't harvest every class's names/answers ever run, forever.
-- drop policy if exists "Anyone can read sessions" on live_quiz_sessions;
-- create policy "Anyone can read recent sessions"
--   on live_quiz_sessions for select to public
--   using (created_at > now() - interval '24 hours');
--
-- drop policy if exists "Anyone can read participants" on live_quiz_participants;
-- create policy "Anyone can read recent participants"
--   on live_quiz_participants for select to public
--   using (session_id in (select id from live_quiz_sessions where created_at > now() - interval '24 hours'));
--
-- drop policy if exists "Anyone can update their own join row" on live_quiz_participants;
-- create policy "Anyone can update their own join row"
--   on live_quiz_participants for update to public
--   using (session_id in (select id from live_quiz_sessions where created_at > now() - interval '24 hours'))
--   with check (session_id in (select id from live_quiz_sessions where created_at > now() - interval '24 hours'));
--
-- drop policy if exists "Anyone can read answers" on live_quiz_answers;
-- create policy "Anyone can read recent answers"
--   on live_quiz_answers for select to public
--   using (session_id in (select id from live_quiz_sessions where created_at > now() - interval '24 hours'));
--
-- -- Then in the Supabase dashboard (not SQL):
-- -- 1. Authentication > Users > Add user — create ONE user with your own
-- --    email + a password only you know. Check "Auto Confirm User" so it
-- --    doesn't need email verification.
-- -- 2. Authentication > Sign In / Providers > Email > turn OFF "Allow new
-- --    users to sign up" — so nobody else can register their own account.
-- -- 3. Authentication > Sign In / Providers > Anonymous > turn back OFF —
-- --    host.html no longer uses it, so leaving it on would still let
-- --    strangers authenticate and create their own sessions (just not touch
-- --    yours).
