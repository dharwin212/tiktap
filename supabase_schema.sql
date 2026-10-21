-- ==============================================================================
-- Skema Database TikTap (PostgreSQL untuk Supabase)
-- Jalankan skrip ini di: Dashboard Supabase -> SQL Editor -> New Query -> Run
-- Aman dijalankan berulang kali (Idempotent / Drop If Exists)
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
drop policy if exists "Profil dapat dibaca oleh pengguna terautentikasi" on public.profiles;
create policy "Profil dapat dibaca oleh pengguna terautentikasi"
  on public.profiles for select
  using (auth.role() = 'authenticated');

-- Policy: Pengguna hanya dapat mengubah profil miliknya sendiri
drop policy if exists "Pengguna dapat mengupdate profil sendiri" on public.profiles;
create policy "Pengguna dapat mengupdate profil sendiri"
  on public.profiles for update
  using (auth.uid() = id);

drop policy if exists "Pengguna dapat menyisipkan profil sendiri" on public.profiles;
create policy "Pengguna dapat menyisipkan profil sendiri"
  on public.profiles for insert
  with check (auth.uid() = id);


-- 2. TABEL METODE PEMBAYARAN (PAYMENT METHODS)
create table if not exists public.payment_methods (
  id text primary key,
  user_id uuid references auth.users on delete cascade not null,
  type text not null,
  number text not null,
  is_default boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.payment_methods enable row level security;

-- Policy: Pengguna hanya dapat membaca metode pembayaran miliknya
drop policy if exists "Pengguna hanya melihat metode pembayaran miliknya" on public.payment_methods;
create policy "Pengguna hanya melihat metode pembayaran miliknya"
  on public.payment_methods for select
  using (auth.uid() = user_id);

-- Policy: Pengguna dapat menyimpan metode pembayaran miliknya
drop policy if exists "Pengguna dapat menyimpan metode pembayaran" on public.payment_methods;
create policy "Pengguna dapat menyimpan metode pembayaran"
  on public.payment_methods for insert
  with check (auth.uid() = user_id);

-- Policy: Pengguna dapat mengupdate metode pembayaran miliknya
drop policy if exists "Pengguna dapat mengupdate metode pembayaran miliknya" on public.payment_methods;
create policy "Pengguna dapat mengupdate metode pembayaran miliknya"
  on public.payment_methods for update
  using (auth.uid() = user_id);

-- Policy: Pengguna dapat menghapus metode pembayaran miliknya
drop policy if exists "Pengguna dapat menghapus metode pembayaran miliknya" on public.payment_methods;
create policy "Pengguna dapat menghapus metode pembayaran miliknya"
  on public.payment_methods for delete
  using (auth.uid() = user_id);


-- 3. TABEL TIKET BIOSKOP
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
drop policy if exists "Pengguna hanya melihat tiket miliknya" on public.tickets;
create policy "Pengguna hanya melihat tiket miliknya"
  on public.tickets for select
  using (auth.uid() = user_id);

-- Policy: Pengguna dapat menyimpan tiket baru miliknya
drop policy if exists "Pengguna dapat menyimpan tiket baru" on public.tickets;
create policy "Pengguna dapat menyimpan tiket baru"
  on public.tickets for insert
  with check (auth.uid() = user_id);

drop policy if exists "Pengguna dapat mengupdate tiket miliknya" on public.tickets;
create policy "Pengguna dapat mengupdate tiket miliknya"
  on public.tickets for update
  using (auth.uid() = user_id);


-- 4. TRIGGER: Registrasi Pengguna Baru (Profil & Metode Pembayaran Default)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  -- Buat profil
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

  -- Otomatis buatkan metode pembayaran default (GOPAY, DANA, OVO, BCA)
  insert into public.payment_methods (id, user_id, type, number, is_default)
  values
    ('pm_gopay_' || new.id, new.id, 'GOPAY', '081234567890', true),
    ('pm_dana_' || new.id, new.id, 'DANA', '081234567890', false),
    ('pm_ovo_' || new.id, new.id, 'OVO', '081234567890', false),
    ('pm_bca_' || new.id, new.id, 'Transfer Bank (BCA)', '1234567890', false)
  on conflict (id) do nothing;

  return new;
end;
$$ language plpgsql security definer;

-- Pasang trigger ke tabel auth bawaan Supabase
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- 5. SEED: Buat Metode Pembayaran Default untuk Semua Akun yang Sudah Terdaftar
insert into public.payment_methods (id, user_id, type, number, is_default)
select 'pm_gopay_' || id, id, 'GOPAY', '081234567890', true
from auth.users
on conflict (id) do update set is_default = excluded.is_default;

insert into public.payment_methods (id, user_id, type, number, is_default)
select 'pm_dana_' || id, id, 'DANA', '081234567890', false
from auth.users
on conflict (id) do nothing;

insert into public.payment_methods (id, user_id, type, number, is_default)
select 'pm_ovo_' || id, id, 'OVO', '081234567890', false
from auth.users
on conflict (id) do nothing;

insert into public.payment_methods (id, user_id, type, number, is_default)
select 'pm_bca_' || id, id, 'Transfer Bank (BCA)', '1234567890', false
from auth.users
on conflict (id) do nothing;

