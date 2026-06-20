# ZAMZAM LAUNDRY — Flutter + Firebase

Aplikasi manajemen laundry berbasis Flutter dan Firebase yang mendukung peran **Admin** dan **Pelanggan** (Customer). Aplikasi ini menyediakan fitur pelacakan order, pengelolaan layanan, laporan transaksi, dan komunikasi langsung (chat) antara admin dan pelanggan.

---

## 🚀 Fitur Utama & Pembaruan Terbaru

- **Autentikasi Pengguna:** Login terpisah untuk Admin dan Pelanggan, serta registrasi mandiri bagi pelanggan.
- **Toggle Visibilitas Password:** Tombol interaktif (icon mata) untuk menampilkan atau menyembunyikan input password secara dinamis saat mengetik di form Login dan Registrasi.
- **Validasi Keamanan Password:** Validasi wajib minimal 8 karakter dengan campuran huruf, angka, dan simbol khusus bagi pendaftar pelanggan baru demi menjaga keamanan akun.
- **Manajemen Layanan:** Pengelolaan daftar layanan laundry (tambah, edit, dan nonaktifkan layanan) oleh Admin.
- **Pemesanan Instan (Instant Dialog Dismissal):** Modal dialog pemesanan pada Admin ("Simpan") maupun Pelanggan ("Pesan Sekarang") akan tertutup secara instan seketika tombol ditekan. Proses pencatatan ke Firestore diproses asinkron di latar belakang untuk pengalaman pengguna yang lebih responsif.
- **Pelacakan Order (Tracking):** Pembuatan order oleh pelanggan, pembaruan status order secara real-time oleh admin (Pending -> Diterima -> Dicuci -> Disetrika -> Siap Diambil -> Selesai/Dibatalkan).
- **Penghapusan Order (Admin):** Admin dapat menghapus data orderan bermasalah secara permanen (ikon sampah merah) lewat tab Status. Proses penghapusan akan membersihkan seluruh dokumen histories dan data transaksi terkait secara otomatis di Firestore.
- **Laporan Transaksi & Pencarian (Admin):** Dashboard admin menyajikan data omzet lunas, jumlah order aktif/selesai, total **Piutang** (Belum Bayar), serta bilah pencarian (search bar) real-time untuk memfilter histori transaksi berdasarkan nama pelanggan.
- **Pencarian Data Pelanggan (Admin):** Fitur pencarian data pelanggan di halaman Pelanggan berdasarkan nama, email, atau nomor telepon.
- **Penyederhanaan Query (Tanpa Composite Index):** Query daftar order, data pelanggan, laporan keuangan, hingga real-time chat room disederhanakan tanpa filter ganda di Firestore. Semua penyaringan dan pengurutan diolah di memori lokal aplikasi (*in-memory sorting*), sehingga aplikasi **bebas dari ketergantungan pembuatan Composite Index** di Firebase Console.
- **Fitur Chat Real-time & Hapus Chat (Admin):** Sistem pesan instan langsung antara pelanggan dan admin laundry. Tab navigasi Chat akan otomatis memunculkan titik merah (badge) jika terdapat pesan belum dibaca. Admin dapat menghapus seluruh histori chat pelanggan secara permanen untuk merapikan antarmuka. Selain itu, room chat pelanggan yang aktif / menerima pesan baru akan otomatis berpindah ke urutan teratas (paling kiri).
- **Lokasi & Jarak Real-Time (Pelanggan):** Menampilkan lokasi Zam Zam Laundry, mengukur jarak dari posisi GPS pengguna secara dinamis, dan menyediakan pilihan navigasi langsung ke Google Maps (aplikasi/browser).
- **Normalisasi UID & Hashing**: Sinkronisasi ID pelanggan yang bertipe integer dan string UID (dari otentikasi Firebase lama) diselesaikan secara mulus menggunakan metode polynomial hashing deterministik, memastikan seluruh order dan riwayat chat terpeta ke pelanggan yang tepat.

---

## 📋 Persyaratan Sistem

Sebelum memulai, pastikan Anda telah memasang lingkungan berikut:
- **Flutter SDK:** `>=3.3.0 <4.0.0`
- **Dart SDK** yang kompatibel.
- Akun dan Project aktif di **Firebase Console**.

---

## 🛠️ Langkah Konfigurasi Firebase

### 1. Buat Project di Firebase Console
1. Buat project baru di [Firebase Console](https://console.firebase.google.com/).
2. Tambahkan aplikasi **Android** dan **Web** ke dalam project Firebase Anda.

---

### 2. Konfigurasi Platform Android
1. **Unduh `google-services.json`:**
   Unduh file konfigurasi dari Firebase Console dan letakkan di direktori proyek Anda pada:
   ```path
   android/app/google-services.json
   ```
2. **Pengaturan Gradle (Kotlin DSL):**
   *Proyek ini telah dikonfigurasi menggunakan Gradle Kotlin DSL (`.gradle.kts`) dan mendukung desugaring Java 8/11 untuk pustaka notifikasi lokal:*
   
   - **[settings.gradle.kts](file:///d:/Semester%206/zamzam_mobile-main/zamzam_mobile-main/android/settings.gradle.kts)**:
     ```kotlin
     plugins {
         // ... plugin lainnya
         id("com.google.gms.google-services") version "4.4.1" apply false
     }
     ```
   - **[android/app/build.gradle.kts](file:///d:/Semester%206/zamzam_mobile-main/zamzam_mobile-main/android/app/build.gradle.kts)**:
     ```kotlin
     plugins {
         // ... plugin lainnya
         id("com.google.gms.google-services")
     }
     ```

---

### 3. Konfigurasi Platform Web & Informasi Project
Jika Anda ingin menjalankan aplikasi di platform Web, buka file [lib/config/app_config.dart](file:///d:/Semester%206/zamzam_mobile-main/zamzam_mobile-main/lib/config/app_config.dart) dan perbarui konfigurasi `FirebaseOptions` Anda:
```dart
static FirebaseOptions get firebaseOptions {
  if (kIsWeb) {
    return const FirebaseOptions(
      apiKey: 'API_KEY_WEB_ANDA',
      authDomain: 'PROJECT_ID_ANDA.firebaseapp.com',
      projectId: 'PROJECT_ID_ANDA',
      storageBucket: 'PROJECT_ID_ANDA.firebasestorage.app',
      messagingSenderId: 'SENDER_ID_ANDA',
      appId: 'APP_ID_WEB_ANDA',
      measurementId: 'MEASUREMENT_ID_ANDA',
    );
  }
  // ... opsi Android
}
```

---

### 4. Konfigurasi Firebase Authentication
1. Di Firebase Console, navigasikan ke menu **Build > Authentication**.
2. Masuk ke tab **Sign-in method** dan aktifkan metode **Email/Password**.

---

### 5. Aturan Keamanan (Security Rules) Firestore
Firestore database baru secara default dibuat dalam mode terkunci. Agar aplikasi dapat membaca dan menulis data:
1. Masuk ke **Build > Firestore Database > Rules**.
2. Salin seluruh konten dari file [firestore.rules](file:///d:/Semester%206/zamzam_mobile-main/zamzam_mobile-main/firestore.rules) lokal Anda.
3. Tempel di editor rules Firebase Console dan klik **Publish**.

---

## 🔑 Pembuatan Akun Awal (Admin & Pelanggan)

- **Akun Pelanggan (Customer):**
  Pelanggan dapat melakukan pendaftaran langsung melalui fitur **Registrasi** di dalam aplikasi.
- **Akun Admin:**
  Akun Admin harus dibuat secara manual di Firebase Console:
  1. Masuk ke **Build > Authentication > Users**.
  2. Klik **Add User** dan masukkan email admin (contoh: `admin@zamzam.com`) serta password.
  3. Salin **UID** dari pengguna baru tersebut.
  4. Masuk ke **Firestore Database**, buat dokumen baru di koleksi `users` dengan ID dokumen yang sama dengan UID pengguna tersebut (atau gunakan ID integer acak, lalu pastikan field `uid` berisi UID dari Auth tadi).
  5. Tambahkan field-field berikut pada dokumen tersebut:
     - `id` (number): ID unik (misalnya: `1`)
     - `uid` (string): UID pengguna dari Authentication
     - `name` (string): `Admin ZAMZAM`
     - `email` (string): `admin@zamzam.com`
     - `phone` (string): `-`
     - `address` (string): `-`
     - `role` (string): `admin`
     - `is_active` (boolean): `true`

---

## 🏃 Menjalankan & Membangun Aplikasi

Pastikan dependencies terpasang terlebih dahulu:
```bash
flutter pub get
```

### Menjalankan di Android (Debug Mode)
```bash
flutter run
```

### Membangun APK Rilis (Release APK)
Sebelum membuild APK rilis, Anda dapat men-generate launcher icon (logo aplikasi) terbaru dengan perintah:
```bash
dart run flutter_launcher_icons
```

Kemudian lakukan kompilasi rilis dengan mematikan fitur *icon tree-shaking* agar ikon-ikon penting yang dipetakan lewat parameter dinamis (seperti menu navigasi bawah) tidak terhapus dan tampil sempurna:
```bash
flutter build apk --no-tree-shake-icons
```
Hasil file rilis APK dapat ditemukan di direktori `build/app/outputs/flutter-apk/app-release.apk`.

### Menjalankan di Web (Chrome)
```bash
flutter run -d chrome
```

---

## 🌐 Deploy Ke Firebase Hosting (Web)

Jika Anda ingin mempublikasikan versi web ke Firebase Hosting:
1. Pastikan Anda telah menginstal Firebase CLI dan login (`firebase login`).
2. Perbarui nama project Anda pada file [.firebaserc](file:///d:/Semester%206/zamzam_mobile-main/zamzam_mobile-main/.firebaserc).
3. Jalankan perintah pembuatan build & deploy:
   ```bash
   flutter build web
   firebase deploy --only hosting
   ```
