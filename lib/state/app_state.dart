import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/formatters.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  AppState() {
    tryAutoLogin();
  }

  final ApiService _api = ApiService();

  AppUser? currentUser;
  String? _token;
  bool isBusy = false;
  String? lastError;

  bool isAutoLoginCheckRunning = true;
  bool rememberMe = false;
  String? savedEmail;
  UserRole? savedRole;

  StreamSubscription<List<ChatRoom>>? _roomsSubscription;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  int? _subscribedRoomId;
  DateTime? _chatStreamInitTime;
  final Set<int> _notifiedMessageIds = <int>{};
  final Map<int, DateTime> _lastSeenMessageTimes = <int, DateTime>{};
  bool _hasUnreadMessages = false;
  bool _isChatActive = false;

  bool get hasUnreadMessages => _hasUnreadMessages;
  bool get isChatActive => _isChatActive;
  set isChatActive(bool value) {
    if (_isChatActive != value) {
      _isChatActive = value;
      if (value) {
        _hasUnreadMessages = false;
      }
      notifyListeners();
    }
  }

  int? _selectedAdminRoomId;

  final List<AppUser> _customers = <AppUser>[];
  final List<LaundryService> _services = <LaundryService>[];
  final List<LaundryOrder> _orders = <LaundryOrder>[];
  final Map<int, List<OrderStatusLog>> _statusLogs =
      <int, List<OrderStatusLog>>{};
  final List<TransactionEntry> _transactions = <TransactionEntry>[];
  final List<ChatRoom> _chatRooms = <ChatRoom>[];
  final Map<int, List<ChatMessage>> _messagesByRoom =
      <int, List<ChatMessage>>{};

  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      rememberMe = prefs.getBool('remember_me') ?? false;
      savedEmail = prefs.getString('saved_email');
      final savedRoleStr = prefs.getString('saved_role');
      if (savedRoleStr != null) {
        savedRole = savedRoleStr == 'admin' ? UserRole.admin : UserRole.customer;
      }

      if (rememberMe) {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          // pre-initialize so me() doesn't throw if firestore is not ready
          final user = await _api.me(firebaseUser.uid);
          if (user.isActive && (savedRole == null || user.role == savedRole)) {
            currentUser = user;
            _token = firebaseUser.uid;
            unawaited(NotificationService.instance.requestPermission());
            unawaited(_loadInitialData());
          } else {
            await _api.signOut();
          }
        }
      } else {
        if (FirebaseAuth.instance.currentUser != null) {
          await _api.signOut();
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('[AppState] Auto-login error: $e');
    } finally {
      isAutoLoginCheckRunning = false;
      notifyListeners();
    }
  }

  int _dashboardActiveOrders = 0;
  double _dashboardMonthlyRevenue = 0;

  List<AppUser> get customers => List<AppUser>.unmodifiable(_customers);
  List<LaundryService> get services =>
      List<LaundryService>.unmodifiable(_services);
  List<TransactionEntry> get transactions =>
      List<TransactionEntry>.unmodifiable(_transactions);
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
    return allOrdersSorted
        .where((order) => order.customerId == user.id)
        .toList();
  }

  int get activeOrdersCount {
    if (currentUser?.role == UserRole.admin && _dashboardActiveOrders > 0) {
      return _dashboardActiveOrders;
    }
    return _orders
        .where((order) =>
            order.status != OrderStatus.completed &&
            order.status != OrderStatus.cancelled)
        .length;
  }

  int get completedOrdersCount =>
      _orders.where((order) => order.status == OrderStatus.completed).length;

  double get totalRevenue {
    if (_transactions.isEmpty && _dashboardMonthlyRevenue > 0) {
      return _dashboardMonthlyRevenue;
    }
    return _transactions
        .where((entry) => entry.status == PaymentStatus.paid)
        .fold<double>(0, (sum, item) => sum + item.amount);
  }

  double get unpaidRevenue {
    return _orders
        .where((order) => order.paymentStatus == PaymentStatus.unpaid && order.status != OrderStatus.cancelled)
        .fold<double>(0, (sum, item) => sum + item.totalPrice);
  }

  Future<bool> login({
    required String email,
    required String password,
    required UserRole role,
    bool remember = false,
  }) async {
    await _guard(() async {
      // Log login attempt for debugging
      // ignore: avoid_print
      print('[AppState] Attempting login email=${email.trim()} role=$role');
      final result = await _api.login(
        email.trim(),
        password,
        expectedRole: role,
      );
      // ignore: avoid_print
      print(
          '[AppState] Login result user=${result.user.email} role=${result.user.role}');
      if (result.user.role != role) {
        throw ApiException('Role akun tidak sesuai dengan pilihan login.');
      }
      currentUser = result.user;
      _token = result.token;
      rememberMe = remember;
      unawaited(NotificationService.instance.requestPermission());

      final prefs = await SharedPreferences.getInstance();
      if (remember) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_email', email.trim());
        await prefs.setString('saved_role', role == UserRole.admin ? 'admin' : 'customer');
        savedEmail = email.trim();
        savedRole = role;
      } else {
        await prefs.setBool('remember_me', false);
        await prefs.remove('saved_email');
        await prefs.remove('saved_role');
        savedEmail = null;
        savedRole = null;
      }

      notifyListeners();
      // ignore: avoid_print
      print(
          '[AppState] Login success, navigating to home. Loading data in background.');
      unawaited(_loadInitialData());
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
      await _api.registerCustomer(
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        address: address.trim(),
        password: password,
      );
      await _api.signOut();
      currentUser = null;
      _token = null;
      notifyListeners();
    }, onError: (message) => error = message);
    return error;
  }

  Future<void> logout() async {
    _cancelChatSubscriptions();
    await _api.signOut();
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
    _dashboardActiveOrders = 0;
    _dashboardMonthlyRevenue = 0;
    _hasUnreadMessages = false;
    _isChatActive = false;
    _lastSeenMessageTimes.clear();

    rememberMe = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', false);

    notifyListeners();
  }

  Future<void> _loadInitialData() async {
    if (_token == null || currentUser == null) {
      return;
    }

    await refreshServices();
    await refreshOrders();
    _setupChatListeners();

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
    _dashboardActiveOrders = _asInt(data['active_orders']);
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
      final matchedOrders =
          _orders.where((order) => order.id == orderId).toList();
      final customerId =
          matchedOrders.isNotEmpty ? matchedOrders.first.customerId : 0;
      return TransactionEntry.fromJson(json, customerId: customerId);
    }).toList();
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
      _selectedAdminRoomId =
          rooms.isNotEmpty ? (_selectedAdminRoomId ?? rooms.first.id) : null;
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

      if (currentUser?.role == UserRole.customer) {
        final hasRoom = _chatRooms.any((r) => r.customerId == currentUser!.id);
        if (!hasRoom) {
          final newRoom = ChatRoom(
            id: targetRoomId,
            customerId: currentUser!.id,
            adminId: 1,
            title: 'Admin ZAMZAM',
            lastMessage: trimmed,
            lastMessageAt: DateTime.now(),
          );
          _chatRooms.add(newRoom);
          _updateMessageSubscription(targetRoomId);
        }
      }

      if (currentUser?.role == UserRole.admin) {
        _selectedAdminRoomId = targetRoomId;
      }
    });
  }

  void selectAdminRoom(int roomId) {
    _selectedAdminRoomId = roomId;
    _updateMessageSubscription(roomId);
    notifyListeners();
  }

  void _cancelChatSubscriptions() {
    _roomsSubscription?.cancel();
    _roomsSubscription = null;
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _subscribedRoomId = null;
  }

  void _setupChatListeners() {
    _cancelChatSubscriptions();
    if (_token == null) return;
    _chatStreamInitTime = DateTime.now();
    _lastSeenMessageTimes.clear();

    _roomsSubscription = _api.getChatRoomsStream(_token!).listen((rooms) {
      if (rooms.isNotEmpty) {
        bool hasNewExternalMessage = false;
        for (final room in rooms) {
          final lastSeen = _lastSeenMessageTimes[room.id];
          if (lastSeen == null) {
            _lastSeenMessageTimes[room.id] = room.lastMessageAt;
          } else if (room.lastMessageAt.isAfter(lastSeen)) {
            _lastSeenMessageTimes[room.id] = room.lastMessageAt;

            if (room.lastMessage != 'Mulai chat dengan admin.') {
              if (currentUser?.role == UserRole.customer) {
                if (!_isChatActive) {
                  hasNewExternalMessage = true;
                }
              } else if (currentUser?.role == UserRole.admin) {
                if (!_isChatActive || _selectedAdminRoomId != room.id) {
                  hasNewExternalMessage = true;
                }
              }
            }
          }
        }
        if (hasNewExternalMessage) {
          _hasUnreadMessages = true;
        }
      }

      _chatRooms
        ..clear()
        ..addAll(rooms);

      if (currentUser?.role == UserRole.admin) {
        if (_selectedAdminRoomId != null && !rooms.any((r) => r.id == _selectedAdminRoomId)) {
          _selectedAdminRoomId = rooms.isNotEmpty ? rooms.first.id : null;
        }
        if (_selectedAdminRoomId == null && rooms.isNotEmpty) {
          _selectedAdminRoomId = rooms.first.id;
        }
        if (_selectedAdminRoomId != null) {
          _updateMessageSubscription(_selectedAdminRoomId!);
        } else {
          _cancelChatSubscriptions();
        }
      } else if (currentUser?.role == UserRole.customer) {
        final room = ensureRoomForCustomer(currentUser!.id);
        if (room.id > 0) {
          _updateMessageSubscription(room.id);
        }
      }
      notifyListeners();
    }, onError: (err) {
      // ignore: avoid_print
      print('[AppState] Chat rooms stream error: $err');
    });
  }

  void _updateMessageSubscription(int roomId) {
    if (_subscribedRoomId == roomId) return;
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _subscribedRoomId = roomId;

    if (roomId > 0) {
      _messagesSubscription = _api
          .getChatMessagesStream(_token!, roomId)
          .listen((messages) {
        _messagesByRoom[roomId] = messages;
        notifyListeners();

        // Trigger local notification for real-time incoming messages
        if (_chatStreamInitTime != null && messages.isNotEmpty) {
          final lastMessage = messages.last;
          if (lastMessage.senderId != currentUser?.id &&
              lastMessage.sentAt.isAfter(_chatStreamInitTime!)) {
            if (_notifiedMessageIds.add(lastMessage.id)) {
              if (!_isChatActive) {
                _hasUnreadMessages = true;
              }
              unawaited(NotificationService.instance.showChatNotification(
                id: lastMessage.id,
                senderName: lastMessage.senderName,
                messageText: lastMessage.text,
              ));
            }
          }
        }
      }, onError: (err) {
        // ignore: avoid_print
        print('[AppState] Chat messages stream error: $err');
      });
    }
  }

  ChatRoom ensureRoomForCustomer(int customerId) {
    if (_chatRooms.isNotEmpty) {
      final matches = _chatRooms.where((room) => room.customerId == customerId);
      if (matches.isNotEmpty) {
        return matches.first;
      }
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
        .where((transaction) =>
            transaction.customerId == customerId &&
            transaction.status == PaymentStatus.paid)
        .fold<double>(0, (sum, item) => sum + item.amount);
  }

  Future<void> createOrder({
    required int customerId,
    required int serviceId,
    required double quantity,
    required double totalPrice,
    required String notes,
    required bool isPaid,
    String paymentMethod = 'Cash',
  }) async {
    if (_token == null) return;
    await _guard(() async {
      await _api.createOrder(
        _token!,
        customerId: customerId,
        serviceId: serviceId,
        quantity: quantity,
        totalPrice: totalPrice,
        notes: notes,
        isPaid: isPaid,
        paymentMethod: paymentMethod,
      );
      await refreshOrders();
      if (currentUser?.role == UserRole.admin) {
        await refreshDashboard();
        await refreshReports();
      }
    });
  }

  Future<void> markOrderAsPaid({
    required int orderId,
    required double amount,
    required String paymentMethod,
  }) async {
    if (_token == null) return;
    await _guard(() async {
      await _api.markOrderAsPaid(
        _token!,
        orderId: orderId,
        amount: amount,
        paymentMethod: paymentMethod,
      );
      await refreshOrders();
      if (currentUser?.role == UserRole.admin) {
        await refreshDashboard();
        await refreshReports();
      }
    });
  }

  Future<void> deleteOrder(int orderId) async {
    if (_token == null) return;
    await _guard(() async {
      await _api.deleteOrder(_token!, orderId);
      await refreshOrders();
      if (currentUser?.role == UserRole.admin) {
        await refreshDashboard();
        await refreshReports();
      }
    });
  }

  Future<void> deleteChatRoom(int roomId) async {
    if (_token == null) return;
    await _guard(() async {
      await _api.deleteChatRoom(_token!, roomId);
      if (_selectedAdminRoomId == roomId) {
        _selectedAdminRoomId = null;
        _messagesSubscription?.cancel();
        _messagesSubscription = null;
        _subscribedRoomId = null;
      }
      await refreshChatRooms();
    });
  }

  String currency(num value) => formatCurrency(value);
  String dateTime(DateTime value) => formatDateTime(value);
  String shortDate(DateTime value) => formatShortDate(value);
  String shortTime(DateTime value) => formatShortTime(value);

  Future<void> _guard(Future<void> Function() action,
      {void Function(String message)? onError}) async {
    try {
      isBusy = true;
      lastError = null;
      notifyListeners();
      await action();
    } on ApiException catch (e) {
      lastError = e.message;
      // Log to console for easier runtime debugging
      // ignore: avoid_print
      print('[AppState] ApiException: ${e.message}');
      onError?.call(e.message);
    } catch (error, stackTrace) {
      lastError = 'Terjadi kesalahan tak terduga.';
      // Log stack trace for unexpected errors
      // ignore: avoid_print
      print('[AppState] Unexpected error: $error\n$stackTrace');
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
