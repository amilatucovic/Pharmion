class ReservationModel {
  final int id;
  final String pharmacyName;
  final String status;
  final String statusDisplay;
  final DateTime createdAt;
  final List<ReservationItemModel> items;

  const ReservationModel({
    required this.id,
    required this.pharmacyName,
    required this.status,
    required this.statusDisplay,
    required this.createdAt,
    required this.items,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as int? ?? 0,
      pharmacyName: json['pharmacyName'] as String? ?? '',
      status: json['reservationState']?.toString() ?? '',
      statusDisplay: json['reservationStateDisplay'] as String? ??
          json['reservationState']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']) ?? DateTime(2000),
      items: ((json['items'] as List?) ?? [])
          .map((i) => ReservationItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim().replaceFirst(' ', 'T');
    final withZ = s.endsWith('Z') ? s : '${s}Z';
    return DateTime.tryParse(withZ)?.toLocal();
  }
}

class ReservationItemModel {
  final int id;
  final String productName;
  final int quantity;

  const ReservationItemModel({
    required this.id,
    required this.productName,
    required this.quantity,
  });

  factory ReservationItemModel.fromJson(Map<String, dynamic> json) =>
      ReservationItemModel(
        id: json['id'] as int? ?? 0,
        productName: json['productName'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
      );
}