import 'api_service.dart';

class PharmacyModel {
  final int id;
  final String name;
  final String address;
  final int cityId;
  final String cityName;
  final bool isActive;

  const PharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.cityId,
    required this.cityName,
    required this.isActive,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) => PharmacyModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        cityId: json['cityId'] as int? ?? 0,
        cityName: json['cityName'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
      );
}

class PagedPharmacies {
  final List<PharmacyModel> items;
  final int totalCount;
  const PagedPharmacies({required this.items, required this.totalCount});
}

class PharmacyService {
  static Future<PagedPharmacies> getPharmacies({
    int page = 0,
    int pageSize = 10,
    String? name,
    bool? isActive,
  }) async {
    final params = StringBuffer('Pharmacy?includeTotalCount=true');
    params.write('&page=$page&pageSize=$pageSize');
    if (name != null && name.isNotEmpty) params.write('&name=$name');
    if (isActive != null) params.write('&isActive=$isActive');

    final data = await ApiService.get(params.toString()) as Map<String, dynamic>;
    final items = ((data['items'] as List?) ?? [])
        .map((e) => PharmacyModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PagedPharmacies(
      items: items,
      totalCount: data['totalCount'] as int? ?? items.length,
    );
  }

  static Future<PharmacyModel> create(Map<String, dynamic> body) async {
    final data = await ApiService.post('Pharmacy', body) as Map<String, dynamic>;
    return PharmacyModel.fromJson(data);
  }

  static Future<PharmacyModel> update(int id, Map<String, dynamic> body) async {
    final data = await ApiService.put('Pharmacy/$id', body) as Map<String, dynamic>;
    return PharmacyModel.fromJson(data);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('Pharmacy/$id');
  }
}