import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/reservation_model.dart';
import '../../data/services/api_service.dart';
import 'payment_screen.dart';

class ReservationDetailScreen extends StatefulWidget {
  final ReservationModel reservation;
  const ReservationDetailScreen({super.key, required this.reservation});

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  bool _actionLoading = false;
  late ReservationModel _reservation;

  @override
  void initState() {
    super.initState();
    _reservation = widget.reservation;
  }

  Future<void> _updateItemQuantity(
      ReservationItemModel item, int newQty) async {
    try {
      await ApiService.put(
        'Reservation/${_reservation.id}/items/${item.id}',
        {'quantity': newQty},
      );
      final data = await ApiService.get('Reservation/${_reservation.id}')
          as Map<String, dynamic>;
      if (mounted)
        setState(() => _reservation = ReservationModel.fromJson(data));
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _deleteItem(ReservationItemModel item) async {
    try {
      await ApiService.delete(
          'Reservation/${_reservation.id}/items/${item.id}');
      final data = await ApiService.get('Reservation/${_reservation.id}')
          as Map<String, dynamic>;
      if (mounted)
        setState(() => _reservation = ReservationModel.fromJson(data));
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _submit() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Submit Reservation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            content: Text(
                'Submit reservation to ${_reservation.pharmacyName}? You will not be able to add or remove items after submitting.',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.kTextMid, height: 1.4)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Back',
                    style: TextStyle(color: AppColors.kTextMid)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Submit'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    setState(() => _actionLoading = true);
    try {
      await ApiService.post('Reservation/${_reservation.id}/submit', {});
      if (mounted) {
        _showSuccess('Reservation submitted successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await _showCancelDialog();
    if (!confirmed) return;
    setState(() => _actionLoading = true);
    try {
      await ApiService.post('Reservation/${_reservation.id}/cancel',
          {'reason': 'Cancelled by patient'});
      if (_reservation.isPaid && _reservation.paymentMethod == 'Stripe') {
        try {
          await ApiService.post('Payment/refund/${_reservation.id}', {});
        } catch (e) {
          debugPrint('Refund error: $e');
        }
      }
      if (mounted) {
        _showSuccess('Reservation cancelled.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<bool> _showCancelDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Cancel Reservation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            content: const Text(
                'Are you sure you want to cancel this reservation? This action cannot be undone.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.kTextMid, height: 1.4)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep',
                    style: TextStyle(color: AppColors.kTextMid)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kError,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel Reservation'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: AppColors.kSuccess,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg.replaceAll('Exception: ', '')),
      backgroundColor: AppColors.kError,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Color get _statusColor {
    if (_reservation.isDraft) return AppColors.kTextMid;
    if (_reservation.isSubmitted) return AppColors.kWarning;
    if (_reservation.isApproved) return AppColors.kSuccess;
    if (_reservation.isReadyForPickup) return const Color(0xFF2563EB);
    if (_reservation.isPickedUp) return AppColors.kTeal;
    if (_reservation.isRejected) return AppColors.kError;
    return AppColors.kTextMid;
  }

  Color get _statusBg {
    if (_reservation.isDraft) return const Color(0xFFF1F5F9);
    if (_reservation.isSubmitted) return const Color(0xFFFEF3C7);
    if (_reservation.isApproved) return const Color(0xFFD1FAE5);
    if (_reservation.isReadyForPickup) return const Color(0xFFDBEAFE);
    if (_reservation.isPickedUp) return AppColors.kTealLight;
    if (_reservation.isRejected) return AppColors.kErrorLight;
    return const Color(0xFFF1F5F9);
  }

  @override
  Widget build(BuildContext context) {
    final r = _reservation;
    final canSubmit = r.isDraft && r.items.isNotEmpty;
    final canCancel = r.isDraft || r.isSubmitted || r.isApproved;
    final canPay = r.isApproved && !r.isPaid;

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
            Text('RES-${r.id}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextDark)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(r.reservationStateDisplay,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: (canSubmit || canCancel || canPay)
          ? Container(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canPay) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final paid = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(reservation: r),
                            ),
                          );
                          if (paid == true && mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                        icon: const Icon(Icons.payment_outlined, size: 18),
                        label: const Text('Proceed to Payment'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (canCancel || canSubmit)
                    Row(children: [
                      if (canCancel) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _actionLoading ? null : _cancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.kError,
                              side: const BorderSide(color: AppColors.kError),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        if (canSubmit) const SizedBox(width: 12),
                      ],
                      if (canSubmit)
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _actionLoading ? null : _submit,
                            child: _actionLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Submit Reservation'),
                          ),
                        ),
                    ]),
                ],
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status banners ───────────────────────────────────────
            if (r.isReadyForPickup)
              _Banner(
                color: const Color(0xFF2563EB),
                bg: const Color(0xFFDBEAFE),
                icon: Icons.store_outlined,
                message: r.pickupDeadline != null
                    ? 'Ready for pickup! Please collect by ${AppDateUtils.formatDate(r.pickupDeadline)}'
                    : 'Your reservation is ready for pickup!',
              ),
            if (r.isDraft)
              _Banner(
                color: AppColors.kTextMid,
                bg: const Color(0xFFF1F5F9),
                icon: Icons.info_outline,
                message:
                    'This reservation is a draft. Review items and submit when ready.',
              ),
            if (r.hasEarlyDispenseException)
              _Banner(
                color: r.earlyDispenseExceptionStatus == 2
                    ? AppColors.kSuccess
                    : r.earlyDispenseExceptionStatus == 3
                        ? AppColors.kError
                        : const Color(0xFFD97706),
                bg: r.earlyDispenseExceptionStatus == 2
                    ? const Color(0xFFD1FAE5)
                    : r.earlyDispenseExceptionStatus == 3
                        ? AppColors.kErrorLight
                        : const Color(0xFFFEF3C7),
                icon: Icons.schedule_outlined,
                message: r.earlyDispenseExceptionStatus == 2
                    ? 'Early dispense request approved by pharmacist.'
                    : r.earlyDispenseExceptionStatus == 3
                        ? 'Early dispense request was rejected by pharmacist.'
                        : 'Early dispense request is pending pharmacist approval.',
              ),
            if (r.isRejected)
              _Banner(
                color: AppColors.kError,
                bg: AppColors.kErrorLight,
                icon: Icons.cancel_outlined,
                message: r.rejectionReason != null
                    ? 'Reservation rejected: ${r.rejectionReason}'
                    : 'This reservation was rejected by the pharmacy.',
              ),
            if (r.isCancelled)
              _Banner(
                color: AppColors.kTextMid,
                bg: const Color(0xFFF1F5F9),
                icon: Icons.block_outlined,
                message: r.cancellationReason != null
                    ? 'Reservation cancelled: ${r.cancellationReason}'
                    : 'This reservation has been cancelled.',
              ),
            if (r.isCancelled && r.isRefunded)
              _Banner(
                color: const Color(0xFF7C3AED),
                bg: const Color(0xFFEDE9FE),
                icon: Icons.undo_outlined,
                message:
                    'Your payment has been refunded. Please allow 5-10 business days for the funds to appear.',
              ),
            if (r.isPaid && !r.isReadyForPickup && !r.isPickedUp)
              _Banner(
                color: AppColors.kSuccess,
                bg: const Color(0xFFD1FAE5),
                icon: Icons.check_circle_outline,
                message: r.paymentMethod == 'Stripe'
                    ? 'Payment completed via Stripe. Awaiting pharmacy preparation.'
                    : 'Pay on pickup selected. Please pay when collecting.',
              ),

            // ── Pharmacy & dates ─────────────────────────────────────
            _InfoCard(children: [
              _DetailRow(
                icon: Icons.local_pharmacy_outlined,
                label: 'Pharmacy',
                value: r.pharmacyName,
              ),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Created',
                value: AppDateUtils.formatDateTime(r.createdAt),
              ),
              if (r.submittedAt != null)
                _DetailRow(
                  icon: Icons.send_outlined,
                  label: 'Submitted',
                  value: AppDateUtils.formatDateTime(r.submittedAt!),
                ),
              if (r.approvedAt != null)
                _DetailRow(
                  icon: Icons.check_circle_outline,
                  label: 'Approved',
                  value: AppDateUtils.formatDateTime(r.approvedAt!),
                ),
              if (r.pickedUpAt != null)
                _DetailRow(
                  icon: Icons.done_all_outlined,
                  label: 'Picked Up',
                  value: AppDateUtils.formatDateTime(r.pickedUpAt!),
                ),
            ]),
            const SizedBox(height: 16),

            // ── Items ────────────────────────────────────────────────
            const Text('Medication Items',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextDark)),
            if (r.items.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: const Row(children: [
                  Icon(Icons.medication_outlined,
                      size: 18, color: AppColors.kTextLight),
                  SizedBox(width: 12),
                  Text('No items in this reservation',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.kTextMid)),
                ]),
              )
            else ...[
              const SizedBox(height: 10),
              ...r.items.map((item) => _ItemCard(
                    item: item,
                    isDraft: r.isDraft,
                    onQuantityChanged: r.isDraft
                        ? (qty) => _updateItemQuantity(item, qty)
                        : null,
                    onDelete: r.isDraft
                        ? () async {
                            final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    title: const Text('Remove Item',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                    content: Text(
                                        'Remove "${item.productName}" from your reservation?',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.kTextMid,
                                            height: 1.4)),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Keep',
                                            style: TextStyle(
                                                color: AppColors.kTextMid)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.kError,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                            if (confirmed) _deleteItem(item);
                          }
                        : null,
                  )),
            ],
            const SizedBox(height: 16),

            // ── Totals ───────────────────────────────────────────────
            if (r.items.isNotEmpty) ...[
              Container(
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
                child: Column(children: [
                  _TotalRow(
                      label: 'Subtotal',
                      value: '${r.totalAmount.toStringAsFixed(2)} KM'),
                  if (r.insurancePaysAmount > 0) ...[
                    const SizedBox(height: 8),
                    _TotalRow(
                        label: 'Insurance covers',
                        value:
                            '- ${r.insurancePaysAmount.toStringAsFixed(2)} KM',
                        valueColor: AppColors.kSuccess),
                  ],
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.kBorder),
                  const SizedBox(height: 8),
                  _TotalRow(
                    label: 'You pay',
                    value: '${r.patientPaysAmount.toStringAsFixed(2)} KM',
                    bold: true,
                    valueColor: AppColors.kTeal,
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 16),

            // ── Timeline ─────────────────────────────────────────────
            const Text('Timeline',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextDark)),
            const SizedBox(height: 10),
            _Timeline(reservation: r),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
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
              child: Text(message,
                  style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w500,
                      height: 1.4)),
            ),
          ],
        ),
      );
}

// ─── Info Card ────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

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
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
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
            width: 80,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.kTextMid)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kTextDark)),
          ),
        ]),
      );
}

// ─── Item Card ────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final ReservationItemModel item;
  final bool isDraft;
  final void Function(int newQty)? onQuantityChanged;
  final VoidCallback? onDelete;
  const _ItemCard({
    required this.item,
    this.isDraft = false,
    this.onQuantityChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product info ─────────────────────────────────────────
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.kTealLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medication_outlined,
                    color: AppColors.kTeal, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextDark)),
                      const SizedBox(height: 2),
                      Text(
                        '${item.productType} · ${item.unitPrice.toStringAsFixed(2)} KM/unit',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.kTextMid),
                      ),
                      if (item.requiresPrescription) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Prescription',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.kError,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${item.lineTotal.toStringAsFixed(2)} KM',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextDark)),
                if (item.insurancePart > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'You: ${item.patientPart.toStringAsFixed(2)} KM',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.kSuccess),
                  ),
                ],
              ]),
            ]),

            // ── Draft controls ───────────────────────────────────────
            if (isDraft) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.kBorder),
              const SizedBox(height: 10),
              Row(children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.kBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    IconButton(
                      onPressed: item.quantity > 1
                          ? () => onQuantityChanged?.call(item.quantity - 1)
                          : null,
                      icon: const Icon(Icons.remove, size: 14),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      color: AppColors.kTextMid,
                      disabledColor: AppColors.kBorder,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${item.quantity}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kTextDark)),
                    ),
                    IconButton(
                      onPressed: () =>
                          onQuantityChanged?.call(item.quantity + 1),
                      icon: const Icon(Icons.add, size: 14),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      color: AppColors.kTeal,
                    ),
                  ]),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.kErrorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.delete_outline,
                          size: 14, color: AppColors.kError),
                      SizedBox(width: 4),
                      Text('Remove',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.kError,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ]),
            ],
          ],
        ),
      );
}

// ─── Total Row ────────────────────────────────────────────────────────────────
class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label,
            style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: bold ? AppColors.kTextDark : AppColors.kTextMid)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: valueColor ?? AppColors.kTextDark)),
      ]);
}

// ─── Timeline ─────────────────────────────────────────────────────────────────
class _Timeline extends StatelessWidget {
  final ReservationModel reservation;
  const _Timeline({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final steps = <_TimelineStep>[
      _TimelineStep(
        label: 'Draft Created',
        date: reservation.createdAt,
        done: true,
        icon: Icons.add_circle_outline,
      ),
      _TimelineStep(
        label: 'Submitted',
        date: reservation.submittedAt,
        done: reservation.submittedAt != null,
        icon: Icons.send_outlined,
      ),
      _TimelineStep(
        label: 'Approved',
        date: reservation.approvedAt,
        done: reservation.approvedAt != null,
        icon: Icons.check_circle_outline,
        skipped: reservation.isRejected,
        skippedLabel: 'Rejected',
      ),
      _TimelineStep(
        label: 'Ready for Pickup',
        date: reservation.readyForPickupAt,
        done: reservation.readyForPickupAt != null,
        icon: Icons.store_outlined,
      ),
      _TimelineStep(
        label: 'Picked Up',
        date: reservation.pickedUpAt,
        done: reservation.pickedUpAt != null,
        icon: Icons.done_all_outlined,
        skipped: reservation.isCancelled,
        skippedLabel: 'Cancelled',
      ),
    ];

    return Container(
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
      child: Column(
        children: steps.asMap().entries.map((e) {
          final i = e.key;
          final step = e.value;
          final isLast = i == steps.length - 1;

          Color dotColor;
          if (step.skipped) {
            dotColor = AppColors.kError;
          } else if (step.done) {
            dotColor = AppColors.kTeal;
          } else {
            dotColor = AppColors.kBorder;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: step.done || step.skipped
                        ? dotColor.withValues(alpha: 0.15)
                        : AppColors.kBorder.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.skipped ? Icons.close : step.icon,
                    size: 14,
                    color: step.done || step.skipped
                        ? dotColor
                        : AppColors.kTextLight,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 28,
                    color: step.done
                        ? AppColors.kTeal.withValues(alpha: 0.3)
                        : AppColors.kBorder,
                  ),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.skipped
                            ? (step.skippedLabel ?? step.label)
                            : step.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: step.done || step.skipped
                              ? AppColors.kTextDark
                              : AppColors.kTextLight,
                        ),
                      ),
                      if (step.date != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          AppDateUtils.formatDateTime(step.date!),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.kTextMid),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TimelineStep {
  final String label;
  final DateTime? date;
  final bool done;
  final IconData icon;
  final bool skipped;
  final String? skippedLabel;
  const _TimelineStep({
    required this.label,
    this.date,
    required this.done,
    required this.icon,
    this.skipped = false,
    this.skippedLabel,
  });
}
