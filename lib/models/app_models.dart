enum UserRole { admin, customer }

enum OrderStatus { pending, pickedUp, washing, ironing, ready, completed, cancelled }

enum PaymentStatus { unpaid, paid }

UserRole userRoleFromApi(String value) {
  return value.toLowerCase() == 'admin' ? UserRole.admin : UserRole.customer;
}

OrderStatus orderStatusFromApi(String value) {
  switch (value) {
    case 'pending':
      return OrderStatus.pending;
    case 'picked_up':
      return OrderStatus.pickedUp;
    case 'washing':
      return OrderStatus.washing;
    case 'ironing':
      return OrderStatus.ironing;
    case 'ready':
      return OrderStatus.ready;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}

String orderStatusToApi(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'pending';
    case OrderStatus.pickedUp:
      return 'picked_up';
    case OrderStatus.washing:
      return 'washing';
    case OrderStatus.ironing:
      return 'ironing';
    case OrderStatus.ready:
      return 'ready';
    case OrderStatus.completed:
      return 'completed';
    case OrderStatus.cancelled:
      return 'cancelled';
  }
}

PaymentStatus paymentStatusFromApi(String value) {
  return value.toLowerCase() == 'paid' ? PaymentStatus.paid : PaymentStatus.unpaid;
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.customer:
        return 'Pelanggan';
    }
  }
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.pickedUp:
        return 'Diterima';
      case OrderStatus.washing:
        return 'Dicuci';
      case OrderStatus.ironing:
        return 'Disetrika';
      case OrderStatus.ready:
        return 'Siap Diambil';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }
}

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Belum Bayar';
      case PaymentStatus.paid:
        return 'Lunas';
    }
  }
}

DateTime _date(dynamic value) {
  if (value == null) {
    return DateTime.now();
  }
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

DateTime? _nullableDate(dynamic value) {
  if (value == null || value.toString().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value == null) return 0;
  final str = value.toString();
  final parsed = int.tryParse(str);
  if (parsed != null) return parsed;
  if (str.isNotEmpty) {
    int hash = 0;
    for (int i = 0; i < str.length; i++) {
      hash = (31 * hash + str.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash;
  }
  return 0;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  return value.toString() == '1' || value.toString().toLowerCase() == 'true';
}

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    required this.address,
    this.isActive = true,
  });

  final int id;
  String name;
  String email;
  String phone;
  String password;
  UserRole role;
  String address;
  bool isActive;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    int parsedId = _int(json['id']);
    if (parsedId == 0 && json['uid'] != null) {
      parsedId = _int(json['uid']);
    }
    return AppUser(
      id: parsedId,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      password: '',
      role: userRoleFromApi(json['role']?.toString() ?? 'customer'),
      address: json['address']?.toString() ?? '',
      isActive: _bool(json['is_active'] ?? true),
    );
  }
}

class LaundryService {
  LaundryService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.estimateDays,
    this.isActive = true,
  });

  final int id;
  String name;
  String description;
  double price;
  String unit;
  int estimateDays;
  bool isActive;

  factory LaundryService.fromJson(Map<String, dynamic> json) {
    return LaundryService(
      id: _int(json['id']),
      name: json['service_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _double(json['price']),
      unit: json['unit']?.toString() ?? 'kg',
      estimateDays: _int(json['estimate_days']),
      isActive: _bool(json['is_active'] ?? true),
    );
  }
}

class LaundryOrder {
  LaundryOrder({
    required this.id,
    required this.invoiceNo,
    required this.customerId,
    required this.serviceId,
    required this.quantity,
    required this.totalPrice,
    required this.paymentStatus,
    required this.status,
    required this.notes,
    required this.createdAt,
    this.customerName = '',
    this.customerPhone = '',
    this.serviceName = '',
    this.completedAt,
  });

  final int id;
  final String invoiceNo;
  final int customerId;
  final int serviceId;
  double quantity;
  double totalPrice;
  PaymentStatus paymentStatus;
  OrderStatus status;
  String notes;
  DateTime createdAt;
  String customerName;
  String customerPhone;
  String serviceName;
  DateTime? completedAt;

  factory LaundryOrder.fromJson(Map<String, dynamic> json) {
    return LaundryOrder(
      id: _int(json['id']),
      invoiceNo: json['invoice_no']?.toString() ?? '',
      customerId: _int(json['customer_id']),
      serviceId: _int(json['service_id']),
      quantity: _double(json['qty']),
      totalPrice: _double(json['total_price']),
      paymentStatus: paymentStatusFromApi(json['payment_status']?.toString() ?? 'unpaid'),
      status: orderStatusFromApi(json['order_status']?.toString() ?? 'pending'),
      notes: json['notes']?.toString() ?? '',
      createdAt: _date(json['created_at']),
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? '',
      completedAt: _nullableDate(json['completed_at']),
    );
  }
}

class OrderStatusLog {
  OrderStatusLog({
    required this.id,
    required this.orderId,
    required this.status,
    required this.note,
    required this.changedBy,
    required this.changedAt,
  });

  final int id;
  final int orderId;
  final OrderStatus status;
  final String note;
  final String changedBy;
  final DateTime changedAt;

  factory OrderStatusLog.fromJson(Map<String, dynamic> json) {
    return OrderStatusLog(
      id: _int(json['id']),
      orderId: _int(json['order_id']),
      status: orderStatusFromApi(json['status']?.toString() ?? 'pending'),
      note: json['note']?.toString() ?? '',
      changedBy: json['created_by_name']?.toString() ?? 'Admin',
      changedAt: _date(json['created_at']),
    );
  }
}

class TransactionEntry {
  TransactionEntry({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.invoiceNo,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.paidAt,
    required this.createdAt,
  });

  final int id;
  final int orderId;
  final int customerId;
  final String invoiceNo;
  final double amount;
  final String paymentMethod;
  final PaymentStatus status;
  final DateTime? paidAt;
  final DateTime createdAt;

  factory TransactionEntry.fromJson(Map<String, dynamic> json, {int customerId = 0}) {
    return TransactionEntry(
      id: _int(json['id']),
      orderId: _int(json['order_id']),
      customerId: customerId,
      invoiceNo: json['invoice_no']?.toString() ?? '',
      amount: _double(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? '-',
      status: paymentStatusFromApi(json['payment_status']?.toString() ?? 'unpaid'),
      paidAt: _nullableDate(json['paid_at']),
      createdAt: _date(json['created_at'] ?? json['paid_at']),
    );
  }
}

class ChatRoom {
  ChatRoom({
    required this.id,
    required this.customerId,
    required this.adminId,
    required this.title,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  final int id;
  final int customerId;
  final int adminId;
  String title;
  String lastMessage;
  DateTime lastMessageAt;

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: _int(json['id']),
      customerId: _int(json['customer_id']),
      adminId: _int(json['admin_id']),
      title: json['customer_name']?.toString() ?? 'Admin ZAMZAM',
      lastMessage: json['last_message']?.toString() ?? 'Belum ada pesan.',
      lastMessageAt: _nullableDate(json['last_message_at']) ?? DateTime.now(),
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  final int id;
  final int roomId;
  final int senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _int(json['id']),
      roomId: _int(json['room_id']),
      senderId: _int(json['sender_id']),
      senderName: json['sender_name']?.toString() ?? '',
      text: json['message']?.toString() ?? '',
      sentAt: _date(json['created_at']),
    );
  }
}

class OrderDetailPayload {
  OrderDetailPayload({
    required this.order,
    required this.histories,
    required this.transaction,
  });

  final LaundryOrder order;
  final List<OrderStatusLog> histories;
  final TransactionEntry? transaction;
}
