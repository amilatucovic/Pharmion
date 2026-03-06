import 'api_service.dart';

class PatientModel {
  final int id;
  final String firstName, lastName, username, email;
  final String phoneNumber, address, cityName;
  final int? cityId;
  final DateTime? dateOfBirth;
  final bool isInsured, isActive;
  final List<String> chronicDiseases;

  const PatientModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.cityName,
    this.cityId,
    this.dateOfBirth,
    required this.isInsured,
    required this.isActive,
    required this.chronicDiseases,
  });

  String get fullName => '$firstName $lastName';

  int get age {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as int? ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      address: json['address'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      cityId: json['cityId'] as int?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      isInsured: json['isInsured'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      chronicDiseases: (json['chronicDiseases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class PagedPatients {
  final List<PatientModel> items;
  final int totalCount;
  const PagedPatients({required this.items, required this.totalCount});
}

class PatientService {
  static Future<PagedPatients> getPatients({
    int page = 0,
    int pageSize = 10,
    String? name,
    bool? isInsured,
    int? cityId,
  }) async {
    final params = StringBuffer('Patient?includeTotalCount=true&retrieveAll=false');
    params.write('&page=$page&pageSize=$pageSize');
    if (name != null && name.isNotEmpty) params.write('&name=$name');
    if (isInsured != null) params.write('&isInsured=$isInsured');
    if (cityId != null) params.write('&cityId=$cityId');

    final data = await ApiService.get(params.toString()) as Map<String, dynamic>;
    final rawItems = (data['items'] as List?) ?? [];

    return PagedPatients(
      items: rawItems
          .map((p) => PatientModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      totalCount: data['totalCount'] as int? ?? 0,
    );
  }

  static Future<PatientModel> getById(int id) async {
    final data = await ApiService.get('Patient/$id') as Map<String, dynamic>;
    return PatientModel.fromJson(data);
  }
}