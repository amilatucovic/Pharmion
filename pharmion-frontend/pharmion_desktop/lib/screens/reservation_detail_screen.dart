import 'package:flutter/material.dart';
import '../services/reservation_service.dart';
import '../theme/app_theme.dart';

class ReservationDetailScreen extends StatefulWidget {
  final int reservationId;
  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  bool _loading = true;
  ReservationModel? _reservation;
  String? _error;
  PatientDetail? _patient;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ReservationService.getById(widget.reservationId);
      final p = await ReservationService.getPatientDetail(r.patientId);
      if (mounted) {
        setState(() {
          _reservation = r;
          _patient = p;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshReservation() async {
  try {
    final r = await ReservationService.getById(widget.reservationId);
    if (mounted) setState(() => _reservation = r);
  } catch (e) {
    debugPrint('Refresh error: $e');
  }
}

  Future<void> _approve() async {
    final confirmed = await _showConfirmDialog(
      title: 'Approve Reservation',
      message: 'Are you sure you want to approve this reservation?',
      confirmLabel: 'Approve',
      confirmColor: const Color(0xFF059669),
    );
    if (!confirmed) return;

    try {
      await ReservationService.approve(widget.reservationId);
      await _refreshReservation();
      if (mounted) _showSuccess('Reservation approved successfully.');
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _reject() async {
    final reason = await _showRejectDialog();
    if (reason == null || reason.isEmpty) return;

    try {
      await ReservationService.reject(widget.reservationId, reason);
      await _refreshReservation();
      if (mounted) _showSuccess('Reservation rejected.');
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _markReady() async {
    final confirmed = await _showConfirmDialog(
      title: 'Mark as Ready for Pickup',
      message:
          'Confirm that the medications are prepared and ready for pickup?',
      confirmLabel: 'Mark Ready',
      confirmColor: const Color(0xFF2563EB),
    );
    if (!confirmed) return;

   try {
     await ReservationService.markReady(widget.reservationId);
     await _refreshReservation();
     if (mounted) _showSuccess('Reservation marked as ready for pickup.');
   } catch (e) {
     if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
   }
  }

  Future<void> _markPickedUp() async {
    final confirmed = await _showConfirmDialog(
      title: 'Mark as Picked Up',
      message: 'Confirm that the patient has picked up their medications?',
      confirmLabel: 'Confirm Pickup',
      confirmColor: AppColors.kTeal,
    );
    if (!confirmed) return;

    try {
      await ReservationService.markPickedUp(widget.reservationId);
      await _refreshReservation();
      if (mounted) _showSuccess('Reservation marked as picked up.');
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.kTextMid),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reject Reservation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.kTeal,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.kTextMid),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      body: Column(
        children: [
          // Top bar
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.kTextMid,
                  ),
                ),
                const SizedBox(width: 4),
                // Breadcrumb
                const Text(
                  'Reservations',
                  style: TextStyle(color: AppColors.kTextMid, fontSize: 14),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.kTextMid,
                ),
                Text(
                  _reservation != null ? 'RES-${_reservation!.id}' : 'Details',
                  style: const TextStyle(
                    color: AppColors.kTextDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_reservation != null) ...[
                  const SizedBox(width: 12),
                  _StatusBadge(status: _reservation!.reservationStateDisplay),
                ],
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.kTeal),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.kTextMid),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kTeal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final r = _reservation!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header info ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: _formatDateTime(r.createdAt),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.local_pharmacy_outlined,
                        label: 'Pharmacy',
                        value: r.pharmacyName,
                      ),
                      if (r.submittedAt != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.send_outlined,
                          label: 'Submitted',
                          value: _formatDateTime(r.submittedAt!),
                        ),
                      ],
                      if (r.pickupDeadline != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.timer_outlined,
                          label: 'Pickup deadline',
                          value: _formatDateTime(r.pickupDeadline!),
                          valueColor: const Color(0xFFD97706),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Financials
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.kBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total: ${r.totalAmount.toStringAsFixed(2)} KM',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.kTextDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patient pays: ${r.patientPaysAmount.toStringAsFixed(2)} KM',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.kTextMid,
                        ),
                      ),
                      Text(
                        'Insurance: ${r.insurancePaysAmount.toStringAsFixed(2)} KM',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.kTextMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient info
              Expanded(
                flex: 2,
                child: _SectionCard(
                  title: 'Patient Information',
                  icon: Icons.person_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        label: 'Full name',
                        value: _patient?.fullName ?? r.patientName,
                      ),
                      _DetailRow(
                        label: 'Email',
                        value: _patient?.email ?? r.patientEmail,
                      ),
                      if (_patient != null) ...[
                        _DetailRow(
                          label: 'Phone',
                          value: _patient!.phoneNumber,
                        ),
                        _DetailRow(
                          label: 'Address',
                          value: '${_patient!.address}, ${_patient!.cityName}',
                        ),
                        _DetailRow(
                          label: 'Age',
                          value: '${_patient!.age} years',
                        ),
                        _DetailRow(
                          label: 'Insured',
                          value: _patient!.isInsured ? 'Yes' : 'No',
                        ),
                        _DetailRow(
                          label: 'Chronic conditions',
                          value: _patient!.chronicDiseases.isEmpty
                              ? 'None recorded'
                              : _patient!.chronicDiseases.join(', '),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Items
              Expanded(
                flex: 3,
                child: _SectionCard(
                  title: 'Medication Items',
                  icon: Icons.medication_outlined,
                  child: Column(
                    children: [
                      // Items header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Product',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kTextMid,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                'Qty',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kTextMid,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                'Price',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kTextMid,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ...r.items.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: i < r.items.length - 1
                                ? const Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFF1F5F9),
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.kTextDark,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (item.requiresPrescription)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              right: 4,
                                              top: 2,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Rx',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFFD97706),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          item.productType,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.kTextMid,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  'x${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.kTextMid,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  '${item.lineTotal.toStringAsFixed(2)} KM',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.kTextDark,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Action buttons ────────────────────────────────────────────
          if (r.allowedActions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.kTextMid,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Available actions:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.kTextMid,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Wrap(
                    spacing: 10,
                    children: r.allowedActions
                        .map(
                          (action) => _ActionButton(
                            action: action,
                            onTap: () => _handleAction(action),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'Approve':
        _approve();
        break;
      case 'Reject':
        _reject();
        break;
      case 'MarkAsReady':
        _markReady();
        break;
      case 'MarkAsPickedUp':
        _markPickedUp();
        break;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(icon, size: 16, color: AppColors.kTeal),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.kTextMid,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.kTextDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.kTextMid),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.kTextMid),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppColors.kTextDark,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'draft':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        break;
      case 'submitted':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case 'approved':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        break;
      case 'readyforpickup':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        break;
      case 'pickedup':
        bg = AppColors.kTealLight;
        fg = AppColors.kTeal;
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
      case 'cancelled':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String action;
  final VoidCallback onTap;

  const _ActionButton({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (action) {
      case 'Approve':
        bg = const Color(0xFF059669);
        fg = Colors.white;
        icon = Icons.check_circle_outline;
        label = 'Approve';
        break;
      case 'Reject':
        bg = const Color(0xFFDC2626);
        fg = Colors.white;
        icon = Icons.cancel_outlined;
        label = 'Reject';
        break;
      case 'MarkAsReady':
        bg = const Color(0xFF2563EB);
        fg = Colors.white;
        icon = Icons.local_shipping_outlined;
        label = 'Mark Ready';
        break;
      case 'MarkAsPickedUp':
        bg = AppColors.kTeal;
        fg = Colors.white;
        icon = Icons.done_all;
        label = 'Mark Picked Up';
        break;
      case 'Cancel':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        icon = Icons.block_outlined;
        label = 'Cancel';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = AppColors.kTextMid;
        icon = Icons.touch_app_outlined;
        label = action;
    }

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
