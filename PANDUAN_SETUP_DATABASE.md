# Panduan Setup Database & Login Sosial TikTap (Supabase)

Aplikasi TikTap kini telah dihubungkan dengan backend **Supabase** (PostgreSQL Cloud, Google/Facebook OAuth, dan Pengiriman Email OTP Otomatis).

---

## 1. Hubungkan Proyek Supabase Anda (1 Menit)
1. Buka [https://supabase.com](https://supabase.com) dan buat akun/proyek baru gratis.
2. Di dashboard proyek Anda, buka **Project Settings** -> **API**.
3. Buka file `lib/supabase_config.dart` di proyek TikTap, lalu ganti:
   - `YOUR_SUPABASE_URL` dengan **Project URL** Anda (contoh: `https://xyzabc.supabase.co`)
   - `YOUR_SUPABASE_ANON_KEY` dengan **anon public key** Anda.

---

## 2. Pasang Skema Database (Tabel Profil & Tiket)
1. Di dashboard Supabase, buka menu **SQL Editor**.
2. Klik **New query**, lalu salin dan tempel seluruh isi file [`supabase_schema.sql`](supabase_schema.sql).
3. Klik tombol **Run**.
   - Tabel `public.profiles` dan `public.tickets` akan otomatis dibuat lengkap dengan *Row Level Security (RLS)* dan trigger registrasi otomatis.

---

## 3. Aktifkan Login Google & Facebook
1. Di dashboard Supabase, buka menu **Authentication** -> **Providers**.
2. **Google**:
   - Aktifkan toggle **Google**.
   - Masukkan *Client ID* dan *Client Secret* dari Google Cloud Console.
   - Pada Google Cloud Console, tambahkan URL Callback dari Supabase (*Authorized redirect URIs*).
3. **Facebook**:
   - Aktifkan toggle **Facebook**.
   - Masukkan *App ID* dan *App Secret* dari Meta for Developers.

---

## 4. Pengiriman Email Lupa Password (Otomatis)
- Supabase secara *built-in* sudah menyediakan pengiriman email otomatis.
- Saat pengguna menekan **Kirim kode ke email** di halaman Lupa Password, kode verifikasi 6-digit dikirimkan langsung ke inbox email pengguna yang terdaftar (tidak lagi ditampilkan di layar).
- Template email dapat disesuaikan di menu **Authentication** -> **Email Templates** -> **Reset Password**.

