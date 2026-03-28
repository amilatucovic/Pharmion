import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  int? _selectedType;
  bool? _isActive;
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _loading = true;
  List<ProductModel> _products = [];
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
      final result = await ProductService.getProducts(
        page: _currentPage,
        pageSize: _pageSize,
        name: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        type: _selectedType,
        isActive: _isActive,
      );
      if (mounted) {
        setState(() {
          _products = result.items;
          _totalCount = result.totalCount;
        });
      }
    } catch (e) {
      debugPrint('Products load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalPages {
    if (_totalCount == 0) return 0;
    return (_totalCount / _pageSize).ceil();
  }

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    ).then((_) => _loadData());
  }

  void _openEdit(ProductModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: p)),
    ).then((_) => _loadData());
  }

  Future<void> _delete(ProductModel p) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Product',
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
      await ProductService.delete(p.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product deleted.'),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // ── Filters ──────────────────────────────────────────────────────────
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
                      hintText: 'Search by name, SKU, barcode...',
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
                  child: DropdownButtonFormField<int?>(
                    value: _selectedType, // ← FIX: value umjesto initialValue
                    hint: const Text(
                      'All types',
                      style: TextStyle(color: AppColors.kTextMid, fontSize: 13),
                    ),
                    decoration: _dropdownDecoration(),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'All types',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      ...ProductService.productTypes.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(
                            e.value,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedType = val;
                        _currentPage = 0;
                      });
                      _loadData();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: DropdownButtonFormField<bool?>(
                    value: _isActive, // ← FIX: value umjesto initialValue
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
                  label: const Text('New Product'),
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
                      children: [
                        // Image placeholder width
                        const SizedBox(width: 56),
                        // Product
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'Product',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Type
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Type',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Manufacturer
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Manufacturer',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Price
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Price',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Prescription Required — wider to fit text
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Prescription Required',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Status
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Actions
                        const SizedBox(
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

                  // Body
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.kTeal,
                            ),
                          )
                        : _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: 48,
                                  color: AppColors.kTextMid.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No products found',
                                  style: TextStyle(
                                    color: AppColors.kTextMid,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _products.length,
                            itemBuilder: (context, index) => _ProductRow(
                              product: _products[index],
                              isEven: index.isEven,
                              onEdit: () => _openEdit(_products[index]),
                              onDelete: () => _delete(_products[index]),
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
                            'Showing ${_currentPage * _pageSize + 1}–${(_currentPage * _pageSize + _products.length)} of $_totalCount',
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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

class _ProductRow extends StatefulWidget {
  final ProductModel product;
  final bool isEven;
  final VoidCallback onEdit, onDelete;

  const _ProductRow({
    required this.product,
    required this.isEven,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
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
            // ── Image avatar — fiksna širina + desni padding da odmaknemo tekst ──
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _ProductAvatar(product: p),
            ),

            // ── Product name + SKU ────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kTextDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (p.sku != null)
                    Text(
                      p.sku!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.kTextMid,
                      ),
                    ),
                ],
              ),
            ),

            // ── Type badge ────────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TypeBadge(type: p.type, typeName: p.typeName),
              ),
            ),

            // ── Manufacturer ──────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Text(
                p.manufacturer ?? '—',
                style: const TextStyle(fontSize: 12, color: AppColors.kTextMid),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Price ─────────────────────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Text(
                '${p.price.toStringAsFixed(2)} KM',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextDark,
                ),
              ),
            ),

            // ── Prescription Required — centriran icon ────────────────────────
            Expanded(
              flex: 2,
              child: p.isPrescriptionRequired
                  ? const Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Required',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      children: [
                        Icon(
                          Icons.remove_circle_outline,
                          size: 16,
                          color: AppColors.kTextMid,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Not Required',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.kTextMid,
                          ),
                        ),
                      ],
                    ),
            ),
            // ── Status ────────────────────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
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

            // ── Actions ───────────────────────────────────────────────────────
            SizedBox(
              width: 100,
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
          ],
        ),
      ),
    );
  }
}

class _ProductAvatar extends StatelessWidget {
  final ProductModel product;
  const _ProductAvatar({required this.product});

  @override
  Widget build(BuildContext context) {
    final url = product.fullImageUrl;
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
      Icons.medication_outlined,
      size: 18,
      color: AppColors.kTeal,
    ),
  );
}

class _TypeBadge extends StatelessWidget {
  final int type;
  final String typeName;
  const _TypeBadge({required this.type, required this.typeName});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (type) {
      case 1: // Medication
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        break;
      case 2: // Supplement
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        break;
      case 3: // Medical Device
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF7C3AED);
        break;
      case 4: // Cosmetic
        bg = const Color(0xFFFFE4E6);
        fg = const Color(0xFFE11D48);
        break;
      case 5: // Baby & Child
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case 6: // Orthopedics
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0284C7);
        break;
      case 7: // Homeopathy
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
        break;
      case 8: // Herbal & Tea
        bg = const Color(0xFFFEF9C3);
        fg = const Color(0xFF854D0E);
        break;
      case 9: // Diagnostic Test
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        break;
      case 10: // Personal Care
        bg = const Color(0xFFFDF4FF);
        fg = const Color(0xFF9333EA);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        typeName,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
