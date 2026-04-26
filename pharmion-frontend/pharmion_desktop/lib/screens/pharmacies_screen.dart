import 'package:flutter/material.dart';
import '../services/pharmacy_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PharmaciesScreen extends StatefulWidget {
  const PharmaciesScreen({super.key});
  @override
  State<PharmaciesScreen> createState() => _PharmaciesScreenState();
}

class _PharmaciesScreenState extends State<PharmaciesScreen> {
  final _searchController = TextEditingController();
  bool? _isActive;
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _loading = true;
  List<PharmacyModel> _pharmacies = [];
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
      final result = await PharmacyService.getPharmacies(
        page: _currentPage,
        pageSize: _pageSize,
        name: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        isActive: _isActive,
      );
      if (mounted) {
        setState(() {
          _pharmacies = result.items;
          _totalCount = result.totalCount;
        });
      }
    } catch (e) {
      debugPrint('Pharmacies load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalPages {
    if (_totalCount == 0) return 0;
    return (_totalCount / _pageSize).ceil();
  }

  void _openCreate() => showDialog(
    context: context,
    builder: (_) => _PharmacyDialog(onSaved: _loadData),
  );

  void _openEdit(PharmacyModel p) => showDialog(
    context: context,
    builder: (_) => _PharmacyDialog(pharmacy: p, onSaved: _loadData),
  );

  Future<void> _delete(PharmacyModel p) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Pharmacy',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to delete "${p.name}"? This cannot be undone.',
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
      await PharmacyService.delete(p.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pharmacy deleted.'),
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
          // ── Filters ───────────────────────────────────────────────────────
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
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: DropdownButtonFormField<bool?>(
                    value: _isActive,
                    hint: const Text(
                      'All statuses',
                      style: TextStyle(color: AppColors.kTextMid, fontSize: 13),
                    ),
                    decoration: _dropdownDecoration(),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'All statuses',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text('Active', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text('Inactive', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _isActive = val;
                        _currentPage = 0;
                      });
                      _loadData();
                    },
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
                  label: const Text('New Pharmacy'),
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

          // ── Table ─────────────────────────────────────────────────────────
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
                  // Header
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
                        SizedBox(width: 48), // icon placeholder
                        Expanded(
                          flex: 3,
                          child: Text('Name', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Address', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('City', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Status',
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

                  // Body
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.kTeal,
                            ),
                          )
                        : _pharmacies.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_pharmacy_outlined,
                                  size: 48,
                                  color: AppColors.kTextMid.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No pharmacies found',
                                  style: TextStyle(
                                    color: AppColors.kTextMid,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _pharmacies.length,
                            itemBuilder: (context, index) => _PharmacyRow(
                              pharmacy: _pharmacies[index],
                              isEven: index.isEven,
                              onEdit: () => _openEdit(_pharmacies[index]),
                              onDelete: () => _delete(_pharmacies[index]),
                            ),
                          ),
                  ),

                  // Pagination
                  if (!_loading && _totalCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Showing ${_currentPage * _pageSize + 1}–${(_currentPage * _pageSize + _pharmacies.length)} of $_totalCount',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.kTextMid,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _currentPage > 0
                                ? () {
                                    setState(() => _currentPage--);
                                    _loadData();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            color: AppColors.kTextMid,
                            disabledColor: const Color(0xFFCBD5E1),
                          ),
                          ...List.generate(_totalPages.clamp(0, 5), (i) {
                            final isSelected = i == _currentPage;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _currentPage = i);
                                _loadData();
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.kTeal
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.kTextMid,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          IconButton(
                            onPressed: _currentPage < _totalPages - 1
                                ? () {
                                    setState(() => _currentPage++);
                                    _loadData();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            color: AppColors.kTextMid,
                            disabledColor: const Color(0xFFCBD5E1),
                          ),
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

  InputDecoration _dropdownDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
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
}

// ─── Row Widget ───────────────────────────────────────────────────────────────
class _PharmacyRow extends StatefulWidget {
  final PharmacyModel pharmacy;
  final bool isEven;
  final VoidCallback onEdit, onDelete;

  const _PharmacyRow({
    required this.pharmacy,
    required this.isEven,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PharmacyRow> createState() => _PharmacyRowState();
}

class _PharmacyRowState extends State<_PharmacyRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.pharmacy;
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
            // Icon avatar
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: p.isActive
                    ? AppColors.kTealLight
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.local_pharmacy_rounded,
                size: 18,
                color: p.isActive ? AppColors.kTeal : AppColors.kTextMid,
              ),
            ),

            // Name
            Expanded(
              flex: 3,
              child: Text(
                p.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.kTextDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Address
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: AppColors.kTextMid,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      p.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.kTextMid,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // City
            Expanded(
              flex: 2,
              child: Text(
                p.cityName,
                style: const TextStyle(fontSize: 12, color: AppColors.kTextMid),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Status
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: p.isActive
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: p.isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
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

// ─── Create / Edit Dialog ─────────────────────────────────────────────────────
class _PharmacyDialog extends StatefulWidget {
  final PharmacyModel? pharmacy;
  final VoidCallback onSaved;
  const _PharmacyDialog({this.pharmacy, required this.onSaved});

  @override
  State<_PharmacyDialog> createState() => _PharmacyDialogState();
}

class _PharmacyDialogState extends State<_PharmacyDialog> {
  bool get _isEdit => widget.pharmacy != null;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  int? _selectedCityId;
  bool _isActive = true;
  bool _saving = false;
  String? _error;
  final _workingHoursController = TextEditingController();

  List<Map<String, dynamic>> _cities = [];
  bool _loadingCities = true;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameController.text = widget.pharmacy!.name;
      _addressController.text = widget.pharmacy!.address;
      _selectedCityId = widget.pharmacy!.cityId;
      _isActive = widget.pharmacy!.isActive;
      _workingHoursController.text = widget.pharmacy!.workingHours ?? '';
    }
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final data = await ApiService.get('City?retrieveAll=true');
      if (mounted) {
        setState(() {
          _cities = ((data['items'] as List?) ?? [])
              .map(
                (e) => {
                  'id': e['id'] as int,
                  'name': e['name'] as String? ?? '',
                },
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Cities load error: $e');
    } finally {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final workingHours = _workingHoursController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (address.isEmpty) {
      setState(() => _error = 'Address is required.');
      return;
    }
    if (_selectedCityId == null) {
      setState(() => _error = 'Please select a city.');
      return;
    }
    if (workingHours.isEmpty) {
      setState(() => _error = 'Working hours are required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final body = {
        'name': name,
        'address': address,
        'cityId': _selectedCityId,
        'isActive': _isActive,
        'workingHours': _workingHoursController.text.trim().isEmpty
            ? null
            : _workingHoursController.text.trim(),
      };

      if (_isEdit) {
        await PharmacyService.update(widget.pharmacy!.id, body);
      } else {
        await PharmacyService.create(body);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Pharmacy updated successfully.'
                  : 'Pharmacy created successfully.',
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
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDeco({String? hint, String? label}) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.kTextMid, fontSize: 13),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                      Icons.local_pharmacy_rounded,
                      size: 18,
                      color: AppColors.kTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? 'Edit Pharmacy' : 'New Pharmacy',
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

              // Error
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

              // Name
              _FieldLabel('Pharmacy Name *'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.kTextDark,
                ),
                decoration: _inputDeco(hint: 'e.g. LUPRIV PHARM 1'),
              ),
              const SizedBox(height: 14),

              // Address
              _FieldLabel('Address *'),
              const SizedBox(height: 6),
              TextField(
                controller: _addressController,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.kTextDark,
                ),
                decoration: _inputDeco(hint: 'e.g. Ferhadija 1'),
              ),
              const SizedBox(height: 14),

              // City
              _FieldLabel('City *'),
              const SizedBox(height: 6),
              _loadingCities
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.kTeal),
                    )
                  : DropdownButtonFormField<int?>(
                      value: _selectedCityId,
                      isExpanded: true,
                      hint: const Text(
                        'Select city',
                        style: TextStyle(
                          color: AppColors.kTextMid,
                          fontSize: 13,
                        ),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.kTeal,
                            width: 2,
                          ),
                        ),
                      ),
                      items: _cities
                          .map(
                            (c) => DropdownMenuItem<int?>(
                              value: c['id'] as int,
                              child: Text(
                                c['name'] as String,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCityId = v),
                    ),
              const SizedBox(height: 16),

              // Active toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.toggle_on_outlined,
                      size: 18,
                      color: AppColors.kTextMid,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.kTextDark,
                            ),
                          ),
                          Text(
                            'Inactive pharmacies are hidden from patients',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.kTextMid,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeColor: AppColors.kTeal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FieldLabel('Working Hours'),
              const SizedBox(height: 6),
              TextField(
                controller: _workingHoursController,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.kTextDark,
                ),
                decoration: _inputDeco(
                  hint: 'e.g. Mon-Fri: 08:00-20:00, Sat: 08:00-15:00',
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
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
                      _isEdit ? 'Save Changes' : 'Create Pharmacy',
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

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
