# Mobile App Flutter - ZAMZAM LAUNDRY

Aplikasi ini adalah source code Flutter/Dart untuk ZAMZAM LAUNDRY.

## Fitur utama
- Login admin dan pelanggan
- Registrasi pelanggan
- List layanan dan harga
- Tracking laundry dan histori status
- Chat admin-pelanggan
- Dashboard admin
- Manajemen layanan
- Data pelanggan
- Laporan transaksi

## Cara memakai SDK lokal di dalam project
SDK lokal akan ditempatkan pada folder:
- `../.flutter_sdk/flutter`

### Windows
```powershell
.\tool\setup_flutter_sdk_windows.ps1
.\tool\bootstrap_project.ps1
.\tool\flutterw.ps1 pub get
.\tool\flutterw.ps1 run
```

### Linux
```bash
chmod +x ./tool/*.sh ./tool/flutterw
./tool/setup_flutter_sdk_linux.sh
./tool/bootstrap_project.sh
./tool/flutterw pub get
./tool/flutterw run
```

### macOS
```bash
chmod +x ./tool/*.sh ./tool/flutterw
./tool/setup_flutter_sdk_macos.sh
./tool/bootstrap_project.sh
./tool/flutterw pub get
./tool/flutterw run
```

## Catatan
- Script setup SDK akan mengunduh Flutter SDK resmi ke folder project.
- Script bootstrap akan menjalankan `flutter create . --platforms=android,ios,web` untuk membuat wrapper platform yang belum ada.
- Setelah itu Anda bisa menjalankan project dengan wrapper `flutterw`.

## Konfigurasi API
Edit `lib/config/app_config.dart` dan sesuaikan `baseUrl`.
