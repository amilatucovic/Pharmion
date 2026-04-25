class InventoryItemModel {
  final int id;
  final int pharmacyId;
  final String pharmacyName;
  final int productId;
  final String productName;
  final String? productSku;
  final String? productImageUrl;
  final int quantityOnHand;
  final int reservedQuantity;
  final int availableQuantity;
  final int reorderLevel;
  final bool isLowStock;
  final DateTime expirationDate;
  final bool isExpired;
  final bool isExpiringSoon;
  final DateTime updatedAt;

  const InventoryItemModel({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.productId,
    required this.productName,
    this.productSku,
    this.productImageUrl,
    required this.quantityOnHand,
    required this.reservedQuantity,
    required this.availableQuantity,
    required this.reorderLevel,
    required this.isLowStock,
    required this.expirationDate,
    required this.isExpired,
    required this.isExpiringSoon,
    required this.updatedAt,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) =>
      InventoryItemModel(
        id: json['id'] as int? ?? 0,
        pharmacyId: json['pharmacyId'] as int? ?? 0,
        pharmacyName: json['pharmacyName'] as String? ?? '',
        productId: json['productId'] as int? ?? 0,
        productName: json['productName'] as String? ?? '',
        productSku: json['productSku'] as String?,
        productImageUrl: json['productImageUrl'] as String?,
        quantityOnHand: json['quantityOnHand'] as int? ?? 0,
        reservedQuantity: json['reservedQuantity'] as int? ?? 0,
        availableQuantity: json['availableQuantity'] as int? ?? 0,
        reorderLevel: json['reorderLevel'] as int? ?? 0,
        isLowStock: json['isLowStock'] as bool? ?? false,
        expirationDate: _parseDate(json['expirationDate']) ?? DateTime(2099),
        isExpired: json['isExpired'] as bool? ?? false,
        isExpiringSoon: json['isExpiringSoon'] as bool? ?? false,
        updatedAt: _parseDate(json['updatedAt']) ?? DateTime(2000),
      );

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim().replaceFirst(' ', 'T');
    final withZ = s.endsWith('Z') ? s : '${s}Z';
    return DateTime.tryParse(withZ)?.toLocal();
  }
}