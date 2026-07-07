-- ============================================================
-- UNZOLO CRM — Supabase Schema
-- Run this in: Supabase Dashboard → SQL Editor
-- ============================================================

-- TRIPS
create table if not exists trips (
  id           text primary key,
  title        text not null,
  location     text,
  price        numeric not null default 0,
  description  text,
  duration     text,
  status       text default 'Available',
  status_bg    bigint,      -- Flutter Color.value (ARGB int)
  status_text  bigint,
  image_url    text,
  category     text,
  start_date   text,
  end_date     text,
  advance_amount numeric default 0,
  group_size   int,
  is_deleted   boolean default false,
  user_id      uuid references auth.users(id) on delete cascade not null,
  created_at   timestamptz default now()
);

-- BOOKINGS
create table if not exists bookings (
  id             text primary key,
  trip_id        text,
  title          text not null,
  dates          text,
  status         text default 'Pending',
  image_url      text,
  amount         text,          -- stored as "₹3,600"
  collected      numeric default 0,
  members_count  int default 1,
  payment_due    boolean default false,
  rating         int,
  stats          text,
  members        jsonb default '[]'::jsonb,
  transactions   jsonb default '[]'::jsonb,
  is_active      boolean default true,
  user_id        uuid references auth.users(id) on delete cascade not null,
  created_at     timestamptz default now()
);

-- EXPENSES
create table if not exists expenses (
  id          text primary key,
  trip_id     text,
  category    text,
  amount      numeric default 0,
  description text,
  date        text,
  payer       text,
  notes       text,
  user_id     uuid references auth.users(id) on delete cascade not null,
  created_at  timestamptz default now()
);

-- CUSTOMERS
create table if not exists customers (
  id                   text primary key,
  name                 text not null,
  age                  int,
  gender               text,
  place                text,
  contact              text,
  travel_count         int default 0,
  cancellations_count  int default 0,
  last_destination     text,
  last_date            text,
  user_id              uuid references auth.users(id) on delete cascade not null,
  created_at           timestamptz default now()
);

-- ENQUIRIES
create table if not exists enquiries (
  id             text primary key,
  name           text not null,
  email          text,
  phone          text,
  trip           text,
  message        text,
  status         text default 'Hot',
  date           text,
  avatar_color   bigint,     -- Flutter Color.value
  follow_up_date text,
  priority       text,
  user_id        uuid references auth.users(id) on delete cascade not null,
  created_at     timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY — each agent sees only their own data
-- ============================================================

alter table trips      enable row level security;
alter table bookings   enable row level security;
alter table expenses   enable row level security;
alter table customers  enable row level security;
alter table enquiries  enable row level security;

create policy "trips_owner"     on trips     for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "bookings_owner"  on bookings  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "expenses_owner"  on expenses  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "customers_owner" on customers for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "enquiries_owner" on enquiries for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
