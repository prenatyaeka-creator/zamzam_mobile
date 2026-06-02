import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/app_models.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LoginResult {
  LoginResult({required this.token, required this.user});

  final String token;
  final AppUser user;
}

class ApiService {
  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final base = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
        : AppConfig.baseUrl;
    return Uri.parse('$base/$path').replace(queryParameters: queryParameters);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    String? token,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    late http.Response response;
    final uri = _uri(path, queryParameters);

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        break;
      default:
        throw ApiException('Metode HTTP tidak didukung.');
    }

    Map<String, dynamic> decoded = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        decoded = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      } catch (_) {
        throw ApiException('Respons server tidak dapat dibaca.');
      }
    }

    final success = decoded['success'] == true;
    if (!success || response.statusCode >= 400) {
      throw ApiException(decoded['message']?.toString() ?? 'Terjadi kesalahan pada server.');
    }

    return decoded['data'];
  }

  Future<LoginResult> login(String email, String password) async {
    final data = Map<String, dynamic>.from(await _request(
      'POST',
      'auth/login.php',
      body: {'email': email, 'password': password},
    ) as Map);

    return LoginResult(
      token: data['token']?.toString() ?? '',
      user: AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }

  Future<LoginResult> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    final data = Map<String, dynamic>.from(await _request(
      'POST',
      'auth/register.php',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'password': password,
      },
    ) as Map);

    return LoginResult(
      token: data['token']?.toString() ?? '',
      user: AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }

  Future<AppUser> me(String token) async {
    final data = Map<String, dynamic>.from(await _request('GET', 'auth/me.php', token: token) as Map);
    return AppUser.fromJson(data);
  }

  Future<List<LaundryService>> getServices({String? token}) async {
    final data = List<Map<String, dynamic>>.from(
      (await _request('GET', 'services/index.php', token: token) as List)
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
    return data.map(LaundryService.fromJson).toList();
  }

  Future<LaundryService> createService(String token, {
    required String name,
    required String description,
    required double price,
    required String unit,
    required int estimateDays,
    bool isActive = true,
  }) async {
    final data = Map<String, dynamic>.from(await _request(
      'POST',
      'services/create.php',
      token: token,
      body: {
        'service_name': name,
        'description': description,
        'price': price,
        'unit': unit,
        'estimate_days': estimateDays,
        'is_active': isActive,
      },
    ) as Map);
    return LaundryService.fromJson(data);
  }

  Future<LaundryService> updateService(String token, {
    required int id,
    required String name,
    required String description,
    required double price,
    required String unit,
    required int estimateDays,
    required bool isActive,
  }) async {
    final data = Map<String, dynamic>.from(await _request(
      'POST',
      'services/update.php',
      token: token,
      body: {
        'id': id,
        'service_name': name,
        'description': description,
        'price': price,
        'unit': unit,
        'estimate_days': estimateDays,
        'is_active': isActive,
      },
    ) as Map);
    return LaundryService.fromJson(data);
  }

  Future<void> deactivateService(String token, int id) async {
    await _request('POST', 'services/delete.php', token: token, body: {'id': id});
  }

  Future<List<LaundryOrder>> getOrders(String token, {int? customerId}) async {
    final query = <String, String>{};
    if (customerId != null && customerId > 0) {
      query['customer_id'] = '$customerId';
    }
    final data = List<Map<String, dynamic>>.from(
      (await _request('GET', 'orders/index.php', token: token, queryParameters: query.isEmpty ? null : query) as List)
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
    return data.map(LaundryOrder.fromJson).toList();
  }

  Future<OrderDetailPayload> getOrderDetail(String token, int id) async {
    final data = Map<String, dynamic>.from(await _request(
      'GET',
      'orders/detail.php',
      token: token,
      queryParameters: {'id': '$id'},
    ) as Map);

    final order = LaundryOrder.fromJson(Map<String, dynamic>.from(data['order'] as Map));
    final histories = List<Map<String, dynamic>>.from(
      ((data['histories'] as List?) ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map)),
    ).map(OrderStatusLog.fromJson).toList();

    final transactionData = data['transaction'];
    TransactionEntry? transaction;
    if (transactionData is Map) {
      transaction = TransactionEntry.fromJson(
        Map<String, dynamic>.from(transactionData),
        customerId: order.customerId,
      );
    }

    return OrderDetailPayload(order: order, histories: histories, transaction: transaction);
  }

  Future<LaundryOrder> updateOrderStatus(String token, {
    required int orderId,
    required OrderStatus status,
    String note = '',
  }) async {
    final data = Map<String, dynamic>.from(await _request(
      'POST',
      'orders/update_status.php',
      token: token,
      body: {
        'order_id': orderId,
        'status': orderStatusToApi(status),
        'note': note,
      },
    ) as Map);
    return LaundryOrder.fromJson(data);
  }

  Future<List<AppUser>> getCustomers(String token) async {
    final data = List<Map<String, dynamic>>.from(
      (await _request('GET', 'customers/index.php', token: token) as List)
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
    return data.map(AppUser.fromJson).toList();
  }

  Future<Map<String, dynamic>> getDashboard(String token) async {
    return Map<String, dynamic>.from(await _request('GET', 'dashboard/index.php', token: token) as Map);
  }

  Future<Map<String, dynamic>> getReport(String token, {String? startDate, String? endDate}) async {
    final query = <String, String>{};
    if (startDate != null) query['start_date'] = startDate;
    if (endDate != null) query['end_date'] = endDate;
    return Map<String, dynamic>.from(await _request(
      'GET',
      'reports/summary.php',
      token: token,
      queryParameters: query.isEmpty ? null : query,
    ) as Map);
  }

  Future<List<ChatRoom>> getChatRooms(String token) async {
    final data = List<Map<String, dynamic>>.from(
      (await _request('GET', 'chats/rooms.php', token: token) as List)
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
    return data.map(ChatRoom.fromJson).toList();
  }

  Future<List<ChatMessage>> getChatMessages(String token, int roomId) async {
    final data = List<Map<String, dynamic>>.from(
      (await _request(
        'GET',
        'chats/messages.php',
        token: token,
        queryParameters: {'room_id': '$roomId'},
      ) as List)
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
    return data.map(ChatMessage.fromJson).toList();
  }

  Future<ChatMessage> sendChatMessage(
    String token, {
    required int roomId,
    required String message,
    int? customerId,
  }) async {
    final body = <String, dynamic>{
      'room_id': roomId,
      'message': message,
    };
    if (customerId != null && customerId > 0) {
      body['customer_id'] = customerId;
    }
    final data = Map<String, dynamic>.from(await _request(
      'POST',
      'chats/send.php',
      token: token,
      body: body,
    ) as Map);
    return ChatMessage.fromJson(data);
  }
}
