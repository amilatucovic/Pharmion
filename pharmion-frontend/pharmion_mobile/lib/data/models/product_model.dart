class ProductModel {
  final int id;
  final String name;
  final int type;
  final String typeName;
  final bool isPrescriptionRequired;
  final bool isActive;
  final String? sku;
  final String? barcode;
  final String? manufacturer;
  final String? unit;
  final int? packageSize;
  final double price;
  final String sideEffects;
  final String instructionsForUse;
  final String contraindications;
  final String? imageUrl;
  final String? description;

  const ProductModel({
    required this.id,
    required this.name,
    required this.type,
    required this.typeName,
    required this.isPrescriptionRequired,
    required this.isActive,
    this.sku,
    this.barcode,
    this.manufacturer,
    this.unit,
    this.packageSize,
    required this.price,
    required this.sideEffects,
    required this.instructionsForUse,
    required this.contraindications,
    this.imageUrl,
    this.description,
  });

  bool get hasRealImage =>
      imageUrl != null &&
      imageUrl!.isNotEmpty &&
      !imageUrl!.contains('default-product');

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        type: json['type'] is int ? json['type'] as int : 0,
        typeName: json['typeName'] as String? ?? json['type']?.toString() ?? '',
        isPrescriptionRequired:
            json['isPrescriptionRequired'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? true,
        sku: json['sku'] as String?,
        barcode: json['barcode'] as String?,
        manufacturer: json['manufacturer'] as String?,
        unit: json['unit'] as String?,
        packageSize: json['packageSize'] is int
            ? json['packageSize'] as int
            : int.tryParse(json['packageSize']?.toString() ?? ''),
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        sideEffects: json['sideEffects'] as String? ?? '',
        instructionsForUse: json['instructionsForUse'] as String? ?? '',
        contraindications: json['contraindications'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        description: json['description'] as String?,
      );
}
