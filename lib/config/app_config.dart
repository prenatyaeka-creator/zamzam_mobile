class AppConfig {
  const AppConfig._();

  // Backend PHP dijalankan dari folder backend_api pada port 8000.
  // Android Emulator menggunakan 10.0.2.2 untuk mengakses localhost MacBook.
  static const String baseUrl = 'http://10.0.2.2:8000';
}
