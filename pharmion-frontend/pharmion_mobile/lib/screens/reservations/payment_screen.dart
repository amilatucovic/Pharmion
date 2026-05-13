import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/reservation_model.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final ReservationModel reservation;
  const PaymentScreen({super.key, required this.reservation});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;
  bool _isPaid = false;
  String? _error;
  int _selectedMethod = 1;
  Map<String, dynamic>? _payment;
  bool _loadingPayment = false;

  String _fmtAmount(double amount) => '${amount.toStringAsFixed(2)} KM';

  Future<void> _pay() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm Payment'),
      content: Text(
        _selectedMethod == 1
            ? 'You will be charged ${_fmtAmount(widget.reservation.patientPaysAmount)} via Stripe. Proceed?'
            : 'You confirm to pay ${_fmtAmount(widget.reservation.patientPaysAmount)} at the pharmacy on pickup. Proceed?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  setState(() {
    _loading = true;
    _error = null;
  });
  try {
    if (_selectedMethod == 1) {
      await _payWithStripe();
    } else {
      await _payOnPickup();
    }
  } catch (e) {
    if (mounted) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  Future<void> _payWithStripe() async {
  final data = await PaymentService.createPaymentIntent(
    reservationId: widget.reservation.id,
    method: 1,
  );

  final clientSecret = data['clientSecret'] as String?;
  if (clientSecret == null)
    throw Exception('Failed to create payment intent');

  await Stripe.instance.initPaymentSheet(
    paymentSheetParameters: SetupPaymentSheetParameters(
      paymentIntentClientSecret: clientSecret,
      merchantDisplayName: 'Pharmion',
      style: ThemeMode.light,
      appearance: PaymentSheetAppearance(
        colors: PaymentSheetAppearanceColors(primary: AppColors.kTeal),
      ),
    ),
  );

  await Stripe.instance.presentPaymentSheet();

  try {
    final checkData = await PaymentService.createPaymentIntent(
      reservationId: widget.reservation.id,
      method: 1,
    );
    final alreadyPaid = checkData['isPaid'] as bool? ?? false;
    if (alreadyPaid && mounted) {
      setState(() => _isPaid = true);
      return;
    }
  } catch (_) {}

  bool confirmed = false;
  for (int i = 0; i < 5; i++) {
    await Future.delayed(const Duration(seconds: 2));
    try {
      final paymentData = await ApiService.get(
        'Payment/by-reservation/${widget.reservation.id}',
      ) as Map<String, dynamic>;
      final isPaid = paymentData['isPaid'] as bool? ?? false;
      if (isPaid) {
        confirmed = true;
        break;
      }
    } catch (_) {}
  }

  if (mounted) {
    if (confirmed) {
      setState(() => _isPaid = true);
    } else {
      setState(() => _error =
          'Payment is still processing. Please wait a moment and check again.');
    }
  }
}

  Future<void> _payOnPickup() async {
  await PaymentService.createPaymentIntent(
    reservationId: widget.reservation.id,
    method: 2,
  );
  if (mounted) setState(() => _isPaid = true);
}

  @override
  void initState() {
    super.initState();
    _loadPaymentStatus();
  }

  Future<void> _loadPaymentStatus() async {
    setState(() => _loadingPayment = true);
    try {
      final data = await ApiService.get(
        'Payment/by-reservation/${widget.reservation.id}',
      ) as Map<String, dynamic>;

      final isPaid = data['isPaid'] as bool? ?? false;

      if (mounted) {
        setState(() {
          _payment = data;
          _isPaid = isPaid;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPayment = false);
    }
  }

  Widget build(BuildContext context) {
    final r = widget.reservation;
    int? _paymentStatusValue() {
      final s = _payment?['status'];
      if (s == null) return null;

      if (s is int) return s;
      return int.tryParse(s.toString());
    }

    final status = _paymentStatusValue();
    final paymentIsPaid = _payment?['isPaid'] as bool? ?? false;
    final hasPendingPayment = !paymentIsPaid && status == 1;

    if (_isPaid) {
      return Scaffold(
        backgroundColor: AppColors.kBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: AppColors.kTextDark),
            onPressed: () => Navigator.pop(context, true),
          ),
          title: const Text('Payment',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextDark)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.kSuccess,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  _selectedMethod == 1
                      ? 'Payment Successful!'
                      : 'Pay on Pickup Selected',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kTextDark),
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedMethod == 1
                      ? 'Your payment has been processed. The pharmacy will prepare your medications.'
                      : 'Please pay when you collect your medications from the pharmacy.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.kTextMid, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Back to Reservation'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.kTextDark),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text('Payment',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextDark)),
      ),
      bottomNavigationBar: Container(
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
        child: ElevatedButton.icon(
          onPressed: (_loading || _loadingPayment || hasPendingPayment) ? null : _pay,
          icon: (_loading || _loadingPayment)
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Icon(
                  _selectedMethod == 1
                      ? Icons.lock_outlined
                      : Icons.store_outlined,
                  size: 18,
                ),
          label: Text(
            _loading || _loadingPayment
                ? 'Processing...'
                : hasPendingPayment
                    ? 'Payment is pending...'
                    : _selectedMethod == 1
                        ? 'Pay ${_fmtAmount(r.patientPaysAmount)}'
                        : 'Confirm Pay on Pickup',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                  const Text('Order Summary',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextDark)),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.kBorder),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.local_pharmacy_outlined,
                        size: 16, color: AppColors.kTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(r.pharmacyName,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.kTextMid)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.medication_outlined,
                        size: 16, color: AppColors.kTeal),
                    const SizedBox(width: 8),
                    Text(
                        '${r.items.length} item${r.items.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.kTextMid)),
                  ]),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.kBorder),
                  const SizedBox(height: 12),
                  if (r.insurancePaysAmount > 0) ...[
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.kTextMid)),
                          Text(_fmtAmount(r.totalAmount),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.kTextMid)),
                        ]),
                    const SizedBox(height: 6),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Insurance covers',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.kTextMid)),
                          Text('- ${_fmtAmount(r.insurancePaysAmount)}',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.kSuccess)),
                        ]),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.kBorder),
                    const SizedBox(height: 8),
                  ],
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('You pay',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.kTextDark)),
                        Text(_fmtAmount(r.patientPaysAmount),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.kTeal)),
                      ]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Payment Method',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextDark)),
            const SizedBox(height: 12),
            _MethodCard(
              selected: _selectedMethod == 1,
              icon: Icons.credit_card_outlined,
              title: 'Pay with Stripe',
              subtitle: 'Secure online payment via card',
              onTap: () => setState(() => _selectedMethod = 1),
            ),
            const SizedBox(height: 10),
            _MethodCard(
              selected: _selectedMethod == 2,
              icon: Icons.store_outlined,
              title: 'Pay on Pickup',
              subtitle: 'Pay in cash or card at the pharmacy',
              onTap: () => setState(() => _selectedMethod = 2),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.kErrorLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.kError.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: AppColors.kError),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.kError)),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.kTealLight : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.kTeal : AppColors.kBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? AppColors.kTeal : AppColors.kTealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 20, color: selected ? Colors.white : AppColors.kTeal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.kTeal
                                : AppColors.kTextDark)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.kTextMid)),
                  ]),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.kTeal : AppColors.kTextLight,
              size: 20,
            ),
          ]),
        ),
      );
}
