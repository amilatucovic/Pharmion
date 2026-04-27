import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/prescription_model.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  final PrescriptionModel prescription;
  const PrescriptionDetailScreen({super.key, required this.prescription});

  Color get _statusColor {
    if (prescription.isExpired) return AppColors.kError;
    if (prescription.isExpiringSoon) return AppColors.kWarning;
    final s = prescription.statusDisplay.toLowerCase();
    if (s == 'active') return AppColors.kSuccess;
    return AppColors.kTextMid;
  }

  Color get _statusBg {
    if (prescription.isExpired) return AppColors.kErrorLight;
    if (prescription.isExpiringSoon) return const Color(0xFFFEF3C7);
    final s = prescription.statusDisplay.toLowerCase();
    if (s == 'active') return const Color(0xFFD1FAE5);
    return const Color(0xFFF1F5F9);
  }

  String get _statusLabel {
    if (prescription.isExpired) return 'Expired';
    if (prescription.isExpiringSoon) return 'Expiring Soon';
    return prescription.statusDisplay;
  }

  @override
  Widget build(BuildContext context) {
    final p = prescription;

    return Scaffold(
      backgroundColor: AppColors.kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.kTextDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RX-${p.id}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextDark),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _statusLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Expiry banner ──────────────────────────────────────
            if (p.isExpiringSoon && !p.isExpired)
              _Banner(
                color: AppColors.kWarning,
                bg: const Color(0xFFFEF3C7),
                icon: Icons.schedule_outlined,
                message: p.validTo != null
                    ? 'This prescription expires on ${AppDateUtils.formatDate(p.validTo!)}. Please renew soon.'
                    : 'This prescription is expiring soon.',
              ),
            if (p.isExpired)
              _Banner(
                color: AppColors.kError,
                bg: AppColors.kErrorLight,
                icon: Icons.error_outline,
                message: 'This prescription has expired and can no longer be used.',
              ),

            // ── Prescription info ──────────────────────────────────
            _SectionCard(
              children: [
                _DetailRow(
                  icon: Icons.person_outlined,
                  label: 'Doctor',
                  value: 'Dr. ${p.doctorName}',
                ),
                if (p.facility != null && p.facility!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.local_hospital_outlined,
                    label: 'Facility',
                    value: p.facility!,
                  ),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Issued',
                  value: AppDateUtils.formatDate(p.issuedAt),
                ),
                if (p.validTo != null)
                  _DetailRow(
                    icon: Icons.event_outlined,
                    label: 'Expires',
                    value: AppDateUtils.formatDate(p.validTo!),
                    valueColor: p.isExpired
                        ? AppColors.kError
                        : p.isExpiringSoon
                            ? AppColors.kWarning
                            : null,
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Medications ────────────────────────────────────────
            const Text(
              'Medications',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextDark),
            ),
            const SizedBox(height: 10),
            ...p.items.map((item) => _MedicationCard(item: item)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Medication Card ──────────────────────────────────────────────────────────
class _MedicationCard extends StatelessWidget {
  final PrescriptionItemModel item;
  const _MedicationCard({required this.item});

  bool get _isExhausted => item.repeatsUsed >= item.repeats;
  bool get _isAvailable =>
      !_isExhausted &&
      (item.nextEligibleDispenseAt == null ||
          item.nextEligibleDispenseAt!.isBefore(DateTime.now()));

  int get _daysUntilNext {
    if (item.nextEligibleDispenseAt == null) return 0;
    return item.nextEligibleDispenseAt!.difference(DateTime.now()).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    Color chipBg;
    String chipLabel;
    IconData chipIcon;

    if (_isExhausted) {
      chipColor = AppColors.kError;
      chipBg = AppColors.kErrorLight;
      chipLabel = 'Exhausted';
      chipIcon = Icons.block_outlined;
    } else if (_isAvailable) {
      chipColor = AppColors.kSuccess;
      chipBg = const Color(0xFFD1FAE5);
      chipLabel = 'Available';
      chipIcon = Icons.check_circle_outline;
    } else {
      chipColor = const Color(0xFF2563EB);
      chipBg = const Color(0xFFDBEAFE);
      chipLabel = 'In $_daysUntilNext days';
      chipIcon = Icons.schedule_outlined;
    }

    return Container(
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
          // ── Header ──────────────────────────────────────────────
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.kTealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medication_outlined,
                  color: AppColors.kTeal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.dosage,
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
                color: chipBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(chipIcon, size: 12, color: chipColor),
                const SizedBox(width: 4),
                Text(
                  chipLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: chipColor),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.kBorder),
          const SizedBox(height: 12),

          // ── Details grid ─────────────────────────────────────────
          Row(children: [
            Expanded(
              child: _MiniStat(
                label: 'Therapy',
                value: item.therapyType == '1' ? 'Chronic' : 'Acute',
                icon: Icons.repeat_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                label: 'Period',
                value: '${item.periodDays} days',
                icon: Icons.date_range_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                label: 'Repeats',
                value: '${item.repeatsUsed}/${item.repeats}',
                icon: Icons.loop_outlined,
                valueColor: _isExhausted ? AppColors.kError : null,
              ),
            ),
          ]),

          // ── Repeat progress bar ──────────────────────────────────
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.repeats > 0 ? item.repeatsUsed / item.repeats : 0,
              backgroundColor: AppColors.kBorder,
              color: _isExhausted
                  ? AppColors.kError
                  : item.repeatsUsed / item.repeats > 0.7
                      ? AppColors.kWarning
                      : AppColors.kTeal,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isExhausted
                ? 'All repeats used'
                : '${item.repeats - item.repeatsUsed} repeat(s) remaining',
            style: TextStyle(
              fontSize: 11,
              color: _isExhausted ? AppColors.kError : AppColors.kTextMid,
              fontWeight: _isExhausted ? FontWeight.w600 : FontWeight.w400,
            ),
          ),

          // ── Next eligible ────────────────────────────────────────
          if (!_isExhausted && !_isAvailable && item.nextEligibleDispenseAt != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.schedule_outlined,
                    size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Next pickup available on ${AppDateUtils.formatDate(item.nextEligibleDispenseAt!)}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ]),
            ),
          ],

          // ── Last dispensed ───────────────────────────────────────
          if (item.lastDispensedAt != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.check_circle_outline,
                  size: 13, color: AppColors.kTextLight),
              const SizedBox(width: 6),
              Text(
                'Last picked up: ${AppDateUtils.formatDate(item.lastDispensedAt!)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.kTextMid),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

// ─── Mini Stat ────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.kBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 11, color: AppColors.kTextLight),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.kTextMid)),
            ]),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.kTextDark),
            ),
          ],
        ),
      );
}

// ─── Banner ───────────────────────────────────────────────────────────────────
class _Banner extends StatelessWidget {
  final Color color;
  final Color bg;
  final IconData icon;
  final String message;
  const _Banner({
    required this.color,
    required this.bg,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                    height: 1.4),
              ),
            ),
          ],
        ),
      );
}

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      );
}

// ─── Detail Row ───────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.kTealLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: AppColors.kTeal),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.kTextMid)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.kTextDark),
            ),
          ),
        ]),
      );
}