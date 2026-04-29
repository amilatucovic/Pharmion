import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/prescription_model.dart';
import '../../data/services/api_service.dart';
import 'package:go_router/go_router.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PrescriptionModel> _prescriptions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.get('Prescription/my?pageSize=100')
          as Map<String, dynamic>;
      final items = ((data['items'] as List?) ?? [])
          .map((p) => PrescriptionModel.fromJson(p as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _prescriptions = items);
    } catch (e) {
      if (mounted) {
       setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PrescriptionModel> get _active => _prescriptions
      .where((p) => p.status == '1' || p.statusDisplay == 'Active')
      .toList();

  List<PrescriptionModel> get _expiringSoon =>
      _active.where((p) => p.isExpiringSoon).toList();

  List<PrescriptionModel> get _inactive => _prescriptions
      .where((p) => p.status != '1' && p.statusDisplay != 'Active')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Prescriptions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.kTextDark,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.kTeal,
          unselectedLabelColor: AppColors.kTextMid,
          indicatorColor: AppColors.kTeal,
          indicatorWeight: 2,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(text: 'Active (${_active.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Expiring'),
                  if (_expiringSoon.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.kWarning,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_expiringSoon.length}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'Inactive (${_inactive.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kTeal))
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: AppColors.kTeal,
                  onRefresh: _load,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _PrescriptionList(
                        prescriptions: _active,
                        emptyMessage: 'No active prescriptions',
                        emptyIcon: Icons.description_outlined,
                      ),
                      _PrescriptionList(
                        prescriptions: _expiringSoon,
                        emptyMessage: 'No prescriptions expiring soon',
                        emptyIcon: Icons.schedule_outlined,
                      ),
                      _PrescriptionList(
                        prescriptions: _inactive,
                        emptyMessage: 'No inactive prescriptions',
                        emptyIcon: Icons.archive_outlined,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _PrescriptionList extends StatelessWidget {
  final List<PrescriptionModel> prescriptions;
  final String emptyMessage;
  final IconData emptyIcon;

  const _PrescriptionList({
    required this.prescriptions,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.kTealLight,
                shape: BoxShape.circle,
              ),
              child: Icon(emptyIcon, size: 32, color: AppColors.kTeal),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pull down to refresh',
              style: TextStyle(fontSize: 13, color: AppColors.kTextMid),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prescriptions.length,
      itemBuilder: (context, index) =>
          _PrescriptionCard(prescription: prescriptions[index]),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final PrescriptionModel prescription;
  const _PrescriptionCard({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final p = prescription;
    final isActive = p.statusDisplay == 'Active' || p.status == '1';
    final isCancelled = p.statusDisplay == 'Cancelled' || p.status == '3';

    Color statusColor;
    Color statusBg;
    String statusLabel;

    if (p.isExpired) {
      statusColor = AppColors.kError;
      statusBg = AppColors.kErrorLight;
      statusLabel = 'Expired';
    } else if (p.isExpiringSoon) {
      statusColor = AppColors.kWarning;
      statusBg = const Color(0xFFFEF3C7);
      statusLabel = 'Expiring Soon';
    } else if (isActive) {
      statusColor = AppColors.kSuccess;
      statusBg = const Color(0xFFD1FAE5);
      statusLabel = 'Active';
    } else if (isCancelled) {
      statusColor = AppColors.kTextMid;
      statusBg = const Color(0xFFF1F5F9);
      statusLabel = 'Cancelled';
    } else {
      statusColor = AppColors.kTextMid;
      statusBg = const Color(0xFFF1F5F9);
      statusLabel = p.statusDisplay;
    }

    final totalRepeatsLeft = p.items
        .fold<int>(0, (sum, item) => sum + (item.repeats - item.repeatsUsed));

    return GestureDetector(
      onTap: () => context.go('/prescriptions/${p.id}', extra: p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.kTealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined,
                      color: AppColors.kTeal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RX-${p.id}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'dr. med. ${p.doctorName}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.kTextMid),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.kBorder),
            const SizedBox(height: 12),

            ...p.items.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const Icon(Icons.medication_outlined,
                        size: 14, color: AppColors.kTeal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.kTextDark,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${item.repeatsUsed}/${item.repeats}',
                      style: TextStyle(
                        fontSize: 11,
                        color: item.repeatsUsed >= item.repeats
                            ? AppColors.kError
                            : AppColors.kTextMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]),
                )),
            if (p.items.length > 2)
              Text(
                '+${p.items.length - 2} more items',
                style: const TextStyle(fontSize: 11, color: AppColors.kTextMid),
              ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.kBorder),
            const SizedBox(height: 10),

            Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: AppColors.kTextLight),
              const SizedBox(width: 4),
              Text(
                'Issued ${AppDateUtils.formatDate(p.issuedAt)}',
                style: const TextStyle(fontSize: 11, color: AppColors.kTextMid),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: totalRepeatsLeft == 0
                      ? AppColors.kErrorLight
                      : AppColors.kTealLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  totalRepeatsLeft == 0
                      ? 'No repeats left'
                      : '$totalRepeatsLeft left',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: totalRepeatsLeft == 0
                          ? AppColors.kError
                          : AppColors.kTeal),
                ),
              ),
              const Spacer(),
              if (p.validTo != null) ...[
                Icon(
                  Icons.event_outlined,
                  size: 12,
                  color: p.isExpiringSoon
                      ? AppColors.kWarning
                      : AppColors.kTextLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Expires ${AppDateUtils.formatDate(p.validTo!)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: p.isExpiringSoon
                          ? AppColors.kWarning
                          : AppColors.kTextMid,
                      fontWeight:
                          p.isExpiringSoon ? FontWeight.w600 : FontWeight.w400),
                ),
              ],
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.kTextLight),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.kErrorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    size: 32, color: AppColors.kError),
              ),
              const SizedBox(height: 16),
              const Text('Something went wrong',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextDark)),
              const SizedBox(height: 8),
              Text(error,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.kTextMid)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
}
