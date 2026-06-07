# ZAMZAM LAUNDRY — Flutter + Firebase

Aplikasi manajemen laundry berbasis Flutter dan Firebase yang mendukung peran **Admin** dan **Pelanggan** (Customer). Aplikasi ini menyediakan fitur pelacakan order, pengelolaan layanan, laporan transaksi, dan komunikasi langsung (chat) antara admin dan pelanggan.

---

## 🚀 Fitur Utama

- **Autentikasi Pengguna:** Login terpisah untuk Admin dan Pelanggan, serta registrasi mandiri bagi pelanggan.
- **Manajemen Layanan:** Pengelolaan daftar layanan laundry (tambah, edit, dan nonaktifkan layanan) oleh Admin.
- **Pelacakan Order (Tracking):** Pembuatan order oleh pelanggan, pembaruan status order secara real-time oleh admin (Pending -> Picked Up -> Washing -> Ironing -> Ready -> Completed/Cancelled).
- **Riwayat Status & Transaksi:** Pencatatan log perubahan status order dan integrasi status pembayaran transaksi.
- **Dashboard Admin:** Statistik pelanggan aktif, total order, pesanan aktif, serta grafik/log pendapatan bulanan & harian.
- **Fitur Chat Real-time:** Sistem pesan instan langsung antara pelanggan dan admin laundry.

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
   *Proyek ini telah dikonfigurasi menggunakan Gradle Kotlin DSL (`.gradle.kts`). Berikut adalah konfigurasi penting yang telah diterapkan:*
   
   - **[settings.gradle.kts](file:///c:/Users/LENOVO/Downloads/zamzam_mobile-main/zamzam_mobile-main/android/settings.gradle.kts)**:
     ```kotlin
     plugins {
         // ... plugin lainnya
         id("com.google.gms.google-services") version "4.4.1" apply false
     }
     ```
   - **[android/app/build.gradle.kts](file:///c:/Users/LENOVO/Downloads/zamzam_mobile-main/zamzam_mobile-main/android/app/build.gradle.kts)**:
     ```kotlin
     plugins {
         // ... plugin lainnya
         id("com.google.gms.google-services")
     }
     ```

---

### 3. Konfigurasi Platform Web & Informasi Project
Jika Anda ingin menjalankan aplikasi di platform Web, buka file [lib/config/app_config.dart](file:///c:/Users/LENOVO/Downloads/zamzam_mobile-main/zamzam_mobile-main/lib/config/app_config.dart) dan perbarui konfigurasi `FirebaseOptions` Anda:
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
2. Salin seluruh konten dari file [firestore.rules](file:///c:/Users/LENOVO/Downloads/zamzam_mobile-main/zamzam_mobile-main/firestore.rules) lokal Anda.
3. Tempel di editor rules Firebase Console dan klik **Publish**.

---

### 6. Pembuatan Indeks Komposit (Composite Indexes) Firestore
Beberapa fitur query dalam aplikasi ini menyaring lebih dari satu kolom sekaligus mengurutkannya. Anda wajib membuat indeks berikut di **Firestore > Indexes > Composite** agar query tidak gagal:

1. **Indeks untuk Daftar Pelanggan Aktif:**
   - Koleksi: `users`
   - Field: `role` (Ascending) ➔ `is_active` (Ascending) ➔ `name` (Ascending)
2. **Indeks untuk Daftar Order Pelanggan:**
   - Koleksi: `orders`
   - Field: `customer_id` (Ascending) ➔ `created_at` (Descending)

> **Tips:** Ketika pertama kali menjalankan fitur yang memicu pencarian di atas, Anda akan melihat pesan error di debug console terminal. Pesan tersebut menyertakan tautan URL unik. Klik tautan tersebut untuk membuat indeks secara otomatis di Firebase Console Anda.

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

## 🏃 Menjalankan Aplikasi

Pastikan dependencies terpasang terlebih dahulu:
```bash
flutter pub get
```

### Menjalankan di Android
```bash
flutter run
```

### Menjalankan di Web (Chrome)
```bash
flutter run -d chrome
```

---

## 🌐 Deploy Ke Firebase Hosting (Web)

Jika Anda ingin mempublikasikan versi web ke Firebase Hosting:
1. Pastikan Anda telah menginstal Firebase CLI dan login (`firebase login`).
2. Perbarui nama project Anda pada file [.firebaserc](file:///c:/Users/LENOVO/Downloads/zamzam_mobile-main/zamzam_mobile-main/.firebaserc).
3. Jalankan perintah pembuatan build & deploy:
   ```bash
   flutter build web
   firebase deploy --only hosting
   ```
