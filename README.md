# TikTap (Flutter - Android, iOS, Web)

## Cara menjalankan
1. Pastikan Flutter SDK terpasang (`flutter --version`).
2. Di folder yang berisi proyek ini, buat platform folder (android/ios/web):
   `flutter create . --project-name tiktap --platforms=android,ios,web`
   (perintah ini tidak menimpa folder `lib/` dan `pubspec.yaml` yang sudah ada; kalau pubspec tertimpa, salin lagi dependensinya)
3. `flutter pub get`
4. Mobile: `flutter run`   |   Web: `flutter run -d chrome`

## Signature & Release Keystore (Konsistensi Download Versi)
Agar setiap kali APK dirilis/di-download dari GitHub (Release/Actions) atau web versinya konsisten dan pengguna bisa melakukan *update* tanpa error bentrok signature (*Signature Mismatch*):

1. **Keystore Rilis:**
   - Lokasi: `android/app/tiktap-release.jks`
   - Alias: `tiktap`
   - Password: `tiktapsecret` (dapat diubah via `android/key.properties` atau GitHub Secrets)
2. **Konfigurasi GitHub Secrets (Opsional / Rekomendasi CI/CD):**
   - `KEYSTORE_BASE64`: String base64 dari file `tiktap-release.jks`
   - `KEY_ALIAS`: `tiktap`
   - `KEY_PASSWORD`: `tiktapsecret`
   - `STORE_PASSWORD`: `tiktapsecret`
3. **Workflow GitHub Actions:**
   - Disediakan di `.github/workflows/release-apk.yml`.
   - Otomatis melakukan build & sign APK setiap push ke branch `main`/`master` atau pembuatan tag `v*` (misal `v1.0.1`).
   - File APK hasil build akan diunggah ke Artifacts dan otomatis dibuatkan GitHub Release.

## Poster film
Taruh gambar di `assets/posters/` lalu isi `posterAsset: 'assets/posters/nama.jpg'` pada data film di `lib/models.dart`.

## Alur
Splash -> Login/Register (atau tombol **Masuk Offline** tanpa akun) -> Home (Choose Movie) -> Order Confirmation -> Midtrans Snap Payment (QRIS / VA / E-Wallet) -> Mobile Ticket (Barcode) -> History -> Profile

## Payment Gateway: Midtrans Snap (Sandbox & Production)
TikTap menggunakan integrasi resmi **Midtrans Snap WebView** siap pakai (tanpa perlu membangun sistem perbankan/pembayaran dari nol):

1. **Metode Pembayaran yang Didukung Secara Otomatis:**
   - **QRIS:** GoPay, OVO, ShopeePay, DANA, BCA Mobile, Livin', LinkAja.
   - **Virtual Account (VA):** BCA, Mandiri, BRI, BNI, Permata, Danamon, CIMB.
   - **Kartu Kredit / Debit Online** & Minimarket (Alfamart / Indomaret).

2. **Pengaturan Kunci API (Sandbox Key):**
   - File konfigurasi: `lib/midtrans_config.dart`.
   - Atau bisa diatur langsung melalui aplikasi: **Profil** -> **Midtrans Snap Gateway** -> Masukkan Server Key & Client Key.
   - Dapatkan Server Key Sandbox gratis di [dashboard.midtrans.com](https://dashboard.midtrans.com) (Menu *Settings* -> *Access Keys* -> Mode Sandbox).

3. **Mode Sandbox Simulator:**
   - Jika Server Key belum dimasukkan, TikTap otomatis menjalankan **Sandbox Simulator Ready** sehingga alur checkout, QRIS, Virtual Account, hingga penerbitan tiket ber-barcode dapat diuji penuh tanpa kendala.
