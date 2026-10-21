-- ==============================================================================
-- Skema Database TikTap (PostgreSQL untuk Supabase)
-- Jalankan skrip ini di: Dashboard Supabase -> SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. TABEL PROFIL PENGGUNA
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  name text not null,
  email text not null,
  phone text default '',
  avatar integer default 0,
  photo_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Aktifkan Row Level Security (RLS)
alter table public.profiles enable row level security;

-- Policy: Semua orang yang login dapat melihat profil
create policy "Profil dapat dibaca oleh pengguna terautentikasi"
  on public.profiles for select
  using (auth.role() = 'authenticated');

-- Policy: Pengguna hanya dapat mengubah profil miliknya sendiri
create policy "Pengguna dapat mengupdate profil sendiri"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Pengguna dapat menyisipkan profil sendiri"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Trigger: Otomatis buat profil saat ada registrasi baru (Email, Google, Facebook)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email, phone, photo_url)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      split_part(new.email, '@', 1)
    ),
    new.email,
    coalesce(new.raw_user_meta_data->>'phone', ''),
    coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture', null)
  )
  on conflict (id) do update set
    email = excluded.email,
    name = coalesce(excluded.name, profiles.name);
  return new;
end;
$$ language plpgsql security definer;

-- Pasang trigger ke tabel auth bawaan Supabase
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- 2. TABEL TIKET BIOSKOP
create table if not exists public.tickets (
  id text primary key,
  user_id uuid references auth.users on delete cascade not null,
  movie_title text not null,
  cinema text not null,
  date text not null,
  time text not null,
  seats text[] not null,
  total integer not null,
  payment text default '',
  show_at timestamp with time zone not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.tickets enable row level security;

-- Policy: Pengguna hanya dapat membaca tiket miliknya sendiri
create policy "Pengguna hanya melihat tiket miliknya"
  on public.tickets for select
  using (auth.uid() = user_id);

-- Policy: Pengguna dapat menyimpan tiket baru miliknya
create policy "Pengguna dapat menyimpan tiket baru"
  on public.tickets for insert
  with check (auth.uid() = user_id);

create policy "Pengguna dapat mengupdate tiket miliknya"
  on public.tickets for update
  using (auth.uid() = user_id);

