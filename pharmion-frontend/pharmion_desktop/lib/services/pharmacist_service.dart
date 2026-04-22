import 'api_service.dart';

class PharmacistModel {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String licenseNumber;
  final int pharmacyId;
  final String pharmacyName;
  final String pharmacyCity;
  final bool isAdministrator;
  final bool isActive;
  final String gender;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const PharmacistModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.licenseNumber,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyCity,
    required this.isAdministrator,
    required this.isActive,
    required this.gender,
    required this.createdAt,
    this.lastLoginAt,
  });

  String get fullName => '$firstName $lastName';

  factory PharmacistModel.fromJson(Map<String, dynamic> json) =>
      PharmacistModel(
        id: json['id'] as int? ?? 0,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        licenseNumber: json['licenseNumber'] as String? ?? '',
        pharmacyId: json['pharmacyId'] as int? ?? 0,
        pharmacyName: json['pharmacyName'] as String? ?? '',
        pharmacyCity: json['pharmacyCity'] as String? ?? '',
        isAdministrator: json['isAdministrator'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? true,
        gender: json['gender']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime(2000),
        lastLoginAt: json['lastLoginAt'] != null
            ? DateTime.tryParse(json['lastLoginAt'])
            : null,
      );
}

class PagedPharmacists {
  final List<PharmacistModel> items;
  final int totalCount;
  const PagedPharmacists({required this.items, required this.totalCount});
}

class PharmacistService {
  static Future<PagedPharmacists> getPharmacists({
    int page = 0,
    int pageSize = 10,
    String? name,
    int? pharmacyId,
    bool? isActive,
    bool? isAdministrator,
  }) async {
    final params = StringBuffer('Pharmacist?includeTotalCount=true');
    params.write('&page=$page&pageSize=$pageSize');
    if (name != null && name.isNotEmpty) params.write('&name=$name');
    if (pharmacyId != null) params.write('&pharmacyId=$pharmacyId');
    if (isActive != null) params.write('&isActive=$isActive');
    if (isAdministrator != null)
      params.write('&isAdministrator=$isAdministrator');

    final data =
        await ApiService.get(params.toString()) as Map<String, dynamic>;
    final items = ((data['items'] as List?) ?? [])
        .map((e) => PharmacistModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PagedPharmacists(
      items: items,
      totalCount: data['totalCount'] as int? ?? items.length,
    );
  }

  static Future<PharmacistModel> create(Map<String, dynamic> body) async {
    final data =
        await ApiService.post('Pharmacist', body) as Map<String, dynamic>;
    return PharmacistModel.fromJson(data);
  }

  static Future<PharmacistModel> update(
      int id, Map<String, dynamic> body) async {
    final data = await ApiService.put('Pharmacist/$id', body)
        as Map<String, dynamic>;
    return PharmacistModel.fromJson(data);
  }

  static Future<PharmacistModel> toggleActive(int id) async {
    final data =
        await ApiService.post('Pharmacist/$id/toggle-active', {})
            as Map<String, dynamic>;
    return PharmacistModel.fromJson(data);
  }
}