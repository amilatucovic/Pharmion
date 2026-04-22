import 'api_service.dart';

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

  InventoryItemModel({
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

  factory InventoryItemModel.fromJson(Map<String, dynamic> j) =>
      InventoryItemModel(
        id: j['id'],
        pharmacyId: j['pharmacyId'],
        pharmacyName: j['pharmacyName'] ?? '',
        productId: j['productId'],
        productName: j['productName'] ?? '',
        productSku: j['productSku'],
        productImageUrl: j['productImageUrl'],
        quantityOnHand: j['quantityOnHand'] ?? 0,
        reservedQuantity: j['reservedQuantity'] ?? 0,
        availableQuantity: j['availableQuantity'] ?? 0,
        reorderLevel: j['reorderLevel'] ?? 0,
        isLowStock: j['isLowStock'] ?? false,
        expirationDate: DateTime.parse(j['expirationDate']),
        isExpired: j['isExpired'] ?? false,
        isExpiringSoon: j['isExpiringSoon'] ?? false,
        updatedAt: DateTime.parse(j['updatedAt']),
      );

  String get fullImageUrl {
    if (productImageUrl == null || productImageUrl!.isEmpty) return '';
    if (productImageUrl!.startsWith('http')) return productImageUrl!;
    return '${ApiService.baseUrl}$productImageUrl';
  }
}

class PagedInventory {
  final List<InventoryItemModel> items;
  final int totalCount;
  PagedInventory({required this.items, required this.totalCount});
}

class InventoryService {
  static Future<PagedInventory> getItems({
    int page = 0,
    int pageSize = 10,
    int? pharmacyId,
    String? productName,
    bool? lowStock,
    bool? expiringSoon,
  }) async {
    final params = StringBuffer(
        'InventoryItem?includeTotalCount=true&retrieveAll=false');
    params.write('&page=$page&pageSize=$pageSize');
    if (pharmacyId != null) params.write('&pharmacyId=$pharmacyId');
    if (productName != null && productName.isNotEmpty) {
        params.write('&productName=$productName');
    }
    if (lowStock == true) params.write('&lowStock=true');
    if (expiringSoon == true) params.write('&expiringSoon=true');

    final data = await ApiService.get(params.toString());
    final items = (data['items'] as List)
        .map((e) => InventoryItemModel.fromJson(e))
        .toList();
    return PagedInventory(
        items: items, totalCount: data['totalCount'] ?? items.length);
  }

  static Future<InventoryItemModel> create(Map<String, dynamic> request) async {
    final data = await ApiService.post('InventoryItem', request);
    return InventoryItemModel.fromJson(data);
  }

  static Future<InventoryItemModel> update(
      int id, Map<String, dynamic> request) async {
    final data = await ApiService.put('InventoryItem/$id', request);
    return InventoryItemModel.fromJson(data);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('InventoryItem/$id');
  }

  static Future<void> addStockMovement(Map<String, dynamic> request) async {
    await ApiService.post('StockMovement', request);
  }
}