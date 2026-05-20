import 'package:flutter/material.dart';
import 'package:pharmion_desktop/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/reservation_service.dart';
import '../theme/app_theme.dart';
import 'reservation_detail_screen.dart';
import '../core/errors/app_exception.dart';
import 'login_screen.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final _searchController = TextEditingController();
  String? _selectedState;
  int _currentPage = 0;
  static const int _pageSize = 10;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _isAdmin = false;
  int? _myPharmacyId;

  bool _loading = true;
  List<ReservationModel> _reservations = [];
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final admin = await ApiService.isAdmin();
    setState(() {
      _isAdmin = admin;
      _myPharmacyId = prefs.getInt('pharmacyId');
    });
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
      final result = await ReservationService.getReservations(
        page: _currentPage,
        pageSize: _pageSize,
        state: _selectedState,
        patientName: _searchController.text.trim(),
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        pharmacyId: _isAdmin ? null : _myPharmacyId,
      );
      if (mounted) {
        setState(() {
          _reservations = result.items;
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

  void _onSearch(String _) {
    setState(() => _currentPage = 0);
    _loadData();
  }

  void _onStateChanged(String? state) {
    setState(() {
      _selectedState = state;
      _currentPage = 0;
    });
    _loadData();
  }

  void _openDetail(ReservationModel reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationDetailScreen(reservationId: reservation.id),
      ),
    ).then((_) => _loadData());
  }

  int get _totalPages => (_totalCount / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: _onSearch,
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
                                _onSearch('');
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
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedState,
                    hint: const Text(
                      'All statuses',
                      style: TextStyle(color: AppColors.kTextMid, fontSize: 13),
                    ),
                    decoration: InputDecoration(
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
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'All statuses',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      ...ReservationService.allStates.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            ReservationService.stateDisplayName(s),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    onChanged: _onStateChanged,
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateFrom ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.kTeal,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateFrom = picked;
                          _currentPage = 0;
                        });
                        _loadData();
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 15),
                    label: Text(
                      _dateFrom != null
                          ? 'From: ${_dateFrom!.day}.${_dateFrom!.month}.${_dateFrom!.year}'
                          : 'From date',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _dateFrom != null
                          ? AppColors.kTeal
                          : AppColors.kTextMid,
                      side: BorderSide(
                        color: _dateFrom != null
                            ? AppColors.kTeal
                            : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateTo ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.kTeal,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateTo = picked;
                          _currentPage = 0;
                        });
                        _loadData();
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 15),
                    label: Text(
                      _dateTo != null
                          ? 'To: ${_dateTo!.day}.${_dateTo!.month}.${_dateTo!.year}'
                          : 'To date',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _dateTo != null
                          ? AppColors.kTeal
                          : AppColors.kTextMid,
                      side: BorderSide(
                        color: _dateTo != null
                            ? AppColors.kTeal
                            : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_dateFrom != null || _dateTo != null)
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _dateFrom = null;
                        _dateTo = null;
                        _currentPage = 0;
                      });
                      _loadData();
                    },
                    icon: const Icon(Icons.clear, size: 15),
                    label: const Text(
                      'Clear dates',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

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
                          flex: 3,
                          child: Text(
                            'Patient',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Pharmacy',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Items',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Date',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMid,
                              fontSize: 12,
                            ),
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
                        : _reservations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 48,
                                  color: AppColors.kTextMid.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No reservations found',
                                  style: TextStyle(
                                    color: AppColors.kTextMid,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _reservations.length,
                            itemBuilder: (context, index) {
                              final r = _reservations[index];
                              return _ReservationRow(
                                reservation: r,
                                isEven: index.isEven,
                                onTap: () => _openDetail(r),
                              );
                            },
                          ),
                  ),

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
                            'Showing ${_currentPage * _pageSize + 1}–${(_currentPage * _pageSize + _reservations.length)} of $_totalCount',
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
                            final page = i;
                            final isSelected = page == _currentPage;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _currentPage = page);
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
                                    '${page + 1}',
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

class _ReservationRow extends StatefulWidget {
  final ReservationModel reservation;
  final bool isEven;
  final VoidCallback onTap;

  const _ReservationRow({
    required this.reservation,
    required this.isEven,
    required this.onTap,
  });

  @override
  State<_ReservationRow> createState() => _ReservationRowState();
}

class _ReservationRowState extends State<_ReservationRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.patientName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kTextDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    r.patientEmail,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.kTextMid,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 3,
              child: Text(
                r.pharmacyName,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.kTextDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${r.items.length} item${r.items.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.kTextMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                '${r.totalAmount.toStringAsFixed(2)} KM',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextDark,
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                _formatDate(r.submittedAt ?? r.createdAt),
                style: const TextStyle(fontSize: 12, color: AppColors.kTextMid),
              ),
            ),

            Expanded(
              flex: 2,
              child: _ReservationStatusBadge(status: r.reservationStateDisplay),
            ),

            SizedBox(
              width: 100,
              child: Center(
                child: TextButton(
                  onPressed: widget.onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.kTeal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.kTeal),
                    ),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

class _ReservationStatusBadge extends StatelessWidget {
  final String status;
  const _ReservationStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'draft':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        icon = Icons.edit_outlined;
        break;
      case 'submitted':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        icon = Icons.pending_outlined;
        break;
      case 'approved':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        icon = Icons.check_circle_outline;
        break;
      case 'readyforpickup':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        icon = Icons.local_shipping_outlined;
        break;
      case 'pickedup':
        bg = AppColors.kTealLight;
        fg = AppColors.kTeal;
        icon = Icons.done_all;
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        icon = Icons.cancel_outlined;
        break;
      case 'cancelled':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        icon = Icons.block_outlined;
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        icon = Icons.help_outline;
    }

    String _formatStatus(String status) {
      return status.replaceAllMapped(
        RegExp(r'(?<=[a-z])(?=[A-Z])'),
        (match) => ' ',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _formatStatus(status),
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
