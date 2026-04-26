import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/services/reservation_service.dart';
import '../../data/services/api_service.dart';

class ReserveBottomSheet extends StatefulWidget {
  final InventoryItemModel inventoryItem;
  final bool isPrescriptionRequired;
  final String productName;
  final double price;

  const ReserveBottomSheet({
    super.key,
    required this.inventoryItem,
    required this.isPrescriptionRequired,
    required this.productName,
    required this.price,
  });

  static Future<bool?> show(
    BuildContext context, {
    required InventoryItemModel inventoryItem,
    required bool isPrescriptionRequired,
    required String productName,
    required double price,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReserveBottomSheet(
        inventoryItem: inventoryItem,
        isPrescriptionRequired: isPrescriptionRequired,
        productName: productName,
        price: price,
      ),
    );
  }

  @override
  State<ReserveBottomSheet> createState() => _ReserveBottomSheetState();
}

class _ReserveBottomSheetState extends State<ReserveBottomSheet> {
  bool _loading = true;
  bool _reserving = false;
  String? _error;
  List<PrescriptionItemWithPrescription> _prescriptionItems = [];
  PrescriptionItemWithPrescription? _selectedPrescriptionItem;
  int _quantity = 1;
  bool _earlyDispenseRequired = false;
  DateTime? _nextEligibleDate;
  int? _daysRemaining;
  int? _selectedReasonType;
  final _earlyReasonController = TextEditingController();
  String _getReasonLabel(int type) {
    switch (type) {
      case 1:
        return 'Urgent medical need';
      case 2:
        return 'Doctor recommendation';
      case 3:
        return 'Lost medication';
      case 4:
        return 'Travel';
      case 5:
        return 'Dose change';
      default:
        return 'Other';
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.isPrescriptionRequired) {
      try {
        final items = await ReservationService.getPrescriptionsForProduct(
            widget.inventoryItem.productId);
        if (mounted) {
          setState(() {
            _prescriptionItems = items
                .map((i) => PrescriptionItemWithPrescription(
                    prescription: i.prescription, item: i.item))
                .toList();
            if (_prescriptionItems.isNotEmpty) {
              _selectedPrescriptionItem = _prescriptionItems.first;
            }
          });
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _reserve({
    String? earlyDispenseReason,
    int? earlyDispenseReasonType,
  }) async {
    if (widget.isPrescriptionRequired && _selectedPrescriptionItem == null) {
      setState(() => _error = 'Please select a prescription item to continue.');
      return;
    }

    setState(() {
      _reserving = true;
      _error = null;
    });

    try {
      await ReservationService.addToReservation(
        pharmacyId: widget.inventoryItem.pharmacyId,
        productId: widget.inventoryItem.productId,
        quantity: _quantity,
        prescriptionItemId: _selectedPrescriptionItem?.item.id,
        earlyDispenseReason: earlyDispenseReason,
        earlyDispenseReasonType: earlyDispenseReasonType,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Added to your reservation!'),
          ]),
          backgroundColor: AppColors.kSuccess,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } on EarlyDispenseRequiredException catch (e) {
      // Backend vratio 409 — prikaži early dispense dialog
      if (mounted) {
        setState(() {
          _earlyDispenseRequired = true;
          _nextEligibleDate = e.nextEligibleDate;
          _daysRemaining = e.daysRemaining;
          _reserving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _reserving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.kTealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_shopping_cart_outlined,
                  color: AppColors.kTeal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add to Reservation',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextDark)),
                    Text(widget.productName,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.kTextMid),
                        overflow: TextOverflow.ellipsis),
                    Text('${widget.price.toStringAsFixed(2)} KM',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon:
                  const Icon(Icons.close, size: 20, color: AppColors.kTextMid),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.kBorder),
          const SizedBox(height: 20),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.kTeal),
              ),
            )
          else ...[
            // Error
            if (_error != null) ...[
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
                              fontSize: 13, color: AppColors.kError))),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Prescription required + no prescriptions
            if (widget.isPrescriptionRequired &&
                _prescriptionItems.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.kWarning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 20, color: AppColors.kWarning),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Prescription Required',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kWarning)),
                          SizedBox(height: 4),
                          Text(
                              'You don\'t have an active prescription for this medication. Please visit your doctor first.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.kTextMid,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.kTealLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.kTeal),
                  ),
                  child: const Center(
                    child: Text('Close',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kTeal)),
                  ),
                ),
              ),
            ],
            if (_earlyDispenseRequired) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.kWarning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.schedule_outlined,
                          size: 18, color: AppColors.kWarning),
                      const SizedBox(width: 8),
                      const Text('Early Dispense Request',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kWarning)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'Your therapy is scheduled until ${_nextEligibleDate != null ? '${_nextEligibleDate!.day}.${_nextEligibleDate!.month}.${_nextEligibleDate!.year}' : ''}. '
                      'You have $_daysRemaining day(s) remaining. Please select a reason for early pickup.',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.kTextMid, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reason type dropdown
              const Text('Reason for early pickup',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextMid)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedReasonType,
                hint: const Text('Select reason',
                    style: TextStyle(fontSize: 13, color: AppColors.kTextMid)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.kBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.kBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.kTeal, width: 2)),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 1, child: Text('Urgent medical need')),
                  DropdownMenuItem(
                      value: 2, child: Text('Doctor recommendation')),
                  DropdownMenuItem(value: 3, child: Text('Lost medication')),
                  DropdownMenuItem(value: 4, child: Text('Travel')),
                  DropdownMenuItem(value: 5, child: Text('Dose change')),
                  DropdownMenuItem(value: 99, child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _selectedReasonType = v),
              ),
              const SizedBox(height: 12),

              // Other reason text field
              if (_selectedReasonType == 99) ...[
                TextField(
                  controller: _earlyReasonController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Please describe your reason...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.kTextMid),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.kBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.kBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.kTeal, width: 2)),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _reserving || _selectedReasonType == null
                      ? null
                      : () => _reserve(
                            earlyDispenseReason: _selectedReasonType == 99
                                ? _earlyReasonController.text.trim()
                                : _getReasonLabel(_selectedReasonType!),
                            earlyDispenseReasonType: _selectedReasonType,
                          ),
                  child: _reserving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Early Request'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _earlyDispenseRequired = false;
                    _selectedReasonType = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kTextMid,
                    side: const BorderSide(color: AppColors.kBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              // Prescription selector
              if (widget.isPrescriptionRequired) ...[
                const Text('Select Prescription',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextMid)),
                const SizedBox(height: 8),
                ..._prescriptionItems.map((pi) => GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPrescriptionItem = pi),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _selectedPrescriptionItem == pi
                              ? AppColors.kTealLight
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedPrescriptionItem == pi
                                ? AppColors.kTeal
                                : AppColors.kBorder,
                            width: _selectedPrescriptionItem == pi ? 2 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            _selectedPrescriptionItem == pi
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: _selectedPrescriptionItem == pi
                                ? AppColors.kTeal
                                : AppColors.kTextLight,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dr. ${pi.prescription.doctorName}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.kTextDark)),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${pi.item.dosage} · ${pi.item.repeats - pi.item.repeatsUsed} refills left',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.kTextMid)),
                                ]),
                          ),
                        ]),
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              // Pharmacy info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.kSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Row(children: [
                  const Icon(Icons.local_pharmacy_outlined,
                      size: 16, color: AppColors.kTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.inventoryItem.pharmacyName,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.kTextDark),
                    ),
                  ),
                  Text(
                    '${widget.inventoryItem.availableQuantity} available',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.kTextMid),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Quantity selector
              Row(children: [
                const Text('Quantity',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextMid)),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.kBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    IconButton(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove, size: 16),
                      color: AppColors.kTextMid,
                      disabledColor: AppColors.kBorder,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text('$_quantity',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kTextDark)),
                    ),
                    IconButton(
                      onPressed:
                          _quantity < widget.inventoryItem.availableQuantity
                              ? () => setState(() => _quantity++)
                              : null,
                      icon: const Icon(Icons.add, size: 16),
                      color: AppColors.kTeal,
                      disabledColor: AppColors.kBorder,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _reserving ? null : _reserve,
                  child: _reserving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm Reservation'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
