import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/exception_service.dart';
import '../theme/app_theme.dart';

class ExceptionsScreen extends StatefulWidget {
  const ExceptionsScreen({super.key});
  @override
  State<ExceptionsScreen> createState() => _ExceptionsScreenState();
}

class _ExceptionsScreenState extends State<ExceptionsScreen> {
  final _searchController = TextEditingController();
  String? _statusFilter = '1'; // default Pending
  String? _reasonFilter;
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _loading = true;
  List<EarlyDispenseExceptionModel> _exceptions = [];
  int _totalCount = 0;
  int? _pharmacyId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _isAdmin = prefs.getBool('isAdministrator') ?? false;
    if (!_isAdmin) {
      _pharmacyId = prefs.getInt('pharmacyId');
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await ExceptionService.getExceptions(
        page: _currentPage,
        pageSize: _pageSize,
        pharmacyId: _isAdmin ? null : _pharmacyId,
        status: _statusFilter,
        reasonType: _reasonFilter,
        patientName: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _exceptions = result.items;
          _totalCount = result.totalCount;
        });
      }
    } catch (e) {
      debugPrint('Exceptions load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalPages =>
      _totalCount == 0 ? 0 : (_totalCount / _pageSize).ceil();

  void _openDetail(EarlyDispenseExceptionModel ex) {
    showDialog(
      context: context,
      builder: (_) =>
          _ExceptionDetailDialog(exception: ex, onActionDone: _loadData),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case '1':
      case 'pending':
        return const Color(0xFFD97706);
      case '2':
      case 'approved':
        return const Color(0xFF059669);
      case '3':
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return AppColors.kTextMid;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case '1':
      case 'pending':
        return const Color(0xFFFEF3C7);
      case '2':
      case 'approved':
        return const Color(0xFFD1FAE5);
      case '3':
      case 'rejected':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case '1':
      case 'pending':
        return 'Pending';
      case '2':
      case 'approved':
        return 'Approved';
      case '3':
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  InputDecoration _dropdownDeco() => InputDecoration(
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

  String _fmtDateTime(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
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
                      hintText: 'Search by patient name...',
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

              // Status filter
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 44,
                  child: DropdownButtonFormField<String?>(
                    value: _statusFilter,
                    decoration: _dropdownDeco(),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'All statuses',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '1',
                        child: Text('Pending', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: '2',
                        child: Text('Approved', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: '3',
                        child: Text('Rejected', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _statusFilter = val;
                        _currentPage = 0;
                      });
                      _loadData();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Reason filter
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: DropdownButtonFormField<String?>(
                    value: _reasonFilter,
                    hint: const Text(
                      'All reasons',
                      style: TextStyle(color: AppColors.kTextMid, fontSize: 13),
                    ),
                    decoration: _dropdownDeco(),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'All reasons',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '1',
                        child: Text('Urgent', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: '2',
                        child: Text(
                          'Doctor Recommendation',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '3',
                        child: Text(
                          'Lost Medication',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '4',
                        child: Text('Travel', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: '5',
                        child: Text(
                          'Dose Change',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '99',
                        child: Text('Other', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _reasonFilter = val;
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
                        Expanded(
                          flex: 3,
                          child: Text('Patient', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Medication', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Pharmacy', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Reason', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Status',
                            textAlign: TextAlign.center,
                            style: _headerStyle,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Requested', style: _headerStyle),
                        ),
                        SizedBox(
                          width: 80,
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
                        : _exceptions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 48,
                                  color: AppColors.kTextMid.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No exceptions found',
                                  style: TextStyle(
                                    color: AppColors.kTextMid,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _exceptions.length,
                            itemBuilder: (context, index) {
                              final ex = _exceptions[index];
                              return _ExceptionRow(
                                exception: ex,
                                isEven: index.isEven,
                                statusColor: _statusColor(ex.status),
                                statusBg: _statusBg(ex.status),
                                statusLabel: _statusLabel(ex.status),
                                fmtDateTime: _fmtDateTime,
                                onTap: () => _openDetail(ex),
                              );
                            },
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
                            'Showing ${_currentPage * _pageSize + 1}–${(_currentPage * _pageSize + _exceptions.length)} of $_totalCount',
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
}

// ─── Row ──────────────────────────────────────────────────────────────────────
class _ExceptionRow extends StatefulWidget {
  final EarlyDispenseExceptionModel exception;
  final bool isEven;
  final Color statusColor, statusBg;
  final String statusLabel;
  final String Function(DateTime?) fmtDateTime;
  final VoidCallback onTap;

  const _ExceptionRow({
    required this.exception,
    required this.isEven,
    required this.statusColor,
    required this.statusBg,
    required this.statusLabel,
    required this.fmtDateTime,
    required this.onTap,
  });

  @override
  State<_ExceptionRow> createState() => _ExceptionRowState();
}

class _ExceptionRowState extends State<_ExceptionRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final ex = widget.exception;
    final isPending =
        ex.status.toLowerCase() == '0' || ex.status.toLowerCase() == 'pending';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _hovering
              ? AppColors.kTealLight.withValues(alpha: 0.4)
              : widget.isEven
              ? Colors.white
              : const Color(0xFFF8FAFC),
          border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            // Patient
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.patientName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kTextDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ex.patientEmail,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.kTextMid,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Medication
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.productName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kTextDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ex.dosage,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.kTextMid,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Pharmacy
            Expanded(
              flex: 2,
              child: Text(
                ex.pharmacyName,
                style: const TextStyle(fontSize: 12, color: AppColors.kTextMid),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Reason
            // Reason
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ExceptionService.reasonTypeLabel(ex.reasonType),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.kTextDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ex.otherReason != null &&
                      ex.otherReason!.isNotEmpty &&
                      ex.otherReason!.toLowerCase() !=
                          ExceptionService.reasonTypeLabel(
                            ex.reasonType,
                          ).toLowerCase())
                    Text(
                      ex.otherReason!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.kTextMid,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Status
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: widget.statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.statusColor,
                    ),
                  ),
                ),
              ),
            ),

            // Requested
            Expanded(
              flex: 2,
              child: Text(
                widget.fmtDateTime(ex.requestedAt),
                style: const TextStyle(fontSize: 11, color: AppColors.kTextMid),
              ),
            ),

            // Actions
            SizedBox(
              width: 80,
              child: Center(
                child: isPending
                    ? ElevatedButton(
                        onPressed: widget.onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kTeal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(0, 30),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        child: const Text('Review'),
                      )
                    : TextButton(
                        onPressed: widget.onTap,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.kTextMid,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 30),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        child: const Text('View'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail / Action Dialog ───────────────────────────────────────────────────
class _ExceptionDetailDialog extends StatefulWidget {
  final EarlyDispenseExceptionModel exception;
  final VoidCallback onActionDone;

  const _ExceptionDetailDialog({
    required this.exception,
    required this.onActionDone,
  });

  @override
  State<_ExceptionDetailDialog> createState() => _ExceptionDetailDialogState();
}

class _ExceptionDetailDialogState extends State<_ExceptionDetailDialog> {
  final _noteCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _isPending {
    final s = widget.exception.status.toLowerCase();
    return s == '1' || s == 'pending';
  }

  Future<void> _approve() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ExceptionService.approve(
        widget.exception.id,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onActionDone();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Exception approved.'),
              ],
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

  Future<void> _reject() async {
    if (_noteCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Note is required when rejecting.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ExceptionService.reject(
        widget.exception.id,
        note: _noteCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onActionDone();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.cancel, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Exception rejected.'),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
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

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  String _fmtDateTime(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exception;

    Color statusColor;
    Color statusBg;
    String statusLabel;
    switch (ex.status.toLowerCase()) {
      case '0':
      case 'pending':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        statusLabel = 'Pending';
        break;
      case '1':
      case 'approved':
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFD1FAE5);
        statusLabel = 'Approved';
        break;
      default:
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
        statusLabel = 'Rejected';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 540,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
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
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Early Dispense Exception',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kTextDark,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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

                // Two column info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Patient + Medication
                    Expanded(
                      child: Column(
                        children: [
                          _Section(
                            title: 'Patient',
                            icon: Icons.person_outline,
                            children: [
                              _DRow('Name', ex.patientName),
                              _DRow('Email', ex.patientEmail),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _Section(
                            title: 'Medication',
                            icon: Icons.medication_outlined,
                            children: [
                              _DRow('Product', ex.productName),
                              _DRow('Dosage', ex.dosage),
                              _DRow('Period', '${ex.periodDays} days'),
                              _DRow(
                                'Last Dispensed',
                                _fmtDate(ex.lastDispensedAt),
                              ),
                              _DRow(
                                'Next Eligible',
                                _fmtDate(ex.nextEligibleDispenseAt),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Right: Exception details
                    Expanded(
                      child: Column(
                        children: [
                          _Section(
                            title: 'Request Details',
                            icon: Icons.warning_amber_outlined,
                            children: [
                              _DRow('Pharmacy', ex.pharmacyName),
                              _DRow('Requested', _fmtDateTime(ex.requestedAt)),
                              _DRow(
                                'Reason',
                                ExceptionService.reasonTypeLabel(ex.reasonType),
                              ),
                              if (ex.otherReason != null &&
                                  ex.otherReason!.isNotEmpty)
                                _DRow('Details', ex.otherReason!),
                            ],
                          ),
                          if (!_isPending) ...[
                            const SizedBox(height: 12),
                            _Section(
                              title: 'Resolution',
                              icon: Icons.check_circle_outline,
                              children: [
                                _DRow('Resolved', _fmtDateTime(ex.approvedAt)),
                                if (ex.approvedByPharmacistName != null)
                                  _DRow(
                                    'By Pharmacist',
                                    ex.approvedByPharmacistName!,
                                  ),
                                if (ex.note != null && ex.note!.isNotEmpty)
                                  _DRow('Note', ex.note!),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Action section (only for pending)
                if (_isPending) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Pharmacist Note',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextMid,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.kTextDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a note (required for rejection)...',
                      hintStyle: const TextStyle(
                        color: AppColors.kTextMid,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
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
                        onPressed: _saving ? null : _reject,
                        icon: _saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cancel_outlined, size: 15),
                        label: const Text(
                          'Reject',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
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
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _approve,
                        icon: _saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 15),
                        label: const Text(
                          'Approve',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
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
                ] else ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
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
                        child: const Text(
                          'Close',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section + Detail Row helpers ────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.kTeal),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

class _DRow extends StatelessWidget {
  final String label, value;
  const _DRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.kTextMid,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.kTextDark),
          ),
        ),
      ],
    ),
  );
}
