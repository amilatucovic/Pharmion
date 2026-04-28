import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/pharmacy_model.dart';
import '../../data/models/prescription_model.dart';
import '../../data/models/reservation_model.dart';
import '../../data/services/dashboard_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/mobile_notification_bell.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  bool _loading = true;
  DashboardData? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await DashboardService.getData();
      if (mounted) setState(() => _data = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.kBg,
      body: RefreshIndicator(
        color: AppColors.kTeal,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF03989E).withValues(alpha: 0.5),
                        Color(0xFF026E73).withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/pharmion_logo.png',
                                height: 30,
                                fit: BoxFit.contain,
                              ),
                              const Spacer(),
                              const MobileNotificationBell(),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_greeting()}, ${auth.firstName ?? ''}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppDateUtils.formatDate(DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.kTeal),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SectionTitle(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      padding: EdgeInsets.zero,
                      children: [
                        _QuickAction(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'New Reservation',
                          color: AppColors.kTeal,
                          bg: AppColors.kTealLight,
                          onTap: () => context.go('/reservations'),
                        ),
                        _QuickAction(
                          icon: Icons.description_outlined,
                          label: 'My Prescriptions',
                          color: const Color(0xFF6366F1),
                          bg: const Color(0xFFEDE9FE),
                          onTap: () => context.go('/prescriptions'),
                        ),
                        _QuickAction(
                          icon: Icons.assignment_outlined,
                          label: 'My Reservations',
                          color: const Color(0xFFD97706),
                          bg: const Color(0xFFFEF3C7),
                          onTap: () => context.go('/reservations'),
                        ),
                        _QuickAction(
                          icon: Icons.local_pharmacy_outlined,
                          label: 'Find Pharmacy',
                          color: const Color(0xFF059669),
                          bg: const Color(0xFFD1FAE5),
                          onTap: () => context.go('/pharmacies'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Active Prescriptions ──────────────────────────────
                    _SectionHeader(
                      title: 'Active Prescriptions',
                      onSeeAll: () => context.go('/prescriptions'),
                    ),
                    const SizedBox(height: 12),
                    if (_data?.activePrescriptions.isEmpty ?? true)
                      _EmptyCard(
                        icon: Icons.description_outlined,
                        message: 'No active prescriptions',
                      )
                    else
                      ..._data!.activePrescriptions
                          .map((p) => _PrescriptionCard(prescription: p)),
                    const SizedBox(height: 24),

                    // ── Recent Reservations ───────────────────────────────
                    _SectionHeader(
                      title: 'Recent Reservations',
                      onSeeAll: () => context.go('/reservations'),
                    ),
                    const SizedBox(height: 12),
                    if (_data?.recentReservations.isEmpty ?? true)
                      _EmptyCard(
                        icon: Icons.assignment_outlined,
                        message: 'No recent reservations',
                      )
                    else
                      ..._data!.recentReservations.map((r) => GestureDetector(
                            onTap: () =>
                                context.go('/reservations/${r.id}', extra: r),
                            child: _ReservationCard(reservation: r),
                          )),
                    const SizedBox(height: 24),

                    // ── Pharmacies in Your City ───────────────────────────
                    _SectionHeader(
                      title: 'Pharmacies Near You',
                      onSeeAll: null,
                    ),
                    const SizedBox(height: 12),
                    if (_data?.nearbyPharmacies.isEmpty ?? true)
                      _EmptyCard(
                        icon: Icons.local_pharmacy_outlined,
                        message: 'No pharmacies found in your area',
                      )
                    else
                      ..._data!.nearbyPharmacies
                          .map((p) => _PharmacyCard(pharmacy: p)),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Widgets ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.kTextDark,
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextDark,
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.kTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      );
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.kTextLight),
          const SizedBox(width: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: AppColors.kTextMid),
          ),
        ]),
      );
}

// ─── Quick Action ─────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextDark,
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Prescription Card ────────────────────────────────────────────────────────

class _PrescriptionCard extends StatelessWidget {
  final PrescriptionModel prescription;
  const _PrescriptionCard({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final isExpiringSoon = prescription.isExpiringSoon;
    final isExpired = prescription.isExpired;

    Color statusColor;
    Color statusBg;
    String statusText;

    if (isExpired) {
      statusColor = AppColors.kError;
      statusBg = AppColors.kErrorLight;
      statusText = 'Expired';
    } else if (isExpiringSoon) {
      statusColor = AppColors.kWarning;
      statusBg = const Color(0xFFFEF3C7);
      statusText = 'Expiring soon';
    } else {
      statusColor = AppColors.kSuccess;
      statusBg = const Color(0xFFD1FAE5);
      statusText = 'Active';
    }

    return GestureDetector(
        onTap: () => context.go(
              '/prescriptions/${prescription.id}',
              extra: prescription,
            ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isExpiringSoon || isExpired
                  ? statusColor.withValues(alpha: 0.3)
                  : AppColors.kBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_outlined,
                  color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.doctorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextDark,
                      ),
                    ),
                    if (prescription.facility != null) ...[
                      const SizedBox(height: 2),
                      Text(prescription.facility!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.kTextMid)),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${prescription.items.length} medication${prescription.items.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.kTextMid),
                    ),
                    if (prescription.validTo != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Valid until: ${AppDateUtils.formatDate(prescription.validTo)}',
                        style: TextStyle(fontSize: 11, color: statusColor),
                      ),
                    ],
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ]),
        ));
  }
}

// ─── Reservation Card ─────────────────────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  const _ReservationCard({required this.reservation});

  Color get _statusColor {
    switch (reservation.reservationState.toLowerCase()) {
      case 'submitted':
        return AppColors.kWarning;
      case 'approved':
        return AppColors.kSuccess;
      case 'readyforpickup':
        return const Color(0xFF2563EB);
      case 'pickedup':
        return AppColors.kTeal;
      case 'rejected':
        return AppColors.kError;
      case 'cancelled':
        return AppColors.kTextMid;
      default:
        return AppColors.kTextMid;
    }
  }

  Color get _statusBg {
    switch (reservation.reservationState.toLowerCase()) {
      case 'submitted':
        return const Color(0xFFFEF3C7);
      case 'approved':
        return const Color(0xFFD1FAE5);
      case 'readyforpickup':
        return const Color(0xFFDBEAFE);
      case 'pickedup':
        return AppColors.kTealLight;
      case 'rejected':
        return AppColors.kErrorLight;
      case 'cancelled':
        return const Color(0xFFF1F5F9);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_outlined,
                color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                reservation.pharmacyName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${reservation.items.length} item${reservation.items.length != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.kTextMid),
              ),
              const SizedBox(height: 2),
              Text(
                AppDateUtils.formatDate(reservation.createdAt),
                style:
                    const TextStyle(fontSize: 11, color: AppColors.kTextLight),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              reservation.reservationStateDisplay,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
          ),
        ]),
      );
}

// ─── Pharmacy Card ────────────────────────────────────────────────────────────

class _PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  const _PharmacyCard({required this.pharmacy});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.go('/pharmacy', extra: pharmacy),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.kTealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_pharmacy_outlined,
                  color: AppColors.kTeal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacy.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pharmacy.address.isNotEmpty
                          ? pharmacy.address
                          : pharmacy.cityName,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.kTextMid),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pharmacy.phone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        pharmacy.phone!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.kTextLight),
                      ),
                    ],
                  ]),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.kTextLight, size: 20),
          ]),
        ),
      );
}
