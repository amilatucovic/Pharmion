import 'api_service.dart';

class ChronicDiseaseModel {
  final int id;
  final String code;
  final String name;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ChronicDiseaseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChronicDiseaseModel.fromJson(Map<String, dynamic> json) =>
      ChronicDiseaseModel(
        id: json['id'] as int? ?? 0,
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime(2000),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
      );
}

class PagedChronicDiseases {
  final List<ChronicDiseaseModel> items;
  final int totalCount;
  const PagedChronicDiseases({required this.items, required this.totalCount});
}

class ChronicDiseaseService {
  static Future<PagedChronicDiseases> getDiseases({
    int page = 0,
    int pageSize = 10,
    String? name,
    bool? isActive,
  }) async {
    final params = StringBuffer('ChronicDisease?includeTotalCount=true');
    params.write('&page=$page&pageSize=$pageSize');
    if (name != null && name.isNotEmpty) params.write('&name=$name');
    if (isActive != null) params.write('&isActive=$isActive');

    final data =
        await ApiService.get(params.toString()) as Map<String, dynamic>;
    final items = ((data['items'] as List?) ?? [])
        .map((e) => ChronicDiseaseModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PagedChronicDiseases(
      items: items,
      totalCount: data['totalCount'] as int? ?? items.length,
    );
  }

  static Future<ChronicDiseaseModel> create(Map<String, dynamic> body) async {
    final data =
        await ApiService.post('ChronicDisease', body) as Map<String, dynamic>;
    return ChronicDiseaseModel.fromJson(data);
  }

  static Future<ChronicDiseaseModel> update(
    int id,
    Map<String, dynamic> body,
  ) async {
    final data =
        await ApiService.put('ChronicDisease/$id', body)
            as Map<String, dynamic>;
    return ChronicDiseaseModel.fromJson(data);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('ChronicDisease/$id');
  }
}
