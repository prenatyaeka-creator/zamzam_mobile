import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_model.dart';
import '../models/order_model.dart';

class ApiService {
  // IP MacBook Profesor (Pastikan tetap di 192.168.1.3)
  static const String baseUrl = "http://10.0.2.2/zamzam_api/api";

  // Fungsi mengambil daftar Layanan Laundry
  Future<List<ServiceModel>> fetchServices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/services.php'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List data = responseData['data'];
        return data.map((item) => ServiceModel.fromJson(item)).toList();
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal ambil data layanan: $e');
    }
  }

  // Fungsi mengambil daftar Pesanan/Order
  Future<List<OrderModel>> fetchOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_orders.php'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List data = responseData['data'];
        return data.map((item) => OrderModel.fromJson(item)).toList();
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal ambil data pesanan: $e');
    }
  }
}