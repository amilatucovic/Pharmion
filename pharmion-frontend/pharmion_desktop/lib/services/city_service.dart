import 'api_service.dart';

class CityModel {
  final int id;
  final String name;
  final String postalCode;

  const CityModel({
    required this.id,
    required this.name,
    required this.postalCode,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        postalCode: json['postalCode'] as String? ?? '',
      );
}

class PagedCities {
  final List<CityModel> items;
  final int totalCount;
  const PagedCities({required this.items, required this.totalCount});
}

class CityService {
  static Future<PagedCities> getCities({
    int page = 0,
    int pageSize = 10,
    String? name,
  }) async {
    final params = StringBuffer('City?includeTotalCount=true');
    params.write('&page=$page&pageSize=$pageSize');
    if (name != null && name.isNotEmpty) params.write('&name=$name');

    final data =
        await ApiService.get(params.toString()) as Map<String, dynamic>;
    final items = ((data['items'] as List?) ?? [])
        .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PagedCities(
      items: items,
      totalCount: data['totalCount'] as int? ?? items.length,
    );
  }

  static Future<CityModel> create(Map<String, dynamic> body) async {
    final data =
        await ApiService.post('City', body) as Map<String, dynamic>;
    return CityModel.fromJson(data);
  }

  static Future<CityModel> update(int id, Map<String, dynamic> body) async {
    final data =
        await ApiService.put('City/$id', body) as Map<String, dynamic>;
    return CityModel.fromJson(data);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('City/$id');
  }
}