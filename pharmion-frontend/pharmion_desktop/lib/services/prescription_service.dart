import 'api_service.dart';

class PrescriptionItemModel {
  final int id;
  final int prescriptionId;
  final int productId;
  final String productName;
  final String dosage;
  final int quantityPerPeriod;
  final int periodDays;
  final int repeats;
  final int repeatsUsed;
  final String therapyType;
  final String therapyTypeDisplay;
  final DateTime? lastDispensedAt;
  final DateTime? nextEligibleDispenseAt;

  const PrescriptionItemModel({
    required this.id,
    required this.prescriptionId,
    required this.productId,
    required this.productName,
    required this.dosage,
    required this.quantityPerPeriod,
    required this.periodDays,
    required this.repeats,
    required this.repeatsUsed,
    required this.therapyType,
    required this.therapyTypeDisplay,
    this.lastDispensedAt,
    this.nextEligibleDispenseAt,
  });

  bool get isExhausted => repeatsUsed >= repeats;
  int get repeatsRemaining => repeats - repeatsUsed;

  factory PrescriptionItemModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionItemModel(
      id: json['id'] as int? ?? 0,
      prescriptionId: json['prescriptionId'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      quantityPerPeriod: json['quantityPerPeriod'] as int? ?? 0,
      periodDays: json['periodDays'] as int? ?? 0,
      repeats: json['repeats'] as int? ?? 0,
      repeatsUsed: json['repeatsUsed'] as int? ?? 0,
      therapyType: json['therapyType'] as String? ?? '',
      therapyTypeDisplay: json['therapyTypeDisplay'] as String? ?? '',
      lastDispensedAt: json['lastDispensedAt'] != null
          ? DateTime.tryParse(json['lastDispensedAt'])
          : null,
      nextEligibleDispenseAt: json['nextEligibleDispenseAt'] != null
          ? DateTime.tryParse(json['nextEligibleDispenseAt'])
          : null,
    );
  }
}

class PrescriptionModel {
  final int id;
  final int patientId;
  final String patientName;
  final int createdByPharmacistId;
  final String pharmacistName;
  final String doctorName;
  final String? facility;
  final DateTime issuedAt;
  final DateTime? validFrom;
  final DateTime? validTo;
  final String status;
  final String statusDisplay;
  final String? notes;
  final List<PrescriptionItemModel> items;

  const PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.createdByPharmacistId,
    required this.pharmacistName,
    required this.doctorName,
    this.facility,
    required this.issuedAt,
    this.validFrom,
    this.validTo,
    required this.status,
    required this.statusDisplay,
    this.notes,
    required this.items,
  });

  bool get isActive => status == 'Active';
  bool get isExpired =>
      validTo != null && validTo!.isBefore(DateTime.now());

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] as int? ?? 0,
      patientId: json['patientId'] as int? ?? 0,
      patientName: json['patientName'] as String? ?? '',
      createdByPharmacistId: json['createdByPharmacistId'] as int? ?? 0,
      pharmacistName: json['pharmacistName'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      facility: json['facility'] as String?,
      issuedAt: DateTime.tryParse(json['issuedAt'] ?? '') ?? DateTime(2000),
      validFrom: json['validFrom'] != null
          ? DateTime.tryParse(json['validFrom'])
          : null,
      validTo: json['validTo'] != null
          ? DateTime.tryParse(json['validTo'])
          : null,
      status: json['status'] as String? ?? '',
      statusDisplay: json['statusDisplay'] as String? ?? '',
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((i) =>
                  PrescriptionItemModel.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PagedPrescriptions {
  final List<PrescriptionModel> items;
  final int totalCount;
  const PagedPrescriptions({required this.items, required this.totalCount});
}

class PrescriptionService {
  static Future<PagedPrescriptions> getPrescriptions({
    int page = 0,
    int pageSize = 10,
    int? patientId,
    String? status,
    String? patientName,
  }) async {
    final params =
        StringBuffer('Prescription?includeTotalCount=true&retrieveAll=false');
    params.write('&page=$page&pageSize=$pageSize');
    if (patientId != null) params.write('&patientId=$patientId');
    if (status != null && status.isNotEmpty) params.write('&status=$status');
    if (patientName != null && patientName.isNotEmpty) 
    params.write('&patientName=$patientName');

    final data =
        await ApiService.get(params.toString()) as Map<String, dynamic>;
    final rawItems = (data['items'] as List?) ?? [];

    return PagedPrescriptions(
      items: rawItems
          .map((p) =>
              PrescriptionModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      totalCount: data['totalCount'] as int? ?? 0,
    );
  }

  static Future<PrescriptionModel> getById(int id) async {
    final data =
        await ApiService.get('Prescription/$id') as Map<String, dynamic>;
    return PrescriptionModel.fromJson(data);
  }

  static Future<PrescriptionModel> create(
      Map<String, dynamic> request) async {
    final data = await ApiService.post('Prescription', request)
        as Map<String, dynamic>;
    return PrescriptionModel.fromJson(data);
  }

  static Future<PrescriptionModel> update(
      int id, Map<String, dynamic> request) async {
    final data = await ApiService.put('Prescription/$id', request)
        as Map<String, dynamic>;
    return PrescriptionModel.fromJson(data);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('Prescription/$id');
  }

  static Future<void> cancel(int id) async {
  await ApiService.post('Prescription/$id/cancel', {});
  }

  static List<String> get allStatuses => ['Active', 'Completed', 'Cancelled'];

  static String therapyTypeDisplay(String type) {
    switch (type) {
      case 'ChronicMonthly':
        return 'Chronic (Monthly)';
      case 'ChronicQuarterly':
        return 'Chronic (Quarterly)';
      case 'Acute':
        return 'Acute';
      default:
        return type;
    }
  }
}