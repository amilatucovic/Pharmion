import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/reservation_model.dart';
import '../../data/services/api_service.dart';
import 'reservation_detail_screen.dart';
import '../../core/errors/app_exception.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  List<ReservationModel> _active = [];
  List<ReservationModel> _history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(AppConstants.keyUserId) ?? 0;

      final data = await ApiService.get('Reservation/by-patient/$userId')
          as List<dynamic>;

      final all = data
          .map((r) => ReservationModel.fromJson(r as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _active = all.where((r) => r.isActive).toList();
          _history = all.where((r) => r.isHistory).toList();
        });
      }
    } on UnauthorizedException {
      if (mounted) context.read<AuthProvider>().logout();
    } on NetworkException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(ReservationModel r) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationDetailScreen(reservation: r),
      ),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Reservations'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.kTeal,
          unselectedLabelColor: AppColors.kTextMid,
          indicatorColor: AppColors.kTeal,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Active'),
                  if (_active.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.kTeal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_active.length}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kTeal))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.kError),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.kTextMid)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Try Again'),
                      ),
                    ]),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.kTeal,
                  onRefresh: _loadData,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ReservationList(
                        reservations: _active,
                        emptyIcon: Icons.assignment_outlined,
                        emptyTitle: 'No active reservations',
                        emptySubtitle:
                            'Add medications to your reservation from the pharmacy screen.',
                        onTap: _openDetail,
                      ),
                      _ReservationList(
                        reservations: _history,
                        emptyIcon: Icons.history_rounded,
                        emptyTitle: 'No reservation history',
                        emptySubtitle:
                            'Your completed and cancelled reservations will appear here.',
                        onTap: _openDetail,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ReservationList extends StatelessWidget {
  final List<ReservationModel> reservations;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(ReservationModel) onTap;

  const _ReservationList({
    required this.reservations,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.kTealLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(emptyIcon, color: AppColors.kTeal, size: 32),
            ),
            const SizedBox(height: 16),
            Text(emptyTitle,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextDark)),
            const SizedBox(height: 8),
            Text(emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.kTextMid, height: 1.4)),
          ]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: reservations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ReservationCard(
        reservation: reservations[i],
        onTap: () => onTap(reservations[i]),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onTap;
  const _ReservationCard({required this.reservation, required this.onTap});

  Color get _statusColor {
    if (reservation.isDraft) return AppColors.kTextMid;
    if (reservation.isSubmitted) return AppColors.kWarning;
    if (reservation.isApproved) return AppColors.kSuccess;
    if (reservation.isReadyForPickup) return const Color(0xFF2563EB);
    if (reservation.isPickedUp) return AppColors.kTeal;
    if (reservation.isRejected) return AppColors.kError;
    return AppColors.kTextMid;
  }

  Color get _statusBg {
    if (reservation.isDraft) return const Color(0xFFF1F5F9);
    if (reservation.isSubmitted) return const Color(0xFFFEF3C7);
    if (reservation.isApproved) return const Color(0xFFD1FAE5);
    if (reservation.isReadyForPickup) return const Color(0xFFDBEAFE);
    if (reservation.isPickedUp) return AppColors.kTealLight;
    if (reservation.isRejected) return AppColors.kErrorLight;
    return const Color(0xFFF1F5F9);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: reservation.isReadyForPickup
                  ? const Color(0xFF2563EB).withValues(alpha: 0.3)
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.assignment_outlined,
                      color: _statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reservation.pharmacyName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kTextDark)),
                        const SizedBox(height: 2),
                        Text(
                          AppDateUtils.formatDate(reservation.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.kTextMid),
                        ),
                      ]),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reservation.stateDisplayFormatted,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.kBorder),
              const SizedBox(height: 10),
              ...reservation.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.medication_outlined,
                          size: 14, color: AppColors.kTextLight),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${item.productName} x${item.quantity}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.kTextMid),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.lineTotal.toStringAsFixed(2)} KM',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.kTextMid),
                      ),
                    ]),
                  )),
              if (reservation.items.length > 2)
                Text(
                  '+${reservation.items.length - 2} more item(s)',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.kTextLight),
                ),
              const SizedBox(height: 8),
              Row(children: [
                const Spacer(),
                Text(
                  'Total: ${reservation.totalAmount.toStringAsFixed(2)} KM',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kTextDark),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.kTextLight),
              ]),
              if (reservation.isReadyForPickup) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.store_outlined,
                        size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    const Text('Ready for pickup!',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB))),
                    if (reservation.pickupDeadline != null) ...[
                      const Spacer(),
                      Text(
                        'Until ${AppDateUtils.formatDate(reservation.pickupDeadline)}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ]),
                ),
              ],
            ],
          ),
        ),
      );
}
