import 'package:flutter/material.dart';
import '../services/prescription_service.dart';
import '../services/patient_service.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final PrescriptionModel? prescription;
  final int? preselectedPatientId;

  const PrescriptionFormScreen({
    super.key,
    this.prescription,
    this.preselectedPatientId,
  });

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  bool get _isEdit => widget.prescription != null;

  // Form controllers
  final _doctorNameController = TextEditingController();
  final _facilityController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _validFrom;
  DateTime? _validTo;

  // Patient search
  final _patientSearchController = TextEditingController();
  PatientModel? _selectedPatient;
  List<PatientModel> _patientSuggestions = [];
  bool _searchingPatients = false;

  // Items
  final List<_PrescriptionItemForm> _items = [];

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.prescription!;
      _doctorNameController.text = p.doctorName;
      _facilityController.text = p.facility ?? '';
      _notesController.text = p.notes ?? '';
      _validFrom = p.validFrom;
      _validTo = p.validTo;
      // Preload items
      for (final item in p.items) {
        _items.add(
          _PrescriptionItemForm(
            productId: item.productId,
            productName: item.productName,
            dosageController: TextEditingController(text: item.dosage),
            quantityPerPeriodController: TextEditingController(
              text: item.quantityPerPeriod.toString(),
            ),
            periodDaysController: TextEditingController(
              text: item.periodDays.toString(),
            ),
            repeatsController: TextEditingController(
              text: item.repeats.toString(),
            ),
            therapyType: item.therapyType,
          ),
        );
      }
    }
    if (widget.preselectedPatientId != null) {
      _loadPreselectedPatient(widget.preselectedPatientId!);
    }
  }

  Future<void> _loadPreselectedPatient(int patientId) async {
    try {
      final p = await PatientService.getById(patientId);
      if (mounted) {
        setState(() {
          _selectedPatient = p;
          _patientSearchController.text = p.fullName;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _facilityController.dispose();
    _notesController.dispose();
    _patientSearchController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _searchPatients(String query) async {
    if (query.length < 2) {
      setState(() => _patientSuggestions = []);
      return;
    }
    setState(() => _searchingPatients = true);
    try {
      final result = await PatientService.getPatients(name: query, pageSize: 5);
      if (mounted) setState(() => _patientSuggestions = result.items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _searchingPatients = false);
    }
  }

  void _addItem() {
    setState(
      () => _items.add(
        _PrescriptionItemForm(
          dosageController: TextEditingController(),
          quantityPerPeriodController: TextEditingController(),
          periodDaysController: TextEditingController(),
          repeatsController: TextEditingController(text: '1'),
        ),
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _save() async {
    // Validacija
    if (!_isEdit && _selectedPatient == null) {
      setState(() => _error = 'Please select a patient.');
      return;
    }
    if (_doctorNameController.text.trim().isEmpty) {
      setState(() => _error = 'Doctor name is required.');
      return;
    }
    if (_items.isEmpty) {
      setState(() => _error = 'At least one medication item is required.');
      return;
    }
    for (final item in _items) {
      if (item.productId == null || item.productName == null) {
        setState(() => _error = 'All items must have a product selected.');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    if (_isEdit) {
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Save Changes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'Are you sure you want to update this prescription? Existing medication items will be replaced with the new ones.',
              ),
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
                    backgroundColor: AppColors.kTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) {
        setState(() => _saving = false);
        return;
      }
    }

    try {
      final request = {
        'patientId': _isEdit
            ? widget.prescription!.patientId
            : _selectedPatient!.id,
        'doctorName': _doctorNameController.text.trim(),
        'facility': _facilityController.text.trim().isEmpty
            ? null
            : _facilityController.text.trim(),
        'validFrom': _validFrom?.toIso8601String(),
        'validTo': _validTo?.toIso8601String(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'items': _items
            .map(
              (item) => {
                'productId': item.productId,
                'dosage': item.dosageController.text.trim(),
                'quantityPerPeriod':
                    int.tryParse(item.quantityPerPeriodController.text) ?? 1,
                'periodDays':
                    int.tryParse(item.periodDaysController.text) ?? 30,
                'repeats': int.tryParse(item.repeatsController.text) ?? 1,
                'therapyType': _therapyTypeToInt(item.therapyType),
              },
            )
            .toList(),
      };

      if (_isEdit) {
        await PrescriptionService.update(widget.prescription!.id, request);
      } else {
        await PrescriptionService.create(request);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _therapyTypeToInt(String? type) {
    switch (type) {
      case 'ChronicMonthly':
        return 1;
      case 'ChronicQuarterly':
        return 2;
      case 'Acute':
        return 3;
      default:
        return 3;
    }
  }

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
                const Text(
                  'Prescriptions',
                  style: TextStyle(color: AppColors.kTextMid, fontSize: 14),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.kTextMid,
                ),
                Text(
                  _isEdit
                      ? 'Edit RX-${widget.prescription!.id}'
                      : 'New Prescription',
                  style: const TextStyle(
                    color: AppColors.kTextDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kTextMid,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 15),
                  label: Text(
                    _isEdit ? 'Save Changes' : 'Create Prescription',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column - General info
                      Expanded(
                        child: _SectionCard(
                          title: 'General Information',
                          icon: Icons.description_outlined,
                          child: Column(
                            children: [
                              // Patient (samo za create)
                              if (!_isEdit) ...[
                                _FormLabel(text: 'Patient *'),
                                const SizedBox(height: 6),
                                _PatientSearchField(
                                  controller: _patientSearchController,
                                  selectedPatient: _selectedPatient,
                                  suggestions: _patientSuggestions,
                                  isSearching: _searchingPatients,
                                  onSearch: _searchPatients,
                                  onSelected: (patient) {
                                    setState(() {
                                      _selectedPatient = patient;
                                      _patientSearchController.text =
                                          patient.fullName;
                                      _patientSuggestions = [];
                                    });
                                  },
                                  onClear: () {
                                    setState(() {
                                      _selectedPatient = null;
                                      _patientSearchController.clear();
                                      _patientSuggestions = [];
                                    });
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],
                              if (_isEdit) ...[
                                _FormLabel(text: 'Patient'),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.kBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    widget.prescription!.patientName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.kTextDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              _FormLabel(text: 'Doctor Name *'),
                              const SizedBox(height: 6),
                              _StyledTextField(
                                controller: _doctorNameController,
                                hint: 'e.g. dr. med. Almedina Omanović',
                              ),
                              const SizedBox(height: 14),
                              _FormLabel(text: 'Facility'),
                              const SizedBox(height: 6),
                              _StyledTextField(
                                controller: _facilityController,
                                hint: 'e.g. Dom zdravlja Mostar',
                              ),
                              const SizedBox(height: 14),
                              _FormLabel(text: 'Notes'),
                              const SizedBox(height: 6),
                              _StyledTextField(
                                controller: _notesController,
                                hint: 'Additional notes...',
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Right column - Dates
                      SizedBox(
                        width: 280,
                        child: _SectionCard(
                          title: 'Validity Period',
                          icon: Icons.calendar_today_outlined,
                          child: Column(
                            children: [
                              _FormLabel(text: 'Valid From'),
                              const SizedBox(height: 6),
                              _DatePickerButton(
                                date: _validFrom,
                                hint: 'Select date',
                                onPick: (date) =>
                                    setState(() => _validFrom = date),
                                onClear: () =>
                                    setState(() => _validFrom = null),
                              ),
                              const SizedBox(height: 14),
                              _FormLabel(text: 'Valid To'),
                              const SizedBox(height: 6),
                              _DatePickerButton(
                                date: _validTo,
                                hint: 'Select date',
                                onPick: (date) =>
                                    setState(() => _validTo = date),
                                onClear: () => setState(() => _validTo = null),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Items section
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.medication_outlined,
                              size: 16,
                              color: AppColors.kTeal,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Medication Items',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.kTextDark,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _addItem,
                              icon: const Icon(Icons.add, size: 14),
                              label: const Text(
                                'Add Item',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.kTeal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),

                        if (_items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.medication_outlined,
                                    size: 36,
                                    color: AppColors.kTextMid.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No items added yet. Click "Add Item" to add medications.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.kTextMid,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...(_items.asMap().entries.map(
                            (entry) => _PrescriptionItemFormWidget(
                              key: ValueKey(entry.key),
                              index: entry.key,
                              item: entry.value,
                              onRemove: () => _removeItem(entry.key),
                              onChanged: () => setState(() {}),
                            ),
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item Form Model ──────────────────────────────────────────────────────────

class _PrescriptionItemForm {
  int? productId;
  String? productName;
  final TextEditingController dosageController;
  final TextEditingController quantityPerPeriodController;
  final TextEditingController periodDaysController;
  final TextEditingController repeatsController;
  String? therapyType;

  _PrescriptionItemForm({
    this.productId,
    this.productName,
    required this.dosageController,
    required this.quantityPerPeriodController,
    required this.periodDaysController,
    required this.repeatsController,
    this.therapyType,
  });

  void dispose() {
    dosageController.dispose();
    quantityPerPeriodController.dispose();
    periodDaysController.dispose();
    repeatsController.dispose();
  }
}

// ─── Item Form Widget ─────────────────────────────────────────────────────────

class _PrescriptionItemFormWidget extends StatefulWidget {
  final int index;
  final _PrescriptionItemForm item;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _PrescriptionItemFormWidget({
    super.key,
    required this.index,
    required this.item,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_PrescriptionItemFormWidget> createState() =>
      _PrescriptionItemFormWidgetState();
}

class _PrescriptionItemFormWidgetState
    extends State<_PrescriptionItemFormWidget> {
  final _productSearchController = TextEditingController();
  List<Map<String, dynamic>> _productSuggestions = [];
  bool _searchingProducts = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.productName != null) {
      _productSearchController.text = widget.item.productName!;
    }
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchProducts(String query) async {
    if (query.length < 2) {
      setState(() => _productSuggestions = []);
      return;
    }
    setState(() => _searchingProducts = true);
    try {
      final data = await _fetchProducts(query);
      if (mounted) setState(() => _productSuggestions = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _searchingProducts = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProducts(String query) async {
    // Koristimo ApiService direktno za products search
    try {
      final result = await _callProductsApi(query);
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _callProductsApi(String query) async {
    // Import ApiService i dohvati producte
    final data = await _ProductSearchHelper.search(query);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.kTeal,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Medication Item',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextDark,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  final confirmed =
                      await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Remove Item',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                            'Are you sure you want to remove "${widget.item.productName ?? 'this item'}" from the prescription?',
                          ),
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
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (confirmed) widget.onRemove();
                },
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(0xFFDC2626),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Product search
          _FormLabel(text: 'Product *'),
          const SizedBox(height: 6),
          _ProductSearchField(
            controller: _productSearchController,
            selectedProductName: item.productName,
            suggestions: _productSuggestions,
            isSearching: _searchingProducts,
            onSearch: _searchProducts,
            onSelected: (id, name) {
              setState(() {
                item.productId = id;
                item.productName = name;
                _productSearchController.text = name;
                _productSuggestions = [];
              });
              widget.onChanged();
            },
            onClear: () {
              setState(() {
                item.productId = null;
                item.productName = null;
                _productSearchController.clear();
                _productSuggestions = [];
              });
              widget.onChanged();
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormLabel(text: 'Dosage *'),
                    const SizedBox(height: 6),
                    _StyledTextField(
                      controller: item.dosageController,
                      hint: 'e.g. 1 tablet daily',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormLabel(text: 'Qty/Period'),
                    const SizedBox(height: 6),
                    _StyledTextField(
                      controller: item.quantityPerPeriodController,
                      hint: '30',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormLabel(text: 'Period (days)'),
                    const SizedBox(height: 6),
                    _StyledTextField(
                      controller: item.periodDaysController,
                      hint: '30',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormLabel(text: 'Repeats'),
                    const SizedBox(height: 6),
                    _StyledTextField(
                      controller: item.repeatsController,
                      hint: '1',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _FormLabel(text: 'Therapy Type'),
          const SizedBox(height: 6),
          Row(
            children: [
              _TherapyTypeChip(
                label: 'Chronic (Monthly)',
                value: 'ChronicMonthly',
                selected: item.therapyType == 'ChronicMonthly',
                onTap: () {
                  setState(() => item.therapyType = 'ChronicMonthly');
                  widget.onChanged();
                },
              ),
              const SizedBox(width: 8),
              _TherapyTypeChip(
                label: 'Chronic (Quarterly)',
                value: 'ChronicQuarterly',
                selected: item.therapyType == 'ChronicQuarterly',
                onTap: () {
                  setState(() => item.therapyType = 'ChronicQuarterly');
                  widget.onChanged();
                },
              ),
              const SizedBox(width: 8),
              _TherapyTypeChip(
                label: 'Acute',
                value: 'Acute',
                selected: item.therapyType == 'Acute',
                onTap: () {
                  setState(() => item.therapyType = 'Acute');
                  widget.onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductSearchHelper {
  static Future<List<Map<String, dynamic>>> search(String query) async {
    try {
      final data = await ApiService.get(
        'Product?name=$query&pageSize=5&retrieveAll=false&includeTotalCount=false',
      );
      final items = (data['items'] as List?) ?? [];
      return items
          .map((i) => {'id': i['id'], 'name': i['name']})
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}

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

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.kTextMid,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, color: AppColors.kTextDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.kTextMid, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.kTeal, width: 2),
        ),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final DateTime? date;
  final String hint;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  const _DatePickerButton({
    required this.date,
    required this.hint,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (context, child) => Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(primary: AppColors.kTeal),
              ),
              child: child!,
            ),
          );
          if (picked != null) onPick(picked);
        },
        icon: Icon(
          date != null
              ? Icons.edit_calendar_outlined
              : Icons.calendar_today_outlined,
          size: 15,
        ),
        label: Row(
          children: [
            Expanded(
              child: Text(
                date != null
                    ? '${date!.day.toString().padLeft(2, '0')}.${date!.month.toString().padLeft(2, '0')}.${date!.year}'
                    : hint,
                style: TextStyle(
                  fontSize: 13,
                  color: date != null
                      ? AppColors.kTextDark
                      : AppColors.kTextMid,
                ),
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.clear,
                  size: 14,
                  color: AppColors.kTextMid,
                ),
              ),
          ],
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: date != null ? AppColors.kTeal : AppColors.kTextMid,
          side: BorderSide(
            color: date != null ? AppColors.kTeal : const Color(0xFFE2E8F0),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

class _TherapyTypeChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _TherapyTypeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.kTeal : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.kTeal : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.kTextMid,
          ),
        ),
      ),
    );
  }
}

class _PatientSearchField extends StatelessWidget {
  final TextEditingController controller;
  final PatientModel? selectedPatient;
  final List<PatientModel> suggestions;
  final bool isSearching;
  final ValueChanged<String> onSearch;
  final ValueChanged<PatientModel> onSelected;
  final VoidCallback onClear;

  const _PatientSearchField({
    required this.controller,
    required this.selectedPatient,
    required this.suggestions,
    required this.isSearching,
    required this.onSearch,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          enabled: selectedPatient == null,
          onChanged: onSearch,
          style: const TextStyle(fontSize: 13, color: AppColors.kTextDark),
          decoration: InputDecoration(
            hintText: 'Search patient by name...',
            hintStyle: const TextStyle(color: AppColors.kTextMid, fontSize: 13),
            prefixIcon: selectedPatient != null
                ? const Icon(
                    Icons.check_circle,
                    color: Color(0xFF059669),
                    size: 18,
                  )
                : isSearching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.kTeal,
                      ),
                    ),
                  )
                : const Icon(Icons.search, color: AppColors.kTextMid, size: 18),
            suffixIcon: selectedPatient != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: selectedPatient != null
                ? const Color(0xFFD1FAE5)
                : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: selectedPatient != null
                    ? const Color(0xFF059669)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: selectedPatient != null
                    ? const Color(0xFF059669)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.kTeal, width: 2),
            ),
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: suggestions
                  .map(
                    (p) => InkWell(
                      onTap: () => onSelected(p),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.kTealLight,
                              child: Text(
                                '${p.firstName[0]}${p.lastName[0]}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.kTeal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.fullName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.kTextDark,
                                    ),
                                  ),
                                  Text(
                                    p.email,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.kTextMid,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              p.cityName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.kTextMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _ProductSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String? selectedProductName;
  final List<Map<String, dynamic>> suggestions;
  final bool isSearching;
  final ValueChanged<String> onSearch;
  final Function(int id, String name) onSelected;
  final VoidCallback onClear;

  const _ProductSearchField({
    required this.controller,
    required this.selectedProductName,
    required this.suggestions,
    required this.isSearching,
    required this.onSearch,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          enabled: selectedProductName == null,
          onChanged: onSearch,
          style: const TextStyle(fontSize: 13, color: AppColors.kTextDark),
          decoration: InputDecoration(
            hintText: 'Search medication...',
            hintStyle: const TextStyle(color: AppColors.kTextMid, fontSize: 13),
            prefixIcon: selectedProductName != null
                ? const Icon(
                    Icons.check_circle,
                    color: Color(0xFF059669),
                    size: 18,
                  )
                : isSearching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.kTeal,
                      ),
                    ),
                  )
                : const Icon(Icons.search, color: AppColors.kTextMid, size: 18),
            suffixIcon: selectedProductName != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: selectedProductName != null
                ? const Color(0xFFD1FAE5)
                : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: selectedProductName != null
                    ? const Color(0xFF059669)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: selectedProductName != null
                    ? const Color(0xFF059669)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.kTeal, width: 2),
            ),
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: suggestions
                  .map(
                    (p) => InkWell(
                      onTap: () =>
                          onSelected(p['id'] as int, p['name'] as String),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.medication_outlined,
                              size: 16,
                              color: AppColors.kTeal,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                p['name'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.kTextDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
