# ZAMZAM LAUNDRY - Flutter + Firebase

Aplikasi laundry sederhana berbasis Flutter dan Firebase.

Fitur utama:
- Login admin dan pelanggan
- Registrasi pelanggan
- Manajemen layanan laundry
- Tracking order dan status layanan
- Dashboard admin
- Chat antara pelanggan dan admin

## Persiapan
1. Pastikan Flutter sudah terpasang.
2. Jalankan:
   ```bash
   flutter pub get
   ```
3. Siapkan Firebase project untuk Android dan Web.

## Konfigurasi Firebase
1. Tambahkan aplikasi Android dan Web di Firebase Console.
2. Untuk Android, letakkan `google-services.json` di `android/app/`.
3. Untuk web, isi `lib/config/app_config.dart` dengan `FirebaseOptions` dan pastikan `authDomain` benar.
4. Pastikan Email/Password Authentication sudah diaktifkan di Firebase Auth.

## Akun Admin dan Pelanggan
- Customer harus register lewat aplikasi.
- Admin harus dibuat manual di Firebase Console.
  - Contoh email admin: `admin@zamzam.com`
  - Password admin harus diatur sendiri di Firebase Console.
- Setelah registrasi berhasil, pelanggan akan kembali ke login dan masuk menggunakan akun yang baru dibuat.

## Menjalankan Aplikasi
### Android
```bash
flutter pub get
flutter run
```

### Web
```bash
flutter pub get
flutter run -d chrome
```

## Firebase Hosting (Opsional)
Jika ingin deploy web:
```bash
flutter build web
firebase deploy --only hosting
```
Pastikan `.firebaserc` sudah berisi project Firebase yang benar.

## File Penting
- `lib/main.dart` — entry point aplikasi
- `lib/config/app_config.dart` — konfigurasi Firebase untuk web/mobile
- `lib/services/api_service.dart` — layanan Firebase Auth dan Firestore
- `android/app/src/main/AndroidManifest.xml` — izin internet Android

## Catatan Singkat
- Proyek ini tidak menyediakan data demo otomatis.
- Semua data pengguna, layanan, dan order dibuat lewat aplikasi atau Firebase Console.
- Pastikan aturan keamanan Firestore sesuai sebelum deploy.

