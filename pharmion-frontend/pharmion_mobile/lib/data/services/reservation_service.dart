import '../models/prescription_model.dart';
import 'api_service.dart';

class ReservationService {
  static Future<List<_PrescriptionItemWithPrescription>>
      getPrescriptionsForProduct(int productId) async {
    final data = await ApiService.get(
        'Prescription/my?pageSize=50&status=1') as Map<String, dynamic>;

    final prescriptions = ((data['items'] as List?) ?? [])
        .map((p) => PrescriptionModel.fromJson(p as Map<String, dynamic>))
        .where((p) => !p.isExpired)
        .toList();

    final result = <_PrescriptionItemWithPrescription>[];
    for (final prescription in prescriptions) {
      for (final item in prescription.items) {
        if (item.productId == productId &&
            item.repeatsUsed < item.repeats) {
          result.add(_PrescriptionItemWithPrescription(
            prescription: prescription,
            item: item,
          ));
        }
      }
    }
    return result;
  }

  static Future<Map<String, dynamic>> addToReservation({
    required int pharmacyId,
    required int productId,
    required int quantity,
    int? prescriptionItemId,
    bool isSubstitutionAllowed = false,
    String? earlyDispenseReason,
    int? earlyDispenseReasonType,
  }) async {
    final body = <String, dynamic>{
      'pharmacyId': pharmacyId,
      'productId': productId,
      'quantity': quantity,
      'isSubstitutionAllowed': isSubstitutionAllowed,
      if (prescriptionItemId != null)
        'prescriptionItemId': prescriptionItemId,
      if (earlyDispenseReason != null)
        'earlyDispenseReason': earlyDispenseReason,
      if (earlyDispenseReasonType != null)
        'earlyDispenseReasonType': earlyDispenseReasonType,
    };

    return await ApiService.post('Reservation/add-to-reservation', body)
        as Map<String, dynamic>;
  }
}

class _PrescriptionItemWithPrescription {
  final PrescriptionModel prescription;
  final PrescriptionItemModel item;
  const _PrescriptionItemWithPrescription({
    required this.prescription,
    required this.item,
  });
}

class PrescriptionItemWithPrescription {
  final PrescriptionModel prescription;
  final PrescriptionItemModel item;
  const PrescriptionItemWithPrescription({
    required this.prescription,
    required this.item,
  });
}