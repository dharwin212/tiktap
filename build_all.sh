#!/usr/bin/env bash
# Build APK + web dengan tombol download APK. Jalankan dari folder proyek.
set -e
flutter pub get
flutter build apk --release
mkdir -p web/downloads
cp build/app/outputs/flutter-apk/app-release.apk web/downloads/tiktap.apk
flutter build web --release
echo "Selesai. Upload isi build/web ke hosting (APK ada di build/web/downloads/tiktap.apk)"
