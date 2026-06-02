import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  final ApiService _api = ApiService();

  AppUser? currentUser;
  String? _token;
  bool isBusy = false;
  String? lastError;

  int? _selectedAdminRoomId;

  final List<AppUser> _customers = <AppUser>[];
  final List<LaundryService> _services = <LaundryService>[];
  final List<LaundryOrder> _orders = <LaundryOrder>[];
  final Map<int, List<OrderStatusLog>> _statusLogs = <int, List<OrderStatusLog>>{};
  final List<TransactionEntry> _transactions = <TransactionEntry>[];
  final List<ChatRoom> _chatRooms = <ChatRoom>[];
  final Map<int, List<ChatMessage>> _messagesByRoom = <int, List<ChatMessage>>{};

  int _dashboardTotalCustomers = 0;
  int _dashboardTotalOrders = 0;
  int _dashboardActiveOrders = 0;
  double _dashboardTodayRevenue = 0;
  double _dashboardMonthlyRevenue = 0;

  List<AppUser> get customers => List<AppUser>.unmodifiable(_customers);
  List<LaundryService> get services => List<LaundryService>.unmodifiable(_services);
  List<TransactionEntry> get transactions => List<TransactionEntry>.unmodifiable(_transactions);
  List<ChatRoom> get sortedRooms {
    final items = [..._chatRooms];
    items.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return items;
  }

  int? get selectedAdminRoomId => _selectedAdminRoomId;

  AppUser get defaultAdmin => currentUser?.role == UserRole.admin
      ? currentUser!
      : AppUser(
          id: 1,
          name: 'Admin ZAMZAM',
          email: 'admin@zamzam.com',
          phone: '-',
          password: '',
          role: UserRole.admin,
          address: '',
        );

  List<LaundryService> get activeServices {
    final items = _services.where((service) => service.isActive).toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  List<LaundryOrder> get allOrdersSorted {
    final items = [..._orders];
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<LaundryOrder> get currentCustomerOrders {
    final user = currentUser;
    if (user == null) return <LaundryOrder>[];
    return allOrdersSorted.where((order) => order.customerId == user.id).toList();
  }

  int get activeOrdersCount {
    if (currentUser?.role == UserRole.admin && _dashboardActiveOrders > 0) {
      return _dashboardActiveOrders;
    }
    return _orders.where((order) => order.status != OrderStatus.completed && order.status != OrderStatus.cancelled).length;
  }

  int get completedOrdersCount => _orders.where((order) => order.status == OrderStatus.completed).length;

  double get totalRevenue {
    if (_transactions.isEmpty && _dashboardMonthlyRevenue > 0) {
      return _dashboardMonthlyRevenue;
    }
    return _transactions
        .where((entry) => entry.status == PaymentStatus.paid)
        .fold<double>(0, (sum, item) => sum + item.amount);
  }

  double get unpaidRevenue {
    return _transactions
        .where((entry) => entry.status == PaymentStatus.unpaid)
        .fold<double>(0, (sum, item) => sum + item.amount);
  }

  Future<bool> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await _guard(() async {
      final result = await _api.login(email.trim(), password);
      if (result.user.role != role) {
        throw ApiException('Role akun tidak sesuai dengan pilihan login.');
      }
      currentUser = result.user;
      _token = result.token;
      await _loadInitialData();
    });

    return currentUser != null && currentUser!.role == role;
  }

  Future<String?> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    String? error;
    await _guard(() async {
      final result = await _api.registerCustomer(
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        address: address.trim(),
        password: password,
      );
      currentUser = result.user;
      _token = result.token;
      await _loadInitialData();
    }, onError: (message) => error = message);
    return error;
  }

  Future<void> logout() async {
    currentUser = null;
    _token = null;
    lastError = null;
    _selectedAdminRoomId = null;
    _customers.clear();
    _services.clear();
    _orders.clear();
    _statusLogs.clear();
    _transactions.clear();
    _chatRooms.clear();
    _messagesByRoom.clear();
    _dashboardTotalCustomers = 0;
    _dashboardTotalOrders = 0;
    _dashboardActiveOrders = 0;
    _dashboardTodayRevenue = 0;
    _dashboardMonthlyRevenue = 0;
    notifyListeners();
  }

  Future<void> _loadInitialData() async {
    if (_token == null || currentUser == null) {
      return;
    }

    await refreshServices();
    await refreshOrders();
    await refreshChatRooms();

    if (currentUser!.role == UserRole.admin) {
      await refreshCustomers();
      await refreshDashboard();
      await refreshReports();
    }
  }

  Future<void> refreshServices() async {
    if (currentUser == null) return;
    final items = await _api.getServices(token: _token);
    _services
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    if (_token == null) return;
    final items = await _api.getOrders(_token!);
    _orders
      ..clear()
      ..addAll(items);
    _statusLogs.clear();
    _transactions.clear();

    for (final order in items) {
      final detail = await _api.getOrderDetail(_token!, order.id);
      _statusLogs[order.id] = detail.histories;
      if (detail.transaction != null) {
        _transactions.add(detail.transaction!);
      }
    }
    notifyListeners();
  }

  Future<void> refreshCustomers() async {
    if (_token == null || currentUser?.role != UserRole.admin) return;
    final items = await _api.getCustomers(_token!);
    _customers
      ..clear()
      ..addAll(items.where((item) => item.role == UserRole.customer));
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    if (_token == null || currentUser?.role != UserRole.admin) return;
    final data = await _api.getDashboard(_token!);
    _dashboardTotalCustomers = _asInt(data['total_customers']);
    _dashboardTotalOrders = _asInt(data['total_orders']);
    _dashboardActiveOrders = _asInt(data['active_orders']);
    _dashboardTodayRevenue = _asDouble(data['today_revenue']);
    _dashboardMonthlyRevenue = _asDouble(data['monthly_revenue']);
    notifyListeners();
  }

  Future<void> refreshReports() async {
    if (_token == null || currentUser?.role != UserRole.admin) return;
    final data = await _api.getReport(_token!);
    final list = ((data['transactions'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((json) {
          final orderId = _asInt(json['order_id']);
          final matchedOrders = _orders.where((order) => order.id == orderId).toList();
          final customerId = matchedOrders.isNotEmpty ? matchedOrders.first.customerId : 0;
          return TransactionEntry.fromJson(json, customerId: customerId);
        })
        .toList();
    _transactions
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  Future<void> refreshChatRooms() async {
    if (_token == null) return;
    final rooms = await _api.getChatRooms(_token!);
    _chatRooms
      ..clear()
      ..addAll(rooms);

    if (currentUser?.role == UserRole.admin) {
      _selectedAdminRoomId = rooms.isNotEmpty ? (_selectedAdminRoomId ?? rooms.first.id) : null;
    }

    _messagesByRoom.clear();
    for (final room in rooms) {
      final messages = await _api.getChatMessages(_token!, room.id);
      _messagesByRoom[room.id] = messages;
    }

    notifyListeners();
  }

  Future<void> addService({
    required String name,
    required String description,
    required double price,
    required String unit,
    required int estimateDays,
  }) async {
    if (_token == null) return;
    await _guard(() async {
      await _api.createService(
        _token!,
        name: name,
        description: description,
        price: price,
        unit: unit,
        estimateDays: estimateDays,
      );
      await refreshServices();
    });
  }

  Future<void> updateService({
    required int id,
    required String name,
    required String description,
    required double price,
    required String unit,
    required int estimateDays,
  }) async {
    if (_token == null) return;
    final existing = _services.firstWhere((item) => item.id == id);
    await _guard(() async {
      await _api.updateService(
        _token!,
        id: id,
        name: name,
        description: description,
        price: price,
        unit: unit,
        estimateDays: estimateDays,
        isActive: existing.isActive,
      );
      await refreshServices();
    });
  }

  Future<void> toggleServiceActive(int id) async {
    if (_token == null) return;
    final service = _services.firstWhere((item) => item.id == id);
    await _guard(() async {
      if (service.isActive) {
        await _api.deactivateService(_token!, id);
      } else {
        await _api.updateService(
          _token!,
          id: id,
          name: service.name,
          description: service.description,
          price: service.price,
          unit: service.unit,
          estimateDays: service.estimateDays,
          isActive: true,
        );
      }
      await refreshServices();
    });
  }

  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    if (_token == null) return;
    await _guard(() async {
      await _api.updateOrderStatus(
        _token!,
        orderId: orderId,
        status: status,
        note: 'Status diperbarui dari aplikasi admin.',
      );
      await refreshOrders();
      if (currentUser?.role == UserRole.admin) {
        await refreshDashboard();
        await refreshReports();
      }
    });
  }

  Future<void> sendMessage({required int roomId, required String text}) async {
    if (_token == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await _guard(() async {
      int? customerId;
      if (currentUser?.role == UserRole.admin && roomId > 0) {
        final room = _chatRooms.firstWhere((item) => item.id == roomId);
        customerId = room.customerId;
      }
      final sent = await _api.sendChatMessage(
        _token!,
        roomId: roomId,
        message: trimmed,
        customerId: customerId,
      );
      final targetRoomId = sent.roomId;
      final bucket = _messagesByRoom.putIfAbsent(targetRoomId, () => <ChatMessage>[]);
      bucket.add(sent);
      await refreshChatRooms();
      if (currentUser?.role == UserRole.admin) {
        _selectedAdminRoomId = targetRoomId;
      }
    });
  }

  void selectAdminRoom(int roomId) {
    _selectedAdminRoomId = roomId;
    notifyListeners();
  }

  ChatRoom ensureRoomForCustomer(int customerId) {
    if (_chatRooms.isNotEmpty) {
      return _chatRooms.first;
    }
    return ChatRoom(
      id: 0,
      customerId: customerId,
      adminId: 1,
      title: 'Admin ZAMZAM',
      lastMessage: 'Mulai chat dengan admin.',
      lastMessageAt: DateTime.now(),
    );
  }

  List<ChatMessage> messagesForRoom(int roomId) {
    final items = [...(_messagesByRoom[roomId] ?? <ChatMessage>[])];
    items.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return items;
  }

  List<OrderStatusLog> logsForOrder(int orderId) {
    final items = [...(_statusLogs[orderId] ?? <OrderStatusLog>[])];
    if (items.isEmpty) {
      final matches = _orders.where((order) => order.id == orderId).toList();
      if (matches.isNotEmpty) {
        items.add(
          OrderStatusLog(
            id: 0,
            orderId: orderId,
            status: matches.first.status,
            note: 'Status terbaru order.',
            changedBy: 'System',
            changedAt: matches.first.createdAt,
          ),
        );
      }
    }
    items.sort((a, b) => a.changedAt.compareTo(b.changedAt));
    return items;
  }

  LaundryService getService(int id) {
    return _services.firstWhere(
      (service) => service.id == id,
      orElse: () => LaundryService(
        id: id,
        name: 'Layanan',
        description: '',
        price: 0,
        unit: 'kg',
        estimateDays: 1,
      ),
    );
  }

  AppUser getUser(int id) {
    if (currentUser?.id == id) {
      return currentUser!;
    }
    return _customers.firstWhere(
      (user) => user.id == id,
      orElse: () => AppUser(
        id: id,
        name: 'Pelanggan',
        email: '-',
        phone: '-',
        password: '',
        role: UserRole.customer,
        address: '',
      ),
    );
  }

  int ordersCountByCustomer(int customerId) {
    return _orders.where((order) => order.customerId == customerId).length;
  }

  double spendingByCustomer(int customerId) {
    return _transactions
        .where((transaction) => transaction.customerId == customerId && transaction.status == PaymentStatus.paid)
        .fold<double>(0, (sum, item) => sum + item.amount);
  }

  String currency(num value) => formatCurrency(value);
  String dateTime(DateTime value) => formatDateTime(value);
  String shortDate(DateTime value) => formatShortDate(value);
  String shortTime(DateTime value) => formatShortTime(value);

  Future<void> _guard(Future<void> Function() action, {void Function(String message)? onError}) async {
    try {
      isBusy = true;
      lastError = null;
      notifyListeners();
      await action();
    } on ApiException catch (e) {
      lastError = e.message;
      onError?.call(e.message);
    } catch (_) {
      lastError = 'Terjadi kesalahan tak terduga.';
      onError?.call(lastError!);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
