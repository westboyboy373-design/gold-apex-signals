-- ============================================================
-- Gold Apex Signals — Supabase schema
-- Run this once in Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- ---------- USERS (profile row per auth user) ----------
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  coins_balance integer not null default 100,       -- 100 free coins on signup
  active_plan text not null default 'none',         -- none | single | fiveDay | monthly | threeMonth | lifetime
  plan_expiry timestamptz,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------- SIGNALS ----------
create table public.signals (
  id uuid primary key default gen_random_uuid(),
  pair text not null,
  direction text not null check (direction in ('buy','sell')),
  entry numeric not null,
  stop_loss numeric not null,
  take_profit numeric not null,
  timeframe text not null,
  risk_level text not null,
  analysis text not null,
  image_url text,
  status text not null default 'active' check (status in ('active','hitTp','hitSl','closed')),
  posted_by uuid references public.users(id),
  posted_at timestamptz not null default now()
);

-- ---------- UNLOCKS (which user unlocked which signal) ----------
create table public.unlocks (
  user_id uuid references public.users(id) on delete cascade,
  signal_id uuid references public.signals(id) on delete cascade,
  unlocked_at timestamptz not null default now(),
  primary key (user_id, signal_id)
);

-- ---------- PAYMENT REQUESTS (manual WhatsApp verification) ----------
create table public.payment_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  reference_id text unique not null,       -- e.g. 5DAYS482913, STRAIGHT771204
  plan_type text not null,                 -- single | fiveDay | monthly | threeMonth | lifetime
  amount_ugx integer not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  proof_image_url text,
  created_at timestamptz not null default now()
);

-- ---------- ADMINS (who added whom, primary admin flag) ----------
create table public.admins (
  user_id uuid primary key references public.users(id) on delete cascade,
  added_by uuid references public.users(id),
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================
-- Auto-create a users row whenever someone signs up via Supabase Auth
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, username)
  values (new.id, coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)));
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- Row Level Security
-- ============================================================
alter table public.users enable row level security;
alter table public.signals enable row level security;
alter table public.unlocks enable row level security;
alter table public.payment_requests enable row level security;
alter table public.admins enable row level security;

-- USERS: everyone can read basic profile info; only the owner can update their own row.
-- (coins_balance / active_plan updates from the app should go through admin-only
-- payment approval logic; consider locking this down further with a Postgres function
-- once you move approval logic server-side.)
create policy "Users are viewable by everyone"
  on public.users for select using (true);

create policy "Users can update their own row"
  on public.users for update using (auth.uid() = id);

-- SIGNALS: everyone (incl. anonymous) can see signal metadata — the app blurs
-- entry/SL/TP client-side for locked users. Only admins can insert/update/delete.
create policy "Signals are viewable by everyone"
  on public.signals for select using (true);

create policy "Only admins can insert signals"
  on public.signals for insert with check (
    exists (select 1 from public.admins where user_id = auth.uid())
  );

create policy "Only admins can update signals"
  on public.signals for update using (
    exists (select 1 from public.admins where user_id = auth.uid())
  );

create policy "Only admins can delete signals"
  on public.signals for delete using (
    exists (select 1 from public.admins where user_id = auth.uid())
  );

-- UNLOCKS: users can see and create their own unlock records only.
create policy "Users can view their own unlocks"
  on public.unlocks for select using (auth.uid() = user_id);

create policy "Users can create their own unlocks"
  on public.unlocks for insert with check (auth.uid() = user_id);

-- PAYMENT REQUESTS: users can view/create their own; only admins can update (approve/reject).
create policy "Users can view their own payment requests"
  on public.payment_requests for select using (
    auth.uid() = user_id or exists (select 1 from public.admins where user_id = auth.uid())
  );

create policy "Users can create their own payment requests"
  on public.payment_requests for insert with check (auth.uid() = user_id);

create policy "Only admins can update payment requests"
  on public.payment_requests for update using (
    exists (select 1 from public.admins where user_id = auth.uid())
  );

-- ADMINS: everyone can see who the admins are; only existing admins can add/remove.
create policy "Admin list is viewable by everyone"
  on public.admins for select using (true);

create policy "Only admins can add admins"
  on public.admins for insert with check (
    exists (select 1 from public.admins where user_id = auth.uid())
  );

create policy "Only admins can remove admins (not the primary one)"
  on public.admins for delete using (
    exists (select 1 from public.admins where user_id = auth.uid())
    and is_primary = false
  );

-- ============================================================
-- Realtime: the app subscribes to live changes on `signals` so new
-- posts appear instantly in the feed without a manual refresh.
-- ============================================================
alter publication supabase_realtime add table public.signals;

-- ============================================================
-- Bootstrap: after your first signup, run this manually once
-- (replace the email) to make yourself the primary admin:
-- ============================================================
-- insert into public.admins (user_id, is_primary)
-- select id, true from public.users where username = 'YOUR_USERNAME_HERE';
-- update public.users set is_admin = true where username = 'YOUR_USERNAME_HERE';
