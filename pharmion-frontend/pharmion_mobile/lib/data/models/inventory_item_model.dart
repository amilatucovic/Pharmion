class InventoryItemModel {
  final int id;
  final int pharmacyId;
  final String pharmacyName;
  final int productId;
  final String productName;
  final String? productSku;
  final String? productImageUrl;
  final bool isAvailable;
  final int availableQuantity;

  const InventoryItemModel({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.productId,
    required this.productName,
    this.productSku,
    this.productImageUrl,
    required this.isAvailable,
    required this.availableQuantity,
    
  });

  bool get isLowStock => false;
  bool get isExpired => false;
  bool get isExpiringSoon => false;
  DateTime get expirationDate => DateTime(2099);

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) =>
      InventoryItemModel(
        id: json['id'] as int? ?? 0,
        pharmacyId: json['pharmacyId'] as int? ?? 0,
        pharmacyName: json['pharmacyName'] as String? ?? '',
        productId: json['productId'] as int? ?? 0,
        productName: json['productName'] as String? ?? '',
        productSku: json['productSku'] as String?,
        productImageUrl: json['productImageUrl'] as String?,
        isAvailable: json['isAvailable'] as bool? ?? false,
        availableQuantity: json['availableQuantity'] as int? ?? 0,
      );

      
  
}


