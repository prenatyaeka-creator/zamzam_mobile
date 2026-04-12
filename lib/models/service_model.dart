class ServiceModel {
  final int id;
  final String serviceName;
  final double price;
  final String unit;

  ServiceModel({
    required this.id,
    required this.serviceName,
    required this.price,
    required this.unit,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: int.parse(json['id'].toString()),
      serviceName: json['service_name'] ?? '',
      price: double.parse(json['price'].toString()), // 🔥 fix
      unit: json['unit'] ?? '',
    );
  }
}