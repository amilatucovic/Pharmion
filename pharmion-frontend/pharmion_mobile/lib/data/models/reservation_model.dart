class ReservationModel {
  final int id;
  final int patientId;
  final int pharmacyId;
  final String pharmacyName;
  final String reservationState;
  final String reservationStateDisplay;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? readyForPickupAt;
  final DateTime? pickedUpAt;
  final double totalAmount;
  final double patientPaysAmount;
  final double insurancePaysAmount;
  final DateTime? pickupDeadline;
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

  const ReservationModel({
    required this.id,
    required this.patientId,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.reservationState,
    required this.reservationStateDisplay,
    required this.createdAt,
    this.submittedAt,
    this.approvedAt,
    this.readyForPickupAt,
    this.pickedUpAt,
    required this.totalAmount,
    required this.patientPaysAmount,
    required this.insurancePaysAmount,
    this.pickupDeadline,
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
  });

  bool get isDraft => reservationState.contains('Draft');
  bool get isSubmitted => reservationState.contains('Submitted');
  bool get isApproved => reservationState.contains('Approved');
  bool get isReadyForPickup => reservationState.contains('ReadyForPickup');
  bool get isPickedUp => reservationState.contains('PickedUp');
  bool get isCancelled => reservationState.contains('Cancelled');
  bool get isRejected => reservationState.contains('Rejected');
  bool get isActive => isDraft || isSubmitted || isApproved || isReadyForPickup;
  bool get isHistory => isPickedUp || isCancelled || isRejected;

  factory ReservationModel.fromJson(Map<String, dynamic> json) =>
      ReservationModel(
        id: json['id'] as int? ?? 0,
        patientId: json['patientId'] as int? ?? 0,
        pharmacyId: json['pharmacyId'] as int? ?? 0,
        pharmacyName: json['pharmacyName'] as String? ?? '',
        reservationState: json['reservationState'] as String? ?? '',
        reservationStateDisplay:
            json['reservationStateDisplay'] as String? ?? '',
        createdAt: _parseDate(json['createdAt']) ?? DateTime(2000),
        submittedAt: _parseDate(json['submittedAt']),
        approvedAt: _parseDate(json['approvedAt']),
        readyForPickupAt: _parseDate(json['readyForPickupAt']),
        pickedUpAt: _parseDate(json['pickedUpAt']),
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
        patientPaysAmount:
            (json['patientPaysAmount'] as num?)?.toDouble() ?? 0.0,
        insurancePaysAmount:
            (json['insurancePaysAmount'] as num?)?.toDouble() ?? 0.0,
        pickupDeadline: _parseDate(json['pickupDeadline']),
        items: ((json['items'] as List?) ?? [])
            .map(
                (i) => ReservationItemModel.fromJson(i as Map<String, dynamic>))
            .toList(),
        cancellationReason: json['cancellationReason'] as String?,
        cancelledAt: json['cancelledAt'] != null
            ? DateTime.tryParse(json['cancelledAt'])
            : null,
        rejectionReason: json['rejectionReason'] as String?,
        isRefunded: json['isRefunded'] as bool? ?? false,
        allowedActions: ((json['allowedActions'] as List?) ?? [])
            .map((a) => a.toString())
            .toList(),
        isPaid: json['isPaid'] as bool? ?? false,
        paymentMethod: json['paymentMethod'] as String?,
        hasEarlyDispenseException:
            json['hasEarlyDispenseException'] as bool? ?? false,
        earlyDispenseExceptionStatus:
            json['earlyDispenseExceptionStatus'] as int?,
      );

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim().replaceFirst(' ', 'T');
    final withZ = s.endsWith('Z') ? s : '${s}Z';
    return DateTime.tryParse(withZ)?.toLocal();
  }

  String get stateDisplayFormatted => reservationStateDisplay.replaceAllMapped(
  RegExp(r'(?<=[a-z])(?=[A-Z])'),
  (match) => ' ',
);
}

class ReservationItemModel {
  final int id;
  final int reservationId;
  final int productId;
  final String productName;
  final String productType;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final double patientPart;
  final double insurancePart;
  final int? prescriptionItemId;
  final bool isSubstitutionAllowed;
  final bool requiresPrescription;

  const ReservationItemModel({
    required this.id,
    required this.reservationId,
    required this.productId,
    required this.productName,
    required this.productType,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.patientPart,
    required this.insurancePart,
    this.prescriptionItemId,
    required this.isSubstitutionAllowed,
    required this.requiresPrescription,
  });

  factory ReservationItemModel.fromJson(Map<String, dynamic> json) =>
      ReservationItemModel(
        id: json['id'] as int? ?? 0,
        reservationId: json['reservationId'] as int? ?? 0,
        productId: json['productId'] as int? ?? 0,
        productName: json['productName'] as String? ?? '',
        productType: json['productType'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
        lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
        patientPart: (json['patientPart'] as num?)?.toDouble() ?? 0.0,
        insurancePart: (json['insurancePart'] as num?)?.toDouble() ?? 0.0,
        prescriptionItemId: json['prescriptionItemId'] as int?,
        isSubstitutionAllowed: json['isSubstitutionAllowed'] as bool? ?? false,
        requiresPrescription: json['requiresPrescription'] as bool? ?? false,
      );
}
