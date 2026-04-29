import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  bool get _isEdit => widget.product != null;

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _unitController = TextEditingController();
  final _packageSizeController = TextEditingController();
  final _priceController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _contraindicationsController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedType = 1;
  bool _isPrescriptionRequired = false;
  bool _isActive = true;

  List<CategoryModel> _medicationCategories = [];
  List<CategoryModel> _pharmacologicalCategories = [];
  int? _selectedMedicationCategoryId;
  int? _selectedPharmacologicalCategoryId;
  final _atcCodeController = TextEditingController();
  bool _requiresColdChain = false;
  String? _existingImageUrl;

  String? _targetGender;
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();
  final _tagsController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageFilename;
  bool _uploadingImage = false;
  bool _saving = false;
  bool _loadingCategories = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _populateFields(widget.product!);
    _loadCategories();
  }

  void _populateFields(ProductModel p) {
    _nameController.text = p.name;
    _skuController.text = p.sku ?? '';
    _barcodeController.text = p.barcode ?? '';
    _manufacturerController.text = p.manufacturer ?? '';
    _unitController.text = p.unit ?? '';
    _packageSizeController.text = p.packageSize?.toString() ?? '';
    _priceController.text = p.price.toStringAsFixed(2);
    _sideEffectsController.text = p.sideEffects;
    _instructionsController.text = p.instructionsForUse;
    _contraindicationsController.text = p.contraindications;
    _selectedType = p.type;
    _isPrescriptionRequired = p.isPrescriptionRequired;
    _isActive = p.isActive;
    _existingImageUrl = p.imageUrl;
    _atcCodeController.text = p.atcCode ?? '';
    _selectedMedicationCategoryId = p.medicationCategoryId;
    _selectedPharmacologicalCategoryId = p.pharmacologicalCategoryId;
    _requiresColdChain = p.requiresColdChain;
    _targetGender = p.targetGender;
    _minAgeController.text = p.minAge?.toString() ?? '';
    _maxAgeController.text = p.maxAge?.toString() ?? '';
    _tagsController.text = p.tags ?? '';
    _descriptionController.text = p.description ?? '';
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final med = await ProductService.getMedicationCategories();
      final pharma = await ProductService.getPharmacologicalCategories();
      if (mounted) {
        setState(() {
          _medicationCategories = med;
          _pharmacologicalCategories = pharma;
        });
      }
    } catch (e) {
      debugPrint('Categories load error: $e');
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _skuController,
      _barcodeController,
      _manufacturerController,
      _unitController,
      _packageSizeController,
      _priceController,
      _sideEffectsController,
      _instructionsController,
      _contraindicationsController,
      _atcCodeController,
      _minAgeController,
      _maxAgeController,
      _tagsController,
      _descriptionController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _imageBytes = result.files.single.bytes!;
        _imageFilename = result.files.single.name;
      });
    }
  }

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Discard Changes?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Are you sure you want to cancel? All unsaved changes will be lost.',
          style: TextStyle(fontSize: 14, color: AppColors.kTextMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Keep Editing',
              style: TextStyle(
                color: AppColors.kTextMid,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Discard',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    // Name
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Product name is required.');
      return;
    }
    if (_nameController.text.trim().length > 200) {
      setState(() => _error = 'Product name must not exceed 200 characters.');
      return;
    }

    // Price
    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (price == null || price <= 0) {
      setState(
        () => _error = 'Valid price is required (must be greater than 0).',
      );
      return;
    }

    // SKU
    if (_skuController.text.trim().length > 100) {
      setState(() => _error = 'SKU must not exceed 100 characters.');
      return;
    }

    // Barcode — samo brojevi, max 100 znakova
    final barcode = _barcodeController.text.trim();
    if (barcode.isNotEmpty) {
      if (barcode.length > 100) {
        setState(() => _error = 'Barcode must not exceed 100 characters.');
        return;
      }
      if (!RegExp(r'^\d+$').hasMatch(barcode)) {
        setState(() => _error = 'Barcode must contain only digits.');
        return;
      }
    }

    // Manufacturer
    if (_manufacturerController.text.trim().length > 150) {
      setState(() => _error = 'Manufacturer must not exceed 150 characters.');
      return;
    }

    // Unit
    if (_unitController.text.trim().length > 50) {
      setState(() => _error = 'Unit must not exceed 50 characters.');
      return;
    }

    // Package size
    if (_packageSizeController.text.trim().isNotEmpty) {
      final packageSize = int.tryParse(_packageSizeController.text.trim());
      if (packageSize == null || packageSize < 1) {
        setState(
          () => _error = 'Package size must be a whole number greater than 0.',
        );
        return;
      }
    }

    // Side Effects / Instructions / Contraindications — max 1000
    if (_sideEffectsController.text.trim().length > 1000) {
      setState(() => _error = 'Side effects must not exceed 1000 characters.');
      return;
    }
    if (_instructionsController.text.trim().length > 1000) {
      setState(
        () => _error = 'Instructions for use must not exceed 1000 characters.',
      );
      return;
    }
    if (_contraindicationsController.text.trim().length > 1000) {
      setState(
        () => _error = 'Contraindications must not exceed 1000 characters.',
      );
      return;
    }

    // Sve prošlo — spremi
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final request = {
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'isPrescriptionRequired': _isPrescriptionRequired,
        'isActive': _isActive,
        if (_skuController.text.trim().isNotEmpty)
          'sku': _skuController.text.trim(),
        if (_barcodeController.text.trim().isNotEmpty)
          'barcode': _barcodeController.text.trim(),
        if (_manufacturerController.text.trim().isNotEmpty)
          'manufacturer': _manufacturerController.text.trim(),
        if (_unitController.text.trim().isNotEmpty)
          'unit': _unitController.text.trim(),
        if (_packageSizeController.text.trim().isNotEmpty)
          'packageSize': int.tryParse(_packageSizeController.text),
        'price': price,
        'sideEffects': _sideEffectsController.text.trim(),
        'instructionsForUse': _instructionsController.text.trim(),
        'contraindications': _contraindicationsController.text.trim(),
        if (_selectedType == 1) ...{
          if (_atcCodeController.text.trim().isNotEmpty)
            'atcCode': _atcCodeController.text.trim(),
          if (_selectedMedicationCategoryId != null)
            'medicationCategoryId': _selectedMedicationCategoryId,
          if (_selectedPharmacologicalCategoryId != null)
            'pharmacologicalCategoryId': _selectedPharmacologicalCategoryId,
          'requiresColdChain': _requiresColdChain,
        },
        if (_selectedType == 2) ...{
          if (_targetGender != null) 'targetGender': _targetGender,
          if (_minAgeController.text.trim().isNotEmpty)
            'minAge': int.tryParse(_minAgeController.text.trim()),
          if (_maxAgeController.text.trim().isNotEmpty)
            'maxAge': int.tryParse(_maxAgeController.text.trim()),
          if (_tagsController.text.trim().isNotEmpty)
            'tags': _tagsController.text.trim(),
          if (_descriptionController.text.trim().isNotEmpty)
            'description': _descriptionController.text.trim(),
        },
      };

      ProductModel saved;
      if (_isEdit) {
        saved = await ProductService.update(widget.product!.id, request);
      } else {
        saved = await ProductService.create(request);
      }

      if (_imageBytes != null && _imageFilename != null) {
        setState(() => _uploadingImage = true);
        await ProductService.uploadImage(
          saved.id,
          _imageBytes!.toList(),
          _imageFilename!,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      body: Column(
        children: [
          // ── Top bar ───────────────────────────────────────────────────────────
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
                  onPressed: _saving ? null : _handleCancel,
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.kTextMid,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Products',
                  style: TextStyle(color: AppColors.kTextMid, fontSize: 14),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.kTextMid,
                ),
                Text(
                  _isEdit ? 'Edit ${widget.product!.name}' : 'New Product',
                  style: const TextStyle(
                    color: AppColors.kTextDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _saving ? null : _handleCancel,
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
                    _uploadingImage
                        ? 'Uploading...'
                        : (_isEdit ? 'Save Changes' : 'Create Product'),
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

          // ── Body ─────────────────────────────────────────────────────────────
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
                      // ── Lijeva kolona ─────────────────────────────────────────────
                      Expanded(
                        child: Column(
                          children: [
                            _SectionCard(
                              title: 'Basic Information',
                              icon: Icons.info_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FormLabel(text: 'Product Name *'),
                                  const SizedBox(height: 6),
                                  _StyledTextField(
                                    controller: _nameController,
                                    hint: 'e.g. Amlodipin 5mg',
                                  ),
                                  const SizedBox(height: 14),
                                  _FormLabel(text: 'Description'),
                                  const SizedBox(height: 6),
                                  _StyledTextField(
                                    controller: _descriptionController,
                                    hint: 'Short product description...',
                                    maxLines: 3,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _FormLabel(text: 'SKU'),
                                            const SizedBox(height: 6),
                                            _StyledTextField(
                                              controller: _skuController,
                                              hint: 'e.g. MED-001',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _FormLabel(text: 'Barcode'),
                                            const SizedBox(height: 6),
                                            _StyledTextField(
                                              controller: _barcodeController,
                                              hint: 'e.g. 3838989',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _FormLabel(text: 'Manufacturer'),
                                            const SizedBox(height: 6),
                                            _StyledTextField(
                                              controller:
                                                  _manufacturerController,
                                              hint: 'e.g. Bosnalijek',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _FormLabel(text: 'Price (KM) *'),
                                            const SizedBox(height: 6),
                                            _StyledTextField(
                                              controller: _priceController,
                                              hint: '0.00',
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _FormLabel(text: 'Unit'),
                                            const SizedBox(height: 6),
                                            _StyledTextField(
                                              controller: _unitController,
                                              hint: 'e.g. tbl, ml, amp',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _FormLabel(text: 'Package Size'),
                                            const SizedBox(height: 6),
                                            _StyledTextField(
                                              controller:
                                                  _packageSizeController,
                                              hint: 'e.g. 30',
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _FormLabel(text: 'Type *'),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: ProductService
                                        .productTypes
                                        .entries
                                        .map(
                                          (e) => _SelectChip(
                                            label: e.value,
                                            selected: _selectedType == e.key,
                                            onTap: () => setState(
                                              () => _selectedType = e.key,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _CheckRow(
                                          label: 'Prescription Required',
                                          value: _isPrescriptionRequired,
                                          onChanged: (v) => setState(
                                            () => _isPrescriptionRequired = v,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: _CheckRow(
                                          label: 'Active',
                                          value: _isActive,
                                          onChanged: (v) =>
                                              setState(() => _isActive = v),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'Medical Information',
                              icon: Icons.medical_information_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FormLabel(text: 'Side Effects'),
                                  const SizedBox(height: 6),
                                  _StyledTextField(
                                    controller: _sideEffectsController,
                                    hint: 'List side effects...',
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 14),
                                  _FormLabel(text: 'Instructions for Use'),
                                  const SizedBox(height: 6),
                                  _StyledTextField(
                                    controller: _instructionsController,
                                    hint: 'How to use...',
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 14),
                                  _FormLabel(text: 'Contraindications'),
                                  const SizedBox(height: 6),
                                  _StyledTextField(
                                    controller: _contraindicationsController,
                                    hint: 'Who should not use...',
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // ── Desna kolona — širina 300, samo ovdje su type-specific paneli ──
                      SizedBox(
                        width: 300,
                        child: Column(
                          children: [
                            // Product Image
                            _SectionCard(
                              title: 'Product Image',
                              icon: Icons.image_outlined,
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      width: double.infinity,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        color: AppColors.kBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: _imageBytes != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.memory(
                                                _imageBytes!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _imagePlaceholder(),
                                              ),
                                            )
                                          : (_existingImageUrl != null &&
                                                _existingImageUrl!.isNotEmpty &&
                                                !_existingImageUrl!.contains(
                                                  'default-product',
                                                ))
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                'http://localhost:5081${_existingImageUrl!}',
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _imagePlaceholder(),
                                              ),
                                            )
                                          : _imagePlaceholder(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(
                                      Icons.upload_outlined,
                                      size: 15,
                                    ),
                                    label: Text(
                                      _imageBytes != null
                                          ? 'Change Image'
                                          : 'Upload Image',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.kTeal,
                                      side: const BorderSide(
                                        color: AppColors.kTeal,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      minimumSize: const Size(
                                        double.infinity,
                                        40,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Medication Details
                            if (_selectedType == 1)
                              _SectionCard(
                                title: 'Medication Details',
                                icon: Icons.science_outlined,
                                child: _loadingCategories
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.kTeal,
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _FormLabel(text: 'ATC Code'),
                                          const SizedBox(height: 6),
                                          _StyledTextField(
                                            controller: _atcCodeController,
                                            hint: 'e.g. C08CA01',
                                          ),
                                          const SizedBox(height: 14),
                                          _FormLabel(
                                            text: 'Medication Category',
                                          ),
                                          const SizedBox(height: 6),
                                          _StyledDropdown<int?>(
                                            value:
                                                _selectedMedicationCategoryId,
                                            hint: 'Select category',
                                            items: [
                                              const DropdownMenuItem(
                                                value: null,
                                                child: Text(
                                                  'None',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              ..._medicationCategories.map(
                                                (c) => DropdownMenuItem(
                                                  value: c.id,
                                                  child: Text(
                                                    c.name,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged: (v) => setState(
                                              () =>
                                                  _selectedMedicationCategoryId =
                                                      v,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          _FormLabel(
                                            text: 'Pharmacological Category',
                                          ),
                                          const SizedBox(height: 6),
                                          _StyledDropdown<int?>(
                                            value:
                                                _selectedPharmacologicalCategoryId,
                                            hint: 'Select category',
                                            items: [
                                              const DropdownMenuItem(
                                                value: null,
                                                child: Text(
                                                  'None',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              ..._pharmacologicalCategories.map(
                                                (c) => DropdownMenuItem(
                                                  value: c.id,
                                                  child: Text(
                                                    c.name,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged: (v) => setState(
                                              () =>
                                                  _selectedPharmacologicalCategoryId =
                                                      v,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          _CheckRow(
                                            label: 'Requires Cold Chain',
                                            value: _requiresColdChain,
                                            onChanged: (v) => setState(
                                              () => _requiresColdChain = v,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),

                            // Supplement Details
                            if (_selectedType == 2)
                              _SectionCard(
                                title: 'Supplement Details',
                                icon: Icons.spa_outlined,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FormLabel(text: 'Target Gender'),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        _SelectChip(
                                          label: 'Both',
                                          selected: _targetGender == null,
                                          onTap: () => setState(
                                            () => _targetGender = null,
                                          ),
                                        ),
                                        _SelectChip(
                                          label: 'Male',
                                          selected: _targetGender == 'Male',
                                          onTap: () => setState(
                                            () => _targetGender = 'Male',
                                          ),
                                        ),
                                        _SelectChip(
                                          label: 'Female',
                                          selected: _targetGender == 'Female',
                                          onTap: () => setState(
                                            () => _targetGender = 'Female',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _FormLabel(text: 'Min Age'),
                                              const SizedBox(height: 6),
                                              _StyledTextField(
                                                controller: _minAgeController,
                                                hint: '0',
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _FormLabel(text: 'Max Age'),
                                              const SizedBox(height: 6),
                                              _StyledTextField(
                                                controller: _maxAgeController,
                                                hint: '99',
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    _FormLabel(text: 'Tags'),
                                    const SizedBox(height: 6),
                                    _StyledTextField(
                                      controller: _tagsController,
                                      hint: 'e.g. immune, energy, vitamin',
                                    ),
                                  ],
                                ),
                              ),

                            if (_selectedType != 1 && _selectedType != 2)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.kTealLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.kTeal.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: AppColors.kTeal,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'No additional details required for this product type. '
                                        'Fill in the general information and medical notes as needed.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.kTeal,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.add_photo_alternate_outlined,
        size: 32,
        color: AppColors.kTextMid.withValues(alpha: 0.4),
      ),
      const SizedBox(height: 8),
      const Text(
        'Click to upload image',
        style: TextStyle(fontSize: 12, color: AppColors.kTextMid),
      ),
    ],
  );
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

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
  Widget build(BuildContext context) => Container(
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

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel({required this.text});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.kTextMid,
    ),
  );
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
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    style: const TextStyle(fontSize: 13, color: AppColors.kTextDark),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.kTextMid, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value,
    isExpanded: true,
    hint: Text(
      hint,
      style: const TextStyle(color: AppColors.kTextMid, fontSize: 13),
    ),
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    items: items,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 13, color: AppColors.kTextDark),
  );
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
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

class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Checkbox(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        activeColor: AppColors.kTeal,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.kTextDark),
        ),
      ),
    ],
  );
}
