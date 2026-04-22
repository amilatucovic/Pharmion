import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/inventory_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  bool _lowStockOnly = false;
  bool _expiringSoonOnly = false;
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _loading = true;
  List<InventoryItemModel> _items = [];
  int _totalCount = 0;
  bool _isAdmin = false;
  int? _myPharmacyId;
  int? _selectedPharmacyId;
  List<Map<String, dynamic>> _pharmacies = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final admin = await ApiService.isAdmin();
    setState(() {
      _isAdmin = admin;
      _myPharmacyId = prefs.getInt('pharmacyId');
    });
    if (admin) await _loadPharmacies();
    _loadData();
  }

  Future<void> _loadPharmacies() async {
    try {
      final data = await ApiService.get('Pharmacy?retrieveAll=true');
      if (mounted) {
        setState(() {
          _pharmacies = (data['items'] as List)
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
      final result = await InventoryService.getItems(
        page: _currentPage,
        pageSize: _pageSize,
        pharmacyId: _isAdmin ? _selectedPharmacyId : _myPharmacyId,
        productName: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        lowStock: _lowStockOnly ? true : null,
        expiringSoon: _expiringSoonOnly ? true : null,
      );
      if (mounted) {
        setState(() {
          _items = result.items;
          _totalCount = result.totalCount;
        });
      }
    } catch (e) {
      debugPrint('Inventory load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalPages {
    if (_totalCount == 0) return 0;
    return (_totalCount / _pageSize).ceil();
  }

  void _openAddItem() => showDialog(
    context: context,
    builder: (_) => _InventoryItemDialog(onSaved: _loadData),
  );

  void _openEdit(InventoryItemModel item) => showDialog(
    context: context,
    builder: (_) => _InventoryItemDialog(item: item, onSaved: _loadData),
  );

  void _openStockMovement(InventoryItemModel item) => showDialog(
    context: context,
    builder: (_) => _StockMovementDialog(item: item, onSaved: _loadData),
  );

  Future<void> _delete(InventoryItemModel item) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Remove from Inventory',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Remove "${item.productName}" from inventory? This cannot be undone.',
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
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await InventoryService.delete(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item removed from inventory.'),
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
          // ── Filters ───────────────────────────────────────────────────────────
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
                      hintText: 'Search by product name...',
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
              if (_isAdmin) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: DropdownButtonFormField<int?>(
                      value: _selectedPharmacyId,
                      hint: const Text(
                        'All pharmacies',
                        style: TextStyle(
                          color: AppColors.kTextMid,
                          fontSize: 13,
                        ),
                      ),
                      decoration: _dropdownDecoration(),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'All pharmacies',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        ..._pharmacies.map(
                          (p) => DropdownMenuItem<int?>(
                            value: p['id'],
                            child: Text(
                              p['name'],
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
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
              ],
              const SizedBox(width: 12),
              _FilterChip(
                label: 'Low Stock',
                icon: Icons.warning_amber_rounded,
                active: _lowStockOnly,
                color: const Color(0xFFDC2626),
                onTap: () {
                  setState(() {
                    _lowStockOnly = !_lowStockOnly;
                    _currentPage = 0;
                  });
                  _loadData();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Expiring Soon',
                icon: Icons.schedule_rounded,
                active: _expiringSoonOnly,
                color: const Color(0xFFD97706),
                onTap: () {
                  setState(() {
                    _expiringSoonOnly = !_expiringSoonOnly;
                    _currentPage = 0;
                  });
                  _loadData();
                },
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
              if (_isAdmin) ...[
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _openAddItem,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Item'),
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
            ],
          ),
          const SizedBox(height: 16),

          // ── Table ─────────────────────────────────────────────────────────────
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
                  // ── Header ───────────────────────────────────────────────────────
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
                      children: [
                        const SizedBox(width: 56),
                        const Expanded(
                          flex: 3,
                          child: Text('Product', style: _headerStyle),
                        ),
                        if (_isAdmin)
                          const Expanded(
                            flex: 2,
                            child: Text('Pharmacy', style: _headerStyle),
                          ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'On Hand',
                            textAlign: TextAlign.center,
                            style: _headerStyle,
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Reserved',
                            textAlign: TextAlign.center,
                            style: _headerStyle,
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Available',
                            textAlign: TextAlign.center,
                            style: _headerStyle,
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Reorder At',
                            textAlign: TextAlign.center,
                            style: _headerStyle,
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Expiration',
                            textAlign: TextAlign.center,
                            style: _headerStyle,
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Status',
                            textAlign: TextAlign.center,
                            style: _headerStyle,
                          ),
                        ),
                        const SizedBox(
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

                  // ── Body ─────────────────────────────────────────────────────────
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
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: AppColors.kTextMid.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No inventory items found',
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
                            itemBuilder: (context, index) => _InventoryRow(
                              item: _items[index],
                              isEven: index.isEven,
                              isAdmin: _isAdmin,
                              onEdit: () => _openEdit(_items[index]),
                              onDelete: () => _delete(_items[index]),
                              onStockMovement: () =>
                                  _openStockMovement(_items[index]),
                            ),
                          ),
                  ),

                  // ── Pagination ───────────────────────────────────────────────────
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
                            'Showing ${_currentPage * _pageSize + 1}–${(_currentPage * _pageSize + _items.length)} of $_totalCount',
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

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? color : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: active ? color : AppColors.kTextMid),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: active ? color : AppColors.kTextMid,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Row Widget ───────────────────────────────────────────────────────────────
class _InventoryRow extends StatefulWidget {
  final InventoryItemModel item;
  final bool isEven;
  final bool isAdmin;
  final VoidCallback onEdit, onDelete, onStockMovement;

  const _InventoryRow({
    required this.item,
    required this.isEven,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.onStockMovement,
  });

  @override
  State<_InventoryRow> createState() => _InventoryRowState();
}

class _InventoryRowState extends State<_InventoryRow> {
  bool _hovering = false;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

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
            // Avatar
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _InventoryAvatar(item: item),
            ),

            // Product name + SKU
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kTextDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.productSku != null)
                    Text(
                      item.productSku!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.kTextMid,
                      ),
                    ),
                ],
              ),
            ),

            // Pharmacy
            if (widget.isAdmin)
              Expanded(
                flex: 2,
                child: Text(
                  item.pharmacyName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.kTextMid,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // On Hand — centered
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  '${item.quantityOnHand}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kTextDark,
                  ),
                ),
              ),
            ),

            // Reserved — centered
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  '${item.reservedQuantity}',
                  style: TextStyle(
                    fontSize: 13,
                    color: item.reservedQuantity > 0
                        ? const Color(0xFFD97706)
                        : AppColors.kTextMid,
                  ),
                ),
              ),
            ),

            // Available — centered
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  '${item.availableQuantity}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: item.isLowStock
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF059669),
                  ),
                ),
              ),
            ),

            // Reorder Level — centered
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  '${item.reorderLevel}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.kTextMid,
                  ),
                ),
              ),
            ),

            // Expiration — centered, colored if needed
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  _fmt(item.expirationDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: item.isExpired
                        ? const Color(0xFFDC2626)
                        : item.isExpiringSoon
                        ? const Color(0xFFD97706)
                        : AppColors.kTextMid,
                  ),
                ),
              ),
            ),

            // Status — centered
            Expanded(
              flex: 1,
              child: Center(
                child: item.isExpired
                    ? _StatusBadge(
                        label: 'Expired',
                        bg: const Color(0xFFFEE2E2),
                        fg: const Color(0xFFDC2626),
                      )
                    : item.isLowStock
                    ? _StatusBadge(
                        label: 'Low Stock',
                        bg: const Color(0xFFFEF3C7),
                        fg: const Color(0xFFD97706),
                      )
                    : item.isExpiringSoon
                    ? _StatusBadge(
                        label: 'Exp. Soon',
                        bg: const Color(0xFFFEF3C7),
                        fg: const Color(0xFFD97706),
                      )
                    : _StatusBadge(
                        label: 'OK',
                        bg: const Color(0xFFD1FAE5),
                        fg: const Color(0xFF059669),
                      ),
              ),
            ),

            // Actions — centered
            SizedBox(
              width: 100,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: widget.onStockMovement,
                      icon: const Icon(
                        Icons.swap_vert_rounded,
                        size: 16,
                        color: AppColors.kTeal,
                      ),
                      tooltip: 'Stock Movement',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    if (widget.isAdmin) ...[
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
                        tooltip: 'Remove',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
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

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _StatusBadge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
    ),
  );
}

class _InventoryAvatar extends StatelessWidget {
  final InventoryItemModel item;
  const _InventoryAvatar({required this.item});

  @override
  Widget build(BuildContext context) {
    final url = item.fullImageUrl;
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: AppColors.kTealLight,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(
      Icons.inventory_2_outlined,
      size: 18,
      color: AppColors.kTeal,
    ),
  );
}

// ─── Stock Movement Dialog ────────────────────────────────────────────────────
class _StockMovementDialog extends StatefulWidget {
  final InventoryItemModel item;
  final VoidCallback onSaved;
  const _StockMovementDialog({required this.item, required this.onSaved});

  @override
  State<_StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends State<_StockMovementDialog> {
  int _selectedType = 1;
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _reasonRequired => _selectedType == 2 || _selectedType == 3;

  Future<void> _save() async {
    final qty = int.tryParse(_quantityController.text.trim());
    if (qty == null || qty < 1) {
      setState(() => _error = 'Quantity must be at least 1.');
      return;
    }
    if (_reasonRequired && _reasonController.text.trim().isEmpty) {
      setState(() => _error = 'Reason is required for Out and Adjustment.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await InventoryService.addStockMovement({
        'inventoryItemId': widget.item.id,
        'type': _selectedType,
        'quantity': qty,
        if (_reasonController.text.trim().isNotEmpty)
          'reason': _reasonController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Stock movement recorded.'),
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

  InputDecoration _inputDeco({String hint = ''}) => InputDecoration(
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
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.swap_vert_rounded,
                    color: AppColors.kTeal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock Movement',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextDark,
                          ),
                        ),
                        Text(
                          widget.item.productName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.kTextMid,
                          ),
                        ),
                      ],
                    ),
                  ),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.kBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _StockInfoCell(
                      label: 'On Hand',
                      value: '${widget.item.quantityOnHand}',
                      color: AppColors.kTextDark,
                    ),
                    const SizedBox(width: 16),
                    _StockInfoCell(
                      label: 'Reserved',
                      value: '${widget.item.reservedQuantity}',
                      color: const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 16),
                    _StockInfoCell(
                      label: 'Available',
                      value: '${widget.item.availableQuantity}',
                      color: widget.item.isLowStock
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF059669),
                    ),
                  ],
                ),
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
              const Text(
                'Movement Type',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextMid,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MovementTypeChip(
                    label: 'Stock In',
                    icon: Icons.add_circle_outline,
                    selected: _selectedType == 1,
                    color: const Color(0xFF059669),
                    onTap: () => setState(() => _selectedType = 1),
                  ),
                  const SizedBox(width: 8),
                  _MovementTypeChip(
                    label: 'Stock Out',
                    icon: Icons.remove_circle_outline,
                    selected: _selectedType == 2,
                    color: const Color(0xFFDC2626),
                    onTap: () => setState(() => _selectedType = 2),
                  ),
                  const SizedBox(width: 8),
                  _MovementTypeChip(
                    label: 'Adjustment',
                    icon: Icons.tune_rounded,
                    selected: _selectedType == 3,
                    color: const Color(0xFF6366F1),
                    onTap: () => setState(() => _selectedType = 3),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _selectedType == 3 ? 'New Total Quantity *' : 'Quantity *',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextMid,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.kTextDark,
                ),
                decoration: _inputDeco(
                  hint: _selectedType == 3
                      ? 'Enter new total quantity'
                      : 'Enter quantity',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text(
                    'Reason',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextMid,
                    ),
                  ),
                  if (_reasonRequired)
                    const Text(
                      ' *',
                      style: TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.kTextDark,
                ),
                decoration: _inputDeco(
                  hint: _reasonRequired
                      ? 'Required for Out and Adjustment...'
                      : 'Optional note...',
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
                        : const Icon(Icons.check_rounded, size: 15),
                    label: const Text(
                      'Confirm',
                      style: TextStyle(fontSize: 13),
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

class _StockInfoCell extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StockInfoCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.kTextMid),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}

class _MovementTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _MovementTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? color : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: selected ? color : AppColors.kTextMid),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? color : AppColors.kTextMid,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Add/Edit Inventory Item Dialog ──────────────────────────────────────────
class _InventoryItemDialog extends StatefulWidget {
  final InventoryItemModel? item;
  final VoidCallback onSaved;
  const _InventoryItemDialog({this.item, required this.onSaved});

  @override
  State<_InventoryItemDialog> createState() => _InventoryItemDialogState();
}

class _InventoryItemDialogState extends State<_InventoryItemDialog> {
  bool get _isEdit => widget.item != null;

  final _quantityController = TextEditingController();
  final _reorderController = TextEditingController();
  DateTime? _expirationDate;
  bool _saving = false;
  String? _error;
  int? _selectedProductId;
  int? _selectedPharmacyId;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _pharmacies = [];
  bool _loadingDropdowns = false;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _quantityController.text = widget.item!.quantityOnHand.toString();
      _reorderController.text = widget.item!.reorderLevel.toString();
      _expirationDate = widget.item!.expirationDate;
    } else {
      _reorderController.text = '10';
      _loadDropdowns();
    }
  }

  Future<void> _loadDropdowns() async {
    setState(() => _loadingDropdowns = true);
    try {
      final prodData = await ApiService.get('Product?retrieveAll=true');
      final pharData = await ApiService.get('Pharmacy?retrieveAll=true');
      if (mounted) {
        setState(() {
          _products = (prodData['items'] as List)
              .map((e) => {'id': e['id'], 'name': e['name']})
              .toList();
          _pharmacies = (pharData['items'] as List)
              .map((e) => {'id': e['id'], 'name': e['name']})
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Dropdown load error: $e');
    } finally {
      if (mounted) setState(() => _loadingDropdowns = false);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reorderController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.kTeal),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  Future<void> _save() async {
    final qty = int.tryParse(_quantityController.text.trim());
    if (qty == null || qty < 0) {
      setState(() => _error = 'Quantity must be 0 or greater.');
      return;
    }
    final reorder = int.tryParse(_reorderController.text.trim()) ?? 10;
    if (_expirationDate == null) {
      setState(() => _error = 'Expiration date is required.');
      return;
    }
    if (!_isEdit &&
        (_selectedProductId == null || _selectedPharmacyId == null)) {
      setState(() => _error = 'Please select a product and pharmacy.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        await InventoryService.update(widget.item!.id, {
          'quantityOnHand': qty,
          'reorderLevel': reorder,
          'expirationDate': _expirationDate!.toIso8601String(),
        });
      } else {
        await InventoryService.create({
          'pharmacyId': _selectedPharmacyId,
          'productId': _selectedProductId,
          'quantityOnHand': qty,
          'reorderLevel': reorder,
          'expirationDate': _expirationDate!.toIso8601String(),
        });
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDeco({String? hint}) => InputDecoration(
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
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isEdit ? Icons.edit_outlined : Icons.add_circle_outline,
                    color: AppColors.kTeal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEdit ? 'Edit Inventory Item' : 'Add to Inventory',
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
                if (_loadingDropdowns)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.kTeal),
                  )
                else ...[
                  _Label('Product *'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int?>(
                    value: _selectedProductId,
                    isExpanded: true,
                    hint: const Text(
                      'Select product',
                      style: TextStyle(color: AppColors.kTextMid, fontSize: 13),
                    ),
                    decoration: _inputDeco(),
                    items: _products
                        .map(
                          (p) => DropdownMenuItem<int?>(
                            value: p['id'],
                            child: Text(
                              p['name'],
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedProductId = v),
                  ),
                  const SizedBox(height: 14),
                  _Label('Pharmacy *'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int?>(
                    value: _selectedPharmacyId,
                    isExpanded: true,
                    hint: const Text(
                      'Select pharmacy',
                      style: TextStyle(color: AppColors.kTextMid, fontSize: 13),
                    ),
                    decoration: _inputDeco(),
                    items: _pharmacies
                        .map(
                          (p) => DropdownMenuItem<int?>(
                            value: p['id'],
                            child: Text(
                              p['name'],
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPharmacyId = v),
                  ),
                  const SizedBox(height: 14),
                ],
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.kBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: AppColors.kTeal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item!.productName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kTextDark,
                              ),
                            ),
                            Text(
                              widget.item!.pharmacyName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.kTextMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Quantity on Hand *'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.kTextDark,
                          ),
                          decoration: _inputDeco(hint: '0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Reorder Level'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _reorderController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.kTextDark,
                          ),
                          decoration: _inputDeco(hint: '10'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _Label('Expiration Date *'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.kTextMid,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _expirationDate != null
                            ? '${_expirationDate!.day.toString().padLeft(2, '0')}.${_expirationDate!.month.toString().padLeft(2, '0')}.${_expirationDate!.year}'
                            : 'Select date',
                        style: TextStyle(
                          fontSize: 13,
                          color: _expirationDate != null
                              ? AppColors.kTextDark
                              : AppColors.kTextMid,
                        ),
                      ),
                    ],
                  ),
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
                      _isEdit ? 'Save Changes' : 'Add Item',
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

  Widget _Label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.kTextMid,
    ),
  );
}
