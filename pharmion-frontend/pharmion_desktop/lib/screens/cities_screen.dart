import 'package:flutter/material.dart';
import '../services/city_service.dart';
import '../theme/app_theme.dart';

class CitiesScreen extends StatefulWidget {
  const CitiesScreen({super.key});
  @override
  State<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends State<CitiesScreen> {
  final _searchController = TextEditingController();
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _loading = true;
  List<CityModel> _cities = [];
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
      final result = await CityService.getCities(
        page: _currentPage,
        pageSize: _pageSize,
        name: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _cities = result.items;
          _totalCount = result.totalCount;
        });
      }
    } catch (e) {
      debugPrint('Cities load error: $e');
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
      builder: (_) => _CityDialog(onSaved: _loadData));

  void _openEdit(CityModel c) => showDialog(
      context: context,
      builder: (_) => _CityDialog(city: c, onSaved: _loadData));

  Future<void> _delete(CityModel c) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete City',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
                'Are you sure you want to delete "${c.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.kTextMid))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await CityService.delete(c.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('City deleted.'),
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
                  hintText: 'Search by city name...',
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
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New City'),
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
                      flex: 4,
                      child: Text('City Name', style: _headerStyle)),
                  Expanded(
                      flex: 2,
                      child: Text('Postal Code',
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
                    : _cities.isEmpty
                        ? Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                Icon(Icons.location_city_outlined,
                                    size: 48,
                                    color: AppColors.kTextMid
                                        .withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                const Text('No cities found',
                                    style: TextStyle(
                                        color: AppColors.kTextMid,
                                        fontSize: 14)),
                              ]))
                        : ListView.builder(
                            itemCount: _cities.length,
                            itemBuilder: (context, index) => _CityRow(
                              city: _cities[index],
                              isEven: index.isEven,
                              onEdit: () => _openEdit(_cities[index]),
                              onDelete: () => _delete(_cities[index]),
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
                        'Showing ${_currentPage * _pageSize + 1}–${(_currentPage * _pageSize + _cities.length)} of $_totalCount',
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

// ─── Row Widget ───────────────────────────────────────────────────────────────
class _CityRow extends StatefulWidget {
  final CityModel city;
  final bool isEven;
  final VoidCallback onEdit, onDelete;

  const _CityRow(
      {required this.city,
      required this.isEven,
      required this.onEdit,
      required this.onDelete});

  @override
  State<_CityRow> createState() => _CityRowState();
}

class _CityRowState extends State<_CityRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.city;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          // Icon
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
                color: AppColors.kTealLight,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.location_city_rounded,
                size: 18, color: AppColors.kTeal),
          ),

          // Name
          Expanded(
            flex: 4,
            child: Text(c.name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kTextDark),
                overflow: TextOverflow.ellipsis),
          ),

          // Postal Code
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(c.postalCode,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextMid)),
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
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Color(0xFFDC2626)),
                  tooltip: 'Delete',
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

// ─── Create / Edit Dialog ─────────────────────────────────────────────────────
class _CityDialog extends StatefulWidget {
  final CityModel? city;
  final VoidCallback onSaved;
  const _CityDialog({this.city, required this.onSaved});

  @override
  State<_CityDialog> createState() => _CityDialogState();
}

class _CityDialogState extends State<_CityDialog> {
  bool get _isEdit => widget.city != null;

  final _nameController = TextEditingController();
  final _postalController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameController.text = widget.city!.name;
      _postalController.text = widget.city!.postalCode;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final postal = _postalController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'City name is required.');
      return;
    }
    if (postal.isEmpty) {
      setState(() => _error = 'Postal code is required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final body = {'name': name, 'postalCode': postal};
      if (_isEdit) {
        await CityService.update(widget.city!.id, body);
      } else {
        await CityService.create(body);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit
              ? 'City updated successfully.'
              : 'City created successfully.'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
           setState(
            () => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDeco({required String hint}) => InputDecoration(
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
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                    child: const Icon(Icons.location_city_rounded,
                        size: 18, color: AppColors.kTeal),
                  ),
                  const SizedBox(width: 12),
                  Text(_isEdit ? 'Edit City' : 'New City',
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

                // Name
                _Label('City Name *'),
                const SizedBox(height: 6),
                TextField(
                    controller: _nameController,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.kTextDark),
                    decoration:
                        _inputDeco(hint: 'e.g. Sarajevo')),
                const SizedBox(height: 14),

                // Postal Code
                _Label('Postal Code *'),
                const SizedBox(height: 6),
                TextField(
                    controller: _postalController,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.kTextDark),
                    decoration: _inputDeco(hint: 'e.g. 71000'),
                    maxLength: 20,
                    buildCounter: (_, {required currentLength,
                          required isFocused,
                          maxLength}) =>
                        null),
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
                            _isEdit ? 'Save Changes' : 'Create City',
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
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.kTextMid));
}