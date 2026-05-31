import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../core/errors/app_exception.dart';
import 'login_screen.dart';
import '../widgets/pagination_widget.dart';

class MedicationCategoryModel {
  final int id;
  final int code;
  final String codeName;
  final String name;
  final String description;
  final double patientPaymentPercentage;
  final double insurancePaymentPercentage;
  final double? flatFee;
  final String codeLabel;

  MedicationCategoryModel({
    required this.id,
    required this.code,
    required this.codeName,
    required this.name,
    required this.description,
    required this.patientPaymentPercentage,
    required this.insurancePaymentPercentage,
    this.flatFee,
    required this.codeLabel,
  });

  factory MedicationCategoryModel.fromJson(Map<String, dynamic> json) {
    int codeInt;
    final codeVal = json['code'];

    if (codeVal is int) {
      codeInt = codeVal;
    } else {
      switch (codeVal?.toString()) {
        case 'CategoryA':
          codeInt = 1;
          break;
        case 'CategoryB':
          codeInt = 2;
          break;
        case 'CategoryC':
          codeInt = 3;
          break;
        default:
          codeInt = 0;
      }
    }

    return MedicationCategoryModel(
      id: json['id'] as int,
      code: codeInt,
      codeName: json['codeName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      patientPaymentPercentage:
          (json['patientPaymentPercentage'] as num?)?.toDouble() ?? 0,
      insurancePaymentPercentage:
          (json['insurancePaymentPercentage'] as num?)?.toDouble() ?? 0,
      flatFee: (json['flatFee'] as num?)?.toDouble(),
      codeLabel: json['codeName'] as String? ?? '',
    );
  }
}

class MedicationCategoriesScreen extends StatefulWidget {
  const MedicationCategoriesScreen({super.key});

  @override
  State<MedicationCategoriesScreen> createState() =>
      _MedicationCategoriesScreenState();
}

class _MedicationCategoriesScreenState
    extends State<MedicationCategoriesScreen> {
  final _searchController = TextEditingController();
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _loading = true;
  List<MedicationCategoryModel> _items = [];
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      String url =
          'MedicationCategory?pageSize=$_pageSize&page=$_currentPage&includeTotalCount=true';
      if (_searchController.text.trim().isNotEmpty)
        url += '&name=${Uri.encodeComponent(_searchController.text.trim())}';

      final data = await ApiService.get(url) as Map<String, dynamic>;
      final items = ((data['items'] as List?) ?? [])
          .map(
            (e) => MedicationCategoryModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      if (mounted) {
        setState(() {
          _items = items;
          _totalCount = data['totalCount'] as int? ?? 0;
        });
      }
    } on UnauthorizedException {
      if (mounted) {
        await ApiService.clearToken();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } on NetworkException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalPages =>
      _totalCount == 0 ? 0 : (_totalCount / _pageSize).ceil();

  void _openCreate() {
    showDialog(
      context: context,
      builder: (_) => _MedicationCategoryDialog(onSaved: _loadData),
    );
  }

  void _openEdit(MedicationCategoryModel item) => showDialog(
    context: context,
    builder: (_) => _MedicationCategoryDialog(item: item, onSaved: _loadData),
  );

  Future<void> _delete(MedicationCategoryModel item) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to delete "${item.name}"? This cannot be undone.',
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
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await ApiService.delete('MedicationCategory/${item.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Category deleted.'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  static const _headerStyle = TextStyle(
    fontWeight: FontWeight.w600,
    color: AppColors.kTextMid,
    fontSize: 12,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) {
                      setState(() => _currentPage = 0);
                      _loadData();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      hintStyle: const TextStyle(
                        color: AppColors.kTextMid,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.kTextMid,
                        size: 18,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _currentPage = 0);
                                _loadData();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
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
                        borderSide: const BorderSide(
                          color: AppColors.kTeal,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kTextMid,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _openCreate,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Category'),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(width: 48),
                        Expanded(
                          flex: 2,
                          child: Text('Code', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Name', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Patient %',
                            textAlign: TextAlign.center,
                            style: _headerStyle,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Insurance %',
                            textAlign: TextAlign.center,
                            style: _headerStyle,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Flat Fee',
                            textAlign: TextAlign.center,
                            style: _headerStyle,
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'Actions',
                            textAlign: TextAlign.center,
                            style: _headerStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.kTeal,
                            ),
                          )
                        : _items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 48,
                                  color: AppColors.kTextMid.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No categories found',
                                  style: TextStyle(
                                    color: AppColors.kTextMid,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) =>
                                _MedicationCategoryRow(
                                  item: _items[index],
                                  isEven: index.isEven,
                                  onEdit: () => _openEdit(_items[index]),
                                  onDelete: () => _delete(_items[index]),
                                ),
                          ),
                  ),
                  if (!_loading && _totalPages > 1)
                    PaginationWidget(
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      totalCount: _totalCount,
                      pageSize: _pageSize,
                      itemCount: _items.length,
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                        _loadData();
                      },
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

class _MedicationCategoryRow extends StatefulWidget {
  final MedicationCategoryModel item;
  final bool isEven;
  final VoidCallback onEdit, onDelete;

  const _MedicationCategoryRow({
    required this.item,
    required this.isEven,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_MedicationCategoryRow> createState() => _MedicationCategoryRowState();
}

class _MedicationCategoryRowState extends State<_MedicationCategoryRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _hovering
              ? AppColors.kTealLight.withValues(alpha: 0.5)
              : widget.isEven
              ? Colors.white
              : const Color(0xFFF8FAFC),
          border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.kTealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.category_rounded,
                size: 18,
                color: AppColors.kTeal,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.codeName,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.kTextDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  '${item.patientPaymentPercentage}%',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.kTextDark,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  '${item.insurancePaymentPercentage}%',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.kTextDark,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: item.flatFee != null
                    ? Text(
                        '${item.flatFee} KM',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.kTextDark,
                        ),
                      )
                    : const Text(
                        '—',
                        style: TextStyle(color: AppColors.kTextMid),
                      ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: widget.onEdit,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.kTeal,
                      ),
                      tooltip: 'Edit',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Color(0xFFDC2626),
                      ),
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationCategoryDialog extends StatefulWidget {
  final MedicationCategoryModel? item;
  final VoidCallback onSaved;

  const _MedicationCategoryDialog({this.item, required this.onSaved});

  @override
  State<_MedicationCategoryDialog> createState() =>
      _MedicationCategoryDialogState();
}

class _MedicationCategoryDialogState extends State<_MedicationCategoryDialog> {
  bool get _isEdit => widget.item != null;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _patientCtrl = TextEditingController();
  final _insuranceCtrl = TextEditingController();
  final _flatFeeCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _codeLabelCtrl = TextEditingController();

  bool _hasFlatFee = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final item = widget.item!;
      _codeCtrl.text = item.code.toString();
      _codeLabelCtrl.text = item.codeLabel;
      _nameCtrl.text = item.name;
      _descCtrl.text = item.description;
      _patientCtrl.text = item.patientPaymentPercentage.toString();
      _insuranceCtrl.text = item.insurancePaymentPercentage.toString();
      if (item.flatFee != null) {
        _hasFlatFee = true;
        _flatFeeCtrl.text = item.flatFee.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _patientCtrl.dispose();
    _insuranceCtrl.dispose();
    _flatFeeCtrl.dispose();
    _codeCtrl.dispose();
    _codeLabelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_isEdit) {
      if (_codeCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Code is required.');
        return;
      }
      if (int.tryParse(_codeCtrl.text.trim()) == null) {
        setState(() => _error = 'Code must be a valid number.');
        return;
      }
      if (_codeLabelCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Code label is required.');
        return;
      }
    }
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (!_hasFlatFee) {
      if (_patientCtrl.text.trim().isEmpty ||
          _insuranceCtrl.text.trim().isEmpty) {
        setState(
          () => _error = 'Patient and insurance percentages are required.',
        );
        return;
      }
      final patient = double.tryParse(_patientCtrl.text.trim());
      final insurance = double.tryParse(_insuranceCtrl.text.trim());
      if (patient == null || insurance == null) {
        setState(() => _error = 'Percentages must be valid numbers.');
        return;
      }
    } else {
      final patient = double.tryParse(_patientCtrl.text.trim()) ?? 0;
      final insurance = double.tryParse(_insuranceCtrl.text.trim()) ?? 0;
      if (patient + insurance > 100) {
        setState(() => _error = 'Percentages cannot exceed 100.');
        return;
      }
    }
    if (_hasFlatFee && _flatFeeCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Flat fee value is required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'codeLabel': _codeLabelCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'patientPaymentPercentage':
            double.tryParse(_patientCtrl.text.trim()) ?? 0,
        'insurancePaymentPercentage':
            double.tryParse(_insuranceCtrl.text.trim()) ?? 0,
        'flatFee': _hasFlatFee
            ? double.tryParse(_flatFeeCtrl.text.trim())
            : null,
      };

      if (_isEdit) {
        if (_codeCtrl.text.trim().isEmpty) {
          setState(() => _error = 'Code is required.');
          return;
        }
        if (_codeLabelCtrl.text.trim().isEmpty) {
          setState(() => _error = 'Code label is required.');
          return;
        }
        if (int.tryParse(_codeCtrl.text.trim()) == null) {
          setState(() => _error = 'Code must be a valid number.');
          return;
        }
        await ApiService.put('MedicationCategory/${widget.item!.id}', body);
      } else {
        body['code'] = int.parse(_codeCtrl.text.trim());
        body['codeLabel'] = _codeLabelCtrl.text.trim();
        await ApiService.post('MedicationCategory', body);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Category updated successfully.'
                  : 'Category created successfully.',
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDeco({required String hint}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.kTextMid, fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.kTealLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.category_rounded,
                        size: 18,
                        color: AppColors.kTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEdit ? 'Edit Category' : 'New Medication Category',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kTextDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.kTextMid,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 14,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!_isEdit) ...[
                  _Label('Category Code *'),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Code (number) *'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _codeCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _inputDeco(hint: 'e.g. 4'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Code Label *'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _codeLabelCtrl,
                              decoration: _inputDeco(hint: 'e.g. CategoryD'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                _Label('Name *'),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.kTextDark,
                  ),
                  decoration: _inputDeco(hint: 'e.g. Lista A'),
                ),
                const SizedBox(height: 14),
                _Label('Description'),
                const SizedBox(height: 6),
                TextField(
                  controller: _descCtrl,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.kTextDark,
                  ),
                  maxLines: 2,
                  decoration: _inputDeco(hint: 'Optional description'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Patient Payment % *'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _patientCtrl,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.kTextDark,
                            ),
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco(hint: 'e.g. 40'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Insurance Payment % *'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _insuranceCtrl,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.kTextDark,
                            ),
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco(hint: 'e.g. 60'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Checkbox(
                      value: _hasFlatFee,
                      activeColor: AppColors.kTeal,
                      onChanged: (v) =>
                          setState(() => _hasFlatFee = v ?? false),
                    ),
                    const Text(
                      'Has Flat Fee',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.kTextDark,
                      ),
                    ),
                  ],
                ),
                if (_hasFlatFee) ...[
                  const SizedBox(height: 8),
                  _Label('Flat Fee (KM)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _flatFeeCtrl,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.kTextDark,
                    ),
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco(hint: 'e.g. 1.00'),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 13),
                      ),
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
                        _isEdit ? 'Save Changes' : 'Create Category',
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
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

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
