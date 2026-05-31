import 'package:flutter/material.dart';
import '../services/chronic_disease_service.dart';
import '../theme/app_theme.dart';
import '../core/errors/app_exception.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../widgets/pagination_widget.dart';

class ChronicDiseasesScreen extends StatefulWidget {
  const ChronicDiseasesScreen({super.key});
  @override
  State<ChronicDiseasesScreen> createState() => _ChronicDiseasesScreenState();
}

class _ChronicDiseasesScreenState extends State<ChronicDiseasesScreen> {
  final _searchController = TextEditingController();
  bool? _isActive;
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _loading = true;
  List<ChronicDiseaseModel> _diseases = [];
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
      final result = await ChronicDiseaseService.getDiseases(
        page: _currentPage,
        pageSize: _pageSize,
        name: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        isActive: _isActive,
      );
      if (mounted) {
        setState(() {
          _diseases = result.items;
          _totalCount = result.totalCount;
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

  int get _totalPages {
    if (_totalCount == 0) return 0;
    return (_totalCount / _pageSize).ceil();
  }

  void _openCreate() => showDialog(
    context: context,
    builder: (_) => _DiseaseDialog(onSaved: _loadData),
  );

  void _openEdit(ChronicDiseaseModel d) => showDialog(
    context: context,
    builder: (_) => _DiseaseDialog(disease: d, onSaved: _loadData),
  );

  Future<void> _delete(ChronicDiseaseModel d) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Chronic Disease',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to delete "${d.name}"? This cannot be undone.',
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
      await ChronicDiseaseService.delete(d.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chronic disease deleted.'),
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
                  label: const Text('New Disease'),
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
                        Expanded(
                          flex: 1,
                          child: Text('Code', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Name', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text('Description', style: _headerStyle),
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

                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.kTeal,
                            ),
                          )
                        : _diseases.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.healing_outlined,
                                  size: 48,
                                  color: AppColors.kTextMid.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No chronic diseases found',
                                  style: TextStyle(
                                    color: AppColors.kTextMid,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _diseases.length,
                            itemBuilder: (context, index) => _DiseaseRow(
                              disease: _diseases[index],
                              isEven: index.isEven,
                              onEdit: () => _openEdit(_diseases[index]),
                              onDelete: () => _delete(_diseases[index]),
                            ),
                          ),
                  ),

                  if (!_loading && _totalCount > 0)
                    PaginationWidget(
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      totalCount: _totalCount,
                      pageSize: _pageSize,
                      itemCount: _diseases.length,
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

class _DiseaseRow extends StatefulWidget {
  final ChronicDiseaseModel disease;
  final bool isEven;
  final VoidCallback onEdit, onDelete;

  const _DiseaseRow({
    required this.disease,
    required this.isEven,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DiseaseRow> createState() => _DiseaseRowState();
}

class _DiseaseRowState extends State<_DiseaseRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.disease;
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
            SizedBox(
              width: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  d.code,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C3AED),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  d.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kTextDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            Expanded(
              flex: 4,
              child: Text(
                d.description.isEmpty ? '—' : d.description,
                style: const TextStyle(fontSize: 12, color: AppColors.kTextMid),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: d.isActive
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
                          color: d.isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        d.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: d.isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
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

class _DiseaseDialog extends StatefulWidget {
  final ChronicDiseaseModel? disease;
  final VoidCallback onSaved;
  const _DiseaseDialog({this.disease, required this.onSaved});

  @override
  State<_DiseaseDialog> createState() => _DiseaseDialogState();
}

class _DiseaseDialogState extends State<_DiseaseDialog> {
  bool get _isEdit => widget.disease != null;

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isActive = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _codeController.text = widget.disease!.code;
      _nameController.text = widget.disease!.name;
      _descController.text = widget.disease!.description;
      _isActive = widget.disease!.isActive;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();

    if (code.isEmpty) {
      setState(() => _error = 'Code is required.');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final body = {
        'code': code,
        'name': name,
        'description': _descController.text.trim(),
        'isActive': _isActive,
      };

      if (_isEdit) {
        await ChronicDiseaseService.update(widget.disease!.id, body);
      } else {
        await ChronicDiseaseService.create(body);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? 'Chronic disease updated.' : 'Chronic disease created.',
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

  InputDecoration _inputDeco({required String hint, int? maxLines}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.kTextMid, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: maxLines != null ? 12 : 12,
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
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.healing_rounded,
                      size: 18,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? 'Edit Chronic Disease' : 'New Chronic Disease',
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

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Code *'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _codeController,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.kTextDark,
                          ),
                          maxLength: 50,
                          buildCounter:
                              (
                                _, {
                                required currentLength,
                                required isFocused,
                                maxLength,
                              }) => null,
                          decoration: _inputDeco(hint: 'e.g. DM2'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Name *'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.kTextDark,
                          ),
                          maxLength: 150,
                          buildCounter:
                              (
                                _, {
                                required currentLength,
                                required isFocused,
                                maxLength,
                              }) => null,
                          decoration: _inputDeco(hint: 'e.g. Type 2 Diabetes'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _Label('Description'),
              const SizedBox(height: 6),
              TextField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.kTextDark,
                ),
                decoration: _inputDeco(
                  hint: 'Optional description of the condition...',
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 14),

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
                            'Inactive diseases are hidden from patients during registration',
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
                      _isEdit ? 'Save Changes' : 'Create',
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
