import 'api_service.dart';

enum ExceptionStatus { pending, approved, rejected }

enum EarlyDispenseReasonType {
  urgent,
  travel,
  stockIssue,
  doctorRecommendation,
  other
}

class EarlyDispenseExceptionModel {
  final int id;
  final int prescriptionItemId;
  final String productName;
  final String dosage;
  final int periodDays;
  final DateTime? nextEligibleDispenseAt;
  final DateTime? lastDispensedAt;
  final int reservationId;
  final String patientName;
  final String patientEmail;
  final String pharmacyName;
  final int pharmacyId;
  final DateTime requestedAt;
  final String status;
  final String statusDisplay;
  final String reasonType;
  final String reasonTypeDisplay;
  final String? otherReason;
  final String? note;
  final DateTime? approvedAt;
  final String? approvedByPharmacistName;

  const EarlyDispenseExceptionModel({
    required this.id,
    required this.prescriptionItemId,
    required this.productName,
    required this.dosage,
    required this.periodDays,
    this.nextEligibleDispenseAt,
    this.lastDispensedAt,
    required this.reservationId,
    required this.patientName,
    required this.patientEmail,
    required this.pharmacyName,
    required this.pharmacyId,
    required this.requestedAt,
    required this.status,
    required this.statusDisplay,
    required this.reasonType,
    required this.reasonTypeDisplay,
    this.otherReason,
    this.note,
    this.approvedAt,
    this.approvedByPharmacistName,
  });

  factory EarlyDispenseExceptionModel.fromJson(Map<String, dynamic> json) =>
      EarlyDispenseExceptionModel(
        id: json['id'] as int? ?? 0,
        prescriptionItemId: json['prescriptionItemId'] as int? ?? 0,
        productName: json['productName'] as String? ?? '',
        dosage: json['dosage'] as String? ?? '',
        periodDays: json['periodDays'] as int? ?? 0,
        nextEligibleDispenseAt: _parseDate(json['nextEligibleDispenseAt']),
        lastDispensedAt: _parseDate(json['lastDispensedAt']),
        reservationId: json['reservationId'] as int? ?? 0,
        patientName: json['patientName'] as String? ?? '',
        patientEmail: json['patientEmail'] as String? ?? '',
        pharmacyName: json['pharmacyName'] as String? ?? '',
        pharmacyId: json['pharmacyId'] as int? ?? 0,
        requestedAt: _parseDate(json['requestedAt']) ?? DateTime(2000),
        status: json['status']?.toString() ?? '',
        statusDisplay: json['statusDisplay'] as String? ?? '',
        reasonType: json['reasonType']?.toString() ?? '',
        reasonTypeDisplay: json['reasonTypeDisplay'] as String? ?? '',
        otherReason: json['otherReason'] as String?,
        note: json['note'] as String?,
        approvedAt: _parseDate(json['approvedAt']),
        approvedByPharmacistName:
            json['approvedByPharmacistName'] as String?,
      );

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim().replaceFirst(' ', 'T');
    final withZ = s.endsWith('Z') ? s : '${s}Z';
    return DateTime.tryParse(withZ)?.toLocal();
  }
}

class PagedExceptions {
  final List<EarlyDispenseExceptionModel> items;
  final int totalCount;
  const PagedExceptions({required this.items, required this.totalCount});
}

class ExceptionService {
  static Future<PagedExceptions> getExceptions({
    int page = 0,
    int pageSize = 10,
    int? pharmacyId,
    String? status,
    String? reasonType,
    String? patientName,
  }) async {
    final params = StringBuffer(
        'EarlyDispenseException?includeTotalCount=true');
    params.write('&page=$page&pageSize=$pageSize');
    if (pharmacyId != null) params.write('&pharmacyId=$pharmacyId');
    if (status != null && status.isNotEmpty) params.write('&status=$status');
    if (reasonType != null && reasonType.isNotEmpty)
      params.write('&reasonType=$reasonType');
    if (patientName != null && patientName.isNotEmpty)
      params.write('&patientName=$patientName');

    final data =
        await ApiService.get(params.toString()) as Map<String, dynamic>;
    final items = ((data['items'] as List?) ?? [])
        .map((e) => EarlyDispenseExceptionModel.fromJson(
            e as Map<String, dynamic>))
        .toList();

    return PagedExceptions(
      items: items,
      totalCount: data['totalCount'] as int? ?? items.length,
    );
  }

  static Future<EarlyDispenseExceptionModel> approve(
      int id, {String? note}) async {
    final data = await ApiService.post(
        'EarlyDispenseException/$id/approve', {'note': note}) as Map<String, dynamic>;
    return EarlyDispenseExceptionModel.fromJson(data);
  }

  static Future<EarlyDispenseExceptionModel> reject(
      int id, {required String note}) async {
    final data = await ApiService.post(
        'EarlyDispenseException/$id/reject', {'note': note}) as Map<String, dynamic>;
    return EarlyDispenseExceptionModel.fromJson(data);
  }

  static String reasonTypeLabel(String reasonType) {
  switch (reasonType) {
    case '1':
    case 'Urgent':
      return 'Urgent';
    case '2':
    case 'DoctorRecommendation':
      return 'Doctor Recommendation';
    case '3':
    case 'LostMedication':
      return 'Lost Medication';
    case '4':
    case 'Travel':
      return 'Travel';
    case '5':
    case 'DoseChange':
      return 'Dose Change';
    case '99':
    case 'Other':
      return 'Other';
    default:
      return reasonType;
  }
}
}