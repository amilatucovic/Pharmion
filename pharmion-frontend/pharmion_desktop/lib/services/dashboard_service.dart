import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class DashboardStats {
  final int reservationsToday;
  final int activePatients;
  final int totalProducts;
  final List<TopProduct> topProducts;
  final List<RecentReservation> recentReservations;

  const DashboardStats({
    required this.reservationsToday,
    required this.activePatients,
    required this.totalProducts,
    required this.topProducts,
    required this.recentReservations,
  });
}

class TopProduct {
  final int rank;
  final String name;
  final int count;
  const TopProduct({
    required this.rank,
    required this.name,
    required this.count,
  });
}

class RecentReservation {
  final int id;
  final String patientName;
  final String pharmacyName;
  final String status;
  final DateTime createdAt;
  const RecentReservation({
    required this.id,
    required this.patientName,
    required this.pharmacyName,
    required this.status,
    required this.createdAt,
  });
}

class DashboardService {
  static Future<DashboardStats> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getBool('isAdministrator') ?? false;
    final pharmacyId = prefs.getInt('pharmacyId') ?? 0;

    final pharmacyFilter = (!isAdmin && pharmacyId > 0)
        ? '&pharmacyId=$pharmacyId'
        : '';

    int? cityId;
    if (!isAdmin) {
      cityId = prefs.getInt('cityId');

      if (cityId == null && pharmacyId > 0) {
        try {
          final pharmacy =
              await ApiService.get('Pharmacy/$pharmacyId')
                  as Map<String, dynamic>;
          cityId = pharmacy['cityId'] as int?;
          if (cityId != null) await prefs.setInt('cityId', cityId);
        } catch (_) {}
      }
    }

    final patientUrl = (!isAdmin && cityId != null)
        ? 'Patient?pageSize=1&includeTotalCount=true&cityId=$cityId'
        : 'Patient?pageSize=1&includeTotalCount=true';

    final reservationUrl =
        'Reservation?pageSize=200&retrieveAll=false$pharmacyFilter';

    final results = await Future.wait([
      ApiService.get(reservationUrl),
      ApiService.get(patientUrl),
      (!isAdmin && pharmacyId > 0)
          ? ApiService.get(
              'InventoryItem?pageSize=1&includeTotalCount=true&pharmacyId=$pharmacyId',
            )
          : ApiService.get('Product?pageSize=1&includeTotalCount=true'),
    ]);

    final reservationsData = results[0] as Map<String, dynamic>;
    final patientsData = results[1] as Map<String, dynamic>;
    final productsData = results[2] as Map<String, dynamic>;

    final allReservations = (reservationsData['items'] as List?) ?? [];

    return DashboardStats(
      reservationsToday: _countToday(allReservations),
      activePatients: patientsData['totalCount'] as int? ?? 0,
      totalProducts: productsData['totalCount'] as int? ?? 0,
      topProducts: _buildTopProducts(allReservations),
      recentReservations: _buildRecentReservations(allReservations),
    );
  }

  static int _countToday(List allReservations) {
    final today = DateTime.now();
    return allReservations.where((r) {
      final submitted = DateTime.tryParse(r['submittedAt'] ?? '');
      if (submitted == null) return false;
      return submitted.year == today.year &&
          submitted.month == today.month &&
          submitted.day == today.day;
    }).length;
  }

  static List<TopProduct> _buildTopProducts(List allReservations) {
    final productCounts = <int, Map<String, dynamic>>{};

    for (final r in allReservations) {
      final items = (r['items'] as List?) ?? [];
      for (final item in items) {
        final pid = item['productId'] as int?;
        final pname = item['productName'] as String? ?? 'Unknown';
        if (pid != null) {
          productCounts.putIfAbsent(pid, () => {'name': pname, 'count': 0});
          productCounts[pid]!['count'] =
              (productCounts[pid]!['count'] as int) + 1;
        }
      }
    }

    final sorted = productCounts.entries.toList()
      ..sort(
        (a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int),
      );

    return List.generate(
      sorted.take(5).length,
      (i) => TopProduct(
        rank: i + 1,
        name: sorted[i].value['name'] as String,
        count: sorted[i].value['count'] as int,
      ),
    );
  }

  static List<RecentReservation> _buildRecentReservations(
    List allReservations,
  ) {
    return allReservations.take(5).map((r) {
      final status =
          r['reservationStateDisplay'] as String? ??
          (r['reservationState'] as String? ?? 'Unknown').replaceAll(
            'ReservationState',
            '',
          );
      return RecentReservation(
        id: r['id'] as int? ?? 0,
        patientName: r['patientName'] as String? ?? 'N/A',
        pharmacyName: r['pharmacyName'] as String? ?? 'N/A',
        status: status,
        createdAt: DateTime.tryParse(r['createdAt'] ?? '') ?? DateTime(2000),
      );
    }).toList();
  }
}
