import 'api_service.dart';

class ReservationItemModel {
  final int id;
  final int productId;
  final String productName;
  final String productType;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final double patientPart;
  final double insurancePart;
  final bool requiresPrescription;
  final bool isSubstitutionAllowed;

  const ReservationItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productType,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.patientPart,
    required this.insurancePart,
    required this.requiresPrescription,
    required this.isSubstitutionAllowed,
  });

  factory ReservationItemModel.fromJson(Map<String, dynamic> json) {
    return ReservationItemModel(
      id: json['id'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String? ?? '',
      productType: json['productType'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
      patientPart: (json['patientPart'] as num?)?.toDouble() ?? 0.0,
      insurancePart: (json['insurancePart'] as num?)?.toDouble() ?? 0.0,
      requiresPrescription: json['requiresPrescription'] as bool? ?? false,
      isSubstitutionAllowed: json['isSubstitutionAllowed'] as bool? ?? false,
    );
  }
}

class PatientDetail {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String address;
  final String cityName;
  final int age;
  final bool isInsured;
  final List<String> chronicDiseases;

  const PatientDetail({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.cityName,
    required this.age,
    required this.isInsured,
    required this.chronicDiseases,
  });

  factory PatientDetail.fromJson(Map<String, dynamic> json) {
    return PatientDetail(
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      address: json['address'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      isInsured: json['isInsured'] as bool? ?? false,
      chronicDiseases:
          (json['chronicDiseases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class ReservationModel {
  final int id;
  final int patientId;
  final String patientName;
  final String patientEmail;
  final int pharmacyId;
  final String pharmacyName;
  final String reservationState;
  final String reservationStateDisplay;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? readyForPickupAt;
  final DateTime? pickedUpAt;
  final DateTime? pickupDeadline;
  final double totalAmount;
  final double patientPaysAmount;
  final double insurancePaysAmount;
  final List<ReservationItemModel> items;
  final List<String> allowedActions;
  final bool isPaid;
  final String? paymentMethod;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final String? rejectionReason;
  final bool isRefunded;
  final bool hasEarlyDispenseException;
  final int? earlyDispenseExceptionStatus;
  final bool paymentMethodSelected;

  const ReservationModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientEmail,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.reservationState,
    required this.reservationStateDisplay,
    required this.createdAt,
    this.submittedAt,
    this.approvedAt,
    this.readyForPickupAt,
    this.pickedUpAt,
    this.pickupDeadline,
    required this.totalAmount,
    required this.patientPaysAmount,
    required this.insurancePaysAmount,
    required this.items,
    required this.allowedActions,
    required this.isPaid,
    this.paymentMethod,
    this.cancellationReason,
    this.cancelledAt,
    this.rejectionReason,
    this.isRefunded = false,
    this.hasEarlyDispenseException = false,
    this.earlyDispenseExceptionStatus,
    required this.paymentMethodSelected,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as int? ?? 0,
      patientId: json['patientId'] as int? ?? 0,
      patientName: json['patientName'] as String? ?? '',
      patientEmail: json['patientEmail'] as String? ?? '',
      pharmacyId: json['pharmacyId'] as int? ?? 0,
      pharmacyName: json['pharmacyName'] as String? ?? '',
      reservationState: json['reservationState'] as String? ?? '',
      reservationStateDisplay: json['reservationStateDisplay'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime(2000),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'])
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'])
          : null,
      readyForPickupAt: json['readyForPickupAt'] != null
          ? DateTime.tryParse(json['readyForPickupAt'])
          : null,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.tryParse(json['pickedUpAt'])
          : null,
      pickupDeadline: json['pickupDeadline'] != null
          ? DateTime.tryParse(json['pickupDeadline'])
          : null,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      patientPaysAmount: (json['patientPaysAmount'] as num?)?.toDouble() ?? 0.0,
      insurancePaysAmount:
          (json['insurancePaysAmount'] as num?)?.toDouble() ?? 0.0,
      isPaid: json['isPaid'] as bool? ?? false,
      paymentMethod: json['paymentMethod'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'])
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      isRefunded: json['isRefunded'] as bool? ?? false,
      hasEarlyDispenseException:
          json['hasEarlyDispenseException'] as bool? ?? false,
      earlyDispenseExceptionStatus:
          json['earlyDispenseExceptionStatus'] as int?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (i) => ReservationItemModel.fromJson(i as Map<String, dynamic>),
              )
              .toList() ??
          [],
      allowedActions:
          (json['allowedActions'] as List<dynamic>?)
              ?.map((a) => a as String)
              .toList() ??
          [],
      paymentMethodSelected: json['paymentMethodSelected'] as bool? ?? false,
    );
  }
}

class PagedReservations {
  final List<ReservationModel> items;
  final int totalCount;

  const PagedReservations({required this.items, required this.totalCount});
}

class ReservationService {
  static Future<PagedReservations> getReservations({
    int page = 0,
    int pageSize = 10,
    String? state,
    String? patientName,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? pharmacyId,
  }) async {
    final params = StringBuffer('Reservation?includeTotalCount=true');
    params.write('&page=$page&pageSize=$pageSize');
    if (state != null && state.isNotEmpty) {
      params.write('&reservationState=$state');
    }
    if (patientName != null && patientName.isNotEmpty) {
      params.write('&patientName=$patientName');
    }
    if (dateFrom != null) {
      params.write('&createdFrom=${dateFrom.toIso8601String()}');
    }
    if (dateTo != null) params.write('&createdTo=${dateTo.toIso8601String()}');
    if (pharmacyId != null) params.write('&pharmacyId=$pharmacyId');
    final data =
        await ApiService.get(params.toString()) as Map<String, dynamic>;
    final rawItems = (data['items'] as List?) ?? [];

    final items = rawItems
        .map((r) => ReservationModel.fromJson(r as Map<String, dynamic>))
        .toList();

    return PagedReservations(
      items: items,
      totalCount: data['totalCount'] as int? ?? items.length,
    );
  }

  static Future<ReservationModel> getById(int id) async {
    final data =
        await ApiService.get('Reservation/$id') as Map<String, dynamic>;
    final reservation = ReservationModel.fromJson(data);

    
    final actionsData =
        await ApiService.get('Reservation/$id/allowed-actions')
            as Map<String, dynamic>;
    final actions =
        (actionsData['allowedActions'] as List?)
            ?.map((a) => a as String)
            .toList() ??
        [];

    return ReservationModel(
      id: reservation.id,
      patientId: reservation.patientId,
      patientName: reservation.patientName,
      patientEmail: reservation.patientEmail,
      pharmacyId: reservation.pharmacyId,
      pharmacyName: reservation.pharmacyName,
      reservationState: reservation.reservationState,
      reservationStateDisplay: reservation.reservationStateDisplay,
      createdAt: reservation.createdAt,
      submittedAt: reservation.submittedAt,
      approvedAt: reservation.approvedAt,
      readyForPickupAt: reservation.readyForPickupAt,
      pickedUpAt: reservation.pickedUpAt,
      pickupDeadline: reservation.pickupDeadline,
      totalAmount: reservation.totalAmount,
      patientPaysAmount: reservation.patientPaysAmount,
      insurancePaysAmount: reservation.insurancePaysAmount,
      items: reservation.items,
      allowedActions: actions,
      isPaid: reservation.isPaid,
      paymentMethod: reservation.paymentMethod,
      cancellationReason: reservation.cancellationReason,
      cancelledAt: reservation.cancelledAt,
      rejectionReason: reservation.rejectionReason,
      isRefunded: reservation.isRefunded,
      hasEarlyDispenseException: reservation.hasEarlyDispenseException,
      earlyDispenseExceptionStatus: reservation.earlyDispenseExceptionStatus,
      paymentMethodSelected: reservation.paymentMethodSelected,
    );
  }

  static Future<ReservationModel> markReady(int id) async {
    await ApiService.post('Reservation/$id/mark-ready', {});
    await Future.delayed(const Duration(milliseconds: 500));
    return getById(id);
  }

  static Future<ReservationModel> approve(int id) async {
    await ApiService.post('Reservation/$id/approve', {});
    return getById(id);
  }

  static Future<ReservationModel> reject(int id, String reason) async {
    await ApiService.post('Reservation/$id/reject', {'reason': reason});
    return getById(id);
  }

  static Future<ReservationModel> markPickedUp(int id) async {
    await ApiService.post('Reservation/$id/mark-picked-up', {});
    return getById(id);
  }

  static Future<PatientDetail> getPatientDetail(int patientId) async {
    final data =
        await ApiService.get('Patient/$patientId') as Map<String, dynamic>;
    return PatientDetail.fromJson(data);
  }

  static Future<void> refund(int reservationId) async {
    await ApiService.post('Payment/refund/$reservationId', {});
  }

  static Future<void> cancel(int id, String reason) async {
    await ApiService.post('Reservation/$id/cancel', {'reason': reason});
  }

  static List<String> get allStates => [
    'SubmittedReservationState',
    'ApprovedReservationState',
    'ReadyForPickupReservationState',
    'PickedUpReservationState',
    'RejectedReservationState',
    'CancelledReservationState',
  ];

  static String stateDisplayName(String state) => state
    .replaceAll('ReservationState', '')
    .replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (match) => ' ',
    );
}
