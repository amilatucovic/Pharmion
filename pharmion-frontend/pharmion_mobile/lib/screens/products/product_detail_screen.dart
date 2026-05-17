import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/services/api_service.dart';
import '../../widgets/common/reserve_bottom_sheet.dart';
import '../../core/errors/app_exception.dart';

class ProductDetailScreen extends StatefulWidget {
  final InventoryItemModel inventoryItem;
  const ProductDetailScreen({super.key, required this.inventoryItem});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _loading = true;
  ProductModel? _product;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final data =
          await ApiService.get('Product/${widget.inventoryItem.productId}')
              as Map<String, dynamic>;
      if (mounted) setState(() => _product = ProductModel.fromJson(data));
    } on NetworkException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.kError,
          behavior: SnackBarBehavior.floating,
        ));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.kError,
          behavior: SnackBarBehavior.floating,
        ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.inventoryItem;

    return Scaffold(
      backgroundColor: AppColors.kBg,
      bottomNavigationBar: (!_loading && _product != null)
          ? Container(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => ReserveBottomSheet.show(
                  context,
                  inventoryItem: widget.inventoryItem,
                  isPrescriptionRequired: _product!.isPrescriptionRequired,
                  productName: _product!.name,
                  price: _product!.price,
                ),
                icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                label: const Text('Reserve Now'),
              ),
            )
          : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kTeal))
          : _product == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.kTextLight),
                      const SizedBox(height: 12),
                      const Text('Failed to load product',
                          style: TextStyle(color: AppColors.kTextMid)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadProduct, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildContent(item, _product!),
    );
  }

  Widget _buildContent(InventoryItemModel item, ProductModel product) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.kTextDark,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.kTextDark),
            ),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: Colors.white,
              child: product.hasRealImage
                  ? Image.network(
                      '${AppConstants.baseUrl}${product.imageUrl}',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _defaultProductImage(),
                    )
                  : _defaultProductImage(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.kBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(product.name,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.kTextDark)),
                          ),
                          if (product.isPrescriptionRequired)
                            Container(
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_long_outlined,
                                      size: 12, color: AppColors.kError),
                                  SizedBox(width: 4),
                                  Text('Prescription',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.kError)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          product.typeName,
                          if (product.manufacturer != null)
                            product.manufacturer!
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.kTextMid),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        _StatChip(
                          icon: Icons.payments_outlined,
                          label: '${product.price.toStringAsFixed(2)} KM',
                          color: AppColors.kTeal,
                          bg: AppColors.kTealLight,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.inventory_2_outlined,
                          label: product.packageSize != null
                              ? '${product.packageSize} ${product.unit ?? 'pcs'}'
                              : product.unit ?? '—',
                          color: const Color(0xFF6366F1),
                          bg: const Color(0xFFEDE9FE),
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: item.isAvailable
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_outlined,
                          label:
                              item.isAvailable ? 'In stock' : 'Not available',
                          color: item.isAvailable
                              ? AppColors.kSuccess
                              : AppColors.kError,
                          bg: item.isAvailable
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEE2E2),
                        ),
                      ]),
                    ],
                  ),
                ),
                if (product.description != null &&
                    product.description!.isNotEmpty)
                  _InfoCard(
                    title: 'Description',
                    icon: Icons.info_outline,
                    children: [
                      Text(product.description!,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.kTextMid,
                              height: 1.5)),
                    ],
                  ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Availability',
                  icon: Icons.local_pharmacy_outlined,
                  children: [
                    _DetailRow(label: 'Pharmacy', value: item.pharmacyName),
                    _DetailRow(
                        label: 'Available',
                        value: item.isAvailable ? 'In stock' : 'Not available',
                        valueColor: item.isAvailable
                            ? AppColors.kSuccess
                            : AppColors.kError),
                  ],
                ),
                const SizedBox(height: 12),
                if (product.instructionsForUse.isNotEmpty)
                  _ExpandableCard(
                    title: 'Instructions for Use',
                    icon: Icons.info_outline,
                    content: product.instructionsForUse,
                    iconColor: AppColors.kTeal,
                    iconBg: AppColors.kTealLight,
                  ),
                if (product.sideEffects.isNotEmpty)
                  _ExpandableCard(
                    title: 'Side Effects',
                    icon: Icons.warning_amber_outlined,
                    content: product.sideEffects,
                    iconColor: AppColors.kWarning,
                    iconBg: const Color(0xFFFEF3C7),
                  ),
                if (product.contraindications.isNotEmpty)
                  _ExpandableCard(
                    title: 'Contraindications',
                    icon: Icons.block_outlined,
                    content: product.contraindications,
                    iconColor: AppColors.kError,
                    iconBg: AppColors.kErrorLight,
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _defaultProductImage() => Container(
        color: AppColors.kTealLight,
        child: const Center(
          child:
              Icon(Icons.medication_rounded, color: AppColors.kTeal, size: 80),
        ),
      );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      );
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.kTealLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.kTeal),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kTextDark)),
            ]),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.kBorder),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.kTextMid,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.kTextDark)),
          ),
        ]),
      );
}

class _ExpandableCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String content;
  final Color iconColor;
  final Color iconBg;
  const _ExpandableCard({
    required this.title,
    required this.icon,
    required this.content,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: widget.iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icon, size: 16, color: widget.iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextDark)),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.kTextMid),
                ),
              ]),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.kBorder),
                  const SizedBox(height: 12),
                  Text(widget.content,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.kTextMid,
                          height: 1.5)),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ]),
      );
}
