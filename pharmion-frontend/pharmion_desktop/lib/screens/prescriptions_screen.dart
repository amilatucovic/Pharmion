import 'package:flutter/material.dart';
import '../services/prescription_service.dart';
import '../theme/app_theme.dart';
import 'prescription_detail_screen.dart';
import 'prescription_form_screen.dart';
import '../core/errors/app_exception.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../widgets/pagination_widget.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  int _currentPage = 0;
  static const int _pageSize = 10;

  bool _loading = true;
  List<PrescriptionModel> _prescriptions = [];
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
      final result = await PrescriptionService.getPrescriptions(
        page: _currentPage,
        pageSize: _pageSize,
        status: _selectedStatus,
        patientName: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _prescriptions = result.items;
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

  int get _totalPages => (_totalCount / _pageSize).ceil();

  void _openDetail(PrescriptionModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrescriptionDetailScreen(prescriptionId: p.id),
      ),
    ).then((_) => _loadData());
  }

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrescriptionFormScreen()),
    ).then((_) => _loadData());
  }

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
                    onSubmitted: (_) {
                      setState(() => _currentPage = 0);
                      _loadData();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by patient...',
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
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
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
                      ...PrescriptionService.allStatuses.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedStatus = val;
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
                  label: const Text('New Prescription'),
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
                    child: const Row(
                      children: [
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
                            'Doctor / Facility',
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
                            'Valid to',
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
                        : _prescriptions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 48,
                                  color: AppColors.kTextMid.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No prescriptions found',
                                  style: TextStyle(
                                    color: AppColors.kTextMid,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _prescriptions.length,
                            itemBuilder: (context, index) => _PrescriptionRow(
                              prescription: _prescriptions[index],
                              isEven: index.isEven,
                              onTap: () => _openDetail(_prescriptions[index]),
                            ),
                          ),
                  ),

                  if (!_loading && _totalCount > 0)
                    PaginationWidget(
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      totalCount: _totalCount,
                      pageSize: _pageSize,
                      itemCount: _prescriptions.length,
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

class _PrescriptionRow extends StatefulWidget {
  final PrescriptionModel prescription;
  final bool isEven;
  final VoidCallback onTap;

  const _PrescriptionRow({
    required this.prescription,
    required this.isEven,
    required this.onTap,
  });

  @override
  State<_PrescriptionRow> createState() => _PrescriptionRowState();
}

class _PrescriptionRowState extends State<_PrescriptionRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.prescription;
    final isExpired = p.validTo != null && p.validTo!.isBefore(DateTime.now());

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
                    p.patientName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kTextDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'by ${p.pharmacistName}',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.doctorName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.kTextDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (p.facility != null && p.facility!.isNotEmpty)
                    Text(
                      p.facility!,
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
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${p.items.length} item${p.items.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.kTextMid,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: p.validTo != null
                  ? Text(
                      _formatDate(p.validTo!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired
                            ? const Color(0xFFDC2626)
                            : AppColors.kTextMid,
                        fontWeight: isExpired
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    )
                  : const Text(
                      '—',
                      style: TextStyle(fontSize: 13, color: AppColors.kTextMid),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _PrescriptionStatusBadge(status: p.statusDisplay),
              ),
            ),
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerLeft,
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

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

class _PrescriptionStatusBadge extends StatelessWidget {
  final String status;
  const _PrescriptionStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'active':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        bg = AppColors.kTealLight;
        fg = AppColors.kTeal;
        icon = Icons.done_all;
        break;
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        icon = Icons.help_outline;
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
              status,
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
