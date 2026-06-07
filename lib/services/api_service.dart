import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _services =>
      _firestore.collection('services');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');
  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _chatRooms =>
      _firestore.collection('chat_rooms');

  Future<void> _initialize() async {
    if (_initialized) return;
    // ignore: avoid_print
    print('[ApiService] initialize start');
    await _ensureDefaultData();
    _initialized = true;
    // ignore: avoid_print
    print('[ApiService] initialize done');
  }

  Future<void> _ensureDefaultData() async {
    // Data awal Firebase tidak diisi secara otomatis.
    // Semua akun dan layanan harus dibuat langsung dari aplikasi atau
    // melalui Firebase Console.
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return value;
  }

  Map<String, dynamic> _normalizeDocument(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _normalizeValue(value)));
  }

  Future<AppUser> _getUserByUid(String uid) async {
    final snapshot = await _users.where('uid', isEqualTo: uid).limit(1).get();
    if (snapshot.docs.isEmpty) {
      throw ApiException('Pengguna tidak ditemukan di Firebase.');
    }
    return _userFromJson(_normalizeDocument(snapshot.docs.first.data()));
  }

  Future<AppUser> _createAdminUser(String uid, {String? email}) async {
    final id = _nextId();
    final data = {
      'id': id,
      'uid': uid,
      'name': 'Admin ZAMZAM',
      'email': email?.trim() ?? 'admin@zamzam.com',
      'phone': '-',
      'address': '-',
      'role': 'admin',
      'is_active': true,
      'created_at': FieldValue.serverTimestamp(),
    };
    await _users.doc('$id').set(data);
    return _userFromJson(_normalizeDocument(data));
  }

  AppUser _userFromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      password: '',
      role: userRoleFromApi(json['role']?.toString() ?? 'customer'),
      address: json['address']?.toString() ?? '',
      isActive: _asBool(json['is_active'] ?? true),
    );
  }

  LaundryService _serviceFromJson(Map<String, dynamic> json) {
    return LaundryService(
      id: _asInt(json['id']),
      name: json['service_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _asDouble(json['price']),
      unit: json['unit']?.toString() ?? 'kg',
      estimateDays: _asInt(json['estimate_days']),
      isActive: _asBool(json['is_active'] ?? true),
    );
  }

  LaundryOrder _orderFromJson(Map<String, dynamic> json) {
    return LaundryOrder.fromJson(json);
  }

  OrderStatusLog _historyFromJson(Map<String, dynamic> json) {
    return OrderStatusLog.fromJson(json);
  }

  TransactionEntry _transactionFromJson(Map<String, dynamic> json) {
    return TransactionEntry.fromJson(json,
        customerId: _asInt(json['customer_id']));
  }

  ChatRoom _chatRoomFromJson(Map<String, dynamic> json) {
    return ChatRoom.fromJson(json);
  }

  ChatMessage _chatMessageFromJson(Map<String, dynamic> json) {
    return ChatMessage.fromJson(json);
  }

  Future<LoginResult> login(String email, String password,
      {UserRole? expectedRole}) async {
    await _initialize();

    // ignore: avoid_print
    print(
        '[ApiService] login start email=${email.trim()} expectedRole=$expectedRole');

    try {
      // ignore: avoid_print
      print('[ApiService] FirebaseAuth signIn start');
      final credential = await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password)
          .timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw ApiException(
            'Login Firebase terlalu lama. Periksa koneksi atau konfigurasi Firebase.',
          );
        },
      );
      // ignore: avoid_print
      print('[ApiService] FirebaseAuth signIn done');
      final uid = credential.user?.uid;
      // ignore: avoid_print
      print('[ApiService] FirebaseAuth success uid=$uid');
      if (uid == null) {
        throw ApiException('Tidak dapat mengautentikasi pengguna.');
      }

      try {
        final user = await _getUserByUid(uid);
        // ignore: avoid_print
        print(
            '[ApiService] User ditemukan di Firestore uid=$uid email=${user.email} role=${user.role}');
        return LoginResult(token: uid, user: user);
      } on ApiException catch (e) {
        // ignore: avoid_print
        print('[ApiService] User lookup failed uid=$uid message=${e.message}');
        if (expectedRole == UserRole.admin &&
            e.message == 'Pengguna tidak ditemukan di Firebase.') {
          final user = await _createAdminUser(uid, email: email.trim());
          // ignore: avoid_print
          print(
              '[ApiService] Admin user created in Firestore uid=$uid email=${user.email}');
          return LoginResult(token: uid, user: user);
        }

        if (expectedRole == UserRole.customer &&
            e.message == 'Pengguna tidak ditemukan di Firebase.') {
          throw ApiException(
              'Data pelanggan tidak ditemukan. Silakan registrasi terlebih dahulu.');
        }
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      // Log full Firebase auth error for debugging
      // ignore: avoid_print
      print(
          '[ApiService] FirebaseAuthException code=${e.code} message=${e.message}');
      throw ApiException(
          'FirebaseAuth: ${e.code} - ${e.message ?? 'Gagal login ke Firebase.'}');
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('[ApiService] login unexpected error: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<LoginResult> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    await _initialize();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      final user = credential.user;
      if (user == null) {
        throw ApiException('Tidak dapat membuat akun pelanggan.');
      }

      final id = _nextId();
      final data = {
        'id': id,
        'uid': user.uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'role': 'customer',
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      };
      await _users.doc('$id').set(data);
      return LoginResult(
          token: user.uid, user: _userFromJson(_normalizeDocument(data)));
    } on FirebaseAuthException catch (e) {
      throw ApiException(e.message ?? 'Gagal mendaftar pengguna.');
    }
  }

  Future<AppUser> me(String token) async {
    await _initialize();
    return _getUserByUid(token);
  }

  Future<List<LaundryService>> getServices({String? token}) async {
    await _initialize();
    final snapshot = await _services.orderBy('service_name').get();
    return snapshot.docs
        .map((doc) => _serviceFromJson(_normalizeDocument({
              'id': _asInt(doc.data()['id'] ?? int.tryParse(doc.id)),
              ...doc.data()
            })))
        .toList();
  }

  Future<LaundryService> createService(
    String token, {
    required String name,
    required String description,
    required double price,
    required String unit,
    required int estimateDays,
    bool isActive = true,
  }) async {
    await _initialize();
    final id = _nextId();
    final data = {
      'id': id,
      'service_name': name.trim(),
      'description': description.trim(),
      'price': price,
      'unit': unit.trim(),
      'estimate_days': estimateDays,
      'is_active': isActive,
      'created_at': FieldValue.serverTimestamp(),
    };
    await _services.doc('$id').set(data);
    return _serviceFromJson(_normalizeDocument(data));
  }

  Future<LaundryService> updateService(
    String token, {
    required int id,
    required String name,
    required String description,
    required double price,
    required String unit,
    required int estimateDays,
    required bool isActive,
  }) async {
    await _initialize();
    final doc = _services.doc('$id');
    await doc.update({
      'service_name': name.trim(),
      'description': description.trim(),
      'price': price,
      'unit': unit.trim(),
      'estimate_days': estimateDays,
      'is_active': isActive,
    });
    final snapshot = await doc.get();
    return _serviceFromJson(_normalizeDocument(
        {'id': _asInt(snapshot.data()?['id'] ?? id), ...?(snapshot.data())}));
  }

  Future<void> deactivateService(String token, int id) async {
    await _initialize();
    await _services.doc('$id').update({'is_active': false});
  }

  Future<List<LaundryOrder>> getOrders(String token, {int? customerId}) async {
    await _initialize();
    Query<Map<String, dynamic>> query = _orders;
    if (customerId != null && customerId > 0) {
      query = query.where('customer_id', isEqualTo: customerId);
    }
    final snapshot = await query.get();
    final list = snapshot.docs
        .map((doc) => _orderFromJson(_normalizeDocument({
              'id': _asInt(doc.data()['id'] ?? int.tryParse(doc.id)),
              ...doc.data()
            })))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<OrderDetailPayload> getOrderDetail(String token, int id) async {
    await _initialize();
    final orderDoc = await _orders.doc('$id').get();
    if (!orderDoc.exists || orderDoc.data() == null) {
      throw ApiException('Order tidak ditemukan.');
    }
    final orderData = _normalizeDocument(
        {'id': _asInt(orderDoc.data()!['id'] ?? id), ...orderDoc.data()!});
    final order = _orderFromJson(orderData);

    final historiesSnapshot = await _orders
        .doc('$id')
        .collection('histories')
        .orderBy('created_at')
        .get();
    final histories = historiesSnapshot.docs
        .map((doc) => _historyFromJson(_normalizeDocument({
              'id': _asInt(doc.data()['id'] ?? int.tryParse(doc.id)),
              'order_id': id,
              ...doc.data()
            })))
        .toList();

    final transactionSnapshot =
        await _transactions.where('order_id', isEqualTo: id).limit(1).get();
    TransactionEntry? transaction;
    if (transactionSnapshot.docs.isNotEmpty) {
      transaction = _transactionFromJson(_normalizeDocument({
        'id': _asInt(transactionSnapshot.docs.first.data()['id'] ??
            int.tryParse(transactionSnapshot.docs.first.id)),
        ...transactionSnapshot.docs.first.data()
      }));
    }

    return OrderDetailPayload(
        order: order, histories: histories, transaction: transaction);
  }

  Future<LaundryOrder> updateOrderStatus(
    String token, {
    required int orderId,
    required OrderStatus status,
    String note = '',
  }) async {
    await _initialize();
    final user = await _getUserByUid(token);
    final statusData = {
      'status': orderStatusToApi(status),
      'note': note.trim(),
      'created_by_name': user.name,
      'created_at': FieldValue.serverTimestamp(),
      'id': _nextId(),
    };
    await _orders.doc('$orderId').update({
      'order_status': orderStatusToApi(status),
      if (status == OrderStatus.completed)
        'completed_at': FieldValue.serverTimestamp(),
    });
    await _orders
        .doc('$orderId')
        .collection('histories')
        .doc('${statusData['id']}')
        .set(statusData);

    final orderDoc = await _orders.doc('$orderId').get();
    if (!orderDoc.exists || orderDoc.data() == null) {
      throw ApiException('Order tidak ditemukan setelah perubahan status.');
    }
    return _orderFromJson(_normalizeDocument({
      'id': _asInt(orderDoc.data()!['id'] ?? orderId),
      ...orderDoc.data()!
    }));
  }

  Future<List<AppUser>> getCustomers(String token) async {
    await _initialize();
    final snapshot = await _users
        .where('role', isEqualTo: 'customer')
        .get();
    final list = snapshot.docs
        .map((doc) => _userFromJson(_normalizeDocument({
              'id': _asInt(doc.data()['id'] ?? int.tryParse(doc.id)),
              ...doc.data()
            })))
        .where((user) => user.isActive)
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<Map<String, dynamic>> getDashboard(String token) async {
    await _initialize();
    final customerSnapshot =
        await _users.where('role', isEqualTo: 'customer').get();
    final orderSnapshot = await _orders.get();
    final activeOrdersSnapshot = await _orders.where('order_status',
        whereIn: ['pending', 'picked_up', 'washing', 'ironing', 'ready']).get();
    final transactionSnapshot =
        await _transactions.where('payment_status', isEqualTo: 'paid').get();

    final today = DateTime.now();
    final monthlyRevenue = transactionSnapshot.docs.fold<double>(0, (acc, doc) {
      final value = _normalizeValue(doc.data()['paid_at']);
      final date = DateTime.tryParse(value?.toString() ?? '');
      if (date == null) return acc;
      return (date.year == today.year && date.month == today.month)
          ? acc + _asDouble(doc.data()['amount'])
          : acc;
    });
    final todayRevenue = transactionSnapshot.docs.fold<double>(0, (acc, doc) {
      final value = _normalizeValue(doc.data()['paid_at']);
      final date = DateTime.tryParse(value?.toString() ?? '');
      if (date == null) return acc;
      return (date.year == today.year &&
              date.month == today.month &&
              date.day == today.day)
          ? acc + _asDouble(doc.data()['amount'])
          : acc;
    });

    return {
      'total_customers': customerSnapshot.docs.length,
      'total_orders': orderSnapshot.docs.length,
      'active_orders': activeOrdersSnapshot.docs.length,
      'today_revenue': todayRevenue,
      'monthly_revenue': monthlyRevenue,
    };
  }

  Future<Map<String, dynamic>> getReport(String token,
      {String? startDate, String? endDate}) async {
    await _initialize();
    final allTransactions = await _transactions.get();
    final transactions = allTransactions.docs
        .map((doc) => _normalizeDocument({
              'id': _asInt(doc.data()['id'] ?? int.tryParse(doc.id)),
              ...doc.data()
            }))
        .where((json) {
      if (startDate == null && endDate == null) return true;
      final createdAt =
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.tryParse(json['paid_at']?.toString() ?? '') ??
              DateTime.now();
      if (startDate != null) {
        final start = DateTime.tryParse(startDate);
        if (start != null && createdAt.isBefore(start)) {
          return false;
        }
      }
      if (endDate != null) {
        final end = DateTime.tryParse(endDate);
        if (end != null &&
            createdAt.isAfter(end
                .add(const Duration(days: 1))
                .subtract(const Duration(milliseconds: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();

    return {'transactions': transactions};
  }

  Future<List<ChatRoom>> getChatRooms(String token) async {
    await _initialize();
    final user = await _getUserByUid(token);
    Query<Map<String, dynamic>> query = _chatRooms;
    if (user.role == UserRole.customer) {
      query = query.where('customer_id', isEqualTo: user.id);
    }
    final snapshot =
        await query.orderBy('last_message_at', descending: true).get();
    return snapshot.docs
        .map((doc) => _chatRoomFromJson(_normalizeDocument({
              'id': _asInt(doc.data()['id'] ?? int.tryParse(doc.id)),
              ...doc.data()
            })))
        .toList();
  }

  Stream<List<ChatRoom>> getChatRoomsStream(String token) {
    return Stream.fromFuture(_getUserByUid(token)).asyncExpand((user) {
      Query<Map<String, dynamic>> query = _chatRooms;
      if (user.role == UserRole.customer) {
        query = query.where('customer_id', isEqualTo: user.id);
      }
      return query
          .orderBy('last_message_at', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => _chatRoomFromJson(_normalizeDocument({
                  'id': _asInt(doc.data()['id'] ?? int.tryParse(doc.id)),
                  ...doc.data()
                })))
            .toList();
      });
    });
  }

  Future<List<ChatMessage>> getChatMessages(String token, int roomId) async {
    await _initialize();
    final snapshot = await _chatRooms
        .doc('$roomId')
        .collection('messages')
        .orderBy('created_at')
        .get();
    return snapshot.docs
        .map((doc) => _chatMessageFromJson(_normalizeDocument({
              'id': _asInt(doc.data()['id'] ?? int.tryParse(doc.id)),
              'room_id': roomId,
              ...doc.data()
            })))
        .toList();
  }

  Stream<List<ChatMessage>> getChatMessagesStream(String token, int roomId) {
    return Stream.fromFuture(_initialize()).asyncExpand((_) {
      return _chatRooms
          .doc('$roomId')
          .collection('messages')
          .orderBy('created_at')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => _chatMessageFromJson(_normalizeDocument({
                  'id': _asInt(doc.data()['id'] ?? int.tryParse(doc.id)),
                  'room_id': roomId,
                  ...doc.data()
                })))
            .toList();
      });
    });
  }

  Future<ChatMessage> sendChatMessage(
    String token, {
    required int roomId,
    required String message,
    int? customerId,
  }) async {
    await _initialize();
    final sender = await _getUserByUid(token);

    ChatRoom room;
    if (roomId <= 0) {
      final targetCustomerId = customerId ?? sender.id;
      final targetCustomer =
          await _users.where('id', isEqualTo: targetCustomerId).limit(1).get();
      final customerName = targetCustomer.docs.isNotEmpty
          ? targetCustomer.docs.first.data()['name']?.toString() ?? 'Pelanggan'
          : sender.name;
      room = await _findOrCreateRoom(targetCustomerId, customerName);
      roomId = room.id;
    } else {
      final roomDoc = await _chatRooms.doc('$roomId').get();
      if (!roomDoc.exists || roomDoc.data() == null) {
        throw ApiException('Room chat tidak ditemukan.');
      }
      room = _chatRoomFromJson(_normalizeDocument(
          {'id': _asInt(roomDoc.data()!['id'] ?? roomId), ...roomDoc.data()!}));
    }

    final now = DateTime.now();
    final messageId = _nextId();
    final messageData = {
      'id': messageId,
      'room_id': roomId,
      'sender_id': sender.id,
      'sender_name': sender.name,
      'message': message.trim(),
      'created_at': Timestamp.fromDate(now),
    };

    await _chatRooms
        .doc('$roomId')
        .collection('messages')
        .doc('$messageId')
        .set(messageData);
    await _chatRooms.doc('$roomId').update({
      'last_message': message.trim(),
      'last_message_at': Timestamp.fromDate(now),
    });

    return _chatMessageFromJson(_normalizeDocument({
      'id': messageId,
      'room_id': roomId,
      ...messageData,
    }));
  }

  Future<ChatRoom> _findOrCreateRoom(
      int customerId, String customerName) async {
    final snapshot = await _chatRooms
        .where('customer_id', isEqualTo: customerId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return _chatRoomFromJson(_normalizeDocument({
        'id': _asInt(snapshot.docs.first.data()['id'] ??
            int.tryParse(snapshot.docs.first.id)),
        ...snapshot.docs.first.data()
      }));
    }

    final newRoomId = _nextId();
    final data = {
      'id': newRoomId,
      'customer_id': customerId,
      'admin_id': 1,
      'title': 'Admin ZAMZAM',
      'customer_name': customerName,
      'last_message': 'Mulai chat dengan admin.',
      'last_message_at': FieldValue.serverTimestamp(),
    };
    await _chatRooms.doc('$newRoomId').set(data);
    return _chatRoomFromJson(_normalizeDocument(data));
  }

  Future<LaundryOrder> createOrder(
    String token, {
    required int customerId,
    required int serviceId,
    required double quantity,
    required double totalPrice,
    required String notes,
    required bool isPaid,
    String paymentMethod = 'Cash',
  }) async {
    await _initialize();
    final user = await _getUserByUid(token);

    // Get customer name and phone
    final customerSnapshot = await _users.where('id', isEqualTo: customerId).limit(1).get();
    final customerName = customerSnapshot.docs.isNotEmpty
        ? customerSnapshot.docs.first.data()['name']?.toString() ?? 'Pelanggan'
        : 'Pelanggan';
    final customerPhone = customerSnapshot.docs.isNotEmpty
        ? customerSnapshot.docs.first.data()['phone']?.toString() ?? '-'
        : '-';

    // Get service name
    final serviceDoc = await _services.doc('$serviceId').get();
    final serviceName = serviceDoc.data()?['service_name']?.toString() ?? 'Layanan';

    final id = _nextId();
    final dateStr = DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 8);
    final invoiceNo = 'INV-$dateStr-${id.toString().substring(id.toString().length - 4)}';

    final orderData = {
      'id': id,
      'invoice_no': invoiceNo,
      'customer_id': customerId,
      'service_id': serviceId,
      'qty': quantity,
      'total_price': totalPrice,
      'payment_status': isPaid ? 'paid' : 'unpaid',
      'order_status': 'pending',
      'notes': notes,
      'created_at': FieldValue.serverTimestamp(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'service_name': serviceName,
    };

    // 1. Create order
    await _orders.doc('$id').set(orderData);

    // 2. Create history
    final historyId = _nextId();
    final statusData = {
      'id': historyId,
      'order_id': id,
      'status': 'pending',
      'note': 'Order dibuat.',
      'created_by_name': user.name,
      'created_at': FieldValue.serverTimestamp(),
    };
    await _orders.doc('$id').collection('histories').doc('$historyId').set(statusData);

    // 3. Create transaction if paid
    if (isPaid) {
      final transactionId = _nextId();
      final transactionData = {
        'id': transactionId,
        'order_id': id,
        'customer_id': customerId,
        'invoice_no': invoiceNo,
        'amount': totalPrice,
        'payment_method': paymentMethod,
        'payment_status': 'paid',
        'paid_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      };
      await _transactions.doc('$transactionId').set(transactionData);
    }

    return _orderFromJson(_normalizeDocument(orderData));
  }

  Future<void> markOrderAsPaid(
    String token, {
    required int orderId,
    required double amount,
    required String paymentMethod,
  }) async {
    await _initialize();

    // 1. Update payment_status to 'paid' in the orders collection
    await _orders.doc('$orderId').update({
      'payment_status': 'paid',
    });

    // 2. Create transaction doc in transactions collection
    final transactionId = _nextId();
    final orderDoc = await _orders.doc('$orderId').get();
    final customerId = _asInt(orderDoc.data()?['customer_id']);
    final invoiceNo = orderDoc.data()?['invoice_no']?.toString() ?? '';

    final transactionData = {
      'id': transactionId,
      'order_id': orderId,
      'customer_id': customerId,
      'invoice_no': invoiceNo,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_status': 'paid',
      'paid_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    };
    await _transactions.doc('$transactionId').set(transactionData);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  int _nextId() => DateTime.now().millisecondsSinceEpoch;
}
