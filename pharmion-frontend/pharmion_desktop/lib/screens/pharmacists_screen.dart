import 'package:flutter/material.dart';
import '../services/pharmacist_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PharmacistsScreen extends StatefulWidget {
  const PharmacistsScreen({super.key});
  @override
  State<PharmacistsScreen> createState() => _PharmacistsScreenState();
}

class _PharmacistsScreenState extends State<PharmacistsScreen> {
  final _searchController = TextEditingController();
  bool? _isActive;
  int? _selectedPharmacyId;
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _loading = true;
  List<PharmacistModel> _pharmacists = [];
  int _totalCount = 0;
  List<Map<String, dynamic>> _pharmacies = [];

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacies() async {
    try {
      final data = await ApiService.get('Pharmacy?retrieveAll=true');
      if (mounted) {
        setState(() {
          _pharmacies = ((data['items'] as List?) ?? [])
              .map((e) => {'id': e['id'], 'name': e['name']})
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Pharmacies load error: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await PharmacistService.getPharmacists(
        page: _currentPage,
        pageSize: _pageSize,
        name: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        pharmacyId: _selectedPharmacyId,
        isActive: _isActive,
      );
      if (mounted) {
        setState(() {
          _pharmacists = result.items;
          _totalCount = result.totalCount;
        });
      }
    } catch (e) {
      debugPrint('Pharmacists load error: $e');
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
      builder: (_) =>
          _PharmacistDialog(pharmacies: _pharmacies, onSaved: _loadData));

  void _openEdit(PharmacistModel p) => showDialog(
      context: context,
      builder: (_) => _PharmacistDialog(
          pharmacist: p, pharmacies: _pharmacies, onSaved: _loadData));

  Future<void> _toggleActive(PharmacistModel p) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(
                '${p.isActive ? 'Deactivate' : 'Activate'} Pharmacist',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
                'Are you sure you want to ${p.isActive ? 'deactivate' : 'activate'} "${p.fullName}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.kTextMid))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: p.isActive
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(p.isActive ? 'Deactivate' : 'Activate'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await PharmacistService.toggleActive(p.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Pharmacist ${p.isActive ? 'deactivated' : 'activated'}.'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  static const _headerStyle = TextStyle(
      fontWeight: FontWeight.w600, color: AppColors.kTextMid, fontSize: 12);

  InputDecoration _dropdownDeco() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.kTeal, width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(children: [
        // ── Filters ───────────────────────────────────────────────────────
        Row(children: [
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
                  hintText: 'Search by name, email...',
                  hintStyle: const TextStyle(
                      color: AppColors.kTextMid, fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.kTextMid, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _currentPage = 0);
                            _loadData();
                          })
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.kTeal, width: 2)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 44,
              child: DropdownButtonFormField<int?>(
                value: _selectedPharmacyId,
                hint: const Text('All pharmacies',
                    style:
                        TextStyle(color: AppColors.kTextMid, fontSize: 13)),
                decoration: _dropdownDeco(),
                items: [
                  const DropdownMenuItem(
                      value: null,
                      child: Text('All pharmacies',
                          style: TextStyle(fontSize: 13))),
                  ..._pharmacies.map((p) => DropdownMenuItem<int?>(
                      value: p['id'] as int,
                      child: Text(p['name'] as String,
                          style: const TextStyle(fontSize: 13)))),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedPharmacyId = val;
                    _currentPage = 0;
                  });
                  _loadData();
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 44,
              child: DropdownButtonFormField<bool?>(
                value: _isActive,
                hint: const Text('Status',
                    style:
                        TextStyle(color: AppColors.kTextMid, fontSize: 13)),
                decoration: _dropdownDeco(),
                items: const [
                  DropdownMenuItem(
                      value: null,
                      child: Text('All', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(
                      value: true,
                      child:
                          Text('Active', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(
                      value: false,
                      child: Text('Inactive',
                          style: TextStyle(fontSize: 13))),
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
                      borderRadius: BorderRadius.circular(10))),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _openCreate,
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: const Text('New Pharmacist'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16)),
            ),
          ),
        ]),
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
                      offset: const Offset(0, 2))
                ]),
            child: Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16)),
                    border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                child: Row(children: const [
                  SizedBox(width: 48),
                  Expanded(
                      flex: 3,
                      child: Text('Pharmacist', style: _headerStyle)),
                  Expanded(
                      flex: 2,
                      child: Text('Pharmacy', style: _headerStyle)),
                  Expanded(
                      flex: 2,
                      child:
                          Text('License Number', style: _headerStyle)),
                  Expanded(
                      flex: 1,
                      child: Text('Role',
                          textAlign: TextAlign.center,
                          style: _headerStyle)),
                  Expanded(
                      flex: 1,
                      child: Text('Status',
                          textAlign: TextAlign.center,
                          style: _headerStyle)),
                  SizedBox(
                      width: 100,
                      child: Text('Actions',
                          textAlign: TextAlign.center,
                          style: _headerStyle)),
                ]),
              ),

              // Body
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.kTeal))
                    : _pharmacists.isEmpty
                        ? Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                Icon(Icons.badge_outlined,
                                    size: 48,
                                    color: AppColors.kTextMid
                                        .withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                const Text('No pharmacists found',
                                    style: TextStyle(
                                        color: AppColors.kTextMid,
                                        fontSize: 14)),
                              ]))
                        : ListView.builder(
                            itemCount: _pharmacists.length,
                            itemBuilder: (context, index) =>
                                _PharmacistRow(
                              pharmacist: _pharmacists[index],
                              isEven: index.isEven,
                              onEdit: () =>
                                  _openEdit(_pharmacists[index]),
                              onToggleActive: () =>
                                  _toggleActive(_pharmacists[index]),
                            ),
                          ),
              ),

              // Pagination
              if (!_loading && _totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0)))),
                  child: Row(children: [
                    Text(
                        'Showing ${_currentPage * _pageSize + 1}–${(_currentPage * _pageSize + _pharmacists.length)} of $_totalCount',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.kTextMid)),
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
                              horizontal: 2),
                          decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.kTeal
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(8)),
                          child: Center(
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.kTextMid))),
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
                  ]),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Row ──────────────────────────────────────────────────────────────────────
class _PharmacistRow extends StatefulWidget {
  final PharmacistModel pharmacist;
  final bool isEven;
  final VoidCallback onEdit, onToggleActive;

  const _PharmacistRow(
      {required this.pharmacist,
      required this.isEven,
      required this.onEdit,
      required this.onToggleActive});

  @override
  State<_PharmacistRow> createState() => _PharmacistRowState();
}

class _PharmacistRowState extends State<_PharmacistRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.pharmacist;
    final initials =
        '${p.firstName.isNotEmpty ? p.firstName[0] : ''}${p.lastName.isNotEmpty ? p.lastName[0] : ''}'
            .toUpperCase();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: _hovering
              ? AppColors.kTealLight.withValues(alpha: 0.5)
              : widget.isEven
                  ? Colors.white
                  : const Color(0xFFF8FAFC),
          border: const Border(
              bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: p.isAdministrator
                        ? [
                            const Color(0xFF7C3AED),
                            const Color(0xFF5B21B6)
                          ]
                        : [AppColors.kTeal, const Color(0xFF026E73)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),

          // Name + email
          Expanded(
            flex: 3,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.fullName,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.kTextDark),
                      overflow: TextOverflow.ellipsis),
                  Text(p.email,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.kTextMid),
                      overflow: TextOverflow.ellipsis),
                ]),
          ),

          // Pharmacy
          Expanded(
            flex: 2,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.pharmacyName,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.kTextDark),
                      overflow: TextOverflow.ellipsis),
                  if (p.pharmacyCity.isNotEmpty)
                    Text(p.pharmacyCity,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.kTextMid)),
                ]),
          ),

          // License
          Expanded(
            flex: 2,
            child: Text(p.licenseNumber,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.kTextMid),
                overflow: TextOverflow.ellipsis),
          ),

          // Role
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: p.isAdministrator
                        ? const Color(0xFFEDE9FE)
                        : AppColors.kTealLight,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(
                    p.isAdministrator ? 'Admin' : 'Pharmacist',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: p.isAdministrator
                            ? const Color(0xFF7C3AED)
                            : AppColors.kTeal)),
              ),
            ),
          ),

          // Status
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: p.isActive
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: p.isActive
                            ? const Color(0xFF059669)
                            : const Color(0xFF94A3B8),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(p.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFF64748B))),
                ]),
              ),
            ),
          ),

          // Actions
          SizedBox(
            width: 100,
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.kTeal),
                  tooltip: 'Edit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  onPressed: widget.onToggleActive,
                  icon: Icon(
                      p.isActive
                          ? Icons.person_off_outlined
                          : Icons.person_outlined,
                      size: 16,
                      color: p.isActive
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF059669)),
                  tooltip: p.isActive ? 'Deactivate' : 'Activate',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 32, minHeight: 32),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Dialog ───────────────────────────────────────────────────────────────────
class _PharmacistDialog extends StatefulWidget {
  final PharmacistModel? pharmacist;
  final List<Map<String, dynamic>> pharmacies;
  final VoidCallback onSaved;

  const _PharmacistDialog(
      {this.pharmacist,
      required this.pharmacies,
      required this.onSaved});

  @override
  State<_PharmacistDialog> createState() => _PharmacistDialogState();
}

class _PharmacistDialogState extends State<_PharmacistDialog> {
  bool get _isEdit => widget.pharmacist != null;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int? _selectedPharmacyId;
  bool _isAdministrator = false;
  bool _isActive = true;
  String _selectedGender = 'Male';
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.pharmacist!;
      _firstNameCtrl.text = p.firstName;
      _lastNameCtrl.text = p.lastName;
      _usernameCtrl.text = p.username;
      _emailCtrl.text = p.email;
      _licenseCtrl.text = p.licenseNumber;
      _selectedPharmacyId = p.pharmacyId;
      _isAdministrator = p.isAdministrator;
      _isActive = p.isActive;
      _selectedGender = p.gender;
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _licenseCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'First and last name are required.');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Email is required.');
      return;
    }
    if (_licenseCtrl.text.trim().isEmpty) {
      setState(() => _error = 'License number is required.');
      return;
    }
    if (_selectedPharmacyId == null) {
      setState(() => _error = 'Please select a pharmacy.');
      return;
    }
    if (!_isEdit) {
      if (_usernameCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Username is required.');
        return;
      }
      if (_passwordCtrl.text.length < 8) {
        setState(
            () => _error = 'Password must be at least 8 characters.');
        return;
      }
      if (_passwordCtrl.text != _confirmCtrl.text) {
        setState(() => _error = 'Passwords do not match.');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_isEdit) {
        await PharmacistService.update(widget.pharmacist!.id, {
          'firstName': _firstNameCtrl.text.trim(),
          'lastName': _lastNameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'licenseNumber': _licenseCtrl.text.trim(),
          'pharmacyId': _selectedPharmacyId,
          'isAdministrator': _isAdministrator,
          'isActive': _isActive,
        });
      } else {
        await PharmacistService.create({
          'firstName': _firstNameCtrl.text.trim(),
          'lastName': _lastNameCtrl.text.trim(),
          'username': _usernameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'confirmPassword': _confirmCtrl.text,
          'licenseNumber': _licenseCtrl.text.trim(),
          'pharmacyId': _selectedPharmacyId,
          'isAdministrator': _isAdministrator,
          'gender': _selectedGender == 'Male' ? 1 : 2,
        });
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit
              ? 'Pharmacist updated successfully.'
              : 'Pharmacist created successfully.'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted)
        setState(
            () => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _deco({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.kTextMid, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.kTeal, width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: AppColors.kTealLight,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.badge_outlined,
                          size: 18, color: AppColors.kTeal),
                    ),
                    const SizedBox(width: 12),
                    Text(
                        _isEdit
                            ? 'Edit Pharmacist'
                            : 'New Pharmacist',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextDark)),
                    const Spacer(),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close,
                            size: 18, color: AppColors.kTextMid),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints()),
                  ]),
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
                          border: Border.all(
                              color: const Color(0xFFFCA5A5))),
                      child: Row(children: [
                        const Icon(Icons.error_outline,
                            size: 14, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFDC2626)))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // First + Last name
                  Row(children: [
                    Expanded(
                      child: _Field(
                          label: 'First Name *',
                          child: TextField(
                              controller: _firstNameCtrl,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.kTextDark),
                              decoration:
                                  _deco(hint: 'e.g. Amira'))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                          label: 'Last Name *',
                          child: TextField(
                              controller: _lastNameCtrl,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.kTextDark),
                              decoration:
                                  _deco(hint: 'e.g. Hodžić'))),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Username (create only) + Email
                  Row(children: [
                    if (!_isEdit) ...[
                      Expanded(
                        child: _Field(
                            label: 'Username *',
                            child: TextField(
                                controller: _usernameCtrl,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.kTextDark),
                                decoration: _deco(
                                    hint: 'e.g. amira.hodzic'))),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _Field(
                          label: 'Email *',
                          child: TextField(
                              controller: _emailCtrl,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.kTextDark),
                              decoration: _deco(
                                  hint:
                                      'e.g. amira@lupriv.ba'))),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Password (create only)
                  if (!_isEdit) ...[
                    Row(children: [
                      Expanded(
                        child: _Field(
                          label: 'Password *',
                          child: TextField(
                            controller: _passwordCtrl,
                            obscureText: !_showPassword,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.kTextDark),
                            decoration: _deco(
                                    hint: 'Min. 8 characters')
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _showPassword
                                        ? Icons
                                            .visibility_off_outlined
                                        : Icons
                                            .visibility_outlined,
                                    size: 18,
                                    color: AppColors.kTextMid),
                                onPressed: () => setState(() =>
                                    _showPassword = !_showPassword),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: 'Confirm Password *',
                          child: TextField(
                            controller: _confirmCtrl,
                            obscureText: !_showConfirm,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.kTextDark),
                            decoration:
                                _deco(hint: 'Repeat password')
                                    .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _showConfirm
                                        ? Icons
                                            .visibility_off_outlined
                                        : Icons
                                            .visibility_outlined,
                                    size: 18,
                                    color: AppColors.kTextMid),
                                onPressed: () => setState(() =>
                                    _showConfirm = !_showConfirm),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ],

                  // License + Pharmacy
                  Row(children: [
                    Expanded(
                      child: _Field(
                          label: 'License Number *',
                          child: TextField(
                              controller: _licenseCtrl,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.kTextDark),
                              decoration: _deco(
                                  hint: 'e.g. MAG-2022-0001'))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label: 'Pharmacy *',
                        child: DropdownButtonFormField<int?>(
                          value: _selectedPharmacyId,
                          isExpanded: true,
                          hint: const Text('Select pharmacy',
                              style: TextStyle(
                                  color: AppColors.kTextMid,
                                  fontSize: 13)),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.kTeal,
                                    width: 2)),
                          ),
                          items: widget.pharmacies
                              .map((p) => DropdownMenuItem<int?>(
                                  value: p['id'] as int,
                                  child: Text(p['name'] as String,
                                      style: const TextStyle(
                                          fontSize: 13))))
                              .toList(),
                          onChanged: (v) => setState(
                              () => _selectedPharmacyId = v),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Gender (create only)
                  if (!_isEdit) ...[
                    _Field(
                      label: 'Gender *',
                      child: Row(children: [
                        _GenderChip(
                            label: 'Male',
                            selected: _selectedGender == 'Male',
                            onTap: () => setState(
                                () => _selectedGender = 'Male')),
                        const SizedBox(width: 8),
                        _GenderChip(
                            label: 'Female',
                            selected: _selectedGender == 'Female',
                            onTap: () => setState(
                                () => _selectedGender = 'Female')),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Toggles
                  Row(children: [
                    Expanded(
                      child: _ToggleRow(
                        label: 'Administrator',
                        subtitle: 'Can manage all pharmacies',
                        value: _isAdministrator,
                        onChanged: (v) =>
                            setState(() => _isAdministrator = v),
                      ),
                    ),
                    if (_isEdit) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ToggleRow(
                          label: 'Active',
                          subtitle: 'Can log in to the system',
                          value: _isActive,
                          onChanged: (v) =>
                              setState(() => _isActive = v),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.kTextMid,
                              side: const BorderSide(
                                  color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10)),
                          child: const Text('Cancel',
                              style: TextStyle(fontSize: 13)),
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
                                      color: Colors.white))
                              : const Icon(Icons.save_outlined,
                                  size: 15),
                          label: Text(
                              _isEdit
                                  ? 'Save Changes'
                                  : 'Create Pharmacist',
                              style: const TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.kTeal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10)),
                        ),
                      ]),
                ]),
          ),
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextMid)),
          const SizedBox(height: 6),
          child,
        ],
      );
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GenderChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.kTealLight : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected
                    ? AppColors.kTeal
                    : const Color(0xFFE2E8F0),
                width: selected ? 2 : 1),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? AppColors.kTeal
                      : AppColors.kTextMid)),
        ),
      );
}

class _ToggleRow extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.label,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.kTextDark)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.kTextMid)),
                ]),
          ),
          Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.kTeal),
        ]),
      );
}