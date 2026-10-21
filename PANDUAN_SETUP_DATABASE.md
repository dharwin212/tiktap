# Panduan Setup Database & Login Sosial TikTap (Supabase)

Aplikasi TikTap terhubung dengan backend **Supabase** (PostgreSQL Cloud, Google/Facebook OAuth, dan Pengiriman Email OTP Otomatis).

---

## 1. Matikan "Confirm Email" (SANGAT PENTING - 1 Menit)
Secara bawaan (*default*), Supabase mewajibkan pengguna untuk membuka Gmail dan mengklik link konfirmasi sebelum bisa login. Jika ini aktif, login akan menampilkan pesan `Email not confirmed`.

Agar pengguna bisa **langsung daftar dan langsung login kapan saja**:
1. Buka dashboard [Supabase](https://supabase.com/dashboard) proyek Anda.
2. Buka menu **Authentication** (ikon gembok/orang di sidebar kiri).
3. Klik **Providers** -> pilih **Email**.
4. Cari opsi **Confirm email**, lalu **MATIKAN (Toggle OFF)**.
5. Klik **Save** di bagian bawah.

> [!TIP]
> **Untuk Akun yang Sudah Terlanjur Terdaftar (seperti `rdhwnkhr@gmail.com`):**
> 1. Buka menu **Authentication** -> **Users**.
> 2. Klik baris akun Anda atau tombol titik tiga (⋮) di sebelah kanan email Anda.
> 3. Klik **"Confirm email"** atau **"Send magic link"**. Akun Anda akan langsung berstatus *Confirmed* dan bisa langsung login!

---

## 2. Pasang Skema Database (Tabel Profil, Tiket & Pembayaran)
1. Di dashboard Supabase, buka menu **SQL Editor**.
2. Klik **New query**, lalu salin dan tempel seluruh isi file [`supabase_schema.sql`](supabase_schema.sql).
3. Klik tombol **Run**.
   - Tabel `public.profiles`, `public.tickets`, dan `public.payment_methods` akan otomatis dibuat/diperbarui lengkap dengan *Row Level Security (RLS)* dan trigger registrasi otomatis. Skrip ini aman dijalankan berulang kali.

---

## 3. Aktifkan Login Google & Facebook

### Mengapa muncul `Unsupported provider: provider is not enabled`?
Pesan tersebut muncul karena provider Google belum diaktifkan di dashboard Supabase Anda. Aplikasi TikTap kini sudah dilengkapi **Masuk Cepat (Simulasi)** jika provider belum diaktifkan.

Bila ingin menggunakan Google OAuth resmi:
1. Buka dashboard Supabase -> **Authentication** -> **Providers** -> **Google**.
2. Nyalakan toggle **Enable Google provider**.
3. Salin URL **Callback URL (for OAuth)** yang tertera di sana (contoh: `https://zbypokzblfjbtfompese.supabase.co/auth/v1/callback`).
4. Buka [Google Cloud Console](https://console.cloud.google.com):
   - Buat proyek baru atau pilih proyek yang ada.
   - Buka menu **APIs & Services** -> **OAuth consent screen** -> Pilih **External** -> Isi nama aplikasi & email.
   - Buka menu **Credentials** -> **Create Credentials** -> **OAuth client ID**.
   - Pilih Application type: **Web application**.
   - Pada kolom **Authorized redirect URIs**, tempelkan Callback URL dari Supabase tadi.
   - Klik **Create**.
5. Salin **Client ID** dan **Client Secret** yang diberikan Google, lalu tempelkan ke form Google Provider di Supabase.
6. Klik **Save** di Supabase.

---

## 4. Pengiriman Email Lupa Password (Otomatis)
- Supabase secara *built-in* sudah menyediakan pengiriman email otomatis.
- Saat pengguna menekan **Kirim kode ke email** di halaman Lupa Password, kode verifikasi 6-digit dikirimkan langsung ke inbox email pengguna yang terdaftar (tidak lagi ditampilkan di layar).
- Template email dapat disesuaikan di menu **Authentication** -> **Email Templates** -> **Reset Password**.
