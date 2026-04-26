import 'package:shared_preferences/shared_preferences.dart';
import '../models/pharmacy_model.dart';
import '../models/prescription_model.dart';
import '../models/reservation_model.dart';
import 'api_service.dart';
import '../../core/constants/app_constants.dart';

class DashboardData {
  final List<ReservationModel> recentReservations;
  final List<PrescriptionModel> activePrescriptions;
  final List<PharmacyModel> nearbyPharmacies;

  const DashboardData({
    required this.recentReservations,
    required this.activePrescriptions,
    required this.nearbyPharmacies,
  });
}

class DashboardService {
  static Future<DashboardData> getData() async {
    final prefs = await SharedPreferences.getInstance();
    final cityId = prefs.getInt(AppConstants.keyCityId);
    final userId = prefs.getInt(AppConstants.keyUserId) ?? 0;

    final results = await Future.wait([
      _getRecentReservations(userId),
      _getActivePrescriptions(userId),
      _getNearbyPharmacies(cityId),
    ]);

    return DashboardData(
      recentReservations: results[0] as List<ReservationModel>,
      activePrescriptions: results[1] as List<PrescriptionModel>,
      nearbyPharmacies: results[2] as List<PharmacyModel>,
    );
  }

  static Future<List<ReservationModel>> _getRecentReservations(
      int userId) async {
    try {
      final data = await ApiService.get('Reservation/by-patient/$userId')
          as List<dynamic>;
      final all = data
          .map((r) => ReservationModel.fromJson(r as Map<String, dynamic>))
          .toList();
      return all.take(3).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<PrescriptionModel>> _getActivePrescriptions(
      int userId) async {
    try {
      final data = await ApiService.get('Prescription/my?pageSize=5&status=1')
          as Map<String, dynamic>;
      return ((data['items'] as List?) ?? [])
          .map((p) => PrescriptionModel.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<PharmacyModel>> _getNearbyPharmacies(int? cityId) async {
    try {
      final url = cityId != null
          ? 'Pharmacy?pageSize=10&cityId=$cityId'
          : 'Pharmacy?pageSize=10';
      final data = await ApiService.get(url) as Map<String, dynamic>;
      return ((data['items'] as List?) ?? [])
          .map((p) => PharmacyModel.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
