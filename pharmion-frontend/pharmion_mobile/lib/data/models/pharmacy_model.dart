class PharmacyModel {
  final int id;
  final String name;
  final String address;
  final String cityName;
  final int cityId;
  final String? phone;
  final String? email;
  final bool isActive;
  final String? workingHours;

  const PharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.cityName,
    required this.cityId,
    this.phone,
    this.email,
    required this.isActive,
    this.workingHours,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) => PharmacyModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        cityName: json['cityName'] as String? ?? '',
        cityId: json['cityId'] as int? ?? 0,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        workingHours: json['workingHours'] as String?,
      );
}