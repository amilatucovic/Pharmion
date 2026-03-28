import 'api_service.dart';

class ProductModel {
  final int id;
  final String name;
  final int type;
  final String typeName;
  final bool isPrescriptionRequired;
  final bool isActive;
  final String? sku, barcode, manufacturer, unit;
  final int? packageSize;
  final double price;
  final String sideEffects, instructionsForUse, contraindications;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductModel({
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
    required this.createdAt,
    this.updatedAt,
  });

  // JEDINI fromJson konstruktor — konvertuje type iz stringa u int
  factory ProductModel.fromJson(Map<String, dynamic> j) {
    int typeInt;
    if (j['type'] is int) {
      typeInt = j['type'];
    } else {
      const typeMap = {
        'Medication': 1,
        'Supplement': 2,
        'MedicalDevice': 3,
        'Cosmetic': 4,
        'BabyAndChild': 5,
        'Orthopedics': 6,
        'Homeopathy': 7,
        'HerbalAndTea': 8,
        'DiagnosticTest': 9,
        'PersonalCare': 10,
      };
      typeInt = typeMap[j['type']] ?? 1;
    }

    return ProductModel(
      id: j['id'],
      name: j['name'],
      type: typeInt,
      typeName: j['typeName'] ?? j['type'] ?? '',
      isPrescriptionRequired: j['isPrescriptionRequired'] ?? false,
      isActive: j['isActive'] ?? true,
      sku: j['sku'],
      barcode: j['barcode'],
      manufacturer: j['manufacturer'],
      unit: j['unit'],
      packageSize: j['packageSize'],
      price: (j['price'] as num).toDouble(),
      sideEffects: j['sideEffects'] ?? '',
      instructionsForUse: j['instructionsForUse'] ?? '',
      contraindications: j['contraindications'] ?? '',
      imageUrl: j['imageUrl'],
      createdAt: DateTime.parse(j['createdAt']),
      updatedAt: j['updatedAt'] != null ? DateTime.parse(j['updatedAt']) : null,
    );
  }

  String get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return '';
    if (imageUrl!.startsWith('http')) return imageUrl!;
    return '${ApiService.baseUrl}$imageUrl';
  }
}

class CategoryModel {
  final int id;
  final String name;
  CategoryModel({required this.id, required this.name});
  factory CategoryModel.fromJson(Map<String, dynamic> j) =>
      CategoryModel(id: j['id'], name: j['name'] ?? j['categoryName'] ?? '');
}

class PagedProducts {
  final List<ProductModel> items;
  final int totalCount;
  PagedProducts({required this.items, required this.totalCount});
}

class ProductService {
  static const Map<int, String> productTypes = {
    1: 'Medication',
    2: 'Supplement',
    3: 'Medical Device',
    4: 'Cosmetic',
    5: 'Baby & Child',
    6: 'Orthopedics',
    7: 'Homeopathy',
    8: 'Herbal & Tea',
    9: 'Diagnostic Tests',
    10: 'Personal Care',
  };

  static Future<PagedProducts> getProducts({
    int page = 0,
    int pageSize = 10,
    String? name,
    int? type,
    bool? isActive,
    bool? isPrescriptionRequired,
  }) async {
    final params = StringBuffer(
      'Product?includeTotalCount=true&retrieveAll=false',
    );
    params.write('&page=$page&pageSize=$pageSize');
    if (name != null && name.isNotEmpty) params.write('&name=$name');
    if (type != null) params.write('&type=$type');
    if (isActive != null) params.write('&isActive=$isActive');
    if (isPrescriptionRequired != null) {
      params.write('&isPrescriptionRequired=$isPrescriptionRequired');
    }

    final data = await ApiService.get(params.toString());
    final items = (data['items'] as List)
        .map((e) => ProductModel.fromJson(e))
        .toList();
    return PagedProducts(
      items: items,
      totalCount: data['totalCount'] ?? items.length,
    );
  }

  static Future<ProductModel> getById(int id) async {
    final data = await ApiService.get('Product/$id');
    return ProductModel.fromJson(data);
  }

  static Future<ProductModel> create(Map<String, dynamic> request) async {
    final data = await ApiService.post('Product', request);
    return ProductModel.fromJson(data);
  }

  static Future<ProductModel> update(
    int id,
    Map<String, dynamic> request,
  ) async {
    final data = await ApiService.put('Product/$id', request);
    return ProductModel.fromJson(data);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('Product/$id');
  }

  static Future<List<CategoryModel>> getMedicationCategories() async {
    final data = await ApiService.get('MedicationCategory?retrieveAll=true');
    final items = (data['items'] as List?) ?? [];
    return items.map((e) => CategoryModel.fromJson(e)).toList();
  }

  static Future<List<CategoryModel>> getPharmacologicalCategories() async {
    final data = await ApiService.get(
      'PharmacologicalCategory?retrieveAll=true',
    );
    final items = (data['items'] as List?) ?? [];
    return items.map((e) => CategoryModel.fromJson(e)).toList();
  }

  static Future<String> uploadImage(
    int productId,
    List<int> bytes,
    String filename,
  ) async {
    final data = await ApiService.uploadFile(
      'Product/$productId/image',
      bytes,
      filename,
    );
    return data['imageUrl'] ?? '';
  }
}
