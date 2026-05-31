import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/inventory_item_model.dart';
import '../../core/errors/app_exception.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<ProductModel> _products = [];
  bool _productsLoading = true;
  bool _loadingMore = false;
  String? _productsError;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedTypeName;
  int _page = 0;
  static const int _pageSize = 10;
  bool _hasMore = true;

  List<RecommendationModel> _recommendations = [];
  bool _recsLoading = true;
  String? _recsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProducts(reset: true);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _productsLoading = true;
        _productsError = null;
        _page = 0;
        _hasMore = true;
        _products = [];
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      String url =
          'Product?pageSize=$_pageSize&page=$_page&isActive=true&includeTotalCount=true';
      if (_selectedTypeName != null)
        url += '&type=${_typeNameToInt(_selectedTypeName!)}';
      if (_searchQuery.trim().isNotEmpty)
        url += '&name=${Uri.encodeComponent(_searchQuery.trim())}';

      final data = await ApiService.get(url) as Map<String, dynamic>;
      final items = ((data['items'] as List?) ?? [])
          .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
          .toList();

      final totalCount = data['totalCount'] as int? ?? 0;

      if (mounted) {
        setState(() {
          if (reset) {
            _products = items;
          } else {
            _products.addAll(items);
          }
          _page++;
          _hasMore = _products.length < totalCount;
        });
      }
    } on UnauthorizedException {
      if (mounted) context.read<AuthProvider>().logout();
    } on NetworkException catch (e) {
      if (mounted) setState(() => _productsError = e.message);
    } catch (e) {
      if (mounted)
        setState(
            () => _productsError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted)
        setState(() {
          _productsLoading = false;
          _loadingMore = false;
        });
    }
  }

  int? _typeNameToInt(String typeName) {
    const map = {
      'Medication': 1,
      'Supplement': 2,
      'MedicalDevice': 3,
      'Cosmetic': 4,
      'BabyAndChild': 5,
      'Orthopedics': 6,
      'Homeopathy': 7,
      'HerbalAndTea': 8,
    };
    return map[typeName];
  }

  Future<void> _loadRecommendations() async {
    final auth = context.read<AuthProvider>();
    final patientId = auth.userId;
    if (patientId == null) return;

    setState(() {
      _recsLoading = true;
      _recsError = null;
    });
    try {
      final data = await ApiService.get('Recommendation/$patientId?count=5')
          as List<dynamic>;
      final items = data
          .map((r) => RecommendationModel.fromJson(r as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _recommendations = items);
    } on UnauthorizedException {
      if (mounted) context.read<AuthProvider>().logout();
    } on NetworkException catch (e) {
      if (mounted) setState(() => _productsError = e.message);
    } catch (e) {
      if (mounted)
        setState(() => _recsError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _recsLoading = false);
    }
  }

  static const _types = [
    (null, 'All'),
    ('Medication', 'Medication'),
    ('Supplement', 'Supplement'),
    ('MedicalDevice', 'Medical Device'),
    ('Cosmetic', 'Cosmetic'),
    ('BabyAndChild', 'Baby & Child'),
    ('Orthopedics', 'Orthopedics'),
    ('Homeopathy', 'Homeopathy'),
    ('HerbalAndTea', 'Herbal & Tea'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Products',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextDark),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.kTeal,
          unselectedLabelColor: AppColors.kTextMid,
          indicatorColor: AppColors.kTeal,
          indicatorWeight: 2,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'All Products'),
            Tab(text: 'For You'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildRecommendationsTab(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_productsLoading)
      return const Center(
          child: CircularProgressIndicator(color: AppColors.kTeal));
    if (_productsError != null)
      return _ErrorState(
          error: _productsError!, onRetry: () => _loadProducts(reset: true));

    return RefreshIndicator(
      color: AppColors.kTeal,
      onRefresh: () => _loadProducts(reset: true),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                    _loadProducts(reset: true);
                  },
                  style:
                      const TextStyle(fontSize: 14, color: AppColors.kTextDark),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: const TextStyle(
                        color: AppColors.kTextLight, fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.kTextMid, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                              _loadProducts(reset: true);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.kBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.kTeal, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _types
                        .map((t) => _TypeChip(
                              label: t.$2,
                              selected: _selectedTypeName == t.$1,
                              onTap: () {
                                setState(() => _selectedTypeName = t.$1);
                                _loadProducts(reset: true);
                              },
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(children: [
              Text(
                '${_products.length} product${_products.length != 1 ? 's' : ''} loaded',
                style: const TextStyle(fontSize: 13, color: AppColors.kTextMid),
              ),
            ]),
          ),
          Expanded(
            child: _products.isEmpty
                ? _EmptyState(
                    icon: Icons.medication_outlined,
                    message: _searchQuery.isNotEmpty
                        ? 'No results for "$_searchQuery"'
                        : 'No products found',
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) =>
                            _ProductGridCard(product: _products[index]),
                      ),
                      if (_hasMore) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed:
                                _loadingMore ? null : () => _loadProducts(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.kTeal,
                              side: const BorderSide(color: AppColors.kTeal),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _loadingMore
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: AppColors.kTeal))
                                : const Text('Load More'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    if (_recsLoading)
      return const Center(
          child: CircularProgressIndicator(color: AppColors.kTeal));
    if (_recsError != null)
      return _ErrorState(error: _recsError!, onRetry: _loadRecommendations);

    if (_recommendations.isEmpty)
      return const _EmptyState(
        icon: Icons.auto_awesome_outlined,
        message: 'No recommendations yet.\nReserve some products first!',
      );

    return RefreshIndicator(
      color: AppColors.kTeal,
      onRefresh: _loadRecommendations,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF03989E), Color(0xFF026E73)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personalized for You',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on your reservation history',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          ..._recommendations.map((rec) => _RecommendationCard(rec: rec)),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.kTeal : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.kTeal : AppColors.kBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.kTextMid,
            ),
          ),
        ),
      );
}

class _ProductGridCard extends StatelessWidget {
  final ProductModel product;
  const _ProductGridCard({required this.product});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _showProductInfo(context),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.hasRealImage
                    ? Image.network(
                        '${AppConstants.baseUrl}${product.imageUrl}',
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultImage(),
                      )
                    : _defaultImage(),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.typeName,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.kTextMid),
                    ),
                    if (product.manufacturer != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.manufacturer!,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.kTextLight),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(2)} KM',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kTeal),
                        ),
                        if (product.isPrescriptionRequired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Rx',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.kError)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _defaultImage() => Container(
        height: 120,
        width: double.infinity,
        color: AppColors.kTealLight,
        child: const Icon(Icons.medication_rounded,
            color: AppColors.kTeal, size: 40),
      );

  void _showProductInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductInfoSheet(product: product),
    );
  }
}

class _ProductInfoSheet extends StatefulWidget {
  final ProductModel product;
  const _ProductInfoSheet({required this.product});

  @override
  State<_ProductInfoSheet> createState() => _ProductInfoSheetState();
}

class _ProductInfoSheetState extends State<_ProductInfoSheet> {
  List<InventoryItemModel> _pharmacies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    final auth = context.read<AuthProvider>();
    final cityId = auth.cityId;

    try {
      String url = 'InventoryItem/public?productId=${widget.product.id}';
      if (cityId != null) url += '&cityId=$cityId';

      final data = await ApiService.get(url) as List<dynamic>;
      final items = data
          .map((e) => InventoryItemModel.fromJson(e as Map<String, dynamic>))
          .where((e) => e.isAvailable)
          .toList();

      if (mounted) setState(() => _pharmacies = items);
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
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.kBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close,
                          size: 20, color: AppColors.kTextMid),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.product.hasRealImage
                            ? Image.network(
                                '${AppConstants.baseUrl}${widget.product.imageUrl}',
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: AppColors.kTealLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.medication_rounded,
                                    color: AppColors.kTeal, size: 32),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.product.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.kTextDark)),
                            const SizedBox(height: 4),
                            Text(widget.product.typeName,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.kTextMid)),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.product.price.toStringAsFixed(2)} KM',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.kTeal),
                            ),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.kBorder),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.local_pharmacy_outlined,
                          size: 16, color: AppColors.kTeal),
                      const SizedBox(width: 6),
                      const Text(
                        'Available in your city',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextDark),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              color: AppColors.kTeal, strokeWidth: 2),
                        ),
                      )
                    else if (_pharmacies.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.kBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.kBorder),
                        ),
                        child: const Row(children: [
                          Icon(Icons.info_outline,
                              size: 16, color: AppColors.kTextMid),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Not available in pharmacies in your city.',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.kTextMid),
                            ),
                          ),
                        ]),
                      )
                    else
                      ..._pharmacies.map((p) => _PharmacyAvailabilityCard(
                            inventoryItem: p,
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/product-detail', extra: p);
                            },
                          )),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _PharmacyAvailabilityCard extends StatelessWidget {
  final InventoryItemModel inventoryItem;
  final VoidCallback onTap;

  const _PharmacyAvailabilityCard({
    required this.inventoryItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.kTealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_pharmacy_outlined,
                  size: 18, color: AppColors.kTeal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                inventoryItem.pharmacyName,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kTextDark),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Available',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kSuccess),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.kTextLight),
          ]),
        ),
      );
}

class _RecommendationCard extends StatelessWidget {
  final RecommendationModel rec;
  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kTeal.withValues(alpha: 0.15)),
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
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: rec.product.hasRealImage
                    ? Image.network(
                        '${AppConstants.baseUrl}${rec.product.imageUrl}',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultImage(),
                      )
                    : _defaultImage(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec.product.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextDark)),
                    const SizedBox(height: 2),
                    Text(rec.product.typeName,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.kTextMid)),
                    const SizedBox(height: 4),
                    Text(
                      '${rec.product.price.toStringAsFixed(2)} KM',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTeal),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.kTealLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    size: 13, color: AppColors.kTeal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(rec.reason,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.kTeal,
                          fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _ProductInfoSheet(product: rec.product),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kTeal,
                  side: const BorderSide(color: AppColors.kTeal),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.local_pharmacy_outlined, size: 16),
                label: const Text('Find in Pharmacy',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      );

  Widget _defaultImage() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.kTealLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.medication_rounded,
            color: AppColors.kTeal, size: 26),
      );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.kTealLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: AppColors.kTeal),
              ),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kTextMid,
                      height: 1.4)),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.kErrorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    size: 32, color: AppColors.kError),
              ),
              const SizedBox(height: 16),
              const Text('Something went wrong',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextDark)),
              const SizedBox(height: 8),
              Text(error,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.kTextMid)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
}
