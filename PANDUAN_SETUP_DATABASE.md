# Panduan Setup Database & Login Sosial TikTap (Supabase)

Aplikasi TikTap terhubung dengan backend **Supabase** (PostgreSQL Cloud, Google/Facebook OAuth, dan Pengiriman Email OTP Otomatis).

---

## 1. Atasi Error `localhost:3000` (URL Configuration) - PENTING
Secara *default*, Supabase mengarahkan (*redirect*) tautan konfirmasi email dan login ke `http://localhost:3000`. Karena di HP Android tidak ada web server localhost di port 3000, browser menampilkan pesan:
`Situs ini tidak dapat dijangkau - localhost menolak untuk terhubung (ERR_CONNECTION_REFUSED)`.

> [!NOTE]
> Walaupun browser menampilkan error tersebut, **akun email Anda sebenarnya SUDAH BERHASIL diverifikasi di Supabase!** Anda sudah bisa langsung membuka aplikasi TikTap dan login.

Agar tautan email dan login selanjutnya **langsung membuka aplikasi TikTap di HP**:
1. Buka dashboard [Supabase](https://supabase.com/dashboard) proyek Anda.
2. Masuk ke menu **Authentication** (sidebar kiri) -> **URL Configuration**.
3. Di kolom **Site URL**:
   - Ganti `http://localhost:3000` menjadi:
     `io.supabase.tiktap://login-callback`
4. Di bagian **Redirect URLs**:
   - Klik **Add URL**
   - Masukkan: `io.supabase.tiktap://**`
   - Klik **Save**.

---

## 2. Matikan "Confirm Email" (Sangat Praktis untuk Uji Coba)
Agar pengguna baru bisa **langsung daftar dan langsung login tanpa perlu buka Gmail**:
1. Buka dashboard Supabase.
2. Masuk ke menu **Authentication** -> **Providers** -> pilih **Email**.
3. Matikan toggle **"Confirm email"** (Toggle OFF).
4. Klik **Save** di bagian bawah.

> [!TIP]
> **Untuk Akun yang Sudah Terlanjur Dibuat (`rdhwnkhr@gmail.com`):**
> 1. Buka menu **Authentication** -> **Users**.
> 2. Klik tombol titik tiga (⋮) di sebelah email Anda -> pilih **"Confirm user"**.
> 3. Akun Anda langsung aktif dan bisa langsung login dengan password Anda di aplikasi!

---

## 3. Pasang Skema Database (Tabel Profil, Tiket & Pembayaran)
1. Di dashboard Supabase, buka menu **SQL Editor**.
2. Klik **New query**, lalu salin dan tempel seluruh isi file [`supabase_schema.sql`](supabase_schema.sql).
3. Klik tombol **Run**.
   - Tabel `public.profiles`, `public.tickets`, dan `public.payment_methods` akan otomatis dibuat/diperbarui lengkap dengan *Row Level Security (RLS)* dan trigger registrasi otomatis. Skrip ini aman dijalankan berulang kali.

---

## 4. Login Google & Facebook

### Cara Paling Cepat: Gunakan "Masuk Cepat (Simulasi)"
Aplikasi TikTap kini memiliki tombol **"Masuk Cepat"** di pop-up aplikasi saat tombol Google ditekan. Anda bisa langsung masuk tanpa perlu repot mengatur Google Cloud Console.

### Jika Ingin Mengaktifkan Google OAuth Resmi:
1. Buka dashboard Supabase -> **Authentication** -> **Providers** -> **Google**.
2. Nyalakan toggle **Enable Google provider**.
3. Salin URL **Callback URL (for OAuth)** (contoh: `https://zbypokzblfjbtfompese.supabase.co/auth/v1/callback`).
4. Buka [Google Cloud Console](https://console.cloud.google.com):
   - Buka menu **APIs & Services** -> **OAuth consent screen** -> Pilih **External** -> Isi nama aplikasi & email.
   - Buka menu **Credentials** -> **Create Credentials** -> **OAuth client ID**.
   - Pilih Application type: **Web application**.
   - Pada kolom **Authorized redirect URIs**, tempelkan Callback URL dari Supabase tadi.
   - Klik **Create**.
5. Salin **Client ID** dan **Client Secret** dari Google ke form Google Provider di Supabase, lalu klik **Save**.

---

## 5. Pengiriman Email Lupa Password (Otomatis)
- Supabase secara *built-in* sudah menyediakan pengiriman email otomatis.
- Saat pengguna menekan **Kirim kode ke email** di halaman Lupa Password, kode verifikasi 6-digit dikirimkan langsung ke inbox email pengguna yang terdaftar (tidak lagi ditampilkan di layar).
