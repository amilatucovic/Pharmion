import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/inventory_service.dart';
import '../services/reservation_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'pdf_generators/inventory_pdf.dart';
import 'pdf_generators/reservations_pdf.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.kTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.kTextMid,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.inventory_2_outlined, size: 18),
                  text: 'Inventory Status Report',
                ),
                Tab(
                  icon: Icon(Icons.assignment_outlined, size: 18),
                  text: 'Reservations Report',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_InventoryReportTab(), _ReservationsReportTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryReportTab extends StatefulWidget {
  const _InventoryReportTab();

  @override
  State<_InventoryReportTab> createState() => _InventoryReportTabState();
}

class _InventoryReportTabState extends State<_InventoryReportTab> {
  int? _selectedPharmacyId;
  String _selectedPharmacyName = 'All Pharmacies';
  String? _statusFilter;
  List<Map<String, dynamic>> _pharmacies = [];
  bool _loadingPharmacies = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
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
    } finally {
      if (mounted) setState(() => _loadingPharmacies = false);
    }
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final result = await InventoryService.getItems(
        page: 0,
        pageSize: 1000,
        pharmacyId: _selectedPharmacyId,
        lowStock: _statusFilter == 'lowStock' ? true : null,
        expiringSoon: _statusFilter == 'expiringSoon' ? true : null,
      );

      String filterLabel = '';
      if (_statusFilter == 'lowStock') filterLabel = 'Low Stock Only';
      if (_statusFilter == 'expiringSoon') filterLabel = 'Expiring Soon Only';

      final pdfBytes = await InventoryPdfGenerator.generate(
        items: result.items,
        pharmacyName: _selectedPharmacyName,
        filterLabel: filterLabel,
        showPharmacyColumn: _selectedPharmacyId == null,
      );

      await Printing.layoutPdf(onLayout: (_) => pdfBytes, name: '...');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: Container(
            padding: const EdgeInsets.all(24),
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
            child: SingleChildScrollView(
              child: Column(
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
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: AppColors.kTeal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inventory Report',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kTextDark,
                            ),
                          ),
                          Text(
                            'Configure & generate PDF',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.kTextMid,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  const _SectionLabel('Pharmacy'),
                  const SizedBox(height: 8),
                  _loadingPharmacies
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.kTeal,
                          ),
                        )
                      : DropdownButtonFormField<int?>(
                          value: _selectedPharmacyId,
                          isExpanded: true,
                          decoration: _inputDeco(),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text(
                                'All Pharmacies',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            ..._pharmacies.map(
                              (p) => DropdownMenuItem<int?>(
                                value: p['id'] as int,
                                child: Text(
                                  p['name'] as String,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedPharmacyId = val;
                              _selectedPharmacyName = val == null
                                  ? 'All Pharmacies'
                                  : _pharmacies.firstWhere(
                                          (p) => p['id'] == val,
                                        )['name']
                                        as String;
                            });
                          },
                        ),
                  const SizedBox(height: 16),

                  const _SectionLabel('Stock Filter'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _statusFilter,
                    isExpanded: true,
                    decoration: _inputDeco(),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'All Items',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'lowStock',
                        child: Text(
                          'Low Stock Only',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'expiringSoon',
                        child: Text(
                          'Expiring Soon Only',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _statusFilter = val),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.kTealLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: AppColors.kTeal,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Report includes:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kTeal,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        _BulletPoint(
                          'Summary: total items, low stock, expiring, expired',
                        ),
                        _BulletPoint('Full inventory table with quantities'),
                        _BulletPoint('Expiration dates and status badges'),
                        _BulletPoint('Pharmacy and product details'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _generating ? null : _generate,
                      icon: _generating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(
                        _generating ? 'Generating...' : 'Generate PDF',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
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
                const Text(
                  'Report Preview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'The generated PDF will contain the following sections:',
                  style: TextStyle(fontSize: 12, color: AppColors.kTextMid),
                ),
                const SizedBox(height: 20),
                _PreviewSection(
                  icon: Icons.view_headline_rounded,
                  title: 'Header',
                  description:
                      'Pharmion logo, report title, generation date, selected pharmacy and active filters.',
                ),
                _PreviewSection(
                  icon: Icons.dashboard_outlined,
                  title: 'Summary Cards',
                  description:
                      'Quick overview: total items count, low stock count, expiring soon count, expired count.',
                ),
                _PreviewSection(
                  icon: Icons.table_chart_outlined,
                  title: 'Inventory Table',
                  description:
                      'Complete list with columns: Product, SKU, On Hand, Reserved, Available, Reorder At, Expiration Date, Status.',
                ),
                _PreviewSection(
                  icon: Icons.horizontal_rule,
                  title: 'Footer',
                  description: 'Report name and page numbers on each page.',
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.print_outlined,
                        size: 16,
                        color: AppColors.kTextMid,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Clicking "Generate PDF" will open the system print/save dialog where you can print or save as PDF. For Inventory Status Report, choose portrait orientation for best results. For Reservations Report, landscape orientation is recommended.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.kTextMid,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReservationsReportTab extends StatefulWidget {
  const _ReservationsReportTab();

  @override
  State<_ReservationsReportTab> createState() => _ReservationsReportTabState();
}

class _ReservationsReportTabState extends State<_ReservationsReportTab> {
  int? _selectedPharmacyId;
  String _selectedPharmacyName = 'All Pharmacies';
  String? _selectedState;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  List<Map<String, dynamic>> _pharmacies = [];
  bool _loadingPharmacies = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, now.month, 1);
    _dateTo = now;
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
    } finally {
      if (mounted) setState(() => _loadingPharmacies = false);
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_dateFrom ?? DateTime.now())
          : (_dateTo ?? DateTime.now()),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.kTeal),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final result = await ReservationService.getReservations(
        page: 0,
        pageSize: 1000,
        state: _selectedState,
        pharmacyId: _selectedPharmacyId,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

      String periodLabel = '';
      if (_dateFrom != null && _dateTo != null) {
        periodLabel = '${_fmtDate(_dateFrom!)} — ${_fmtDate(_dateTo!)}';
      } else if (_dateFrom != null) {
        periodLabel = 'From ${_fmtDate(_dateFrom!)}';
      } else if (_dateTo != null) {
        periodLabel = 'Until ${_fmtDate(_dateTo!)}';
      }

      String statusLabel = _selectedState != null
          ? _selectedState!.replaceAll('ReservationState', '')
          : 'All Statuses';

      final pdfBytes = await ReservationsPdfGenerator.generate(
        reservations: result.items,
        pharmacyName: _selectedPharmacyName,
        periodLabel: periodLabel,
        statusLabel: statusLabel,
      );

      await Printing.layoutPdf(onLayout: (_) => pdfBytes, name: '...');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: Container(
            padding: const EdgeInsets.all(24),
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reservations Report',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kTextDark,
                            ),
                          ),
                          Text(
                            'Configure & generate PDF',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.kTextMid,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  const _SectionLabel('Pharmacy'),
                  const SizedBox(height: 8),
                  _loadingPharmacies
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.kTeal,
                          ),
                        )
                      : DropdownButtonFormField<int?>(
                          value: _selectedPharmacyId,
                          isExpanded: true,
                          decoration: _inputDeco(),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text(
                                'All Pharmacies',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            ..._pharmacies.map(
                              (p) => DropdownMenuItem<int?>(
                                value: p['id'] as int,
                                child: Text(
                                  p['name'] as String,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedPharmacyId = val;
                              _selectedPharmacyName = val == null
                                  ? 'All Pharmacies'
                                  : _pharmacies.firstWhere(
                                          (p) => p['id'] == val,
                                        )['name']
                                        as String;
                            });
                          },
                        ),
                  const SizedBox(height: 16),

                  const _SectionLabel('Reservation Status'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _selectedState,
                    isExpanded: true,
                    decoration: _inputDeco(),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'All Statuses',
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
                    onChanged: (val) => setState(() => _selectedState = val),
                  ),
                  const SizedBox(height: 16),

                  const _SectionLabel('Date Range'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickDate(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _dateFrom != null
                                    ? AppColors.kTeal
                                    : const Color(0xFFE2E8F0),
                                width: _dateFrom != null ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: _dateFrom != null
                                      ? AppColors.kTeal
                                      : AppColors.kTextMid,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _dateFrom != null
                                      ? _fmtDate(_dateFrom!)
                                      : 'From',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _dateFrom != null
                                        ? AppColors.kTeal
                                        : AppColors.kTextMid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickDate(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _dateTo != null
                                    ? AppColors.kTeal
                                    : const Color(0xFFE2E8F0),
                                width: _dateTo != null ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: _dateTo != null
                                      ? AppColors.kTeal
                                      : AppColors.kTextMid,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _dateTo != null ? _fmtDate(_dateTo!) : 'To',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _dateTo != null
                                        ? AppColors.kTeal
                                        : AppColors.kTextMid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Report includes:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        _BulletPoint(
                          'Financial summary: revenue, patient pays, insurance',
                          color: Color(0xFF1E3A5F),
                        ),
                        _BulletPoint(
                          'Status breakdown count',
                          color: Color(0xFF1E3A5F),
                        ),
                        _BulletPoint(
                          'Full reservations table with patient info',
                          color: Color(0xFF1E3A5F),
                        ),
                        _BulletPoint(
                          'Totals row at bottom',
                          color: Color(0xFF1E3A5F),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _generating ? null : _generate,
                      icon: _generating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(
                        _generating ? 'Generating...' : 'Generate PDF',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
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
                const Text(
                  'Report Preview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'The generated PDF will contain the following sections:',
                  style: TextStyle(fontSize: 12, color: AppColors.kTextMid),
                ),
                const SizedBox(height: 20),
                _PreviewSection(
                  icon: Icons.view_headline_rounded,
                  title: 'Header',
                  description:
                      'Pharmion logo, report title, generation date, pharmacy, period and status filter.',
                ),
                _PreviewSection(
                  icon: Icons.bar_chart_rounded,
                  title: 'Financial Summary',
                  description:
                      'Total reservations, total revenue, patient pays total, insurance pays total.',
                ),
                _PreviewSection(
                  icon: Icons.donut_small_outlined,
                  title: 'Status Breakdown',
                  description:
                      'Count of reservations per status (Submitted, Approved, PickedUp, etc.)',
                ),
                _PreviewSection(
                  icon: Icons.table_chart_outlined,
                  title: 'Reservations Table',
                  description:
                      'Full list: Patient name & email, Pharmacy, Item count, Total, Patient Pays, Date, Status.',
                ),
                _PreviewSection(
                  icon: Icons.calculate_outlined,
                  title: 'Totals Row',
                  description: 'Sum of all amounts at the bottom of the table.',
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.print_outlined,
                        size: 16,
                        color: AppColors.kTextMid,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Clicking "Generate PDF" will open the system print/save dialog where you can print or save as PDF. For Inventory Status Report, choose portrait orientation for best results. For Reservations Report, landscape orientation is recommended.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.kTextMid,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDeco() => InputDecoration(
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
  constraints: const BoxConstraints(maxHeight: 44),
);

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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

class _BulletPoint extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletPoint(this.text, {this.color = AppColors.kTextDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 11, color: color)),
        ),
      ],
    ),
  );
}

class _PreviewSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _PreviewSection({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.kTealLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.kTeal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: AppColors.kTextMid),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
