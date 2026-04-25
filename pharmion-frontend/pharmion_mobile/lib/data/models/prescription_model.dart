class PrescriptionModel {
  final int id;
  final String doctorName;
  final String? facility;
  final String status;
  final String statusDisplay;
  final DateTime? validTo;
  final DateTime issuedAt;
  final List<PrescriptionItemModel> items;

  const PrescriptionModel({
    required this.id,
    required this.doctorName,
    this.facility,
    required this.status,
    required this.statusDisplay,
    this.validTo,
    required this.issuedAt,
    required this.items,
  });

  bool get isExpiringSoon {
    if (validTo == null) return false;
    final diff = validTo!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 30;
  }

  bool get isExpired {
    if (validTo == null) return false;
    return validTo!.isBefore(DateTime.now());
  }

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) =>
      PrescriptionModel(
        id: json['id'] as int? ?? 0,
        doctorName: json['doctorName'] as String? ?? '',
        facility: json['facility'] as String?,
        status: json['status']?.toString() ?? '',
        statusDisplay: json['statusDisplay'] as String? ??
            json['status']?.toString() ?? '',
        validTo: _parseDate(json['validTo']),
        issuedAt: _parseDate(json['issuedAt']) ?? DateTime(2000),
        items: ((json['items'] as List?) ?? [])
            .map((i) =>
                PrescriptionItemModel.fromJson(i as Map<String, dynamic>))
            .toList(),
      );

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim().replaceFirst(' ', 'T');
    final withZ = s.endsWith('Z') ? s : '${s}Z';
    return DateTime.tryParse(withZ)?.toLocal();
  }
}

class PrescriptionItemModel {
  final int id;
  final String productName;
  final String dosage;
  final int periodDays;
  final int repeats;
  final int repeatsUsed;
  final String therapyType;
  final DateTime? nextEligibleDispenseAt;
  final DateTime? lastDispensedAt;

  const PrescriptionItemModel({
    required this.id,
    required this.productName,
    required this.dosage,
    required this.periodDays,
    required this.repeats,
    required this.repeatsUsed,
    required this.therapyType,
    this.nextEligibleDispenseAt,
    this.lastDispensedAt,
  });

  factory PrescriptionItemModel.fromJson(Map<String, dynamic> json) =>
      PrescriptionItemModel(
        id: json['id'] as int? ?? 0,
        productName: json['productName'] as String? ?? '',
        dosage: json['dosage'] as String? ?? '',
        periodDays: json['periodDays'] as int? ?? 0,
        repeats: json['repeats'] as int? ?? 0,
        repeatsUsed: json['repeatsUsed'] as int? ?? 0,
        therapyType: json['therapyType']?.toString() ?? '',
        nextEligibleDispenseAt:
            _parseDate(json['nextEligibleDispenseAt']),
        lastDispensedAt: _parseDate(json['lastDispensedAt']),
      );

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim().replaceFirst(' ', 'T');
    final withZ = s.endsWith('Z') ? s : '${s}Z';
    return DateTime.tryParse(withZ)?.toLocal();
  }
}