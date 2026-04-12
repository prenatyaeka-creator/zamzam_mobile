class OrderModel {
  final String invoiceNo;
  final String customerName;
  final String serviceName;
  final String orderStatus;
  final double totalPrice;

  OrderModel({
    required this.invoiceNo,
    required this.customerName,
    required this.serviceName,
    required this.orderStatus,
    required this.totalPrice,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      invoiceNo: json['invoice_no'] ?? '-',
      customerName: json['customer_name'] ?? '-',
      serviceName: json['service_name'] ?? 'Layanan Umum',
      orderStatus: json['order_status'] ?? 'pending',
      totalPrice: double.parse(json['total_price'].toString()),
    );
  }
}